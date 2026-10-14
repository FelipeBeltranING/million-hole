extends Control
# Tienda entre rondas. Izquierda: mejoras permanentes (duran la partida). Derecha: consumibles (se gastan al usarlos).

const MAIN_SCENE := "res://main.tscn"
const MENU_SCENE := "res://menu.tscn"

var coins_label: Label
var rows := {}        # id de mejora -> {"label": Label, "button": Button}
var item_rows := {}   # id de consumible -> {"label": Label, "button": Button}

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Cabecera (ancho completo, centrada)
	var head := VBoxContainer.new()
	head.position = Vector2(0, 14)
	head.custom_minimum_size = Vector2(1280, 0)
	head.add_theme_constant_override("separation", 4)
	add_child(head)
	head.add_child(_label("BOUTIQUE", 44, Color(1.0, 0.82, 0.15)))
	head.add_child(_label("Ronda %d superada  -  %d puntos   |   Proxima cuota: %d" % [
		Game.round_number, Game.last_round_score, Game.quota_for(Game.round_number + 1)], 20, Color(0.8, 0.8, 0.85)))
	coins_label = _label("", 28, Color(1.0, 0.82, 0.15))
	head.add_child(coins_label)

	# Columna izquierda: mejoras
	var left := VBoxContainer.new()
	left.position = Vector2(40, 150)
	left.custom_minimum_size = Vector2(640, 0)
	left.add_theme_constant_override("separation", 8)
	add_child(left)
	left.add_child(_label("MEJORAS", 22, Color(0.3, 0.9, 0.95)))
	for id in Game.UPGRADES.keys():
		rows[id] = _make_row(left, 430, _on_buy.bind(id))

	# Columna derecha: consumibles + botones
	var right := VBoxContainer.new()
	right.position = Vector2(720, 150)
	right.custom_minimum_size = Vector2(520, 0)
	right.add_theme_constant_override("separation", 8)
	add_child(right)
	right.add_child(_label("CONSUMIBLES", 22, Color(0.3, 0.9, 0.95)))
	for id in Game.CONSUMABLES.keys():
		item_rows[id] = _make_row(right, 330, _on_buy_item.bind(id))
	right.add_child(_label("Los consumibles te duran entre rondas hasta que los uses.", 15, Color(0.7, 0.7, 0.75)))
	right.add_child(_label(" ", 20, Color(1, 1, 1)))

	var next := Button.new()
	next.text = "Siguiente ronda  (Enter)"
	next.custom_minimum_size = Vector2(0, 52)
	next.focus_mode = Control.FOCUS_NONE
	next.add_theme_font_size_override("font_size", 22)
	next.pressed.connect(_next_round)
	right.add_child(next)

	var quit := Button.new()
	quit.text = "Terminar partida y volver al menu  (Esc)"
	quit.custom_minimum_size = Vector2(0, 40)
	quit.focus_mode = Control.FOCUS_NONE
	quit.add_theme_font_size_override("font_size", 16)
	quit.pressed.connect(_quit_run)
	right.add_child(quit)

	_refresh()

func _make_row(parent: Control, label_w: float, on_press: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(label_w, 0)
	lbl.add_theme_font_size_override("font_size", 17)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(170, 46)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(on_press)
	row.add_child(lbl)
	row.add_child(btn)
	parent.add_child(row)
	return {"label": lbl, "button": btn}

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _refresh() -> void:
	coins_label.text = "Dinero: $%d" % Game.coins
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
	for id in item_rows.keys():
		var info: Dictionary = Game.CONSUMABLES[id]
		var have := Game.stock_of(id)
		var mx := int(info["max"])
		item_rows[id]["label"].text = "%s   [tienes %d/%d]\n%s" % [info["name"], have, mx, info["desc"]]
		var btn: Button = item_rows[id]["button"]
		if have >= mx:
			btn.text = "LLENO"
			btn.disabled = true
		else:
			btn.text = "Comprar  %d" % int(info["price"])
			btn.disabled = not Game.can_buy_item(id)

func _on_buy(id: String) -> void:
	Game.buy(id)
	_refresh()

func _on_buy_item(id: String) -> void:
	Game.buy_item(id)
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
