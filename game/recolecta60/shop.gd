extends Control
# BOUTIQUE (diseño del mockup de Figma "BOUTIQUE", estilo de la heredera: ui.gd).
# 5 ofertas al azar (mejoras, reliquias, consumibles): no alcanza para todo, hay que elegir.
# Se pueden renovar pagando (cada renovacion cuesta mas). Los precios suben con la ronda.
# Iconos opcionales: upgrade_<id>.png (mejoras; el bolsazo usa tool_bolsazo.png), relic_<id>.png, tool_<id>.png (consumibles).

const UI = preload("res://ui.gd")
const IconBox = preload("res://icon_box.gd")

const MAIN_SCENE := "res://main.tscn"
const CONTRACT_SCENE := "res://contract.tscn"
const MENU_SCENE := "res://menu.tscn"



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
const CARD_SIZE := Vector2(288, 208)

const KIND_TAGS := {"upgrade": "UPGRADE", "relic": "RELIC", "consumable": "CONSUMABLE"}
const KIND_COLORS := {"upgrade": Color.WHITE, "relic": ACCENT, "consumable": SKY}

var money_label: Label
var grid: GridContainer
var reroll_button: Button
var relics_row: HBoxContainer
var stock_row: HBoxContainer

func _ready() -> void:
	Sound.music("music_shop")
	Game.new_shop()
	var next_r := Game.round_number + 1

	var bg := ColorRect.new()
	bg.color = BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# --- Titulo (arriba izquierda)
	var head := VBoxContainer.new()
	head.position = Vector2(32, 18)
	head.custom_minimum_size = Vector2(884, 0)
	head.add_theme_constant_override("separation", 0)
	head.add_child(UI.label("BOUTIQUE", 48, ACCENT, 8))
	head.add_child(UI.label("Round %d cleared - %d points | Next quota: %d" % [
		Game.round_number, Game.last_round_score, Game.quota_estimate(next_r)], 28, Color.WHITE, 4))
	add_child(head)

	# --- Dinero (arriba derecha)
	var money_panel := PanelContainer.new()
	money_panel.position = Vector2(940, 24)
	money_panel.custom_minimum_size = Vector2(320, 80)
	money_panel.add_theme_stylebox_override("panel", UI.panel_style(CARD, BORDER, 14, 3, false, 16))
	money_label = UI.label("", 38, ACCENT, 4)
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_panel.add_child(money_label)
	add_child(money_panel)

	# --- Aviso de gala con jefe
	if Game.is_boss_round(next_r):
		var banner := PanelContainer.new()
		banner.position = Vector2(32, 120)
		banner.custom_minimum_size = Vector2(1216, 44)
		banner.add_theme_stylebox_override("panel", UI.panel_style(Color(CORAL.r, CORAL.g, CORAL.b, 0.12), CORAL, 12, 3, false, 6))
		var brow := HBoxContainer.new()
		brow.add_child(UI.label("NEXT ROUND IS A GALA WITH A BOSS!", 28, CORAL, 3))
		var bsp := Control.new()
		bsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		brow.add_child(bsp)
		brow.add_child(UI.label("Brace for the flashes.", 18, CORAL, 0))
		banner.add_child(brow)
		add_child(banner)

	# --- Ofertas (cuadricula de 3 columnas)
	grid = GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(32, 182)
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	add_child(grid)

	# --- Panel de la derecha
	var side := PanelContainer.new()
	side.position = Vector2(940, 182)
	side.custom_minimum_size = Vector2(320, 384)
	side.add_theme_stylebox_override("panel", UI.panel_style(CARD, BORDER, 14, 3, false, 20))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	side.add_child(col)
	col.add_child(UI.label("Ready for more?", 30, ACCENT, 3))
	var blurb := UI.label("Buy something pretty. Then throw it into the vortex.", 18, Color.WHITE, 0)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(0, 48)
	col.add_child(blurb)

	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(0, 56)
	reroll_button.add_theme_font_size_override("font_size", 24)
	_style_button(reroll_button, DARK, HOVER_DARK, ACCENT, ACCENT)
	reroll_button.pressed.connect(_on_reroll)
	col.add_child(reroll_button)

	var nextcol := VBoxContainer.new()
	nextcol.add_theme_constant_override("separation", 6)
	var next := Button.new()
	next.text = "Next round"
	next.custom_minimum_size = Vector2(0, 64)
	next.add_theme_font_size_override("font_size", 30)
	_style_button(next, ORANGE, ORANGE.lightened(0.2), ORANGE, UI.INK)
	next.pressed.connect(_next_round)
	nextcol.add_child(next)
	var enter_hint := UI.label("Press Enter to continue", 18, ORANGE, 0)
	enter_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nextcol.add_child(enter_hint)
	col.add_child(nextcol)

	var quit := Button.new()
	quit.text = "End run (Esc)"
	quit.custom_minimum_size = Vector2(0, 44)
	quit.add_theme_font_size_override("font_size", 18)
	_style_button(quit, DARK, HOVER_DARK, MUTED, MUTED)
	quit.pressed.connect(_quit_run)
	col.add_child(quit)
	add_child(side)

	# --- Abajo: reliquias y consumibles que tienes
	var have := HBoxContainer.new()
	have.position = Vector2(32, 636)
	have.custom_minimum_size = Vector2(884, 64)
	have.add_theme_constant_override("separation", 24)
	var rcol := VBoxContainer.new()
	rcol.custom_minimum_size = Vector2(488, 0)
	rcol.add_theme_constant_override("separation", 4)
	rcol.add_child(UI.label("YOUR RELICS", 18, ACCENT, 2))
	relics_row = HBoxContainer.new()
	relics_row.add_theme_constant_override("separation", 12)
	rcol.add_child(relics_row)
	have.add_child(rcol)
	var ccol := VBoxContainer.new()
	ccol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ccol.add_theme_constant_override("separation", 4)
	ccol.add_child(UI.label("CONSUMABLES", 18, SKY, 2))
	stock_row = HBoxContainer.new()
	stock_row.add_theme_constant_override("separation", 16)
	ccol.add_child(stock_row)
	have.add_child(ccol)
	add_child(have)

	# --- Titulo del juego (abajo derecha)
	var title := UI.label(Game.TITLE, 20, ACCENT, 4)
	title.position = Vector2(940, 667)
	add_child(title)

	_refresh()

