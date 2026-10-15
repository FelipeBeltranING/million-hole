extends Node2D
# Peligro del mapa. kind:
#   "puddle"    Charco de champan: te frena mientras estas dentro.
#   "spikes"    Pinchos: ciclo apagado -> aviso (parpadea) -> activo (rojo, golpea).
#   "paparazzi" Te persigue. Al tocarte hace flash, te aturde y se retira un momento.
#   "boss"      Paparazzi Supremo (ronda de gala): grande, te persigue y dispara destellos.
#   "orb"       Destello que dispara el jefe: va en linea recta y desaparece al golpear.
# Los golpes los aplica player.gd (consulta el grupo "hazards").

const Assets = preload("res://assets.gd")

const SPIKE_OFF_TIME := 1.8
const SPIKE_WARN_TIME := 0.7
const SPIKE_ON_TIME := 1.2
const PAPARAZZI_PAUSE := 1.8

var kind := "puddle"
var radius := 50.0
var target: Node2D = null     # paparazzi / jefe: a quien persigue
var map_rect := Rect2()
var speed := 100.0            # paparazzi / jefe
var t := 0.0
var state := "off"            # pinchos: off / warn / on
var phase_time := 0.0
var pause_timer := 0.0        # paparazzi / jefe: retirada tras golpear
var stun_timer := 0.0         # paparazzi / jefe: aturdido
var sleep_timer := 0.0        # paparazzi: dormido (reliquia Perfume)
var hp := 5                   # jefe
var max_hp := 5
var boss_size := 70.0         # jefe: radio
var shoot_interval := 2.4     # jefe
var shoot_timer := 2.0
var orb_speed := 310.0
var dash_state := ""          # jefe: "" / windup / dash (embestida)
var dash_t := 0.0
var dash_cd := 5.0
var dash_dir := Vector2.RIGHT
var vel := Vector2.ZERO       # orb
var life := 6.0               # orb
var face := 0.0               # giro del dibujo de paparazzi / jefe (asset mirando a la derecha)

func _ready() -> void:
	add_to_group("hazards")
	match kind:
		"puddle":
			radius = 58.0
		"spikes":
			radius = 32.0
			phase_time = randf() * SPIKE_OFF_TIME   # que no esten todos sincronizados
		"paparazzi":
			radius = 20.0
		"boss":
			radius = boss_size
			shoot_timer = shoot_interval
		"orb":
			radius = 14.0

func _process(delta: float) -> void:
	t += delta
	_update_face(delta)
	match kind:
		"spikes":
			_update_spikes(delta)
		"paparazzi":
			_update_paparazzi(delta)
		"boss":
			_update_boss(delta)
		"orb":
			_update_orb(delta)
	queue_redraw()

# El dibujo de paparazzi y jefe mira hacia el jugador (o hacia donde embiste)
func _update_face(delta: float) -> void:
	if (kind != "paparazzi" and kind != "boss") or target == null:
		return
	var aim: Vector2 = dash_dir if dash_state == "dash" else target.position - position
	if aim.length() > 1.0:
		face = lerp_angle(face, aim.angle() - PI / 2.0, minf(1.0, delta * 10.0))

func slows() -> bool:
	return kind == "puddle"

func is_harmful() -> bool:
	match kind:
		"spikes":
			return state == "on"
		"paparazzi":
			return pause_timer <= 0.0 and stun_timer <= 0.0 and sleep_timer <= 0.0
		"boss":
			return pause_timer <= 0.0 and stun_timer <= 0.0
		"orb":
			return true
	return false

# Lo llama el jugador cuando este peligro lo golpea
func on_hit() -> void:
	match kind:
		"paparazzi":
			pause_timer = PAPARAZZI_PAUSE
		"boss":
			pause_timer = 1.5
			dash_state = ""
			dash_cd = 3.0
		"orb":
			queue_free()

# Bolsazo / flash del jugador: aturde al paparazzi (el jefe es inmune; solo lo dañan los caprichos)
func get_stunned(secs: float, push_dir: Vector2) -> void:
	if kind == "boss":
		# el jefe NO se aturde de verdad: solo trastabilla un momento (y pierde la embestida)
		stun_timer = maxf(stun_timer, minf(secs * 0.3, 1.0))
		dash_state = ""
		position += push_dir * 40.0
		_clamp_to_map()
		return
	if kind != "paparazzi":
		return
	stun_timer = secs
	position += push_dir * 70.0
	_clamp_to_map()

# El jefe recibe daño al completar un capricho: se aturde y sale despedido lejos del pozo
func boss_damaged(push_dir: Vector2) -> void:
	stun_timer = 1.6
	dash_state = ""
	dash_cd = 3.0
	position += push_dir * 80.0
	_clamp_to_map()

# Furioso: con la mitad de vida o menos
func is_raging() -> bool:
	return kind == "boss" and hp * 2 <= max_hp

func _clamp_to_map() -> void:
	var m := Vector2(radius, radius)
	position = position.clamp(map_rect.position + m, map_rect.end - m)

