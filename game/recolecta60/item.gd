extends Node2D
# Un objeto recogible en el mapa. Si el vórtice lo pide, se ve con un aro dorado que pulsa.

const ItemDB = preload("res://item_database.gd")
const Assets = preload("res://assets.gd")
const RADIUS := 14.0

var data: Dictionary = {}
var highlighted := false
var tilt := randf_range(-0.35, 0.35)   # giro fijo al azar (solo se nota con asset: que no se vean todos iguales)

func _ready() -> void:
	set_process(false)

func setup(item_data: Dictionary) -> void:
	data = item_data
	add_to_group("items")
	queue_redraw()

func set_highlight(value: bool) -> void:
	highlighted = value
	set_process(value)   # solo redibuja cada frame si esta resaltado (para la pulsacion)
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if data.is_empty():
		return
	ItemDB.draw_item(self, data, RADIUS, Vector2.ZERO, tilt)
	if not Assets.has("item_" + String(data["id"])):
		draw_arc(Vector2.ZERO, RADIUS + 5.0, 0.0, TAU, 24, Color(1, 1, 1, 0.45), 2.0)   # aro blanco solo del dibujo provisional
	if int(data["points"]) >= 8:   # legendario: halo dorado
		draw_arc(Vector2.ZERO, RADIUS + 12.0, 0.0, TAU, 32, Color(1.0, 0.95, 0.5, 0.4), 4.0)
	if highlighted:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		draw_arc(Vector2.ZERO, RADIUS + 9.0 + pulse * 4.0, 0.0, TAU, 32, Color(1.0, 0.82, 0.15, 0.95), 3.0)
