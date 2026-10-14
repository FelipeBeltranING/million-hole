extends CharacterBody2D
# Jugador: WASD / flechas para moverse. E o Espacio = recoger / soltar en el pozo.
# Monedas y relojes se recogen solos al pasar por encima. Las mejoras vienen del autoload Game.

const ItemDB = preload("res://item_database.gd")

signal carry_changed(carried: Array, max_carry: int)
signal items_deposited(items: Array)
signal coin_collected(value: int)
signal time_bonus_collected(seconds: float)
signal shield_blocked
signal hit_taken(dropped: Array)   # un peligro te golpeo; "dropped" = lo que llevabas

const RADIUS := 18.0
const BASE_SPEED := 280.0
const COIN_PICK_RADIUS := 28.0
const BONUS_PICK_RADIUS := 30.0
const MAGNET_SPEED := 450.0
const PUDDLE_SLOW := 0.5     # velocidad dentro de un charco
const STUN_TIME := 0.5       # inmovil tras un golpe
const INVULN_TIME := 1.5     # sin recibir golpes tras uno (parpadea)
const TURBO_TIME := 3.0
const TURBO_MULT := 1.7
const SWING_FX_TIME := 0.25

var speed := BASE_SPEED
var pickup_radius := 45.0
var max_carry := 2

var carried: Array = []
var map_rect := Rect2()
var pit
var active := true
var facing := Vector2.DOWN
var stun_timer := 0.0
var invuln_timer := 0.0
var swing_cd := 0.0      # enfriamiento del bolsazo
var swing_fx := 0.0      # animacion del bolsazo
var turbo_timer := 0.0
var fx_was := false

func _ready() -> void:
	speed = BASE_SPEED * Game.speed_mult()
	max_carry = Game.max_carry()

func _physics_process(delta: float) -> void:
	if not active:
		return
	invuln_timer = maxf(invuln_timer - delta, 0.0)
	stun_timer = maxf(stun_timer - delta, 0.0)
	swing_cd = maxf(swing_cd - delta, 0.0)
	swing_fx = maxf(swing_fx - delta, 0.0)
	turbo_timer = maxf(turbo_timer - delta, 0.0)
	modulate.a = 0.45 if (invuln_timer > 0.0 and int(invuln_timer * 10.0) % 2 == 0) else 1.0
	var slow := _check_hazards()
	var dir := Vector2.ZERO if stun_timer > 0.0 else _read_direction()
	if dir != Vector2.ZERO:
		facing = dir
		queue_redraw()
	var turbo := TURBO_MULT if turbo_timer > 0.0 else 1.0
	velocity = dir * speed * slow * turbo
	move_and_slide()
	var m := Vector2(RADIUS, RADIUS)
	position = position.clamp(map_rect.position + m, map_rect.end - m)
	_collect_pickups(delta)
	var fx_now := swing_fx > 0.0 or turbo_timer > 0.0
	if fx_now or fx_was:
		queue_redraw()
	fx_was = fx_now

# Revisa los peligros cercanos. Devuelve el multiplicador de velocidad (charcos).
func _check_hazards() -> float:
	var slow := 1.0
	for h in get_tree().get_nodes_in_group("hazards"):
		var d: float = position.distance_to(h.position)
		if h.slows():
			if d <= h.radius:
				slow = PUDDLE_SLOW
		elif h.is_harmful() and d <= h.radius + RADIUS * 0.6 and invuln_timer <= 0.0:
			h.on_hit()
			_take_hit()
	return slow

func _take_hit() -> void:
	if Game.use_item("shield"):
		invuln_timer = 1.0
		shield_blocked.emit()
		return
	stun_timer = STUN_TIME
	invuln_timer = INVULN_TIME
	var dropped := carried.duplicate()
	carried.clear()
	_notify()
	hit_taken.emit(dropped)

