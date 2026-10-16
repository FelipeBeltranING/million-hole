extends Node2D
# Juego principal: mapa, cosas de lujo, caprichos (pedido), dinero, combo, bonus de tiempo,
# cuota, peligros y (cada 5 rondas) el jefe de la gala.

const ItemDB = preload("res://item_database.gd")
const ItemScript = preload("res://item.gd")
const PitScript = preload("res://pit.gd")
const PlayerScript = preload("res://player.gd")
const HudScript = preload("res://hud.gd")
const CoinScript = preload("res://coin.gd")
const TimeBonusScript = preload("res://time_bonus.gd")
const HazardScript = preload("res://hazard.gd")
const Assets = preload("res://assets.gd")

# --- Ronda ---
const MAX_TIME := 60.0      # el reloj nunca pasa de esto al sumar bonus (relojes, pedidos); la ronda normal EMPIEZA en 30 (Game.BASE_TIME)
# --- Colores del piso del mapa (cambialos aqui) ---
const FLOOR_A := Color("2A2547")      # baldosa oscura
const FLOOR_B := Color("332D57")      # baldosa clara (poca diferencia = se ve sutil)
const FLOOR_TILE := 64.0              # tamaño de cada baldosa en px
const FLOOR_OUTSIDE := Color("16132A")  # lo que queda detras del HUD, fuera del mapa
const FLOOR_EDGE := Color(1.0, 0.82, 0.15, 0.55)   # linea dorada fina en el borde del mapa

const MAP_RECT := Rect2(48, 100, 1184, 528)   # zona de juego (el HUD ocupa el resto)

# --- Objetos en el mapa ---
const ITEMS_ON_MAP := 18
const ITEM_RESPAWN := 1.5   # cada cuantos segundos reaparece uno si faltan
# En la gala del jefe hacen falta MUCHOS mas objetos (los caprichos son su unica debilidad)
const BOSS_ITEMS_ON_MAP := 36
const BOSS_ITEM_RESPAWN := 0.45

# --- Combo ---
const COMBO_WINDOW := 6.0
const COMBO_STEP := 0.5     # el tope (x3, o x5 con el Anillo del combo) lo da Game.combo_max()

# --- Pedido del pozo ---
const ORDER_SIZE := 3
const ORDER_SLOT_MULT := 3        # bonus por objeto pedido = puntos del objeto x esto
const ORDER_COMPLETE_POINTS := 25
const ORDER_COMPLETE_TIME := 4.0  # segundos que suma completar un pedido
const ORDER_COMPLETE_COINS := 8

# --- Dinero: cada pieza que sale del agujero es de un tipo al azar ---
const COIN_VALUE := 1     # moneda (la mas comun)
const BILL_VALUE := 2     # billete
const BAR_VALUE := 3      # lingote
const BILL_CHANCE := 0.16   # 16% de las piezas son billetes
const BAR_CHANCE := 0.04    # 4% son lingotes; el resto, ~80%, monedas

# --- Relojes de bonus ---
const BONUS_INTERVAL := 7.0
const BONUS_MAX_ON_MAP := 2
const BONUS_SECONDS := 2.0

var time_left := 30.0
var max_time := MAX_TIME
var quota := 0
var quota_toast_done := false
var passed := false
var boss_round := false
var boss = null               # el jefe (un hazard.gd con kind "boss"), o null
var boss_defeated := false
var order_size := ORDER_SIZE
var items_on_map := ITEMS_ON_MAP     # en la gala sube a BOSS_ITEMS_ON_MAP
var item_respawn := ITEM_RESPAWN     # en la gala baja a BOSS_ITEM_RESPAWN
var score := 0
var coins_collected := 0
var money_frac := 0.0         # resto fraccionario de los multiplicadores de dinero
var orders_completed := 0
var combo := 0
var combo_timer := 0.0
var respawn_timer := ITEM_RESPAWN
var bonus_timer := BONUS_INTERVAL
var order_slots: Array = []   # [{"item": Dictionary, "done": bool}, ...]
var running := true
var can_leave := false
var tally := {}
var map_rect := Rect2()
var pit
var player
var hud
var last_tick := -1    # ultimo segundo en que sono el tic de cuenta regresiva

