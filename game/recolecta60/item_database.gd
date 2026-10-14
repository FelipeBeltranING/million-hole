extends RefCounted
const Assets = preload("res://assets.gd")
# COSAS de lujo que la heredera lleva y tira al agujero.
# name: identificador (el pedido compara por nombre) | points: valor al tirarlo
# weight: que tan comun es (mayor = mas comun) | shape: ver draw_shape() abajo
# Rareza: comun (weight 7-10), media (5), rara (3), legendaria (1). Legendaria = points >= 8 (brilla en el mapa)

const ITEMS = [
	{"id": "collar_perlas", "name": "Collar de perlas",      "shape": "circle",   "color": Color(0.96, 0.86, 0.92), "points": 1,  "weight": 10},
	{"id": "tarjeta_platino", "name": "Tarjeta platino",       "shape": "card",     "color": Color(0.72, 0.78, 0.85), "points": 1,  "weight": 10},
	{"id": "osito_oro", "name": "Osito bañado en oro",   "shape": "bear",     "color": Color(1.00, 0.80, 0.25), "points": 2,  "weight": 8},
	{"id": "busto_marmol", "name": "Busto de mármol",       "shape": "square",   "color": Color(0.92, 0.92, 0.95), "points": 2,  "weight": 7},
	{"id": "guantelete", "name": "Guantelete de repuesto","shape": "triangle", "color": Color(0.95, 0.90, 0.20), "points": 2,  "weight": 7},
	{"id": "poni_cristal", "name": "Poni de cristal",       "shape": "diamond",  "color": Color(0.55, 0.90, 1.00), "points": 3,  "weight": 5},
	{"id": "saco_dinero", "name": "Saco con $",            "shape": "sack",     "color": Color(0.30, 0.70, 0.35), "points": 3,  "weight": 5},
	{"id": "mochila_cohete", "name": "Mochila cohete",        "shape": "rocket",   "color": Color(1.00, 0.45, 0.20), "points": 4,  "weight": 3},
	{"id": "dron", "name": "Dron carísimo",         "shape": "hex",      "color": Color(0.30, 0.40, 0.90), "points": 4,  "weight": 3},
	{"id": "corona_rubies", "name": "Corona con rubíes",     "shape": "crown",    "color": Color(0.95, 0.15, 0.30), "points": 5,  "weight": 3},
	{"id": "cofre", "name": "Cofre sin abrir",       "shape": "square",   "color": Color(0.55, 0.33, 0.15), "points": 8,  "weight": 1},
	{"id": "estatua_oro", "name": "Estatua de oro",        "shape": "star",     "color": Color(1.00, 0.90, 0.30), "points": 10, "weight": 1},
]

# Peso efectivo de una cosa: raras (4-7 pts) x rare_mult, legendarias (>= 8 pts) x legend_mult
static func _weight(it: Dictionary, mults: Vector2) -> float:
	var w := float(it["weight"])
	var pts := int(it["points"])
	if pts >= 8:
		w *= mults.y
	elif pts >= 4:
		w *= mults.x
	return w

# Elige un objeto al azar respetando la rareza (weight). mults = Game.rarity_mults()
static func pick_weighted(mults: Vector2 = Vector2.ONE) -> Dictionary:
	var total := 0.0
	for it in ITEMS:
		total += _weight(it, mults)
	var r := randf() * total
	for it in ITEMS:
		r -= _weight(it, mults)
		if r <= 0.0:
			return it
	return ITEMS[0]

# Dibuja una cosa de lujo: usa el asset res://assets/item_<id>.png si existe; si no, la forma provisional.
# r = radio visual (el asset se escala a 2r x 2.4). tilt = giro (radianes) solo para el asset. alpha = transparencia.
static func draw_item(canvas: CanvasItem, it: Dictionary, r: float, at: Vector2 = Vector2.ZERO, tilt: float = 0.0, alpha: float = 1.0) -> void:
	if Assets.draw(canvas, "item_" + String(it["id"]), r * 2.4, at, tilt, Vector2.ONE, Color(1, 1, 1, alpha)):
		return
	var col: Color = it["color"]
	col.a = alpha
	draw_shape(canvas, it["shape"], col, r, at)

# Dibuja una forma sobre cualquier nodo (llamar dentro de su _draw)
static func draw_shape(canvas: CanvasItem, shape: String, color: Color, r: float, at: Vector2 = Vector2.ZERO) -> void:
	match shape:
		"square":
			canvas.draw_rect(Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), color)
		"triangle":
			canvas.draw_colored_polygon(PackedVector2Array([
				at + Vector2(0, -r), at + Vector2(r, r), at + Vector2(-r, r)]), color)
		"diamond":
			canvas.draw_colored_polygon(PackedVector2Array([
				at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0)]), color)
		"card":
			canvas.draw_rect(Rect2(at + Vector2(-r * 1.3, -r * 0.8), Vector2(r * 2.6, r * 1.6)), color)
			canvas.draw_rect(Rect2(at + Vector2(-r * 1.3, -r * 0.35), Vector2(r * 2.6, r * 0.3)), color.darkened(0.45))
		"bear":
			canvas.draw_circle(at + Vector2(-r * 0.75, -r * 0.8), r * 0.42, color)
			canvas.draw_circle(at + Vector2(r * 0.75, -r * 0.8), r * 0.42, color)
			canvas.draw_circle(at, r * 0.95, color)
		"sack":
			canvas.draw_circle(at + Vector2(0, r * 0.2), r * 0.9, color)
			canvas.draw_rect(Rect2(at + Vector2(-r * 0.35, -r * 0.95), Vector2(r * 0.7, r * 0.5)), color)
		"rocket":
			canvas.draw_colored_polygon(PackedVector2Array([
				at + Vector2(0, -r), at + Vector2(r * 0.6, r * 0.3), at + Vector2(r * 0.6, r),
				at + Vector2(-r * 0.6, r), at + Vector2(-r * 0.6, r * 0.3)]), color)
		"hex":
			var hp := PackedVector2Array()
			for i in 6:
				var a := i * TAU / 6.0
				hp.append(at + Vector2(cos(a), sin(a)) * r)
			canvas.draw_colored_polygon(hp, color)
		"crown":
			canvas.draw_colored_polygon(PackedVector2Array([
				at + Vector2(-r, r * 0.7), at + Vector2(-r, -r * 0.6), at + Vector2(-r * 0.5, 0.0),
				at + Vector2(0, -r), at + Vector2(r * 0.5, 0.0), at + Vector2(r, -r * 0.6),
				at + Vector2(r, r * 0.7)]), color)
		"star":
			var sp := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				var rad := r if i % 2 == 0 else r * 0.45
				sp.append(at + Vector2(cos(a), sin(a)) * rad)
			canvas.draw_colored_polygon(sp, color)
		_:
			canvas.draw_circle(at, r, color)
