extends Node
# REGISTRO CENTRAL DE AUDIO (autoload "Sound"). Es el equivalente de assets.gd pero para sonidos.
# Regla: si existe res://audio/<clave>.ogg (o .wav / .mp3) el juego lo reproduce solo en el momento justo.
# Si no existe, NO suena nada y NO da error. O sea: para poner un audio basta con copiar el archivo
# con el nombre exacto a la carpeta res://audio/ . No hay que tocar codigo.
# La lista de nombres (45) esta en audio/LEEME.txt y en INFORME_AUDIO.md.
#
# Uso desde otros scripts:
#   Sound.play("sfx_coin")                      efecto
#   Sound.play("sfx_combo", 0.0, 1.3)           efecto con tono 30% mas agudo
#   Sound.play_near("sfx_spikes_on", pos, jugador.position, 450.0)   efecto que se oye mas bajo si esta lejos
#   Sound.music("music_game")                   musica en bucle (si ya suena esa, no la reinicia)
#   Sound.stop_music(0.4)                       apaga la musica con fundido de 0.4 s

const DIR := "res://audio/"
const EXTS := [".ogg", ".wav", ".mp3"]   # acepta cualquiera de los tres
const POOL_SIZE := 16                    # cuantos efectos pueden sonar a la vez

# Volumen general (en dB; 0 = tal cual el archivo, -6 = a la mitad aprox.)
const MUSIC_DB := -8.0   # la musica queda mas baja que los efectos
const SFX_DB := 0.0

# Ajuste de volumen por sonido (dB). Si un audio que bajaste de internet suena muy fuerte o muy bajo,
# se corrige AQUI sin tocar el archivo. Lo que no esta en la lista suena a 0.
const VOLUMES := {
	"sfx_coin": -6.0,
	"sfx_bill": -4.0,
	"sfx_bar": -3.0,
	"sfx_time_tick": -4.0,
	"sfx_puddle": -3.0,
	"sfx_spikes_warn": -4.0,
	"sfx_spikes_on": -2.0,
	"sfx_boss_shoot": -3.0,
}

# Variacion de tono al azar (0.05 = +-5%): que las monedas y pasos repetidos no suenen siempre identicos
const PITCH_RANDOM := {
	"sfx_coin": 0.08,
	"sfx_bill": 0.06,
	"sfx_bar": 0.05,
	"sfx_pickup": 0.05,
	"sfx_deposit": 0.04,
	"sfx_hit": 0.04,
	"sfx_pap_stun": 0.05,
}

# Tiempo minimo entre dos reproducciones del MISMO sonido (segundos). Evita el "ametrallado" cuando salen 40 monedas.
const DEFAULT_GAP := 0.03
const MIN_GAP := {
	"sfx_coin": 0.05,
	"sfx_bill": 0.05,
	"sfx_bar": 0.05,
	"sfx_time_tick": 0.5,
}

# Si falta el audio de la izquierda, suena el de la derecha (para no quedarse sin musica en esa pantalla)
const FALLBACKS := {
	"music_boss": "music_game",
	"music_shop": "music_menu",
}

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last_play := {}
var _music: AudioStreamPlayer
var _music_key := ""
var _fade: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.finished.connect(_on_music_finished)

# Devuelve el audio de la clave, o null si todavia no hay archivo (entonces no suena nada)
func stream(key: String) -> AudioStream:
	if _cache.has(key):
		return _cache[key]
	var s: AudioStream = null
	for ext in EXTS:
		var path: String = DIR + key + String(ext)
		if ResourceLoader.exists(path):
			s = load(path)
			break
	_cache[key] = s
	return s

func has(key: String) -> bool:
	return stream(key) != null

# ---------------------------------------------------------------- Efectos

# vol_db: volumen extra en dB (0 = normal). pitch: 1.0 = normal, 2.0 = una octava mas agudo.
func play(key: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var s := stream(key)
	if s == null:
		return
	var now := Time.get_ticks_msec()
	var gap_ms := int(float(MIN_GAP.get(key, DEFAULT_GAP)) * 1000.0)
	if now - int(_last_play.get(key, -100000)) < gap_ms:
		return
	_last_play[key] = now
	var player := _free_player()
	player.stream = s
	player.volume_db = SFX_DB + float(VOLUMES.get(key, 0.0)) + vol_db
	var rnd := float(PITCH_RANDOM.get(key, 0.0))
	player.pitch_scale = maxf(0.1, pitch * (1.0 + randf_range(-rnd, rnd)))
	player.play()

# Como play() pero el volumen baja con la distancia (from = donde suena, to = donde esta la heredera)
func play_near(key: String, from: Vector2, to: Vector2, max_dist: float = 600.0, pitch: float = 1.0) -> void:
	var d := from.distance_to(to)
	if d >= max_dist:
		return
	var k := 1.0 - d / max_dist
	play(key, linear_to_db(maxf(k * k, 0.01)), pitch)

func _free_player() -> AudioStreamPlayer:
	for q in _pool:
		if not q.playing:
			return q
	var stolen := _pool[_next]   # todos ocupados: se reutiliza el siguiente
	_next = (_next + 1) % _pool.size()
	return stolen

# ---------------------------------------------------------------- Musica

# Musica en bucle. Si ya suena esa misma, no la reinicia (la boutique y los contratos comparten pista).
func music(key: String) -> void:
	if _fade != null:
		_fade.kill()
		_fade = null
	if stream(key) == null and FALLBACKS.has(key):
		key = String(FALLBACKS[key])
	if key == _music_key and _music.playing:
		_music.volume_db = MUSIC_DB + float(VOLUMES.get(key, 0.0))
		return
	_music_key = key
	var s := stream(key)
	if s == null:
		_music.stop()
		return
	_music.stream = s
	_music.volume_db = MUSIC_DB + float(VOLUMES.get(key, 0.0))
	_music.play()

func stop_music(fade_secs: float = 0.0) -> void:
	_music_key = ""
	if _fade != null:
		_fade.kill()
		_fade = null
	if fade_secs <= 0.0 or not _music.playing:
		_music.stop()
		return
	_fade = create_tween()
	_fade.tween_property(_music, "volume_db", -40.0, fade_secs)
	_fade.tween_callback(_music.stop)

# El bucle se hace a mano: asi funciona igual con .ogg, .wav y .mp3 sin configurar nada en el importador
func _on_music_finished() -> void:
	if _music_key != "":
		_music.play()