func _ready() -> void:
	randomize()
	var r := Game.round_number
	boss_round = Game.is_boss_round(r)
	order_size = Game.BOSS_ORDER_SIZE if boss_round else ORDER_SIZE
	items_on_map = BOSS_ITEMS_ON_MAP if boss_round else ITEMS_ON_MAP
	item_respawn = BOSS_ITEM_RESPAWN if boss_round else ITEM_RESPAWN
	respawn_timer = item_respawn
	time_left = Game.round_time(r)
	max_time = maxf(MAX_TIME + (Game.BOSS_EXTRA_TIME if boss_round else 0.0), time_left)
	quota = Game.current_quota(r)
	var size := get_viewport_rect().size
	map_rect = MAP_RECT

	pit = PitScript.new()
	pit.radius = pit.radius * Game.pit_scale()
	pit.position = size / 2.0
	var pplan := Game.pit_plan(r)
	pit.map_rect = map_rect
	pit.avoid_zones = HudScript.ZONES
	pit.mode = pplan["mode"]
	pit.interval = pplan["interval"]
	pit.move_speed = pplan["speed"]
	pit.relocating.connect(_on_pit_relocating)
	pit.relocated.connect(_on_pit_relocated)
	add_child(pit)

	for i in items_on_map:
		_spawn_item()

	player = PlayerScript.new()
	player.position = size / 2.0 + Vector2(0, 130)
	player.map_rect = map_rect
	player.pit = pit
	player.items_deposited.connect(_on_items_deposited)
	player.coin_collected.connect(_on_coin_collected)
	player.time_bonus_collected.connect(_on_time_bonus_collected)
	player.hit_taken.connect(_on_player_hit)
	player.shield_blocked.connect(_on_shield_blocked)
	add_child(player)

	hud = HudScript.new()
	add_child(hud)
	player.carry_changed.connect(hud.set_carry)
	hud.set_time(time_left)
	hud.set_quota(quota)
	hud.set_score(score)
	hud.set_coins(Game.coins)
	hud.set_round(r, Game.best_round_score, Game.CONTRACTS[Game.contract_id]["name"])
	hud.set_relics(Game.relics)
	hud.set_carry(player.carried, player.max_carry)
	hud.set_combo(0, 1.0, 0.0)
	_new_order()
	_spawn_hazards()
	if boss_round:
		_spawn_boss()
	Sound.music("music_boss" if boss_round else "music_game")
	if not boss_round:
		Sound.play("sfx_round_start")   # en la gala suena sfx_boss_intro en su lugar

# ---------------------------------------------------------------- Objetos

func _random_pos(min_pit_dist: float) -> Vector2:
	var pos := Vector2.ZERO
	for attempt in 30:
		pos = Vector2(
			randf_range(map_rect.position.x + 20.0, map_rect.end.x - 20.0),
			randf_range(map_rect.position.y + 20.0, map_rect.end.y - 20.0))
		if pos.distance_to(pit.position) > min_pit_dist and not _in_hud(pos):
			break
	return pos

# true si el punto cae debajo de un panel del HUD
func _in_hud(p: Vector2) -> bool:
	for z in HudScript.ZONES:
		if z.grow(18.0).has_point(p):
			return true
	return false

func _spawn_item(data: Dictionary = {}, at = null) -> void:
	var item = ItemScript.new()
	item.position = at if at != null else _random_pos(pit.radius + 60.0)
	add_child(item)
	if player != null:
		move_child(item, player.get_index())   # el jugador se dibuja encima
	item.setup(data if not data.is_empty() else ItemDB.pick_weighted(Game.rarity_mults()))
	item.set_highlight(_is_wanted(item.data["name"]))

func _count_on_map(item_name: String) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("items"):
		if node.data["name"] == item_name:
			n += 1
	return n

# ---------------------------------------------------------------- Pedido

func _is_wanted(item_name: String) -> bool:
	for slot in order_slots:
		if not slot["done"] and slot["item"]["name"] == item_name:
			return true
	return false

func _refresh_highlights() -> void:
	for node in get_tree().get_nodes_in_group("items"):
		node.set_highlight(_is_wanted(node.data["name"]))

func _new_order() -> void:
	var pool: Array = ItemDB.ITEMS.duplicate()
	pool.shuffle()
	order_slots = []
	for i in order_size:
		order_slots.append({"item": pool[i], "done": false})
		# asegurar que al menos uno de cada tipo pedido exista en el mapa
		if _count_on_map(pool[i]["name"]) == 0:
			_spawn_item(pool[i])
	hud.set_order(order_slots)
	_refresh_highlights()

func _order_is_complete() -> bool:
	for slot in order_slots:
		if not slot["done"]:
			return false
	return true

# ---------------------------------------------------------------- Bucle

