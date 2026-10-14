extends Node2D
# El pozo del centro del mapa donde se sueltan los objetos.

@export var radius := 70.0

func contains(point: Vector2) -> bool:
	return position.distance_to(point) <= radius

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.04, 0.04, 0.06))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(0, 0, 0))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.60, 0.45, 0.25), 6.0)
	draw_string(ThemeDB.fallback_font, Vector2(-30, 6), "POZO",
		HORIZONTAL_ALIGNMENT_CENTER, 60, 18, Color(1, 1, 1, 0.8))
