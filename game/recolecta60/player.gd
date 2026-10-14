extends CharacterBody2D
# Jugador: WASD / flechas para moverse. E o Espacio = recoger / soltar en el pozo.
# Monedas y relojes se recogen solos al pasar por encima. Las mejoras vienen del autoload Game.

const ItemDB = preload("res://item_database.gd")

signal carry_changed(carried: Array, max_carry: int)
signal items_deposited(items: Array)
signal coin_collected(value: int)
signal time_bonus_collected(seconds: float)

const RADIUS := 18.0
const BASE_SPEED := 280.0
const COIN_PICK_RADIUS := 28.0
const BONUS_PICK_RADIUS := 30.0
const MAGNET_SPEED := 450.0

var speed := BASE_SPEED
var pickup_radius := 45.0
var max_carry := 2

var carried: Array = []
var map_rect := Rect2()
var pit
var active := true
var facing := Vector2.DOWN

func _ready() -> void:
	speed = BASE_SPEED * Game.speed_mult()
	max_carry = Game.max_carry()

func _physics_process(delta: float) -> void:
	if not active:
		return
	var dir := _read_direction()
	if dir != Vector2.ZERO:
		facing = dir
		queue_redraw()
	velocity = dir * speed
	move_and_slide()
	var m := Vector2(RADIUS, RADIUS)
	position = position.clamp(map_rect.position + m, map_rect.end - m)
	_collect_pickups(delta)

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
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_interact()

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
	draw_circle(Vector2.ZERO, RADIUS, Color(0.25, 0.55, 0.95))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(1, 1, 1), 2.0)
	draw_line(Vector2.ZERO, facing * RADIUS, Color(1, 1, 1), 3.0)
	for i in carried.size():
		var it: Dictionary = carried[i]
		var x := (i - (carried.size() - 1) / 2.0) * 24.0
		ItemDB.draw_shape(self, it["shape"], it["color"], 9.0, Vector2(x, -RADIUS - 18.0))
