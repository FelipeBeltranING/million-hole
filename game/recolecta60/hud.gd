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
var quota_value := 0
var tools_label: Label

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
	tools_label = _make_label(Vector2(20, 186), 18)
	tools_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	round_label = _make_label(Vector2(size.x - 340.0, 172.0), 18)
	var help := _make_label(Vector2(20, 685), 16)
	help.text = "WASD / Flechas: mover  |  E / Espacio: recoger cosas o tirarlas en el agujero  |  Camina sobre el dinero y los relojes"
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

# Herramientas: bolsazo (si lo tienes), turbo y escudo
func set_tools(bolsazo_lvl: int, cd: float, turbo_n: int, shield_n: int) -> void:
	var parts := PackedStringArray()
	if bolsazo_lvl > 0:
		parts.append("Q Bolsazo: %s" % ("LISTO" if cd <= 0.0 else "%.1fs" % cd))
	if turbo_n > 0:
		parts.append("Shift Turbo x%d" % turbo_n)
	if shield_n > 0:
		parts.append("Escudo x%d" % shield_n)
	tools_label.text = "   |   ".join(parts)

func set_quota(q: int) -> void:
	quota_value = q

# Muestra puntos / cuota; se pone verde al alcanzar la cuota
func set_score(points: int) -> void:
	score_label.text = "Puntos: %d / %d" % [points, quota_value]
	var c := Color(0.4, 1.0, 0.5) if points >= quota_value else Color(1, 1, 1)
	score_label.add_theme_color_override("font_color", c)

func set_coins(amount: int) -> void:
	coins_label.text = "Dinero: $%d" % amount

func set_carry(carried: Array, max_carry: int) -> void:
	var names: PackedStringArray = []
	for it in carried:
		names.append(it["name"])
	carry_label.text = "Llevas %d/%d: %s" % [carried.size(), max_carry, ", ".join(names)]

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

# info: passed, score, quota, coins, orders, tally, round, new_record,
#       run_best_score, run_best_round, session_best, session_best_round
func show_round_result(info: Dictionary) -> void:
	var size := get_viewport().get_visible_rect().size
	var text := ""
	if info["passed"]:
		text = "RONDA %d SUPERADA\n\nPuntos: %d / cuota %d     Dinero: $%d     Caprichos: %d\n\n" % [
			info["round"], info["score"], info["quota"], info["coins"], info["orders"]]
		var row := PackedStringArray()
		for item_name in info["tally"]:
			row.append("%s x%d" % [item_name, info["tally"][item_name]])
			if row.size() == 3:
				text += "     ".join(row) + "\n"
				row = PackedStringArray()
		if row.size() > 0:
			text += "     ".join(row) + "\n"
		if info["new_record"]:
			text += "\nNUEVO RECORD DE LA SESION"
		hint_label.text = "ENTER: ir a la boutique     |     ESC: terminar partida"
	else:
		text = "FIN DE LA PARTIDA\n\nNo llegaste a la cuota en la ronda %d\nPuntos: %d / cuota %d   (te faltaron %d)\n\n" % [
			info["round"], info["score"], info["quota"], info["quota"] - info["score"]]
		text += "Rondas superadas: %d\n" % (int(info["round"]) - 1)
		text += "Mejor ronda de esta partida: %d puntos (ronda %d)\n" % [info["run_best_score"], info["run_best_round"]]
		text += "Record de la sesion: %d puntos (ronda %d)\n" % [info["session_best"], info["session_best_round"]]
		if info["new_record"]:
			text += "\nNUEVO RECORD DE LA SESION"
		hint_label.text = "ENTER: jugar de nuevo     |     ESC: volver al menu"
	dim.size = size
	dim.visible = true
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.text = text
	message_label.size = Vector2(size.x, size.y - 110.0)
	message_label.visible = true
	hint_label.size = Vector2(size.x, 50.0)
	hint_label.position = Vector2(0.0, size.y - 90.0)
	hint_label.visible = true
