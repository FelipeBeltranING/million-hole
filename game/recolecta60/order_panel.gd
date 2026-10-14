extends Node2D
# Panel del HUD que muestra el pedido actual del pozo (3 objetos).

const ItemDB = preload("res://item_database.gd")
const W := 320.0
const H := 150.0

var slots: Array = []

func set_order(new_slots: Array) -> void:
	slots = new_slots
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var gold := Color(1.0, 0.82, 0.15)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(0, 0, W, H), gold, false, 2.0)
	draw_string(font, Vector2(14, 28), "CAPRICHOS DE HOY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, gold)
	for i in slots.size():
		var s = slots[i]
		var item: Dictionary = s["item"]
		var done: bool = s["done"]
		var y := 66.0 + i * 36.0
		var a := 0.35 if done else 1.0
		var col: Color = item["color"]
		col.a = a
		ItemDB.draw_shape(self, item["shape"], col, 11.0, Vector2(28, y - 6.0))
		draw_string(font, Vector2(52, y), item["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, a))
		if done:
			var green := Color(0.3, 0.95, 0.4)
			draw_line(Vector2(270, y - 8), Vector2(279, y), green, 4.0)
			draw_line(Vector2(279, y), Vector2(296, y - 18), green, 4.0)