func _collect_pickups(delta: float) -> void:
	var magnet := Game.magnet_radius()
	for coin in get_tree().get_nodes_in_group("coins"):
		if not coin.collectable:
			continue
		var d: float = position.distance_to(coin.position)
		if magnet > 0.0 and d <= magnet and d > COIN_PICK_RADIUS:
			coin.position = coin.position.move_toward(position, MAGNET_SPEED * delta)
			d = position.distance_to(coin.position)
		if d <= COIN_PICK_RADIUS:
			coin.collectable = false
			coin_collected.emit(coin.value)
			coin.queue_free()
	for bonus in get_tree().get_nodes_in_group("time_bonuses"):
		if position.distance_to(bonus.position) <= BONUS_PICK_RADIUS:
			bonus.remove_from_group("time_bonuses")
			time_bonus_collected.emit(bonus.seconds)
			bonus.queue_free()

func _read_direction() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		d.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		d.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		d.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		d.y += 1.0
	return d.normalized()

func _unhandled_input(event: InputEvent) -> void:
	if not active or stun_timer > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_interact()
		elif event.keycode == KEY_Q:
			_swing()
		elif event.keycode == KEY_SHIFT:
			_turbo()

# Bolsazo: aturde (y empuja) a los paparazzi que esten cerca. Requiere la mejora de la boutique.
func _swing() -> void:
	if Game.level("bolsazo") <= 0 or swing_cd > 0.0:
		return
	swing_cd = Game.bolsazo_cooldown()
	swing_fx = SWING_FX_TIME
	var r := Game.bolsazo_radius()
	for h in get_tree().get_nodes_in_group("hazards"):
		if h.kind == "paparazzi" and position.distance_to(h.position) <= r + h.radius:
			h.get_stunned(Game.bolsazo_stun(), (h.position - position).normalized())
	queue_redraw()

# Turbo: consumible
func _turbo() -> void:
	if turbo_timer > 0.0 or not Game.use_item("turbo"):
		return
	turbo_timer = TURBO_TIME
	queue_redraw()

func _interact() -> void:
	# Dentro del pozo: soltar todo lo que cargas
	if pit.contains(position):
		if carried.size() > 0:
			items_deposited.emit(carried.duplicate())
			carried.clear()
			_notify()
		return
	_try_pickup()

func _try_pickup() -> void:
	if carried.size() >= max_carry:
		return
	var best = null
	var best_dist := pickup_radius
	for node in get_tree().get_nodes_in_group("items"):
		var d: float = position.distance_to(node.position)
		if d <= best_dist:
			best = node
			best_dist = d
	if best != null:
		carried.append(best.data)
		best.queue_free()
		_notify()

func _notify() -> void:
	carry_changed.emit(carried, max_carry)
	queue_redraw()

func _draw() -> void:
	if swing_fx > 0.0:
		var p := 1.0 - swing_fx / SWING_FX_TIME
		draw_arc(Vector2.ZERO, Game.bolsazo_radius() * p, 0.0, TAU, 48, Color(1.0, 0.7, 0.9, 1.0 - p), 5.0)
	if turbo_timer > 0.0:
		draw_arc(Vector2.ZERO, RADIUS + 7.0, 0.0, TAU, 32, Color(0.4, 0.9, 1.0, 0.9), 3.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.60, 0.78))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(1, 1, 1), 2.0)
	draw_line(Vector2.ZERO, facing * RADIUS, Color(1, 1, 1), 3.0)
	# tiara dorada
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -RADIUS + 3), Vector2(-9, -RADIUS - 6), Vector2(-4.5, -RADIUS - 1),
		Vector2(0, -RADIUS - 9), Vector2(4.5, -RADIUS - 1), Vector2(9, -RADIUS - 6),
		Vector2(9, -RADIUS + 3)]), Color(1.0, 0.82, 0.15))
	for i in carried.size():
		var it: Dictionary = carried[i]
		var x := (i - (carried.size() - 1) / 2.0) * 24.0
		ItemDB.draw_shape(self, it["shape"], it["color"], 9.0, Vector2(x, -RADIUS - 30.0))
