extends Node2D
# El VORTICE del centro: donde se tiran las cosas (y salen billetes, oro y lingotes).
# Ya no es fijo. mode:
#   "static"  no se mueve (ronda 1)
#   "jump"    cada "interval" s avisa (marca fantasma 2 s) y se muda a otro sitio
#   "drift"   se desliza despacio por el mapa
#   "both"    se desliza Y ademas salta
# Mientras se muda (cerrandose / abriendose) NO se puede tirar nada dentro.

const Assets = preload("res://assets.gd")

signal relocating(secs: float)   # empieza el aviso de mudanza
signal relocated                 # ya abrio en el sitio nuevo

const WARN_TIME := 2.0
const CLOSE_TIME := 0.35
const MIN_JUMP := 320.0

@export var radius := 70.0
var map_rect := Rect2()
var mode := "static"
var interval := 14.0
var move_speed := 55.0

var state := "open"        # open / warn / closing / opening
var anim := 1.0            # 0..1, escala visual y de recogida
var jump_timer := 0.0
var state_t := 0.0
var next_pos := Vector2.ZERO
var waypoint := Vector2.ZERO
var t := 0.0

func _ready() -> void:
	jump_timer = interval
	waypoint = position
	if mode == "drift" or mode == "both":
		_pick_waypoint()

func contains(point: Vector2) -> bool:
	return anim > 0.6 and position.distance_to(point) <= radius * anim

func _process(delta: float) -> void:
	t += delta
	if mode == "drift" or mode == "both":
		_drift(delta)
	if mode == "jump" or mode == "both":
		_update_jump(delta)
	queue_redraw()

# ---------------------------------------------------------------- Deslizarse
func _drift(delta: float) -> void:
	if state == "closing" or state == "opening":
		return
	if position.distance_to(waypoint) < 8.0:
		_pick_waypoint()
	position = position.move_toward(waypoint, move_speed * delta)

func _pick_waypoint() -> void:
	waypoint = _safe_spot(120.0, false)

# ---------------------------------------------------------------- Saltar
func _update_jump(delta: float) -> void:
	match state:
		"open":
			jump_timer -= delta
			if jump_timer <= 0.0:
				next_pos = _safe_spot(MIN_JUMP, true)
				state = "warn"
				state_t = WARN_TIME
				relocating.emit(WARN_TIME)
		"warn":
			state_t -= delta
			if state_t <= 0.0:
				state = "closing"
				state_t = CLOSE_TIME
		"closing":
			state_t -= delta
			anim = clampf(state_t / CLOSE_TIME, 0.0, 1.0)
			if state_t <= 0.0:
				position = next_pos
				waypoint = next_pos
				_push_items_away()
				state = "opening"
				state_t = CLOSE_TIME
		"opening":
			state_t -= delta
			anim = clampf(1.0 - state_t / CLOSE_TIME, 0.0, 1.0)
			if state_t <= 0.0:
				anim = 1.0
				state = "open"
				jump_timer = interval
				relocated.emit()

# Saca las cosas que quedaron justo debajo del vortice nuevo
func _push_items_away() -> void:
	for node in get_tree().get_nodes_in_group("items"):
		var d: float = position.distance_to(node.position)
		if d < radius + 20.0:
			var dir: Vector2 = (node.position - position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.RIGHT
			node.position = (position + dir * (radius + 45.0)).clamp(
				map_rect.position + Vector2(20, 20), map_rect.end - Vector2(20, 20))

# Busca un sitio libre: dentro del mapa, lejos de charcos y pinchos (y del sitio actual si hace falta)
func _safe_spot(min_from_here: float, far: bool) -> Vector2:
	var m := radius + 30.0
	var best := position
	var best_score := -INF
	for attempt in 40:
		var p := Vector2(
			randf_range(map_rect.position.x + m, map_rect.end.x - m),
			randf_range(map_rect.position.y + m, map_rect.end.y - m))
		var score := 0.0
		var d_here := p.distance_to(position)
		if d_here < min_from_here:
			score -= (min_from_here - d_here)
		for h in get_tree().get_nodes_in_group("hazards"):
			if h.kind == "puddle" or h.kind == "spikes":
				var gap: float = p.distance_to(h.position) - (radius + h.radius + 25.0)
				if gap < 0.0:
					score += gap * 2.0
		score += randf() * 20.0
		if score > best_score:
			best_score = score
			best = p
		if score > 15.0 and (not far or d_here >= min_from_here):
			return p
	return best

# ---------------------------------------------------------------- Dibujo
func _draw() -> void:
	# marca fantasma del sitio nuevo
	if state == "warn":
		var g := next_pos - position
		var pulse := 0.5 + 0.5 * sin(t * 10.0)
		draw_circle(g, radius, Color(1.0, 0.82, 0.15, 0.10 + 0.12 * pulse))
		draw_arc(g, radius, 0.0, TAU, 48, Color(1.0, 0.82, 0.15, 0.5 + 0.4 * pulse), 4.0)
		draw_arc(g, radius * (1.0 - state_t / WARN_TIME), 0.0, TAU, 48, Color(1, 1, 1, 0.8), 3.0)
		draw_dashed_line(Vector2.ZERO, g, Color(1.0, 0.82, 0.15, 0.35), 3.0, 14.0)
	var r := radius * anim
	if r < 1.0:
		return
	var blink := state == "warn" and int(t * 8.0) % 2 == 0
	# con asset: res://assets/vortex.png (vista desde arriba, se escala al radio y gira solo)
	if Assets.draw(self, "vortex", r * 2.0, Vector2.ZERO, t * 1.2):
		if blink:
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.45, 0.2), 6.0)   # aviso de mudanza
		return
	draw_circle(Vector2.ZERO, r, Color(0.04, 0.04, 0.06))
	draw_circle(Vector2.ZERO, r * 0.7, Color(0, 0, 0))
	# espirales que giran (da sensacion de vortice)
	for i in 3:
		var a0 := t * 2.2 + TAU * float(i) / 3.0
		draw_arc(Vector2.ZERO, r * 0.55, a0, a0 + 1.4, 16, Color(0.6, 0.45, 0.1, 0.8), 3.0)
		draw_arc(Vector2.ZERO, r * 0.85, -a0, -a0 + 0.9, 16, Color(1.0, 0.82, 0.15, 0.35), 2.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48,
		Color(1.0, 0.45, 0.2) if blink else Color(1.0, 0.82, 0.15), 6.0)
	draw_string(ThemeDB.fallback_font, Vector2(-30, 14), "$",
		HORIZONTAL_ALIGNMENT_CENTER, 60, int(40.0 * anim), Color(1.0, 0.82, 0.15, 0.9))
