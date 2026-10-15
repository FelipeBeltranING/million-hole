extends RefCounted
# Estilo visual compartido (HUD, panel de caprichos...). Paleta de la heredera: naranja, amarillo, piel, contorno negro grueso.
# Fuente: Lilita One (res://fonts/, licencia OFL). Si falta el archivo se usa la fuente por defecto.

const ORANGE := Color("F04800")
const ORANGE_SOFT := Color("FF8A1F")   # barra superior del HUD (mas naranja, menos rojo que ORANGE)
const YELLOW := Color("FFE61A")
const SKIN := Color("F8B080")
const INK := Color("120C0A")          # casi negro (contornos)
const PANEL := Color(0.10, 0.06, 0.05, 0.86)
const GREEN := Color("5CF07A")
const CYAN := Color("4DE6F2")
const RED := Color("FF4D59")
const GRAY := Color("9C8F8A")

const FONT_PATH := "res://fonts/LilitaOne-Regular.ttf"

static var _font: Font = null

static func font() -> Font:
	if _font == null:
		if ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH)
		else:
			_font = ThemeDB.fallback_font
	return _font

# Panel con borde grueso y sombra dura (estilo caricatura)
static func panel_style(fill: Color = PANEL, border: Color = YELLOW, radius: int = 14,
		bw: int = 4, shadow: bool = true, margin: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.8)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(4, 5)
	return sb

# Label con la fuente del juego y contorno negro (se lee sobre cualquier fondo)
static func label(text: String, size: int, color: Color = Color.WHITE, outline: int = 6) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
