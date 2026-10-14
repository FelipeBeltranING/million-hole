extends Control
# Contrato de riesgo: antes de cada ronda eliges 1 de 3. Mas riesgo = mas dinero.
# La opcion tranquila siempre esta. Teclas 1 / 2 / 3.

const MAIN_SCENE := "res://main.tscn"

var choices: Array = []

func _ready() -> void:
	choices = Game.roll_contracts()
	var r := Game.round_number
	var size := get_viewport_rect().size

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var head := VBoxContainer.new()
	head.position = Vector2(0, 40)
	head.custom_minimum_size = Vector2(size.x, 0)
	head.add_theme_constant_override("separation", 6)
	add_child(head)
	head.add_child(_label("CONTRATO DE LA RONDA %d" % r, 44, Color(1.0, 0.82, 0.15)))
	head.add_child(_label("Elige cuanto riesgo quieres. Mas riesgo = mas dinero.", 20, Color(0.8, 0.8, 0.85)))
	head.add_child(_label("Dinero: $%d" % Game.coins, 26, Color(1.0, 0.82, 0.15)))

	var row := HBoxContainer.new()
	row.position = Vector2(60, 200)
	row.custom_minimum_size = Vector2(size.x - 120.0, 0)
	row.add_theme_constant_override("separation", 24)
	add_child(row)

	for i in choices.size():
		var id: String = choices[i]
		var info: Dictionary = Game.CONTRACTS[id]
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(360, 0)
		card.add_theme_constant_override("separation", 14)
		var panel := ColorRect.new()
		panel.color = Color(0.13, 0.14, 0.19)
		panel.custom_minimum_size = Vector2(360, 330)
		var inner := VBoxContainer.new()
		inner.custom_minimum_size = Vector2(340, 0)
		inner.position = Vector2(10, 14)
		inner.add_theme_constant_override("separation", 14)
		panel.add_child(inner)
		inner.add_child(_label(info["name"], 28, Color(1.0, 0.82, 0.15) if id != "calm" else Color(0.6, 0.9, 1.0)))
		var desc := _label(info["desc"], 18, Color(0.9, 0.9, 0.95))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(340, 130)
		inner.add_child(desc)
		var q := roundi(float(Game.quota_estimate(r)) * float(info.get("quota_mult", 1.0)))
		inner.add_child(_label("Cuota: %d puntos" % q, 22, Color(0.4, 1.0, 0.5)))
		var btn := Button.new()
		btn.text = "Elegir  (%d)" % (i + 1)
		btn.custom_minimum_size = Vector2(0, 52)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_choose.bind(i))
		inner.add_child(btn)
		card.add_child(panel)
		row.add_child(card)

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _choose(i: int) -> void:
	Game.set_contract(choices[i])
	get_tree().change_scene_to_file(MAIN_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_choose(0)
		elif event.keycode == KEY_2:
			_choose(1)
		elif event.keycode == KEY_3:
			_choose(2)
