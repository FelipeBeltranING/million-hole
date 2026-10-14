extends CanvasLayer
# Interfaz: tiempo, puntos, monedas, combo, carga, pedido, avisos y pantalla final.

const OrderPanelScript = preload("res://order_panel.gd")

var time_label: Label
var score_label: Label
var coins_label: Label
var carry_label: Label
var combo_label: Label
var round_label: Label
var order_panel
var dim: ColorRect
var message_label: Label
var hint_label: Label

func _ready() -> void:
	var size := get_viewport().get_visible_rect().size
	time_label = _make_label(Vector2(20, 10), 34)
	score_label = _make_label(Vector2(20, 54), 24)
	coins_label = _make_label(Vector2(20, 86), 22)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.15))
	carry_label = _make_label(Vector2(20, 118), 20)
	combo_label = _make_label(Vector2(20, 150), 26)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
	combo_label.visible = false
	round_label = _make_label(Vector2(size.x - 340.0, 172.0), 18)
	var help := _make_label(Vector2(20, 685), 16)
	help.text = "WASD / Flechas: mover  |  E / Espacio: recoger o soltar en el pozo  |  Monedas y relojes: camina sobre ellos"
	order_panel = OrderPanelScript.new()
	order_panel.position = Vector2(size.x - 340.0, 14.0)
	add_child(order_panel)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.visible = false
	add_child(dim)
	message_label = _make_label(Vector2.ZERO, 34)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.visible = false
	hint_label = _make_label(Vector2.ZERO, 28)
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.15))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.visible = false

func _make_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	add_child(l)
	return l

func set_time(seconds: float) -> void:
	time_label.text = "Tiempo: %d" % ceili(seconds)
	var c := Color(1, 0.3, 0.3) if seconds <= 10.0 else Color(1, 1, 1)
	time_label.add_theme_color_override("font_color", c)

func set_score(points: int) -> void:
	score_label.text = "Puntos: %d" % points

func set_coins(amount: int) -> void:
	coins_label.text = "Monedas: %d" % amount

func set_carry(carried: Array, max_carry: int) -> void:
	var names: PackedStringArray = []
	for it in carried:
		names.append(it["name"])
	carry_label.text = "Cargando %d/%d: %s" % [carried.size(), max_carry, ", ".join(names)]

func set_order(slots: Array) -> void:
	order_panel.set_order(slots)

# combo = entregas seguidas, mult = multiplicador, secs = tiempo que queda para mantenerlo
func set_combo(combo: int, mult: float, secs: float) -> void:
	if combo <= 0:
		combo_label.visible = false
		return
	combo_label.visible = true
	combo_label.text = "COMBO x%.1f  (%.1fs)" % [mult, secs]

# Aviso grande que sube y se desvanece
func toast(text: String, color: Color = Color(1, 1, 1)) -> void:
	var size := get_viewport().get_visible_rect().size
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(size.x, 60)
	l.position = Vector2(0, size.y * 0.2)
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50.0, 1.3)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.5)
	tw.finished.connect(l.queue_free)

func set_round(round_number: int, best: int) -> void:
	round_label.text = "Ronda %d   |   Mejor ronda: %d pts" % [round_number, best]

func show_game_over(score: int, coins: int, orders: int, tally: Dictionary, round_number: int) -> void:
	var size := get_viewport().get_visible_rect().size
	var text := "RONDA %d TERMINADA\n\nPuntos: %d     Monedas: %d     Pedidos: %d\n\n" % [round_number, score, coins, orders]
	# objetos entregados, 3 por fila para que no se salga de la pantalla
	var row := PackedStringArray()
	for item_name in tally:
		row.append("%s x%d" % [item_name, tally[item_name]])
		if row.size() == 3:
			text += "     ".join(row) + "\n"
			row = PackedStringArray()
	if row.size() > 0:
		text += "     ".join(row) + "\n"
	dim.size = size
	dim.visible = true
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.text = text
	message_label.size = Vector2(size.x, size.y - 110.0)
	message_label.visible = true
	hint_label.text = "ENTER: ir a la tienda     |     ESC: terminar partida"
	hint_label.size = Vector2(size.x, 50.0)
	hint_label.position = Vector2(0.0, size.y - 90.0)
	hint_label.visible = true
