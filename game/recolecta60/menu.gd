extends Control
# Menu principal.

const UI = preload("res://ui.gd")
const Assets = preload("res://assets.gd")

const MAIN_SCENE := "res://main.tscn"

func _ready() -> void:
	Sound.music("music_menu")
	# fondo de inicio: assets/bg_menu.* o assets/fondo.jpg; si no hay, color liso
	var bg_tex := Assets.background("menu")
	if bg_tex != null:
		var bg_img := TextureRect.new()
		bg_img.texture = bg_tex
		bg_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg_img)
		bg_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var bg := ColorRect.new()
		bg.color = Color(0.08, 0.09, 0.12)
		add_child(bg)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# panel oscuro centrado (para que el texto se lea sobre el fondo)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", UI.panel_style(Color(0.10, 0.06, 0.05, 0.90), UI.YELLOW, 20, 6, true, 28))
	add_child(panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(640, 0)
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := UI.label(Game.TITLE, 48, UI.YELLOW, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_label(Game.SUBTITLE, 20, Color(0.8, 0.8, 0.85)))
	if Game.best_round_score > 0:
		box.add_child(_label("Best round this session: %d points (round %d)" % [Game.best_round_score, Game.best_round_no], 22, Color(0.3, 0.9, 0.95)))
	else:
		box.add_child(_label(" ", 22, Color(1, 1, 1)))

	var play := _button("Play  (Enter)")
	play.pressed.connect(_play)
	box.add_child(play)
	var quit := _button("Quit  (Esc)")
	quit.pressed.connect(get_tree().quit)
	box.add_child(quit)

	box.add_child(_label("WASD / Arrows: move   |   E / Space: pick up items or drop them into the vortex", 16, Color(0.7, 0.7, 0.75)))
	box.add_child(_label("Q: bag smack (upgrade)   |   Shift: turbo   |   F: blinding flash   (bought at the boutique)", 16, Color(0.7, 0.7, 0.75)))
	box.add_child(_label("Progress is NOT saved: closing the game erases everything.", 16, Color(0.7, 0.7, 0.75)))

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
	Sound.play("ui_start")
	Game.reset_run()
	get_tree().change_scene_to_file(MAIN_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_play()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
