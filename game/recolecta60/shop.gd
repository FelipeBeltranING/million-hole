extends Control
# Tienda entre rondas. Las mejoras duran hasta terminar la partida o cerrar el juego.

const MAIN_SCENE := "res://main.tscn"
const MENU_SCENE := "res://menu.tscn"

var coins_label: Label
var rows := {}   # id -> {"label": Label, "button": Button}

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.position = Vector2(320, 24)
	box.custom_minimum_size = Vector2(640, 0)
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	box.add_child(_label("TIENDA", 44, Color(1.0, 0.82, 0.15)))
	box.add_child(_label("Ronda %d terminada  -  %d puntos" % [Game.round_number, Game.last_round_score], 20, Color(0.8, 0.8, 0.85)))
	coins_label = _label("", 28, Color(1.0, 0.82, 0.15))
	box.add_child(coins_label)

	for id in Game.UPGRADES.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(450, 0)
		lbl.add_theme_font_size_override("font_size", 18)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(170, 48)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_buy.bind(id))
		row.add_child(lbl)
		row.add_child(btn)
		box.add_child(row)
		rows[id] = {"label": lbl, "button": btn}

	var next := Button.new()
	next.text = "Siguiente ronda  (Enter)"
	next.custom_minimum_size = Vector2(0, 52)
	next.focus_mode = Control.FOCUS_NONE
	next.add_theme_font_size_override("font_size", 22)
	next.pressed.connect(_next_round)
	box.add_child(next)

	var quit := Button.new()
	quit.text = "Terminar partida y volver al menu  (Esc)"
	quit.custom_minimum_size = Vector2(0, 40)
	quit.focus_mode = Control.FOCUS_NONE
	quit.add_theme_font_size_override("font_size", 16)
	quit.pressed.connect(_quit_run)
	box.add_child(quit)

	_refresh()

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _refresh() -> void:
	coins_label.text = "Monedas: %d" % Game.coins
	for id in rows.keys():
		var info: Dictionary = Game.UPGRADES[id]
		var lvl := Game.level(id)
		var mx := int(info["max"])
		rows[id]["label"].text = "%s   [%d/%d]\n%s" % [info["name"], lvl, mx, info["desc"]]
		var btn: Button = rows[id]["button"]
		if Game.is_maxed(id):
			btn.text = "MAXIMO"
			btn.disabled = true
		else:
			btn.text = "Comprar  %d" % Game.cost(id)
			btn.disabled = not Game.can_buy(id)

func _on_buy(id: String) -> void:
	Game.buy(id)
	_refresh()

func _next_round() -> void:
	Game.round_number += 1
	get_tree().change_scene_to_file(MAIN_SCENE)

func _quit_run() -> void:
	Game.reset_run()
	get_tree().change_scene_to_file(MENU_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_next_round()
		elif event.keycode == KEY_ESCAPE:
			_quit_run()