func _update_spikes(delta: float) -> void:
	phase_time += delta
	if state == "off" and phase_time >= SPIKE_OFF_TIME:
		state = "warn"
		phase_time = 0.0
	elif state == "warn" and phase_time >= SPIKE_WARN_TIME:
		state = "on"
		phase_time = 0.0
	elif state == "on" and phase_time >= SPIKE_ON_TIME:
		state = "off"
		phase_time = 0.0

func _chase(delta: float) -> void:
	var dir: Vector2 = (target.position - position).normalized()
	if pause_timer > 0.0:
		pause_timer -= delta
		position -= dir * speed * 0.5 * delta   # se retira un poco
	else:
		position += dir * speed * delta
	_clamp_to_map()

func _update_paparazzi(delta: float) -> void:
	if target == null:
		return
	if sleep_timer > 0.0:
		sleep_timer -= delta
		return
	if stun_timer > 0.0:
		stun_timer -= delta
		return
	_chase(delta)

func _update_boss(delta: float) -> void:
	if target == null:
		return
	if stun_timer > 0.0:
		stun_timer -= delta
		return
	var rage := is_raging()
	var dash_speed := speed * 3.4
	if dash_state == "windup":
		dash_t -= delta
		if dash_t <= 0.0:
			dash_dir = (target.position - position).normalized()
			dash_state = "dash"
			dash_t = 0.55
		return
	if dash_state == "dash":
		position += dash_dir * dash_speed * delta
		_clamp_to_map()
		dash_t -= delta
		if dash_t <= 0.0:
			dash_state = ""
			dash_cd = randf_range(3.5, 5.5) * (0.7 if rage else 1.0)
		return
	var base_speed := speed
	speed = base_speed * (1.3 if rage else 1.0)
	_chase(delta)
	speed = base_speed
	dash_cd -= delta
	if dash_cd <= 0.0 and position.distance_to(target.position) > 160.0:
		dash_state = "windup"
		dash_t = 0.7 if not rage else 0.55
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = shoot_interval * (0.7 if rage else 1.0)
		_shoot(rage)

func _shoot(rage: bool) -> void:
	# apunta un poco por delante de donde vas a estar
	var lead: Vector2 = target.position
	if "velocity" in target:
		lead += target.velocity * 0.35
	var base_dir: Vector2 = (lead - position).normalized()
	var angles := [-0.38, 0.0, 0.38] if rage else [0.0]
	for a in angles:
		var o = get_script().new()
		o.kind = "orb"
		o.position = position
		o.map_rect = map_rect
		o.vel = base_dir.rotated(a) * orb_speed * (1.1 if rage else 1.0)
		get_parent().add_child(o)

func _update_orb(delta: float) -> void:
	position += vel * delta
	life -= delta
	if life <= 0.0 or not map_rect.grow(40.0).has_point(position):
		queue_free()

func _draw() -> void:
	match kind:
		"puddle":
			_draw_puddle()
		"spikes":
			_draw_spikes()
		"paparazzi":
			_draw_paparazzi()
		"boss":
			_draw_boss()
		"orb":
			if not Assets.draw(self, "orb", Assets.SIZES["orb"], Vector2.ZERO, t * 6.0):
				draw_circle(Vector2.ZERO, radius + 5.0, Color(1.0, 0.95, 0.5, 0.35))
				draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 0.85))

func _draw_puddle() -> void:
	# con asset: res://assets/puddle.png (se escala al radio del charco)
	if Assets.draw(self, "puddle", radius * 2.0):
		return
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.85, 0.35, 0.28))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.92, 0.55, 0.65), 2.0)
	for i in 4:
		var a := float(i) * 1.7 + t * 0.6
		var p := Vector2.from_angle(a) * radius * (0.25 + 0.15 * float(i))
		var b := 3.0 + 2.0 * sin(t * 2.0 + float(i))
		draw_circle(p, b, Color(1.0, 1.0, 0.85, 0.7))

func _draw_spikes() -> void:
	# con asset: spikes_off.png (escondidos) y spikes_on.png (sacados). El aviso parpadea entre las dos con tinte naranja.
	if Assets.has("spikes_off") and Assets.has("spikes_on"):
		var key := "spikes_off"
		var mod := Color.WHITE
		if state == "on":
			key = "spikes_on"
		elif state == "warn":
			key = "spikes_on" if int(t * 10.0) % 2 == 0 else "spikes_off"
			mod = Color(1.0, 0.65, 0.3)
		Assets.draw(self, key, radius * 2.0, Vector2.ZERO, 0.0, Vector2.ONE, mod)
		return
	draw_circle(Vector2.ZERO, radius, Color(0.12, 0.12, 0.14, 0.85))
	var tip := radius * 0.45
	var col := Color(0.55, 0.55, 0.6)
	if state == "warn":
		tip = radius * 0.7
		col = Color(1.0, 0.55, 0.15) if int(t * 10.0) % 2 == 0 else Color(0.55, 0.55, 0.6)
	elif state == "on":
		tip = radius
		col = Color(1.0, 0.2, 0.2)
	for i in 6:
		var dir := Vector2.from_angle(TAU * float(i) / 6.0)
		var perp := dir.rotated(PI / 2.0) * 5.0
		draw_colored_polygon(PackedVector2Array([
			dir * radius * 0.2 + perp, dir * radius * 0.2 - perp, dir * tip]), col)

