extends Node2D
# Panel del HUD "CAPRICHOS DE HOY": icono + nombre + marca verde al entregar. Esquina inferior izquierda.

const ItemDB = preload("res://item_database.gd")
const UI = preload("res://ui.gd")
const W := 288.0
const H := 208.0

var slots: Array = []

func set_order(new_slots: Array) -> void:
	slots = new_slots
	queue_redraw()

func _draw() -> void:
	var font := UI.font()
	draw_style_box(UI.panel_style(), Rect2(0, 0, W, H))
	draw_string(font, Vector2(16, 38), "TODAY'S WHIMS", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UI.YELLOW)
	for i in slots.size():
		var s = slots[i]
		var item: Dictionary = s["item"]
		var done: bool = s["done"]
		var y := 52.0 + float(i) * 50.0
		var a := 0.4 if done else 1.0
		# icono de la cosa
		draw_style_box(UI.panel_style(Color(0.05, 0.03, 0.03, 0.9), Color(UI.YELLOW, a), 8, 3, false, 0), Rect2(16, y, 40, 40))
		ItemDB.draw_item(self, item, 9.5, Vector2(36, y + 20), 0.0, a)
		# nombre (se achica si no cabe)
		var fs := 18
		while fs > 12 and font.get_string_size(item["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 158.0:
			fs -= 1
		draw_string(font, Vector2(64, y + 27), item["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))
		# casilla de entregado
		var box_col := UI.GREEN if done else UI.GRAY.darkened(0.5)
		draw_style_box(UI.panel_style(Color(0.05, 0.03, 0.03, 0.9), box_col, 8, 3, false, 0), Rect2(232, y, 40, 40))
		if done:
			draw_line(Vector2(241, y + 21), Vector2(250, y + 30), UI.GREEN, 5.0)
			draw_line(Vector2(250, y + 30), Vector2(264, y + 11), UI.GREEN, 5.0)
