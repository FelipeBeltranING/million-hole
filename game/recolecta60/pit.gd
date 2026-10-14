extends Node2D
# El agujero del centro donde se tiran las cosas (y salen billetes, oro y lingotes).

@export var radius := 70.0

func contains(point: Vector2) -> bool:
	return position.distance_to(point) <= radius

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.04, 0.04, 0.06))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(0, 0, 0))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.82, 0.15), 6.0)
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 48, Color(0.6, 0.45, 0.1), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-30, 14), "$",
		HORIZONTAL_ALIGNMENT_CENTER, 60, 40, Color(1.0, 0.82, 0.15, 0.9))
