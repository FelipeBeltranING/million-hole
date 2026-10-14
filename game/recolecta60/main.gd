extends Node2D
# Juego principal: mapa, cosas de lujo, caprichos (pedido), dinero, combo y bonus de tiempo.

const ItemDB = preload("res://item_database.gd")
const ItemScript = preload("res://item.gd")
const PitScript = preload("res://pit.gd")
const PlayerScript = preload("res://player.gd")
const HudScript = preload("res://hud.gd")
const CoinScript = preload("res://coin.gd")
const TimeBonusScript = preload("res://time_bonus.gd")
const HazardScript = preload("res://hazard.gd")

# --- Ronda ---
const GAME_TIME := 30.0     # segundos iniciales
const MAX_TIME := 60.0      # el reloj nunca pasa de esto
const MARGIN := 50.0

# --- Objetos en el mapa ---
const ITEMS_ON_MAP := 18
const ITEM_RESPAWN := 1.5   # cada cuantos segundos reaparece uno si faltan

# --- Combo ---
const COMBO_WINDOW := 6.0
const COMBO_STEP := 0.5
const COMBO_MAX := 3.0

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
const BILL_CHANCE := 0.16   # 16% de las piezas son billetes (antes 20%)
const BAR_CHANCE := 0.04    # 4% son lingotes (antes 6%); el resto, ~80%, monedas

# --- Relojes de bonus ---
const BONUS_INTERVAL := 7.0
const BONUS_MAX_ON_MAP := 2
const BONUS_SECONDS := 2.0

var time_left := GAME_TIME
var score := 0
var coins_collected := 0
var orders_completed := 0
var combo := 0
var combo_timer := 0.0
var respawn_timer := ITEM_RESPAWN
var bonus_timer := BONUS_INTERVAL
var order_slots: Array = []   # [{"item": Dictionary, "done": bool}, ...]
var quota := 0
var quota_toast_done := false
var passed := false
var running := true
var can_leave := false
var tally := {}
var map_rect := Rect2()
var pit
var player
var hud

func _ready() -> void:
	randomize()
	time_left = GAME_TIME + Game.start_time_bonus()
	quota = Game.quota_for(Game.round_number)
	var size := get_viewport_rect().size
	map_rect = Rect2(Vector2(MARGIN, MARGIN), size - Vector2(MARGIN, MARGIN) * 2.0)

	pit = PitScript.new()
	pit.position = size / 2.0
	add_child(pit)

	for i in ITEMS_ON_MAP:
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
	hud.set_round(Game.round_number, Game.best_round_score)
	hud.set_carry(player.carried, player.max_carry)
	hud.set_combo(0, 1.0, 0.0)
	_new_order()
	_spawn_hazards()

# ---------------------------------------------------------------- Objetos

func _random_pos(min_pit_dist: float) -> Vector2:
	var pos := Vector2.ZERO
	for attempt in 30:
		pos = Vector2(
			randf_range(map_rect.position.x + 20.0, map_rect.end.x - 20.0),
			randf_range(map_rect.position.y + 20.0, map_rect.end.y - 20.0))
		if pos.distance_to(pit.position) > min_pit_dist:
			break
	return pos

func _spawn_item(data: Dictionary = {}, at = null) -> void:
	var item = ItemScript.new()
	item.position = at if at != null else _random_pos(pit.radius + 60.0)
	add_child(item)
	if player != null:
		move_child(item, player.get_index())   # el jugador se dibuja encima
	item.setup(data if not data.is_empty() else ItemDB.pick_weighted())
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
	for i in ORDER_SIZE:
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
	hud.set_tools(Game.level("bolsazo"), player.swing_cd, Game.stock_of("turbo"), Game.stock_of("shield"))
	_update_combo(delta)

	respawn_timer -= delta
	if respawn_timer <= 0.0:
		respawn_timer = ITEM_RESPAWN
		if get_tree().get_nodes_in_group("items").size() < ITEMS_ON_MAP:
			_spawn_item()

	bonus_timer -= delta
	if bonus_timer <= 0.0:
		bonus_timer = BONUS_INTERVAL
		if get_tree().get_nodes_in_group("time_bonuses").size() < BONUS_MAX_ON_MAP:
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
	return minf(1.0 + COMBO_STEP * float(combo - 1), COMBO_MAX)

# ---------------------------------------------------------------- Eventos

func _on_items_deposited(items: Array) -> void:
	combo += 1
	combo_timer = COMBO_WINDOW + Game.combo_window_bonus()
	var mult := _multiplier()
	var coin_total := 0
	var slot_bonus := 0
	for it in items:
		var pts := int(it["points"])
		score += int(roundf(pts * mult))
		coin_total += ceili(pts * mult)
		tally[it["name"]] = int(tally.get(it["name"], 0)) + 1
		# el objeto cuenta para el pedido si todavia falta
		for slot in order_slots:
			if not slot["done"] and slot["item"]["name"] == it["name"]:
				slot["done"] = true
				slot_bonus += pts * ORDER_SLOT_MULT
				break
	if slot_bonus > 0:
		score += slot_bonus
		hud.toast("Pedido +%d" % slot_bonus, Color(1.0, 0.82, 0.15))
	_spawn_coins(coin_total)
	hud.set_score(score)
	_check_quota()
	hud.set_combo(combo, mult, combo_timer)
	hud.set_order(order_slots)

	if _order_is_complete():
		orders_completed += 1
		score += ORDER_COMPLETE_POINTS
		time_left = minf(time_left + ORDER_COMPLETE_TIME, MAX_TIME)
		_spawn_coins(ORDER_COMPLETE_COINS)
		hud.set_score(score)
		_check_quota()
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
		hud.toast("¡CUOTA CUMPLIDA!", Color(0.4, 1.0, 0.5))

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
	coins_collected += value
	Game.coins += value   # las monedas ya NO dan puntos: son dinero para la tienda
	hud.set_coins(Game.coins)

func _on_time_bonus_collected(seconds: float) -> void:
	time_left = minf(time_left + seconds, MAX_TIME)
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

# ---------------------------------------------------------------- Fin

func _end_game() -> void:
	running = false
	player.active = false
	for h in get_tree().get_nodes_in_group("hazards"):
		h.set_process(false)
	passed = score >= quota
	var new_record := Game.record_round(score)
	hud.set_combo(0, 1.0, 0.0)
	hud.show_round_result({
		"passed": passed, "score": score, "quota": quota, "coins": coins_collected,
		"orders": orders_completed, "tally": tally, "round": Game.round_number,
		"new_record": new_record,
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
				get_tree().change_scene_to_file("res://shop.tscn")
			else:
				Game.reset_run()   # perdiste: nueva partida directa
				get_tree().change_scene_to_file("res://main.tscn")
		elif event.keycode == KEY_ESCAPE:
			Game.reset_run()
			get_tree().change_scene_to_file("res://menu.tscn")

func _draw() -> void:
	draw_rect(map_rect, Color(0.16, 0.22, 0.16))
	draw_rect(map_rect, Color(0.45, 0.35, 0.2), false, 4.0)
