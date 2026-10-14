extends RefCounted
# Lista finita de objetos del juego.
# name: identificador (el pedido compara por nombre)  | weight: que tan comun es (mayor = mas comun)
# points: valor al entregarlo
# shapes disponibles: "circle", "square", "triangle", "diamond"

const ITEMS = [
	{"name": "Pilas",         "shape": "circle",   "color": Color(0.35, 0.85, 0.35), "points": 1, "weight": 10},
	{"name": "Cuerda",        "shape": "triangle", "color": Color(0.65, 0.45, 0.25), "points": 1, "weight": 10},
	{"name": "Lata de comida","shape": "square",   "color": Color(0.85, 0.55, 0.20), "points": 2, "weight": 8},
	{"name": "Mapa",          "shape": "diamond",  "color": Color(0.85, 0.80, 0.55), "points": 2, "weight": 7},
	{"name": "Reloj",         "shape": "circle",   "color": Color(0.75, 0.40, 0.90), "points": 2, "weight": 6},
	{"name": "Agua",          "shape": "circle",   "color": Color(0.30, 0.65, 1.00), "points": 3, "weight": 6},
	{"name": "Linterna",      "shape": "triangle", "color": Color(1.00, 0.90, 0.25), "points": 3, "weight": 5},
	{"name": "Radio",         "shape": "diamond",  "color": Color(0.70, 0.70, 0.75), "points": 4, "weight": 3},
	{"name": "Herramientas",  "shape": "square",   "color": Color(0.45, 0.45, 0.50), "points": 4, "weight": 3},
	{"name": "Botiquin",      "shape": "square",   "color": Color(0.90, 0.15, 0.15), "points": 5, "weight": 2},
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

# Dibuja una de las formas sobre cualquier nodo (llamar dentro de su _draw)
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
		_:
			canvas.draw_circle(at, r, color)