# ---------------------------------------------------------------- Construccion

# Estilo de boton: normal / hover / pressed / desactivado (todo con la fuente del juego)
func _style_button(btn: Button, fill: Color, hover: Color, border: Color, txt: Color,
		dis_fill: Color = DISABLED, dis_border: Color = DISABLED, dis_txt: Color = MUTED) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", UI.font())
	btn.add_theme_stylebox_override("normal", UI.panel_style(fill, border, 12, 3, false, 6))
	btn.add_theme_stylebox_override("hover", UI.panel_style(hover, border, 12, 3, false, 6))
	btn.add_theme_stylebox_override("pressed", UI.panel_style(hover, border, 12, 3, false, 6))
	btn.add_theme_stylebox_override("disabled", UI.panel_style(dis_fill, dis_border, 12, 3, false, 6))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, txt)
	btn.add_theme_color_override("font_disabled_color", dis_txt)

func _icon_key(o: Dictionary) -> String:
	match o["kind"]:
		"upgrade":
			return "tool_bolsazo" if o["id"] == "bolsazo" else "upgrade_" + String(o["id"])
		"relic":
			return "relic_" + String(o["id"])
	return "tool_" + String(o["id"])

func _make_card(i: int) -> PanelContainer:
	var o: Dictionary = Game.shop_offers[i]
	var kind: String = o["kind"]
	var accent: Color = KIND_COLORS[kind]
	var name_text: String = Game.offer_name(o)

	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", UI.panel_style(CARD, BORDER, 14, 3, false, 12))
	if o["sold"]:
		card.modulate.a = 0.4

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)

	# fila 1: tipo + nivel
	var top := HBoxContainer.new()
	top.add_child(UI.label(KIND_TAGS[kind], 20, accent, 2))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	if kind == "upgrade":
		top.add_child(UI.label("Level %d/%d" % [Game.level(o["id"]), int(Game.UPGRADES[o["id"]]["max"])], 26, ORANGE, 3))
	col.add_child(top)

	# fila 2: icono + nombre y descripcion
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	var icon := IconBox.new(96.0)
	icon.show_icon(_icon_key(o), name_text.substr(0, 1).to_upper(), accent)
	body.add_child(icon)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.custom_minimum_size = Vector2(120, 96)
	texts.clip_contents = true
	var nm := UI.label(name_text, 22, Color.WHITE, 2)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.max_lines_visible = 2
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(nm)
	var ds := UI.label(Game.offer_desc(o), 15, MUTED, 0)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.max_lines_visible = 3
	ds.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(ds)
	body.add_child(texts)
	col.add_child(body)

	# fila 3: boton
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 24)
	# naranja solo en las MEJORAS; reliquias y consumibles ("powers") mantienen su color de antes (crema)
	var buy_col: Color = ORANGE if kind == "upgrade" else ACCENT
	_style_button(btn, buy_col, buy_col.lightened(0.2), buy_col, UI.INK)
	if o["sold"]:
		btn.text = "SOLD"
		btn.disabled = true
	elif not Game.offer_available(o):
		btn.text = "MAXED" if kind == "upgrade" else "FULL"
		btn.disabled = true
	else:
		btn.text = "FREE" if o.get("free", false) else "Buy %d" % Game.offer_price(o)
		btn.disabled = not Game.can_buy_offer(i)
	btn.pressed.connect(_on_buy.bind(i))
	col.add_child(btn)
	return card