func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(time_left - delta, 0.0)
	hud.set_time(time_left)
	var secs_left := ceili(time_left)
	if time_left > 0.0 and secs_left <= 5 and secs_left != last_tick:
		last_tick = secs_left
		Sound.play("sfx_time_tick")   # ultimos 5 segundos
	hud.set_tools(Game.level("bolsazo"), player.swing_cd,
		Game.stock_of("turbo"), Game.stock_of("shield"), Game.stock_of("flash"))
	_update_combo(delta)

	respawn_timer -= delta
	if respawn_timer <= 0.0:
		respawn_timer = item_respawn
		if get_tree().get_nodes_in_group("items").size() < items_on_map:
			_spawn_item()

	bonus_timer -= delta
	if bonus_timer <= 0.0:
		bonus_timer = BONUS_INTERVAL
		if not Game.no_time_bonuses() and get_tree().get_nodes_in_group("time_bonuses").size() < BONUS_MAX_ON_MAP:
			_spawn_time_bonus()

	if time_left <= 0.0:
		_end_game()

func _update_combo(delta: float) -> void:
	if combo <= 0:
		return
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo = 0
	hud.set_combo(combo, _multiplier(), maxf(combo_timer, 0.0))

func _multiplier() -> float:
	if combo <= 0:
		return 1.0
	return minf(1.0 + COMBO_STEP * float(combo - 1), Game.combo_max())

# ---------------------------------------------------------------- Eventos

func _on_items_deposited(items: Array) -> void:
	combo += 1
	combo_timer = maxf(2.0, COMBO_WINDOW + Game.combo_window_bonus())
	var mult := _multiplier()
	if combo >= 2:
		Sound.play("sfx_combo", 0.0, 1.0 + 0.07 * minf(float(combo - 2), 8.0))   # sube el tono con el combo
	var om := Game.order_mult()
	var coin_total := 0
	var slot_bonus := 0
	for it in items:
		var pts := int(it["points"])
		score += int(roundf(pts * mult * Game.score_mult()))
		coin_total += ceili(pts * mult)
		tally[it["name"]] = int(tally.get(it["name"], 0)) + 1
		# el objeto cuenta para el pedido si todavia falta
		for slot in order_slots:
			if not slot["done"] and slot["item"]["name"] == it["name"]:
				slot["done"] = true
				slot_bonus += pts * ORDER_SLOT_MULT
				break
	if slot_bonus > 0:
		slot_bonus = roundi(float(slot_bonus) * om)
		score += slot_bonus
		Sound.play("sfx_order_item")
		hud.toast("Pedido +%d" % slot_bonus, Color(1.0, 0.82, 0.15))
	_spawn_coins(coin_total)
	hud.set_score(score)
	_check_quota()
	hud.set_combo(combo, mult, combo_timer)
	hud.set_order(order_slots)

	if _order_is_complete():
		orders_completed += 1
		Sound.play("sfx_order_complete")
		score += roundi(ORDER_COMPLETE_POINTS * om)
		time_left = minf(time_left + ORDER_COMPLETE_TIME, max_time)
		_spawn_coins(roundi(ORDER_COMPLETE_COINS * om))
		hud.set_score(score)
		_check_quota()
		if boss != null:
			_damage_boss()
		else:
			hud.toast("¡PEDIDO COMPLETO!  +%ds" % int(ORDER_COMPLETE_TIME), Color(0.3, 0.95, 0.4))
		_new_order()
	else:
		_refresh_highlights()

# Avisa (una sola vez por ronda) cuando llegas a la cuota. Sigue jugando: mas puntos = mas dinero.
func _check_quota() -> void:
	if quota_toast_done or score < quota:
		return
	quota_toast_done = true
	get_tree().create_timer(0.7).timeout.connect(_show_quota_toast)

func _show_quota_toast() -> void:
	if running:
		Sound.play("sfx_quota")
		hud.toast("¡CUOTA CUMPLIDA!", Color(0.4, 1.0, 0.5))

func _on_pit_relocating(secs: float) -> void:
	Sound.play("sfx_vortex_warn")
	hud.toast("¡El vórtice se muda!", Color(1.0, 0.82, 0.15))

func _on_pit_relocated() -> void:
	pass

func _on_shield_blocked() -> void:
	hud.toast("¡ESCUDO!", Color(0.4, 0.9, 1.0))

func _on_player_hit(dropped: Array) -> void:
	hud.toast("¡AUCH!", Color(1.0, 0.3, 0.3))
	var m := Vector2(20, 20)
	for it in dropped:
		var p: Vector2 = player.position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 90.0)
		p = p.clamp(map_rect.position + m, map_rect.end - m)
		_spawn_item(it, p)   # lo que llevabas cae al suelo cerca de ti

