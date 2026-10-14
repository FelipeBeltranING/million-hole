extends Control
# Menu principal.

const MAIN_SCENE := "res://main.tscn"

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.position = Vector2(340, 130)
	box.custom_minimum_size = Vector2(600, 0)
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	box.add_child(_label(Game.TITLE, 48, Color(1.0, 0.82, 0.15)))
	box.add_child(_label(Game.SUBTITLE, 20, Color(0.8, 0.8, 0.85)))
	if Game.best_round_score > 0:
		box.add_child(_label("Mejor ronda de esta sesion: %d puntos (ronda %d)" % [Game.best_round_score, Game.best_round_no], 22, Color(0.3, 0.9, 0.95)))
	else:
		box.add_child(_label(" ", 22, Color(1, 1, 1)))

	var play := _button("Jugar  (Enter)")
	play.pressed.connect(_play)
	box.add_child(play)
	var quit := _button("Salir  (Esc)")
	quit.pressed.connect(get_tree().quit)
	box.add_child(quit)

	box.add_child(_label("WASD / Flechas: mover   |   E / Espacio: recoger cosas o tirarlas en el agujero", 16, Color(0.7, 0.7, 0.75)))
	box.add_child(_label("Q: bolsazo (mejora de la boutique)   |   Shift: turbo (consumible)", 16, Color(0.7, 0.7, 0.75)))
	box.add_child(_label("El progreso NO se guarda: al cerrar el juego se pierde todo.", 16, Color(0.7, 0.7, 0.75)))

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	return b

func _play() -> void:
	Game.reset_run()
	get_tree().change_scene_to_file(MAIN_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_play()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
