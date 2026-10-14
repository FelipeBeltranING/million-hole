extends Node
# AUTOLOAD "Game": estado de la partida actual (solo en memoria, sin guardado en disco).
# Al cerrar el juego todo se pierde. "Terminar partida" o "Jugar" llaman a reset_run().

# Mejoras de la tienda. cost = base_cost * 1.5 ^ nivel_actual
const UPGRADES = {
	"boots":    {"name": "Botas",             "desc": "+10% de velocidad",              "max": 5, "base_cost": 25},
	"backpack": {"name": "Mochila",           "desc": "Cargas 1 objeto mas",            "max": 2, "base_cost": 40},
	"magnet":   {"name": "Iman de monedas",   "desc": "Las monedas cercanas vuelan a ti","max": 3, "base_cost": 30},
	"durable":  {"name": "Monedas duraderas", "desc": "+2 s de vida a las monedas",     "max": 3, "base_cost": 25},
	"combo":    {"name": "Ventana de combo",  "desc": "+2 s para mantener el combo",    "max": 3, "base_cost": 25},
	"pocket":   {"name": "Reloj de bolsillo", "desc": "+5 s al empezar cada ronda",     "max": 4, "base_cost": 35},
}

const MAGNET_RADII := [0.0, 90.0, 150.0, 220.0]

var coins := 0               # dinero (cartera) para la tienda
var levels := {}             # id de mejora -> nivel comprado
var round_number := 1
var last_round_score := 0
var best_round_score := 0    # record de la sesion (se pierde al cerrar el juego)

func reset_run() -> void:
	coins = 0
	levels = {}
	round_number = 1
	last_round_score = 0

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