func _draw_stun_fx() -> void:
	draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 24, Color(0.4, 0.8, 1.0), 3.0)
	for i in 3:
		var a := t * 4.0 + TAU * float(i) / 3.0
		draw_circle(Vector2(cos(a) * 14.0, -radius - 6.0 + sin(a) * 4.0), 3.5, Color(1.0, 0.9, 0.2))

func _draw_paparazzi() -> void:
	var sleeping := sleep_timer > 0.0
	var body := Color(0.62, 0.62, 0.68, 0.45 if sleeping else 1.0)
	# con asset: res://assets/paparazzi.png (mirando a la derecha; se gira hacia ti)
	if not Assets.draw(self, "paparazzi", Assets.SIZES["paparazzi"], Vector2.ZERO, face, Vector2.ONE, Color(1, 1, 1, body.a)):
		draw_circle(Vector2.ZERO, radius, body)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.15, 0.15, 0.2), 2.0)
		draw_rect(Rect2(-12.0, -6.0, 24.0, 14.0), Color(0.1, 0.1, 0.14))
		draw_circle(Vector2(0, 1), 5.0, Color(0.35, 0.65, 1.0))
		draw_rect(Rect2(-8.0, -10.0, 8.0, 4.0), Color(0.1, 0.1, 0.14))
	if sleeping:
		draw_string(ThemeDB.fallback_font, Vector2(radius * 0.6, -radius * 0.6), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.8, 0.9, 1.0))
	if stun_timer > 0.0:
		_draw_stun_fx()
	if pause_timer > PAPARAZZI_PAUSE - 0.25:
		draw_circle(Vector2.ZERO, radius + 12.0, Color(1, 1, 1, 0.6))   # flash

func _draw_boss() -> void:
	var k := radius / 46.0   # el dibujo original era para radio 46
	var rage := is_raging()
	var body := Color(0.42, 0.25, 0.55) if not rage else Color(0.62, 0.2, 0.35)
	# aviso de embestida: linea hacia ti
	if dash_state == "windup" and target != null:
		var d: Vector2 = (target.position - position).normalized()
		var blink := 0.5 + 0.5 * sin(t * 30.0)
		draw_line(Vector2.ZERO, d * 900.0, Color(1.0, 0.2, 0.2, 0.25 + 0.35 * blink), radius * 0.9)
		draw_circle(Vector2.ZERO, radius + 10.0, Color(1.0, 0.2, 0.2, 0.3 + 0.3 * blink))
	# con asset: res://assets/boss.png (mirando a la derecha, con corona incluida; se gira hacia ti).
	# Opcional: boss_rage.png para la furia; si no existe se usa boss.png con tinte rojo.
	var drawn := false
	if Assets.has("boss"):
		var rage_key := "boss_rage" if (rage and Assets.has("boss_rage")) else "boss"
		var tint := Color(1.0, 0.55, 0.55) if (rage and rage_key == "boss") else Color.WHITE
		drawn = Assets.draw(self, rage_key, radius * 2.4, Vector2.ZERO, face, Vector2.ONE, tint)
	if not drawn:
		draw_circle(Vector2.ZERO, radius, body)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.82, 0.15), 5.0)
		# lente gigante
		draw_circle(Vector2.ZERO, radius * 0.55, Color(0.08, 0.08, 0.12))
		draw_circle(Vector2.ZERO, radius * 0.35, Color(1.0, 0.3, 0.2) if rage else Color(0.3, 0.55, 1.0))
		draw_circle(Vector2(-radius * 0.1, -radius * 0.1), radius * 0.1, Color(1, 1, 1, 0.8))
		# corona
		draw_colored_polygon(PackedVector2Array([
			Vector2(-18 * k, -radius + 2), Vector2(-18 * k, -radius - 14 * k), Vector2(-9 * k, -radius - 6 * k),
			Vector2(0, -radius - 20 * k), Vector2(9 * k, -radius - 6 * k), Vector2(18 * k, -radius - 14 * k),
			Vector2(18 * k, -radius + 2)]), Color(1.0, 0.82, 0.15))
	# barrita de vida
	var seg := 18.0
	for i in max_hp:
		var c := Color(0.95, 0.2, 0.25) if i < hp else Color(0.25, 0.25, 0.3)
		draw_rect(Rect2(-float(max_hp) * seg / 2.0 + float(i) * seg + 1.0, radius + 8.0, seg - 2.0, 7.0), c)
	if stun_timer > 0.0:
		_draw_stun_fx()
	elif shoot_timer < 0.5 and dash_state == "":
		draw_circle(Vector2.ZERO, radius + 8.0, Color(1, 1, 1, 0.45))   # aviso del disparo
