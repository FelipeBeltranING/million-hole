extends RefCounted
# COSAS de lujo que la heredera lleva y tira al agujero.
# name: identificador (el pedido compara por nombre) | points: valor al tirarlo
# weight: que tan comun es (mayor = mas comun) | shape: ver draw_shape() abajo
# Rareza: comun (weight 7-10), media (5), rara (3), legendaria (1). Legendaria = points >= 8 (brilla en el mapa)

const ITEMS = [
	{"name": "Collar de perlas",      "shape": "circle",   "color": Color(0.96, 0.86, 0.92), "points": 1,  "weight": 10},
	{"name": "Tarjeta platino",       "shape": "card",     "color": Color(0.72, 0.78, 0.85), "points": 1,  "weight": 10},
	{"name": "Osito bañado en oro",   "shape": "bear",     "color": Color(1.00, 0.80, 0.25), "points": 2,  "weight": 8},
	{"name": "Busto de mármol",       "shape": "square",   "color": Color(0.92, 0.92, 0.95), "points": 2,  "weight": 7},
	{"name": "Guantelete de repuesto","shape": "triangle", "color": Color(0.95, 0.90, 0.20), "points": 2,  "weight": 7},
	{"name": "Poni de cristal",       "shape": "diamond",  "color": Color(0.55, 0.90, 1.00), "points": 3,  "weight": 5},
	{"name": "Saco con $",            "shape": "sack",     "color": Color(0.30, 0.70, 0.35), "points": 3,  "weight": 5},
	{"name": "Mochila cohete",        "shape": "rocket",   "color": Color(1.00, 0.45, 0.20), "points": 4,  "weight": 3},
	{"name": "Dron carísimo",         "shape": "hex",      "color": Color(0.30, 0.40, 0.90), "points": 4,  "weight": 3},
	{"name": "Corona con rubíes",     "shape": "crown",    "color": Color(0.95, 0.15, 0.30), "points": 5,  "weight": 3},
	{"name": "Cofre sin abrir",       "shape": "square",   "color": Color(0.55, 0.33, 0.15), "points": 8,  "weight": 1},
	{"name": "Estatua de oro",        "shape": "star",     "color": Color(1.00, 0.90, 0.30), "points": 10, "weight": 1},
]

# Elige un objeto al azar respetando la rareza (weight)
static func pick_weighted() -> Dictionary:
	var total := 0
	for it in ITEMS:
		total += int(it["weight"])
	var r := randi_range(1, total)
	for it in ITEMS:
		r -= int(it["weight"])
		if r <= 0:
			return it
	return ITEMS[0]

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
