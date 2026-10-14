extends Node2D
# Moneda que sale disparada del pozo. Se recoge caminando sobre ella y expira.

const RADIUS := 9.0
const BASE_LIFETIME := 6.0   # segundos antes de desaparecer (sin mejoras)
const BLINK_TIME := 2.0   # parpadea durante los ultimos segundos
const FLY_TIME := 0.45    # duracion de la animacion de salida

var value := 1
var lifetime := BASE_LIFETIME
var collectable := false
var age := 0.0

func launch(from: Vector2, to: Vector2) -> void:
	position = from
	add_to_group("coins")
	var tw := create_tween()
	tw.tween_property(self, "position", to, FLY_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): collectable = true)

func _process(delta: float) -> void:
	age += delta
	var remaining := lifetime - age
	if remaining <= 0.0:
		queue_free()
		return
	visible = not (remaining < BLINK_TIME and int(age * 8.0) % 2 == 0)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.82, 0.15))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 20, Color(0.65, 0.45, 0.05), 2.0)
	draw_arc(Vector2.ZERO, RADIUS * 0.55, 0.0, TAU, 16, Color(0.85, 0.62, 0.08), 1.5)
