extends Control
# Boutique entre rondas: 5 ofertas al azar (mejoras, reliquias, consumibles). No alcanza para todo: hay que elegir.
# Se pueden renovar las ofertas pagando (cada renovacion cuesta mas). Los precios suben con la ronda.

const MAIN_SCENE := "res://main.tscn"
const CONTRACT_SCENE := "res://contract.tscn"
const MENU_SCENE := "res://menu.tscn"

const KIND_TAGS := {"upgrade": "MEJORA", "relic": "RELIQUIA", "consumable": "CONSUMIBLE"}
const KIND_COLORS := {
	"upgrade": Color(1, 1, 1),
	"relic": Color(1.0, 0.82, 0.15),
	"consumable": Color(0.6, 0.9, 1.0),
}

var coins_label: Label
var offers_box: VBoxContainer
var reroll_button: Button
var relics_label: Label
var stock_label: Label

func _ready() -> void:
	Game.new_shop()
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Cabecera (ancho completo, centrada)
	var head := VBoxContainer.new()
	head.position = Vector2(0, 12)
	head.custom_minimum_size = Vector2(1280, 0)
	head.add_theme_constant_override("separation", 4)
	add_child(head)
	head.add_child(_label("BOUTIQUE", 44, Color(1.0, 0.82, 0.15)))
	var next_r := Game.round_number + 1
	head.add_child(_label("Ronda %d superada  -  %d puntos   |   Proxima cuota: %d" % [
		Game.round_number, Game.last_round_score, Game.quota_estimate(next_r)], 20, Color(0.8, 0.8, 0.85)))
	if Game.is_boss_round(next_r):
		head.add_child(_label("¡LA PROXIMA RONDA ES UNA GALA CON JEFE!  (derrota al Paparazzi Supremo)", 20, Color(1.0, 0.4, 0.45)))
	else:
		head.add_child(_label("Los precios suben %d%% por ronda   |   Esta boutique solo ofrece 5 cosas: elige bien" % int(Game.PRICE_ROUND_GROWTH * 100.0), 16, Color(0.7, 0.7, 0.75)))
	coins_label = _label("", 28, Color(1.0, 0.82, 0.15))
	head.add_child(coins_label)

	# Columna izquierda: ofertas
	var left := VBoxContainer.new()
	left.position = Vector2(40, 160)
	left.custom_minimum_size = Vector2(720, 0)
	left.add_theme_constant_override("separation", 8)
	add_child(left)
	left.add_child(_label("OFERTAS DEL DIA", 22, Color(0.3, 0.9, 0.95)))
	offers_box = VBoxContainer.new()
	offers_box.add_theme_constant_override("separation", 8)
	left.add_child(offers_box)

	# Columna derecha: botones + lo que tienes
	var right := VBoxContainer.new()
	right.position = Vector2(800, 160)
	right.custom_minimum_size = Vector2(440, 0)
	right.add_theme_constant_override("separation", 8)
	add_child(right)

	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(0, 46)
	reroll_button.focus_mode = Control.FOCUS_NONE
	reroll_button.add_theme_font_size_override("font_size", 19)
	reroll_button.pressed.connect(_on_reroll)
	right.add_child(reroll_button)

	var next := Button.new()
	next.text = "Siguiente ronda  (Enter)"
	next.custom_minimum_size = Vector2(0, 52)
	next.focus_mode = Control.FOCUS_NONE
	next.add_theme_font_size_override("font_size", 22)
	next.pressed.connect(_next_round)
	right.add_child(next)

	var quit := Button.new()
	quit.text = "Terminar partida y volver al menu  (Esc)"
	quit.custom_minimum_size = Vector2(0, 38)
	quit.focus_mode = Control.FOCUS_NONE
	quit.add_theme_font_size_override("font_size", 15)
	quit.pressed.connect(_quit_run)
	right.add_child(quit)

	right.add_child(_label(" ", 8, Color(1, 1, 1)))
	right.add_child(_label("TUS RELIQUIAS", 20, Color(1.0, 0.82, 0.15)))
	relics_label = Label.new()
	relics_label.custom_minimum_size = Vector2(440, 0)
	relics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relics_label.add_theme_font_size_override("font_size", 14)
	right.add_child(relics_label)
	stock_label = Label.new()
	stock_label.custom_minimum_size = Vector2(440, 0)
	stock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stock_label.add_theme_font_size_override("font_size", 16)
	stock_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	right.add_child(stock_label)

	_refresh()

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _refresh() -> void:
	coins_label.text = "Dinero: $%d" % Game.coins

	# ofertas (se reconstruyen cada vez)
	for child in offers_box.get_children():
		child.queue_free()
	for i in Game.shop_offers.size():
		var o: Dictionary = Game.shop_offers[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(520, 0)
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", KIND_COLORS[o["kind"]])
		var tag: String = KIND_TAGS[o["kind"]]
		if o["kind"] == "upgrade":
			tag += " %d/%d" % [Game.level(o["id"]), int(Game.UPGRADES[o["id"]]["max"])]
		lbl.text = "[%s]  %s\n%s" % [tag, Game.offer_name(o), Game.offer_desc(o)]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(170, 52)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 18)
		if o["sold"]:
			btn.text = "VENDIDO"
			btn.disabled = true
			lbl.modulate.a = 0.4
		elif not Game.offer_available(o):
			btn.text = "LLENO"
			btn.disabled = true
			lbl.modulate.a = 0.4
		else:
			btn.text = "GRATIS" if o.get("free", false) else "Comprar  %d" % Game.offer_price(o)
			btn.disabled = not Game.can_buy_offer(i)
		btn.pressed.connect(_on_buy.bind(i))
		row.add_child(lbl)
		row.add_child(btn)
		offers_box.add_child(row)

	reroll_button.text = "Renovar ofertas  (%d)" % Game.reroll_cost()
	reroll_button.disabled = Game.coins < Game.reroll_cost()

	# lo que tienes
	if Game.relics.is_empty():
		relics_label.text = "Ninguna todavia"
	else:
		var lines := PackedStringArray()
		for id in Game.relics:
			lines.append("- %s: %s" % [Game.RELICS[id]["name"], Game.RELICS[id]["desc"]])
		relics_label.text = "\n".join(lines)
	var st := PackedStringArray()
	for id in Game.CONSUMABLES.keys():
		st.append("%s x%d" % [Game.CONSUMABLES[id]["name"], Game.stock_of(id)])
	stock_label.text = "Consumibles: " + "  |  ".join(st)

func _on_buy(i: int) -> void:
	Game.buy_offer(i)
	_refresh()

func _on_reroll() -> void:
	Game.reroll()
	_refresh()

func _next_round() -> void:
	Game.round_number += 1
	if Game.is_boss_round(Game.round_number):
		Game.set_contract("calm")   # la gala no tiene contrato
		get_tree().change_scene_to_file(MAIN_SCENE)
	else:
		get_tree().change_scene_to_file(CONTRACT_SCENE)

func _quit_run() -> void:
	Game.reset_run()
	get_tree().change_scene_to_file(MENU_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_next_round()
		elif event.keycode == KEY_ESCAPE:
			_quit_run()