func _on_coin_collected(value: int) -> void:
	# los multiplicadores de dinero (contrato, reliquias) pueden dar decimales: se acumula el resto
	money_frac += float(value) * Game.money_mult()
	var gain := floori(money_frac)
	money_frac -= float(gain)
	coins_collected += gain
	Game.coins += gain   # las monedas ya NO dan puntos: son dinero para la tienda
	hud.set_coins(Game.coins)

func _on_time_bonus_collected(seconds: float) -> void:
	time_left = minf(time_left + seconds, max_time)
	hud.toast("+%ds" % int(seconds), Color(0.30, 0.90, 0.95))

# ---------------------------------------------------------------- Spawns

# Sale una pieza por cada punto de "amount" (como antes: mucha cantidad = satisfaccion visual).
# Cada pieza es moneda, billete o lingote al azar, y vale 1, 2 o 3.
func _spawn_coins(amount: int) -> void:
	for i in amount:
		var r := randf()
		if r < BAR_CHANCE:
			_spawn_money("bar", BAR_VALUE)
		elif r < BAR_CHANCE + BILL_CHANCE:
			_spawn_money("bill", BILL_VALUE)
		else:
			_spawn_money("coin", COIN_VALUE)

func _spawn_money(kind: String, value: int) -> void:
	var m := Vector2(18, 18)
	var angle := randf() * TAU
	var dist := randf_range(pit.radius + 30.0, pit.radius + 140.0)
	var target: Vector2 = pit.position + Vector2.from_angle(angle) * dist
	target = target.clamp(map_rect.position + m, map_rect.end - m)
	var coin = CoinScript.new()
	coin.kind = kind
	coin.value = value
	coin.lifetime = CoinScript.BASE_LIFETIME + Game.coin_life_bonus()
	add_child(coin)
	move_child(coin, player.get_index())
	coin.launch(pit.position, target)

func _spawn_time_bonus() -> void:
	var bonus = TimeBonusScript.new()
	bonus.seconds = BONUS_SECONDS
	bonus.position = _random_pos(pit.radius + 120.0)
	add_child(bonus)
	move_child(bonus, player.get_index())

# ---------------------------------------------------------------- Peligros

func _hazard_pos(kind: String, placed: Array) -> Vector2:
	var pos := Vector2.ZERO
	for attempt in 40:
		pos = Vector2(
			randf_range(map_rect.position.x + 60.0, map_rect.end.x - 60.0),
			randf_range(map_rect.position.y + 60.0, map_rect.end.y - 60.0))
		var ok := true
		if kind == "paparazzi":
			ok = pos.distance_to(player.position) > 350.0
		else:
			ok = pos.distance_to(pit.position) > pit.radius + 90.0 and pos.distance_to(player.position) > 150.0
		if _in_hud(pos):
			ok = false
		for q in placed:
			if pos.distance_to(q) < 140.0:
				ok = false
		if ok:
			break
	return pos

func _spawn_hazards() -> void:
	var r := Game.round_number
	var plan := Game.hazard_plan(r)
	var placed: Array = []
	for kind in ["puddle", "spikes", "paparazzi"]:
		for i in int(plan[kind]):
			var h = HazardScript.new()
			h.kind = kind
			h.position = _hazard_pos(kind, placed)
			h.map_rect = map_rect
			h.target = player
			h.speed = Game.paparazzi_speed(r)
			if kind == "paparazzi":
				h.sleep_timer = Game.pap_sleep()
			placed.append(h.position)
			add_child(h)
			if kind == "puddle":
				move_child(h, pit.get_index())      # el charco queda debajo de todo
			else:
				move_child(h, player.get_index())   # encima de objetos, debajo del jugador
	if r == Game.HAZARD_START_ROUND:
		hud.toast("¡Cuidado! Charcos y pinchos", Color(1.0, 0.6, 0.2))
	elif r == Game.PAPARAZZI_START_ROUND:
		hud.toast("¡Cuidado! Paparazzi", Color(1.0, 0.6, 0.2))   # (usa el bolsazo para aturdirlos)

# ---------------------------------------------------------------- Jefe

