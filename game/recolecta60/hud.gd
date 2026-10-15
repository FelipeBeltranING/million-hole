extends CanvasLayer
# Interfaz de la partida. Diseño base 1280x720 (viene del mockup de Figma), estilo de la heredera:
# naranja/amarillo, contornos negros gruesos, fuente Lilita One. Estilos y colores compartidos en ui.gd.

const OrderPanelScript = preload("res://order_panel.gd")
const IconBox = preload("res://icon_box.gd")
const UI = preload("res://ui.gd")
const Assets = preload("res://assets.gd")

# Zonas que el HUD ocupa sobre el mapa. main.gd evita poner cosas ahi (objetos, peligros, vortice).
const ZONES = [
	Rect2(24, 96, 288, 110),    # ronda / contrato
	Rect2(24, 324, 250, 100),   # lo que llevas
	Rect2(24, 460, 288, 208),   # caprichos
	Rect2(1012, 96, 240, 70),   # combo
	Rect2(440, 576, 400, 92),   # reliquias
	Rect2(824, 524, 432, 144),  # herramientas
	Rect2(400, 92, 480, 76),    # barra del jefe
]

var quota_value := 1
var time_label: Label
var score_label: Label
var score_bar: ProgressBar
var coins_label: Label
var round_label: Label
var contract_label: Label
var best_label: Label
var combo_panel: PanelContainer
var combo_label: Label
var combo_bar: ProgressBar
var combo_max := 0.0
var carry_title: Label
var carry_row: HBoxContainer
var order_panel
var relics_panel: PanelContainer
var relics_row: HBoxContainer
var tools_box: HBoxContainer
var tool_cards := {}
var boss_panel: PanelContainer
var boss_row: HBoxContainer
var dim: ColorRect
var end_bg: TextureRect   # fondo de la pantalla de FIN DE LA PARTIDA (assets/fondo.jpg o bg_gameover)
var result_panel: Panel
var message_label: RichTextLabel
var hint_label: Label

func _ready() -> void:
	_build_top_bar()
	_build_round_card()
	_build_carry()
	order_panel = OrderPanelScript.new()
	order_panel.position = Vector2(24, 460)
	add_child(order_panel)
	_build_combo()
	_build_relics()
	_build_tools()
	_build_boss()
	var help := UI.label("WASD / Flechas: mover   ·   E / Espacio: recoger y tirar en el vórtice   ·   Q bolsazo   ·   Shift turbo   ·   F flash", 16, UI.GRAY, 4)
	help.position = Vector2(24, 682)
	add_child(help)
	_build_result()

# ---------------------------------------------------------------- Construccion

