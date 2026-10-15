extends Node2D
# Dinero que sale disparado del vórtice. Se recoge caminando encima y expira.
# Tipos: "coin" (moneda, gira), "bill" (billete), "bar" (lingote).
# main.gd decide el tipo y el valor (COIN_VALUE / BILL_VALUE / BAR_VALUE).
# NOTA: los dibujos son PROVISIONALES (placeholders) hasta tener los assets definitivos.
# Para cambiarlos, reemplaza el contenido de _draw() por un Sprite2D / textura.

const Assets = preload("res://assets.gd")
const BASE_LIFETIME := 6.0   # segundos antes de desaparecer (sin mejoras)
const BLINK_TIME := 2.0
const FLY_TIME := 0.45

var kind := "coin"
var value := 1
var lifetime := BASE_LIFETIME
var collectable := false
var age := 0.0
var spin_offset := randf() * TAU

func launch(from: Vector2, to: Vector2) -> void:
	position = from
	if kind == "bill":
		rotation = randf_range(-0.6, 0.6)
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
	if kind == "coin":
		queue_redraw()   # la moneda gira

func _draw() -> void:
	# con asset: res://assets/coin.png | bill.png | bar.png (la moneda gira achatandose, como el provisional)
	var spin := Vector2.ONE
	if Assets.draw(self, kind, Assets.SIZES[kind], Vector2.ZERO, 0.0, spin):
		return
	match kind:
		"bill":
			draw_rect(Rect2(-12, -7, 24, 14), Color(0.45, 0.80, 0.50))
			draw_rect(Rect2(-12, -7, 24, 14), Color(0.15, 0.45, 0.20), false, 2.0)
			draw_circle(Vector2.ZERO, 3.5, Color(0.15, 0.45, 0.20))
		"bar":
			var pts := PackedVector2Array([Vector2(-14, 7), Vector2(-10, -7), Vector2(10, -7), Vector2(14, 7)])
			draw_colored_polygon(pts, Color(1.0, 0.85, 0.25))
			var outline := pts.duplicate()
			outline.append(pts[0])
			draw_polyline(outline, Color(0.65, 0.45, 0.05), 2.0)
			draw_line(Vector2(-7, -3), Vector2(2, -3), Color(1.0, 1.0, 0.85), 2.5)
		_:
			var w := absf(cos(Time.get_ticks_msec() / 180.0 + spin_offset))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(maxf(w, 0.15), 1.0))
			draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.82, 0.15))
			draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, Color(0.65, 0.45, 0.05), 2.0)
			draw_arc(Vector2.ZERO, 5.5, 0.0, TAU, 16, Color(0.85, 0.62, 0.08), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