func _spawn_boss() -> void:
	var r := Game.round_number
	boss = HazardScript.new()
	boss.kind = "boss"
	boss.position = _hazard_pos("paparazzi", [])   # lejos del jugador
	boss.map_rect = map_rect
	boss.target = player
	boss.speed = Game.boss_speed(r)
	boss.boss_size = Game.boss_radius(r)
	boss.orb_speed = Game.boss_orb_speed(r)
	boss.max_hp = Game.boss_hp(r)
	boss.hp = boss.max_hp
	boss.shoot_interval = Game.boss_shoot_interval(r)
	add_child(boss)
	move_child(boss, player.get_index())
	Sound.play("sfx_boss_intro")
	hud.set_boss(boss.hp, boss.max_hp)
	hud.toast("¡GALA!  Completa caprichos para derrotar al jefe", Color(1.0, 0.82, 0.15))

# Cada capricho completado le hace 1 de daño al jefe
func _damage_boss() -> void:
	boss.hp -= 1
	var away: Vector2 = (boss.position - pit.position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	if boss.hp <= 0:
		boss_defeated = true
		for h in get_tree().get_nodes_in_group("hazards"):
			if h.kind == "orb":
				h.queue_free()
		boss.queue_free()
		boss = null
		_spawn_coins(40)
		hud.hide_boss()
		Sound.play("sfx_boss_defeated")
		hud.toast("¡JEFE DERROTADO!", Color(1.0, 0.82, 0.15))
	else:
		var was_raging: bool = boss.is_raging()
		boss.boss_damaged(away)
		hud.set_boss(boss.hp, boss.max_hp)
		if boss.is_raging() and not was_raging:
			Sound.play("sfx_boss_rage")
			hud.toast("¡EL JEFE SE ENFURECE!", Color(1.0, 0.25, 0.3))
		hud.toast("¡GOLPE AL JEFE!  (%d/%d)" % [boss.max_hp - boss.hp, boss.max_hp], Color(1.0, 0.55, 0.2))

# ---------------------------------------------------------------- Fin

func _end_game() -> void:
	running = false
	player.active = false
	for h in get_tree().get_nodes_in_group("hazards"):
		h.set_process(false)
	pit.set_process(false)
	passed = score >= quota and (not boss_round or boss_defeated)
	if passed and boss_round:
		Game.free_relic_pending = true   # premio: una reliquia gratis en la boutique
	var new_record := Game.record_round(score)
	Sound.stop_music(0.4)
	Sound.play("sfx_round_end")
	var jingle := "jingle_win" if passed else "jingle_lose"
	get_tree().create_timer(0.8).timeout.connect(func(): Sound.play(jingle))
	hud.set_combo(0, 1.0, 0.0)
	hud.show_round_result({
		"passed": passed, "score": score, "quota": quota, "coins": coins_collected,
		"orders": orders_completed, "tally": tally, "round": Game.round_number,
		"new_record": new_record, "contract": Game.CONTRACTS[Game.contract_id]["name"],
		"boss_round": boss_round, "boss_defeated": boss_defeated,
		"run_best_score": Game.run_best_score, "run_best_round": Game.run_best_round,
		"session_best": Game.best_round_score, "session_best_round": Game.best_round_no})
	# pequeña pausa para no saltarse la pantalla sin querer
	get_tree().create_timer(0.8).timeout.connect(func(): can_leave = true)

func _unhandled_input(event: InputEvent) -> void:
	if running or not can_leave:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if passed:
				Sound.play("ui_click")
				get_tree().change_scene_to_file("res://shop.tscn")
			else:
				Sound.play("ui_start")
				Game.reset_run()   # perdiste: nueva partida directa
				get_tree().change_scene_to_file("res://main.tscn")
		elif event.keycode == KEY_ESCAPE:
			Sound.play("ui_back")
			Game.reset_run()
			get_tree().change_scene_to_file("res://menu.tscn")

func _draw() -> void:
	# con asset: res://assets/background.png (1280x720, cubre toda la pantalla)
	if Assets.draw_fill(self, "background", Rect2(Vector2.ZERO, get_viewport_rect().size)):
		return
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), FLOOR_OUTSIDE)
	var cols := ceili(map_rect.size.x / FLOOR_TILE)
	var rows := ceili(map_rect.size.y / FLOOR_TILE)
	for cy in rows:
		for cx in cols:
			var tile := Rect2(map_rect.position + Vector2(cx, cy) * FLOOR_TILE, Vector2(FLOOR_TILE, FLOOR_TILE))
			draw_rect(tile.intersection(map_rect), FLOOR_A if (cx + cy) % 2 == 0 else FLOOR_B)
	draw_rect(map_rect.grow(3.0), Color(0.07, 0.05, 0.04), false, 6.0)
	draw_rect(map_rect, FLOOR_EDGE, false, 2.0)