func _panel(pos: Vector2, min_w: float, border: Color = UI.YELLOW, margin: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.custom_minimum_size = Vector2(min_w, 0)
	p.add_theme_stylebox_override("panel", UI.panel_style(UI.PANEL, border, 14, 4, true, margin))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p

func _bar(w: float, h: float, fill: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = 0.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = UI.INK
	bg.set_corner_radius_all(int(h / 2.0))
	b.add_theme_stylebox_override("background", bg)
	var fl := StyleBoxFlat.new()
	fl.bg_color = fill
	fl.set_corner_radius_all(int(h / 2.0))
	b.add_theme_stylebox_override("fill", fl)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _bar_color(b: ProgressBar, c: Color) -> void:
	var fl := b.get_theme_stylebox("fill") as StyleBoxFlat
	if fl != null:
		fl.bg_color = c

func _build_top_bar() -> void:
	var bar := Panel.new()
	bar.size = Vector2(1280, 80)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI.ORANGE_SOFT   # (antes UI.ORANGE, un rojo-naranja muy fuerte)
	sb.border_color = UI.INK
	sb.border_width_bottom = 6
	bar.add_theme_stylebox_override("panel", sb)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	# tiempo (izquierda)
	var ticon := IconBox.new(44.0)
	ticon.position = Vector2(24, 14)
	ticon.show_icon("icon_time", "T", UI.CYAN)
	add_child(ticon)
	time_label = UI.label("Tiempo: 30", 34, Color.WHITE, 8)
	time_label.position = Vector2(80, 12)
	add_child(time_label)
	# puntos / cuota (centro)
	score_label = UI.label("Puntos: 0 / 0", 32, Color.WHITE, 8)
	score_label.position = Vector2(340, 4)
	score_label.size = Vector2(600, 40)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(score_label)
	score_bar = _bar(320.0, 12.0, UI.YELLOW)
	score_bar.position = Vector2(480, 52)
	score_bar.size = Vector2(320, 12)
	add_child(score_bar)
	# dinero (derecha)
	coins_label = UI.label("Dinero: $0", 34, Color.WHITE, 8)
	coins_label.position = Vector2(880, 12)
	coins_label.size = Vector2(320, 44)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(coins_label)
	var micon := IconBox.new(44.0)
	micon.position = Vector2(1212, 14)
	micon.show_icon("icon_money", "$", UI.YELLOW)
	add_child(micon)

func _build_round_card() -> void:
	var p := _panel(Vector2(24, 96), 288.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	round_label = UI.label("Ronda 1", 32, UI.YELLOW)
	contract_label = UI.label("Contrato: -", 18, Color.WHITE, 4)
	best_label = UI.label("", 15, UI.GRAY, 3)
	v.add_child(round_label)
	v.add_child(contract_label)
	v.add_child(best_label)

func _build_carry() -> void:
	var p := _panel(Vector2(24, 324), 176.0, UI.YELLOW, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	carry_title = UI.label("Llevas 0/2", 28)
	v.add_child(carry_title)
	carry_row = HBoxContainer.new()
	carry_row.add_theme_constant_override("separation", 8)
	v.add_child(carry_row)

func _build_combo() -> void:
	combo_panel = _panel(Vector2(1012, 96), 240.0, UI.ORANGE)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	combo_panel.add_child(v)
	combo_label = UI.label("COMBO x1.0", 30, UI.ORANGE.lightened(0.25))
	v.add_child(combo_label)
	combo_bar = _bar(212.0, 10.0, UI.ORANGE.lightened(0.15))
	v.add_child(combo_bar)
	combo_panel.visible = false

func _build_relics() -> void:
	relics_panel = _panel(Vector2(560, 576), 140.0, UI.YELLOW, 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	relics_panel.add_child(v)
	v.add_child(UI.label("RELIQUIAS", 18, UI.YELLOW, 4))
	relics_row = HBoxContainer.new()
	relics_row.add_theme_constant_override("separation", 6)
	v.add_child(relics_row)
	relics_panel.visible = false

func _build_tools() -> void:
	tools_box = HBoxContainer.new()
	tools_box.position = Vector2(824, 524)
	tools_box.size = Vector2(432, 144)
	tools_box.alignment = BoxContainer.ALIGNMENT_END
	tools_box.add_theme_constant_override("separation", 12)
	tools_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tools_box)
	var defs := [
		{"id": "bolsazo", "name": "Bolsazo", "key": "Q", "glyph": "B"},
		{"id": "turbo", "name": "Turbo", "key": "Shift", "glyph": "T"},
		{"id": "flash", "name": "Flash", "key": "F", "glyph": "F"},
		{"id": "shield", "name": "Escudo", "key": "Auto", "glyph": "E"},
	]
	for d in defs:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(96, 0)
		card.add_theme_stylebox_override("panel", UI.panel_style(UI.PANEL, UI.YELLOW, 14, 4, true, 10))
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.visible = false
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 4)
		card.add_child(v)
		var top := HBoxContainer.new()
		top.alignment = BoxContainer.ALIGNMENT_CENTER
		top.add_theme_constant_override("separation", 6)
		v.add_child(top)
		var icon := IconBox.new(40.0)
		icon.show_icon("tool_" + String(d["id"]), String(d["glyph"]), UI.CYAN)
		top.add_child(icon)
		var count := UI.label("x0", 26, UI.CYAN, 5)
		top.add_child(count)
		var nm := UI.label(String(d["name"]), 18, Color.WHITE, 4)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var key := UI.label(String(d["key"]), 26 if d["key"] != "Auto" else 20, UI.YELLOW, 5)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(key)
		var cd := _bar(76.0, 6.0, UI.GRAY)
		cd.visible = d["id"] == "bolsazo"
		v.add_child(cd)
		tools_box.add_child(card)
		tool_cards[d["id"]] = {"card": card, "icon": icon, "count": count, "bar": cd}

func _build_boss() -> void:
	boss_panel = _panel(Vector2(400, 92), 480.0, UI.RED, 10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	boss_panel.add_child(v)
	var t := UI.label("PAPARAZZI SUPREMO", 26, UI.RED, 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	boss_row = HBoxContainer.new()
	boss_row.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_row.add_theme_constant_override("separation", 4)
	v.add_child(boss_row)
	boss_panel.visible = false

func _build_result() -> void:
	end_bg = TextureRect.new()
	end_bg.size = Vector2(1280, 720)
	end_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	end_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	end_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_bg.visible = false
	add_child(end_bg)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	result_panel = Panel.new()
	result_panel.position = Vector2(200, 90)
	result_panel.size = Vector2(880, 540)
	result_panel.add_theme_stylebox_override("panel", UI.panel_style(Color(0.10, 0.06, 0.05, 0.96), UI.YELLOW, 20, 6, true))
	result_panel.visible = false
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result_panel)
	message_label = RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.scroll_active = false
	message_label.position = Vector2(230, 110)
	message_label.size = Vector2(820, 420)
	message_label.add_theme_font_override("normal_font", UI.font())
	message_label.add_theme_font_size_override("normal_font_size", 24)
	message_label.add_theme_color_override("default_color", Color.WHITE)
	message_label.add_theme_color_override("font_outline_color", UI.INK)
	message_label.add_theme_constant_override("outline_size", 6)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_label.visible = false
	add_child(message_label)
	hint_label = UI.label("", 26, UI.YELLOW, 6)
	hint_label.position = Vector2(200, 568)
	hint_label.size = Vector2(880, 44)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.visible = false
	add_child(hint_label)

# ---------------------------------------------------------------- Actualizacion (API usada por main.gd)

func set_time(seconds: float) -> void:
	time_label.text = "Tiempo: %d" % ceili(seconds)
	time_label.add_theme_color_override("font_color", UI.RED.lightened(0.2) if seconds <= 10.0 else Color.WHITE)

# Herramientas: bolsazo (si lo tienes), turbo, flash y escudo. Se llama cada frame (solo cambia valores).
func set_tools(bolsazo_lvl: int, cd: float, turbo_n: int, shield_n: int, flash_n: int) -> void:
	var b: Dictionary = tool_cards["bolsazo"]
	b["card"].visible = bolsazo_lvl > 0
	if bolsazo_lvl > 0:
		var is_ready := cd <= 0.0
		b["count"].text = "OK" if is_ready else "%ds" % ceili(cd)
		b["count"].add_theme_color_override("font_color", UI.GREEN if is_ready else UI.GRAY)
		b["icon"].set_border(UI.GREEN if is_ready else UI.GRAY)
		var bar: ProgressBar = b["bar"]
		bar.max_value = Game.bolsazo_cooldown()
		bar.value = bar.max_value - cd
	_tool_count("turbo", turbo_n)
	_tool_count("flash", flash_n)
	_tool_count("shield", shield_n)

func _tool_count(id: String, n: int) -> void:
	var t: Dictionary = tool_cards[id]
	t["card"].visible = n > 0
	t["count"].text = "x%d" % n

func set_quota(q: int) -> void:
	quota_value = maxi(q, 1)
	score_bar.max_value = float(quota_value)

# Puntos / cuota; la barra y el texto se ponen verdes al llegar a la cuota
func set_score(points: int) -> void:
	score_label.text = "Puntos: %d / %d" % [points, quota_value]
	var reached := points >= quota_value
	score_label.add_theme_color_override("font_color", UI.GREEN if reached else Color.WHITE)
	score_bar.value = float(points)
	_bar_color(score_bar, UI.GREEN if reached else UI.YELLOW)

func set_coins(amount: int) -> void:
	coins_label.text = "Dinero: $%d" % amount

func set_carry(carried: Array, max_carry: int) -> void:
	carry_title.text = "Llevas %d/%d" % [carried.size(), max_carry]
	for c in carry_row.get_children():
		carry_row.remove_child(c)
		c.queue_free()
	for i in max_carry:
		var box := IconBox.new(48.0)
		if i < carried.size():
			box.show_item(carried[i])
		else:
			box.show_empty()
		carry_row.add_child(box)

func set_order(slots: Array) -> void:
	order_panel.set_order(slots)

# combo = entregas seguidas, mult = multiplicador, secs = tiempo que queda para mantenerlo
func set_combo(combo: int, mult: float, secs: float) -> void:
	if combo <= 0:
		combo_panel.visible = false
		combo_max = 0.0
		return
	combo_panel.visible = true
	combo_label.text = "COMBO x%.1f" % mult
	combo_max = maxf(combo_max, secs)
	combo_bar.max_value = maxf(combo_max, 0.1)
	combo_bar.value = secs

func set_round(round_number: int, best: int, contract_name: String = "") -> void:
	round_label.text = "Ronda %d" % round_number
	contract_label.text = "Contrato: %s" % contract_name
	best_label.text = "Mejor ronda: %d pts" % best

func set_relics(ids: Array) -> void:
	for c in relics_row.get_children():
		relics_row.remove_child(c)
		c.queue_free()
	relics_panel.visible = not ids.is_empty()
	for id in ids:
		var b := IconBox.new(38.0)
		b.show_icon("relic_" + String(id), String(Game.RELICS[id]["name"]).substr(0, 1), UI.YELLOW)
		relics_row.add_child(b)
	var w := maxf(140.0, 24.0 + float(ids.size()) * 44.0)
	relics_panel.position.x = (1280.0 - w) / 2.0

# Barra de vida del jefe: segmentos rojos
func set_boss(hp: int, max_hp: int) -> void:
	boss_panel.visible = true
	for c in boss_row.get_children():
		boss_row.remove_child(c)
		c.queue_free()
	var w := minf(72.0, 440.0 / float(maxi(max_hp, 1))) - 4.0
	for i in max_hp:
		var seg := Panel.new()
		seg.custom_minimum_size = Vector2(w, 16)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UI.RED if i < hp else Color(0.25, 0.2, 0.2)
		sb.border_color = UI.INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		seg.add_theme_stylebox_override("panel", sb)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss_row.add_child(seg)

func hide_boss() -> void:
	boss_panel.visible = false

# Aviso grande que sube y se desvanece
func toast(text: String, color: Color = Color(1, 1, 1)) -> void:
	var size := get_viewport().get_visible_rect().size
	var l := UI.label(text, 44, color, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(size.x, 70)
	l.position = Vector2(0, size.y * 0.2)
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50.0, 1.3)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.5)
	tw.finished.connect(l.queue_free)

# info: passed, score, quota, coins, orders, tally, round, new_record, contract, boss_round, boss_defeated,
#       run_best_score, run_best_round, session_best, session_best_round
func show_round_result(info: Dictionary) -> void:
	var size := get_viewport().get_visible_rect().size
	var text := "[center]"
	if info["passed"]:
		var title := "RONDA %d SUPERADA" % info["round"]
		if info["boss_round"]:
			title = "¡GALA SUPERADA!\nJEFE DERROTADO"
		text += "[color=#5CF07A][font_size=42]%s[/font_size][/color]\n\n" % title
		text += "Puntos: %d / cuota %d      Dinero: $%d      Caprichos: %d\nContrato: %s\n\n" % [
			info["score"], info["quota"], info["coins"], info["orders"], info["contract"]]
		var row := PackedStringArray()
		for item_name in info["tally"]:
			row.append("%s x%d" % [item_name, info["tally"][item_name]])
			if row.size() == 3:
				text += "     ".join(row) + "\n"
				row = PackedStringArray()
		if row.size() > 0:
			text += "     ".join(row) + "\n"
		if info["boss_round"]:
			text += "\n[color=#FFE61A]PREMIO: una reliquia GRATIS en la boutique[/color]\n"
		if info["new_record"]:
			text += "\n[color=#FFE61A]NUEVO RECORD DE LA SESION[/color]"
		hint_label.text = "ENTER: ir a la boutique     |     ESC: terminar partida"
	else:
		text += "[color=#FF4D59][font_size=42]FIN DE LA PARTIDA[/font_size][/color]\n\n"
		if info["score"] < info["quota"]:
			text += "No llegaste a la cuota en la ronda %d\nPuntos: %d / cuota %d   (te faltaron %d)\n" % [
				info["round"], info["score"], info["quota"], info["quota"] - info["score"]]
		if info["boss_round"] and not info["boss_defeated"]:
			text += "No derrotaste al Paparazzi Supremo\n(completa caprichos para dañarlo)\n"
		text += "\n"
		text += "Rondas superadas: %d\n" % (int(info["round"]) - 1)
		text += "Mejor ronda de esta partida: %d puntos (ronda %d)\n" % [info["run_best_score"], info["run_best_round"]]
		text += "Record de la sesion: %d puntos (ronda %d)\n" % [info["session_best"], info["session_best_round"]]
		if info["new_record"]:
			text += "\n[color=#FFE61A]NUEVO RECORD DE LA SESION[/color]"
		hint_label.text = "ENTER: jugar de nuevo     |     ESC: volver al menu"
	text += "[/center]"
	dim.size = size
	dim.visible = true
	# fin de partida (perdiste): fondo completo en vez de ver la partida oscurecida
	var end_tex := Assets.background("gameover")
	if not info["passed"] and end_tex != null:
		end_bg.texture = end_tex
		end_bg.visible = true
		dim.visible = false
	result_panel.visible = true
	message_label.text = text
	message_label.visible = true
	hint_label.visible = true
