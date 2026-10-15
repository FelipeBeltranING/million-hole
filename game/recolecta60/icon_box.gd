extends Control
# Cuadrito de icono del HUD: marco + (cosa de lujo | icono con asset | letra provisional | vacio).
# Assets opcionales (PNG cuadrado, ~128 px): icon_time, icon_money, tool_bolsazo, tool_turbo, tool_flash, tool_shield, relic_<id>.

const Assets = preload("res://assets.gd")
const ItemDB = preload("res://item_database.gd")
const UI = preload("res://ui.gd")

var item: Dictionary = {}
var icon_key := ""
var glyph := ""
var border := UI.YELLOW
var alpha := 1.0
var empty := false

func _init(px: float = 40.0) -> void:
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_item(it: Dictionary, a: float = 1.0, b: Color = UI.YELLOW) -> void:
	item = it
	icon_key = ""
	empty = false
	alpha = a
	border = b
	queue_redraw()

func show_icon(key: String, letter: String, b: Color = UI.YELLOW) -> void:
	item = {}
	icon_key = key
	glyph = letter
	empty = false
	border = b
	queue_redraw()

func show_empty() -> void:
	item = {}
	icon_key = ""
	empty = true
	queue_redraw()

func set_border(b: Color) -> void:
	border = b
	queue_redraw()

func _draw() -> void:
	var line := UI.GRAY.darkened(0.5) if empty else border
	line.a = alpha
	draw_style_box(UI.panel_style(Color(0.05, 0.03, 0.03, 0.92 * alpha), line, 8, 3, false, 0), Rect2(Vector2.ZERO, size))
	if empty:
		return
	var c := size / 2.0
	if not item.is_empty():
		ItemDB.draw_item(self, item, size.x * 0.30, c, 0.0, alpha)
		return
	if icon_key != "" and Assets.draw(self, icon_key, size.x * 0.82, c, 0.0, Vector2.ONE, Color(1, 1, 1, alpha)):
		return
	var col := border
	col.a = alpha
	draw_string(UI.font(), Vector2(0.0, c.y + size.y * 0.22), glyph, HORIZONTAL_ALIGNMENT_CENTER,
		size.x, int(size.y * 0.62), col)
