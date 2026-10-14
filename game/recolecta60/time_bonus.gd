extends Node2D
# Reloj que suma segundos. Se recoge caminando encima (no ocupa espacio en las manos).

const RADIUS := 14.0
const LIFETIME := 9.0
const BLINK_TIME := 2.5

var seconds := 2.0
var age := 0.0

func _ready() -> void:
	add_to_group("time_bonuses")

func _process(delta: float) -> void:
	age += delta
	var remaining := LIFETIME - age
	if remaining <= 0.0:
		queue_free()
		return
	visible = not (remaining < BLINK_TIME and int(age * 8.0) % 2 == 0)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.30, 0.90, 0.95))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, Color(1, 1, 1), 2.5)
	draw_line(Vector2.ZERO, Vector2(0, -9), Color(0.05, 0.25, 0.3), 2.5)   # manecillas
	draw_line(Vector2.ZERO, Vector2(6, 3), Color(0.05, 0.25, 0.3), 2.5)
	draw_string(ThemeDB.fallback_font, Vector2(-18, 32), "+%ds" % int(seconds),
		HORIZONTAL_ALIGNMENT_CENTER, 36, 16, Color(0.30, 0.90, 0.95))
