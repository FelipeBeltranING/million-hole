extends Node2D
# Peligro del mapa. kind:
#   "puddle"    Charco de champan: te frena mientras estas dentro.
#   "spikes"    Pinchos: ciclo apagado -> aviso (parpadea) -> activo (rojo, golpea).
#   "paparazzi" Te persigue. Al tocarte hace flash, te aturde y se retira un momento.
# Los golpes los aplica player.gd (consulta el grupo "hazards").

const SPIKE_OFF_TIME := 1.8
const SPIKE_WARN_TIME := 0.7
const SPIKE_ON_TIME := 1.2
const PAPARAZZI_PAUSE := 1.8

var kind := "puddle"
var radius := 50.0
var target: Node2D = null     # paparazzi: a quien persigue
var map_rect := Rect2()
var speed := 100.0            # paparazzi
var t := 0.0
var state := "off"            # pinchos: off / warn / on
var phase_time := 0.0
var pause_timer := 0.0        # paparazzi: retirada tras golpear
var stun_timer := 0.0         # paparazzi: aturdido por el bolsazo

func _ready() -> void:
	add_to_group("hazards")
	match kind:
		"puddle":
			radius = 58.0
		"spikes":
			radius = 32.0
			phase_time = randf() * SPIKE_OFF_TIME   # que no esten todos sincronizados
		"paparazzi":
			radius = 20.0

func _process(delta: float) -> void:
	t += delta
	if kind == "spikes":
		_update_spikes(delta)
	elif kind == "paparazzi":
		_update_paparazzi(delta)
	queue_redraw()

func slows() -> bool:
	return kind == "puddle"

func is_harmful() -> bool:
	if kind == "spikes":
		return state == "on"
	if kind == "paparazzi":
		return pause_timer <= 0.0 and stun_timer <= 0.0
	return false

# Lo llama el jugador cuando este peligro lo golpea
func on_hit() -> void:
	if kind == "paparazzi":
		pause_timer = PAPARAZZI_PAUSE

# Bolsazo del jugador: aturde al paparazzi y lo empuja un poco hacia atras
func get_stunned(secs: float, push_dir: Vector2) -> void:
	if kind != "paparazzi":
		return
	stun_timer = secs
	position += push_dir * 70.0
	var m := Vector2(radius, radius)
	position = position.clamp(map_rect.position + m, map_rect.end - m)

func _update_spikes(delta: float) -> void:
	phase_time += delta
	if state == "off" and phase_time >= SPIKE_OFF_TIME:
		state = "warn"
		phase_time = 0.0
	elif state == "warn" and phase_time >= SPIKE_WARN_TIME:
		state = "on"
		phase_time = 0.0
	elif state == "on" and phase_time >= SPIKE_ON_TIME:
		state = "off"
		phase_time = 0.0

func _update_paparazzi(delta: float) -> void:
	if target == null:
		return
	if stun_timer > 0.0:
		stun_timer -= delta
		return
	var dir: Vector2 = (target.position - position).normalized()
	if pause_timer > 0.0:
		pause_timer -= delta
		position -= dir * speed * 0.5 * delta   # se retira un poco
	else:
		position += dir * speed * delta
	var m := Vector2(radius, radius)
	position = position.clamp(map_rect.position + m, map_rect.end - m)

func _draw() -> void:
	match kind:
		"puddle":
			_draw_puddle()
		"spikes":
			_draw_spikes()
		"paparazzi":
			_draw_paparazzi()

func _draw_puddle() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.85, 0.35, 0.28))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.92, 0.55, 0.65), 2.0)
	for i in 4:
		var a := float(i) * 1.7 + t * 0.6
		var p := Vector2.from_angle(a) * radius * (0.25 + 0.15 * float(i))
		var b := 3.0 + 2.0 * sin(t * 2.0 + float(i))
		draw_circle(p, b, Color(1.0, 1.0, 0.85, 0.7))

func _draw_spikes() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.12, 0.12, 0.14, 0.85))
	var tip := radius * 0.45
	var col := Color(0.55, 0.55, 0.6)
	if state == "warn":
		tip = radius * 0.7
		col = Color(1.0, 0.55, 0.15) if int(t * 10.0) % 2 == 0 else Color(0.55, 0.55, 0.6)
	elif state == "on":
		tip = radius
		col = Color(1.0, 0.2, 0.2)
	for i in 6:
		var dir := Vector2.from_angle(TAU * float(i) / 6.0)
		var perp := dir.rotated(PI / 2.0) * 5.0
		draw_colored_polygon(PackedVector2Array([
			dir * radius * 0.2 + perp, dir * radius * 0.2 - perp, dir * tip]), col)

func _draw_paparazzi() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.62, 0.62, 0.68))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.15, 0.15, 0.2), 2.0)
	draw_rect(Rect2(-12.0, -6.0, 24.0, 14.0), Color(0.1, 0.1, 0.14))
	draw_circle(Vector2(0, 1), 5.0, Color(0.35, 0.65, 1.0))
	draw_rect(Rect2(-8.0, -10.0, 8.0, 4.0), Color(0.1, 0.1, 0.14))
	if stun_timer > 0.0:
		draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 24, Color(0.4, 0.8, 1.0), 3.0)
		for i in 3:
			var a := t * 4.0 + TAU * float(i) / 3.0
			draw_circle(Vector2(cos(a) * 14.0, -radius - 6.0 + sin(a) * 4.0), 3.5, Color(1.0, 0.9, 0.2))
	if pause_timer > PAPARAZZI_PAUSE - 0.25:
		draw_circle(Vector2.ZERO, radius + 12.0, Color(1, 1, 1, 0.6))   # flash
