extends Control
# Pantalla de CONTRATO DE RIESGO (diseño del mockup de Figma, estilo de la heredera: ui.gd).
# Antes de cada ronda eliges 1 de 3 tarjetas. Mas riesgo = mas dinero. "Ronda tranquila" siempre esta.
# Teclas 1 / 2 / 3 o clic en el boton de la tarjeta.
# Icono de cada contrato (opcional): res://assets/contract_<id>.png  (calm, double, rush, vip, high, slippery).

const UI = preload("res://ui.gd")
const IconBox = preload("res://icon_box.gd")

const MAIN_SCENE := "res://main.tscn"

const BG := Color("3B3466")        # fondo: el moradito del suelo del juego, un poco mas claro
const CARD := Color("54478A")      # tarjetas y paneles: lila
const DARK := Color("2A2547")      # botones oscuros: morado del suelo
const DISABLED := Color("6A5F96")  # botones que no se pueden usar
const HOVER_DARK := Color("3B3466") # hover de los botones oscuros
const ORANGE := Color("F2A65E")    # naranja damasco suave: botones de accion y riesgo (contraste con el morado)
const ACCENT := Color("EADFCB")    # crema pergamino: titulos, botones (suave, sin brillo)
const BORDER := Color("C9B2F5")    # lila pastel: bordes de tarjetas
const MINT := Color("A6F2BC")      # verde pastel (cuota)
const SKY := Color("A5EAF2")       # celeste pastel
const CORAL := Color("E8C98A")     # arena suave (aviso de jefe)
const MUTED := Color("D5CCEE")     # texto secundario

const RISK_TAGS := ["SIN RIESGO", "RIESGO 1 · MEDIO", "RIESGO 2 · ALTO"]

# Letra provisional del icono mientras no exista el PNG
const GLYPHS := {"calm": "R", "double": "x2", "rush": "P", "vip": "V", "high": "$", "slippery": "~"}

var choices: Array = []
var chosen := false

func _ready() -> void:
	choices = Game.roll_contracts()
	var r := Game.round_number

	var bg := ColorRect.new()
	bg.color = BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 0)
	margin.add_child(page)

	# Cabecera
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.add_child(UI.label("CONTRATO DE LA RONDA %d" % r, 48, ACCENT, 8))
	head.add_child(UI.label("Elige cuánto riesgo quieres. Más riesgo = más dinero.", 22, Color.WHITE, 0))
	page.add_child(head)
	page.add_child(_spacer_v())

	# Las 3 tarjetas
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 24)
	page.add_child(cards)
	for i in choices.size():
		cards.add_child(_make_card(i, r))

	page.add_child(_spacer_v())

	# Pie
	var foot := HBoxContainer.new()
	foot.add_child(UI.label(Game.TITLE, 20, ACCENT, 4))
	foot.add_child(_spacer_h())
	foot.add_child(UI.label("Pulsa la tecla de tu contrato para elegir.", 18, MUTED, 0))
	page.add_child(foot)

func _spacer_v() -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s

func _spacer_h() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s

func _fmt(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return str(snappedf(v, 0.01))

func _make_card(i: int, r: int) -> PanelContainer:
	var id: String = choices[i]
	var info: Dictionary = Game.CONTRACTS[id]
	var risk := clampi(int(info.get("risk", 0)), 0, 2)
	var accent := SKY if risk == 0 else ORANGE

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 470)
	card.add_theme_stylebox_override("panel", UI.panel_style(CARD, BORDER, 14, 3, false, 24))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	card.add_child(col)

	# nivel de riesgo
	col.add_child(UI.label(RISK_TAGS[risk], 30, accent, 3))

	# icono + nombre
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	var icon := IconBox.new(96.0)
	icon.show_icon("contract_" + id, GLYPHS.get(id, "?"), accent)
	top.add_child(icon)
	var title := UI.label(info["name"], 34, accent, 3)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size = Vector2(120, 0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	col.add_child(top)

	# descripcion
	var desc := UI.label(String(info["desc"]).replace("\n", " "), 20, Color.WHITE, 0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 84)
	col.add_child(desc)

	# numeros: cuota, dinero y tiempo (ya con tus mejoras y reliquias)
	var nums := VBoxContainer.new()
	nums.add_theme_constant_override("separation", 6)
	nums.add_child(UI.label("Cuota: %d puntos" % Game.current_quota(r, id), 28, MINT, 3))
	nums.add_child(UI.label("Dinero x%s · Tiempo: %ds" % [
		_fmt(Game.contract_val(id, "money_mult", 1.0)), roundi(Game.round_time(r, id))], 26, accent, 3))
	col.add_child(nums)

	col.add_child(_spacer_v())
	col.add_child(_make_button(i, risk))
	return card

func _make_button(i: int, risk: int) -> Button:
	var btn := Button.new()
	btn.text = "Elegir (%d)" % (i + 1)
	btn.custom_minimum_size = Vector2(0, 56)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", UI.font())
	btn.add_theme_font_size_override("font_size", 28)
	var filled := risk > 0   # los contratos con riesgo: boton amarillo; el tranquilo: oscuro con borde amarillo
	var fill := ORANGE if filled else DARK
	var hover := ORANGE.lightened(0.2) if filled else HOVER_DARK
	var txt := UI.INK if filled else ACCENT
	btn.add_theme_stylebox_override("normal", UI.panel_style(fill, ORANGE if filled else ACCENT, 12, 3, false, 8))
	btn.add_theme_stylebox_override("hover", UI.panel_style(hover, ORANGE if filled else ACCENT, 12, 3, false, 8))
	btn.add_theme_stylebox_override("pressed", UI.panel_style(hover, ORANGE if filled else ACCENT, 12, 3, false, 8))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, txt)
	btn.pressed.connect(_choose.bind(i))
	return btn

func _choose(i: int) -> void:
	if chosen:
		return
	chosen = true
	Game.set_contract(choices[i])
	get_tree().change_scene_to_file(MAIN_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_choose(0)
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_choose(1)
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_choose(2)