func _make_info_block() -> Control:
	var m := MarginContainer.new()
	m.custom_minimum_size = CARD_SIZE
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	var t := UI.label("Luxury has limits.", 30, ACCENT, 3)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var d := UI.label("Upgrades stack. Relics are unique. Consumables have limited capacity.", 18, MUTED, 0)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	m.add_child(v)
	return m

func _make_relic_chip(id: String, with_name: bool) -> Control:
	var info: Dictionary = Game.RELICS[id]
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 44)
	chip.add_theme_stylebox_override("panel", UI.panel_style(CARD, CARD, 10, 0, false, 4))
	chip.tooltip_text = "%s: %s" % [info["name"], info["desc"]]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var icon := IconBox.new(36.0)
	icon.show_icon("relic_" + id, String(info["name"]).substr(0, 1).to_upper(), ACCENT)
	h.add_child(icon)
	if with_name:
		var l := UI.label(info["name"], 18, Color.WHITE, 0)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(l)
	chip.add_child(h)
	return chip

# ---------------------------------------------------------------- Refresco

func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _refresh() -> void:
	money_label.text = "Cash: $%d" % Game.coins

	_clear(grid)
	for i in Game.shop_offers.size():
		grid.add_child(_make_card(i))
	grid.add_child(_make_info_block())

	var cost := Game.reroll_cost()
	reroll_button.text = "Reroll offers (%d)" % cost
	reroll_button.disabled = Game.coins < cost

	# reliquias que tienes (con mas de 2, solo iconos; el nombre sale al pasar el mouse)
	_clear(relics_row)
	if Game.relics.is_empty():
		relics_row.add_child(UI.label("None yet", 18, MUTED, 0))
	else:
		for id in Game.relics:
			relics_row.add_child(_make_relic_chip(id, Game.relics.size() <= 2))

	# consumibles que tienes
	_clear(stock_row)
	var shown := 0
	for id in Game.CONSUMABLES.keys():
		var n := Game.stock_of(id)
		if n > 0:
			shown += 1
	var fsize := 30 if shown <= 2 else 24
	for id in Game.CONSUMABLES.keys():
		var n := Game.stock_of(id)
		if n > 0:
			var short_name: String = String(Game.CONSUMABLES[id]["name"]).split(" ")[-1]
			stock_row.add_child(UI.label("%s x%d" % [short_name, n], fsize, SKY, 3))
	if shown == 0:
		stock_row.add_child(UI.label("None", 18, MUTED, 0))

# ---------------------------------------------------------------- Acciones

func _on_buy(i: int) -> void:
	if Game.buy_offer(i):
		Sound.play("ui_buy")
	_refresh()

func _on_reroll() -> void:
	if Game.reroll():
		Sound.play("ui_reroll")
	_refresh()

func _next_round() -> void:
	Sound.play("ui_start")
	Game.round_number += 1
	if Game.is_boss_round(Game.round_number):
		Game.set_contract("calm")   # la gala no tiene contrato
		get_tree().change_scene_to_file(MAIN_SCENE)
	else:
		get_tree().change_scene_to_file(CONTRACT_SCENE)

func _quit_run() -> void:
	Sound.play("ui_back")
	Game.reset_run()
	get_tree().change_scene_to_file(MENU_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_next_round()
		elif event.keycode == KEY_ESCAPE:
			_quit_run()
