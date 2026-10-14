extends Node
# AUTOLOAD "Game": estado de la partida actual (solo en memoria, sin guardado en disco).
# Al cerrar el juego todo se pierde. "Terminar partida" o "Jugar" llaman a reset_run().

# Mejoras de la tienda. cost = base_cost * 1.5 ^ nivel_actual
const UPGRADES = {
	"boots":    {"name": "Zapatillas de diseñador",             "desc": "+10% de velocidad",              "max": 5, "base_cost": 25},
	"backpack": {"name": "Bolso de marca",           "desc": "Cargas 1 objeto mas",            "max": 2, "base_cost": 40},
	"magnet":   {"name": "Imán de billetes",   "desc": "El dinero cercano vuela hacia ti","max": 3, "base_cost": 30},
	"durable":  {"name": "Dinero duradero", "desc": "+2 s de vida al dinero",     "max": 3, "base_cost": 25},
	"combo":    {"name": "Racha de caprichos",  "desc": "+2 s para mantener el combo",    "max": 3, "base_cost": 25},
	"pocket":   {"name": "Reloj de pulsera", "desc": "+5 s al empezar cada ronda",     "max": 4, "base_cost": 35},
	"bolsazo":  {"name": "Bolsazo de diseñador", "desc": "Q: aturde a los paparazzi cercanos", "max": 3, "base_cost": 60},
}

const TITLE := "MILLONES AL AGUJERO"
const SUBTITLE := "Tira tus caprichos de lujo y convierte todo en dinero"

const MAGNET_RADII := [0.0, 90.0, 150.0, 220.0]

# --- Cuota de puntos por ronda: cuota = QUOTA_PER_ROUND * ronda (100, 200, 300...) ---
# Si al acabar el tiempo no llegaste a la cuota, termina la partida. AJUSTA ESTE NUMERO para nivelar.
const QUOTA_PER_ROUND := 100

# --- Peligros ---
const HAZARD_START_ROUND := 3      # charcos y pinchos desde aqui
const PAPARAZZI_START_ROUND := 4   # paparazzi desde aqui
const PAPARAZZI_START_COUNT := 2   # cuantos salen en esa ronda (+1 por ronda)
const PAPARAZZI_MAX := 6

# --- Bolsazo (mejora nivel 1-3): indice = nivel ---
const BOLSAZO_RADII := [0.0, 110.0, 150.0, 190.0]
const BOLSAZO_COOLDOWNS := [0.0, 8.0, 6.0, 4.0]
const BOLSAZO_STUNS := [0.0, 2.5, 3.0, 3.5]

# --- Consumables (se compran en la boutique, se gastan al usarlos, duran entre rondas) ---
const CONSUMABLES = {
	"shield": {"name": "Escudo de diamantes", "desc": "Bloquea el proximo golpe (automatico)", "price": 25, "max": 3},
	"turbo":  {"name": "Turbo de lujo",       "desc": "Shift: +70% de velocidad durante 3 s", "price": 15, "max": 3},
}

var coins := 0               # dinero (cartera) para la tienda
var levels := {}             # id de mejora -> nivel comprado
var items_stock := {}        # id de consumible -> cantidad que tienes
var round_number := 1
var last_round_score := 0
var best_round_score := 0    # record de la sesion (se pierde al cerrar el juego)
var best_round_no := 0       # en que ronda se logro el record de la sesion
var run_best_score := 0      # mejor ronda de ESTA partida
var run_best_round := 0

func reset_run() -> void:
	coins = 0
	levels = {}
	items_stock = {}
	round_number = 1
	last_round_score = 0
	run_best_score = 0
	run_best_round = 0

func level(id: String) -> int:
	return int(levels.get(id, 0))

func cost(id: String) -> int:
	var info: Dictionary = UPGRADES[id]
	return roundi(float(info["base_cost"]) * pow(1.5, level(id)))

func is_maxed(id: String) -> bool:
	return level(id) >= int(UPGRADES[id]["max"])

func can_buy(id: String) -> bool:
	return not is_maxed(id) and coins >= cost(id)

func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	coins -= cost(id)
	levels[id] = level(id) + 1
	return true

# --- Efectos de las mejoras (los consultan player.gd y main.gd) ---
func speed_mult() -> float:
	return 1.0 + 0.10 * level("boots")

func max_carry() -> int:
	return 2 + level("backpack")

func magnet_radius() -> float:
	return MAGNET_RADII[clampi(level("magnet"), 0, MAGNET_RADII.size() - 1)]

func coin_life_bonus() -> float:
	return 2.0 * level("durable")

func combo_window_bonus() -> float:
	return 2.0 * level("combo")

func start_time_bonus() -> float:
	return 5.0 * level("pocket")

# --- Cuota y peligros ---
func quota_for(r: int) -> int:
	return QUOTA_PER_ROUND * r

# Anota el resultado de la ronda actual. Devuelve true si es nuevo record de la sesion.
func record_round(score: int) -> bool:
	last_round_score = score
	if score > run_best_score:
		run_best_score = score
		run_best_round = round_number
	var is_record := score > best_round_score
	if is_record:
		best_round_score = score
		best_round_no = round_number
	return is_record

# Cuantos peligros de cada tipo salen en la ronda r
func hazard_plan(r: int) -> Dictionary:
	var plan := {"puddle": 0, "spikes": 0, "paparazzi": 0}
	if r >= HAZARD_START_ROUND:
		var k := r - HAZARD_START_ROUND
		plan["puddle"] = mini(2 + k, 5)
		plan["spikes"] = mini(2 + floori(k / 2.0), 5)
	if r >= PAPARAZZI_START_ROUND:
		plan["paparazzi"] = mini(PAPARAZZI_START_COUNT + (r - PAPARAZZI_START_ROUND), PAPARAZZI_MAX)
	return plan

func paparazzi_speed(r: int) -> float:
	return minf(90.0 + 10.0 * float(r - PAPARAZZI_START_ROUND), 170.0)

# --- Bolsazo ---
func bolsazo_radius() -> float:
	return BOLSAZO_RADII[clampi(level("bolsazo"), 0, 3)]

func bolsazo_cooldown() -> float:
	return BOLSAZO_COOLDOWNS[clampi(level("bolsazo"), 0, 3)]

func bolsazo_stun() -> float:
	return BOLSAZO_STUNS[clampi(level("bolsazo"), 0, 3)]

# --- Consumables ---
func stock_of(id: String) -> int:
	return int(items_stock.get(id, 0))

func can_buy_item(id: String) -> bool:
	var info: Dictionary = CONSUMABLES[id]
	return stock_of(id) < int(info["max"]) and coins >= int(info["price"])

func buy_item(id: String) -> bool:
	if not can_buy_item(id):
		return false
	coins -= int(CONSUMABLES[id]["price"])
	items_stock[id] = stock_of(id) + 1
	return true

# Gasta uno si tienes. Devuelve true si lo gasto.
func use_item(id: String) -> bool:
	if stock_of(id) <= 0:
		return false
	items_stock[id] = stock_of(id) - 1
	return true
