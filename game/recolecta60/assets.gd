extends RefCounted
# REGISTRO CENTRAL DE ASSETS.
# Regla: si existe res://assets/<clave>.png, el juego lo usa solo. Si no existe, usa el dibujo provisional (_draw).
# O sea: para poner un asset basta con copiar el PNG con el nombre exacto a la carpeta res://assets/ . No hay que tocar codigo.
#
# CONVENCION DE ARTE (para el equipo de diseño):
#   - PNG con fondo transparente, vista desde ARRIBA (top-down).
#   - Los personajes (player, paparazzi, boss) se dibujan MIRANDO A LA DERECHA (->). El codigo los gira.
#   - El tamaño en pantalla lo decide el codigo (ver SIZES): el PNG puede ser de cualquier resolucion (recomendado 2x-4x), se escala solo.
#   - Centrado en el lienzo (el centro del PNG = el centro del objeto).

const DIR := "res://assets/"

# Tamaño en pantalla (px del lado mayor) de cada asset. Se puede ajustar aqui sin tocar el resto.
# Los que dependen de un radio variable (vortex, puddle, spikes, boss) se calculan en su script.
const SIZES := {
	"player": 64.0,
	"paparazzi": 52.0,
	"orb": 40.0,
	"coin": 28.0,
	"bill": 34.0,
	"bar": 36.0,
	"time_bonus": 40.0,
}

static var _cache := {}

# Devuelve la textura de la clave, o null si todavia no hay asset (entonces se usa el dibujo provisional)
static func tex(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t: Texture2D = null
	var path := DIR + key + ".png"
	if ResourceLoader.exists(path):
		t = load(path)
	_cache[key] = t
	return t

static func has(key: String) -> bool:
	return tex(key) != null

# Dibuja el asset sobre "canvas" (llamar DENTRO de su _draw). Devuelve true si habia asset, false si hay que dibujar el provisional.
#   size:  lado mayor en px (conserva proporcion)
#   rot:   giro en radianes (0 = mirando a la derecha)
#   scl:   escala extra (p. ej. la moneda que gira usa Vector2(x, 1))
static func draw(canvas: CanvasItem, key: String, size: float, at: Vector2 = Vector2.ZERO,
		rot: float = 0.0, scl: Vector2 = Vector2.ONE, mod: Color = Color(1, 1, 1, 1)) -> bool:
	var t := tex(key)
	if t == null:
		return false
	var ts := t.get_size()
	var k := size / maxf(ts.x, ts.y)
	var sz := ts * k
	canvas.draw_set_transform(at, rot, scl)
	canvas.draw_texture_rect(t, Rect2(-sz / 2.0, sz), false, mod)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

# Fondo a pantalla completa
static func draw_fill(canvas: CanvasItem, key: String, rect: Rect2) -> bool:
	var t := tex(key)
	if t == null:
		return false
	canvas.draw_texture_rect(t, rect, false)
	return true
