extends Node
# AUTOLOAD "Game": estado de la partida actual (solo en memoria, sin guardado en disco).
# Al cerrar el juego todo se pierde. "Terminar partida" o "Jugar" llaman a reset_run().

const BASE_TIME := 30.0   # <<< TIEMPO DE UNA RONDA NORMAL (segundos), igual en todas las rondas. Contratos, reliquias y mejoras lo cambian encima.

# ------------------------------------------------------------------ Mejoras permanentes (con niveles)
# precio = base_cost * 1.5^nivel_actual * multiplicador de ronda (ver price_mult)
const UPGRADES = {
	"boots":      {"name": "Zapatillas de diseñador", "desc": "+10% de velocidad",                         "max": 5, "base_cost": 25},
	"backpack":   {"name": "Bolso de marca",          "desc": "Cargas 1 objeto mas",                       "max": 2, "base_cost": 40},
	"magnet":     {"name": "Imán de billetes",        "desc": "El dinero cercano vuela hacia ti",          "max": 3, "base_cost": 30},
	"durable":    {"name": "Dinero duradero",         "desc": "+2 s de vida al dinero",                    "max": 3, "base_cost": 25},
	"combo":      {"name": "Racha de caprichos",      "desc": "+2 s para mantener el combo",               "max": 3, "base_cost": 25},
	"pocket":     {"name": "Reloj de pulsera",        "desc": "+5 s al empezar cada ronda",                "max": 4, "base_cost": 35},
	"bolsazo":    {"name": "Bolsazo de diseñador",    "desc": "Q: aturde a los paparazzi cercanos",        "max": 3, "base_cost": 60},
	"reach":      {"name": "Manos largas",            "desc": "+15 de alcance al recoger cosas",           "max": 3, "base_cost": 30},
	"pitwide":    {"name": "Vórtice grande",             "desc": "El vórtice es 15% mas ancho",               "max": 3, "base_cost": 45},
	"luck":       {"name": "Suerte de heredera",      "desc": "Salen mas cosas raras y legendarias",       "max": 3, "base_cost": 40},
	"orderbonus": {"name": "Bonus de capricho",       "desc": "+25% de recompensa al completar caprichos", "max": 3, "base_cost": 50},
}

# ------------------------------------------------------------------ Consumibles (se gastan; duran entre rondas)
const CONSUMABLES = {
	"shield": {"name": "Escudo de diamantes", "desc": "Bloquea el proximo golpe (automatico)",      "price": 25, "max": 3},
	"turbo":  {"name": "Turbo de lujo",       "desc": "Shift: +70% de velocidad durante 3 s",       "price": 15, "max": 3},
	"flash":  {"name": "Flash cegador",       "desc": "F: aturde a TODOS los paparazzi durante 5 s", "price": 30, "max": 3},
}

# ------------------------------------------------------------------ Reliquias (unicas, con ventaja Y desventaja)
const RELICS = {
	"greed":        {"name": "Collar de la codicia",  "desc": "Dinero x2, pero los paparazzi van 30% mas rapido",        "price": 140},
	"combo_ring":   {"name": "Anillo del combo",      "desc": "El combo llega a x5, pero dura 3 s menos",                "price": 120},
	"shades":       {"name": "Gafas oscuras",         "desc": "Paparazzi 35% mas lentos, pero empiezas con 5 s menos",   "price": 110},
	"blank_check":  {"name": "Cheque en blanco",      "desc": "+50% de puntos, pero la cuota sube 25%",                  "price": 130},
	"tiara":        {"name": "Tiara de la reina",     "desc": "Legendarias x3 mas comunes, pero cargas 1 objeto menos",  "price": 125},
	"perfume":      {"name": "Perfume carisimo",      "desc": "Paparazzi dormidos 12 s, pero ganas 30% menos de dinero", "price": 120},
	"glass_shoes":  {"name": "Zapatos de cristal",    "desc": "+25% de velocidad, pero los golpes te aturden el doble",  "price": 115},
	"golden_watch": {"name": "Reloj de oro macizo",   "desc": "+10 s al empezar, pero ya no salen relojes de bonus",     "price": 100},
}

# ------------------------------------------------------------------ Contratos de riesgo (se elige uno antes de cada ronda)
const CONTRACTS = {
	"calm":     {"name": "Ronda tranquila",  "desc": "Sin cambios. La opción segura.", "risk": 0},
	"double":   {"name": "Doble o nada",     "desc": "Peligros x2, +1 paparazzi, cuota +30%.\nDinero x2.",
				 "hazard_mult": 2.0, "extra_pap": 1, "quota_mult": 1.3, "money_mult": 2.0, "risk": 2},
	"rush":     {"name": "Prisa de compras", "desc": "10 s menos de tiempo.\nPuntos +30%, dinero x1.5.",
				 "time_add": -10.0, "score_mult": 1.3, "money_mult": 1.5, "risk": 1},
	"vip":      {"name": "Paparazzi VIP",    "desc": "+2 paparazzi.\nDinero x1.75.",
				 "extra_pap": 2, "money_mult": 1.75, "risk": 1},
	"high":     {"name": "Cuota de lujo",    "desc": "Cuota +50%.\nDinero x2.5.",
				 "quota_mult": 1.5, "money_mult": 2.5, "risk": 2},
	"slippery": {"name": "Piso de champán",  "desc": "Charcos y pinchos x3.\nDinero x1.5.",
				 "hazard_mult": 3.0, "money_mult": 1.5, "risk": 1},
}

const TITLE := "MILLONES AL AGUJERO"
const SUBTITLE := "Tira tus caprichos de lujo y convierte todo en dinero"

const MAGNET_RADII := [0.0, 90.0, 150.0, 220.0]

# --- Cuota de puntos por ronda: cuota = QUOTA_PER_ROUND * ronda (100, 200, 300...) ---
const QUOTA_PER_ROUND := 100

# --- Peligros ---
const HAZARD_START_ROUND := 2      # charcos y pinchos desde aqui
const PAPARAZZI_START_ROUND := 3   # paparazzi desde aqui
const PAPARAZZI_START_COUNT := 1   # cuantos salen en esa ronda (+1 por ronda)
const PAPARAZZI_MAX := 6

# --- Jefe (ronda de gala) ---
const BOSS_EVERY := 5              # rondas 5, 10, 15...
const BOSS_EXTRA_TIME := 10.0   # <<< segundos EXTRA de la gala (jefe). Gala = BASE_TIME + esto = 30 + 10 = 40 s
const BOSS_QUOTA_MULT := 0.8       # la cuota de la gala es mas baja (hay que derrotar al jefe)
const BOSS_ORDER_SIZE := 2         # cada capricho completado en la gala hace 1 de dano al jefe

# --- Bolsazo (mejora nivel 1-3): indice = nivel ---
const BOLSAZO_RADII := [0.0, 110.0, 150.0, 190.0]
const BOLSAZO_COOLDOWNS := [0.0, 8.0, 6.0, 4.0]
const BOLSAZO_STUNS := [0.0, 2.5, 3.0, 3.5]

# --- Boutique ---
const OFFER_COUNT := 5
const REROLL_BASE := 20
const PRICE_ROUND_GROWTH := 0.12   # los precios suben 12% por ronda

var coins := 0               # dinero (cartera) para la tienda
var levels := {}             # id de mejora -> nivel comprado
var items_stock := {}        # id de consumible -> cantidad que tienes
var relics: Array = []       # ids de reliquias que tienes
var contract_id := "calm"    # contrato de la ronda actual
var shop_offers: Array = []  # [{"kind","id","sold","free"}]
var reroll_count := 0
var free_relic_pending := false   # premio por derrotar al jefe: una reliquia gratis en la proxima boutique
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
	relics = []
	contract_id = "calm"
	shop_offers = []
	reroll_count = 0
	free_relic_pending = false
	round_number = 1
	last_round_score = 0
	run_best_score = 0
	run_best_round = 0

func level(id: String) -> int:
	return int(levels.get(id, 0))

func is_maxed(id: String) -> bool:
	return level(id) >= int(UPGRADES[id]["max"])

func has_relic(id: String) -> bool:
	return relics.has(id)

func cv(key: String, default_value: float) -> float:
	return contract_val(contract_id, key, default_value)

# Valor de un contrato cualquiera (no solo el activo). La pantalla de contratos lo usa para las 3 tarjetas.
func contract_val(id: String, key: String, default_value: float) -> float:
	return float(CONTRACTS[id].get(key, default_value))

# ------------------------------------------------------------------ Efectos (los consultan player.gd y main.gd)
func speed_mult() -> float:
	return 1.0 + 0.10 * level("boots") + (0.25 if has_relic("glass_shoes") else 0.0)

func max_carry() -> int:
	return maxi(1, 2 + level("backpack") - (1 if has_relic("tiara") else 0))

func pickup_bonus() -> float:
	return 15.0 * level("reach")

func pit_scale() -> float:
	return 1.0 + 0.15 * level("pitwide")

func magnet_radius() -> float:
	return MAGNET_RADII[clampi(level("magnet"), 0, MAGNET_RADII.size() - 1)]

func coin_life_bonus() -> float:
	return 2.0 * level("durable")

func combo_window_bonus() -> float:
	return 2.0 * level("combo") - (3.0 if has_relic("combo_ring") else 0.0)

func combo_max() -> float:
	return 5.0 if has_relic("combo_ring") else 3.0

func start_time_bonus() -> float:
	var t := 5.0 * level("pocket")
	if has_relic("golden_watch"):
		t += 10.0
	if has_relic("shades"):
		t -= 5.0
	return t

func order_mult() -> float:
	return 1.0 + 0.25 * level("orderbonus")

# Multiplicadores de rareza para item_database.pick_weighted(): x = raras, y = legendarias
func rarity_mults() -> Vector2:
	var luck := 1.0 + 0.5 * level("luck")
	var legend := luck * (3.0 if has_relic("tiara") else 1.0)
	return Vector2(luck, legend)

func money_mult() -> float:
	var m := cv("money_mult", 1.0)
	if has_relic("greed"):
		m *= 2.0
	if has_relic("perfume"):
		m *= 0.7
	return m

func score_mult() -> float:
	return cv("score_mult", 1.0) * (1.5 if has_relic("blank_check") else 1.0)

func stun_mult() -> float:
	return 2.0 if has_relic("glass_shoes") else 1.0

func no_time_bonuses() -> bool:
	return has_relic("golden_watch")

func pap_sleep() -> float:
	return 12.0 if has_relic("perfume") else 0.0

# ------------------------------------------------------------------ Rondas, cuota, peligros, jefe
func is_boss_round(r: int) -> bool:
	return r > 0 and r % BOSS_EVERY == 0

func boss_tier(r: int) -> int:
	return maxi(floori(float(r) / float(BOSS_EVERY)) - 1, 0)

func boss_hp(r: int) -> int:
	return mini(5 + boss_tier(r), 9)

func boss_speed(r: int) -> float:
	return minf(115.0 + 12.0 * float(boss_tier(r)), 210.0)

func boss_shoot_interval(r: int) -> float:
	return maxf(2.4 - 0.25 * float(boss_tier(r)), 1.2)

func boss_radius(r: int) -> float:
	return minf(70.0 + 4.0 * float(boss_tier(r)), 90.0)

func boss_orb_speed(r: int) -> float:
	return minf(310.0 + 20.0 * float(boss_tier(r)), 420.0)

# ------------------------------------------------------------------ Vortice (antes "agujero"): como se mueve en la ronda r
const PIT_MOVE_START_ROUND := 2
func pit_plan(r: int) -> Dictionary:
	if r < PIT_MOVE_START_ROUND:
		return {"mode": "static", "interval": 99.0, "speed": 0.0}
	var interval := clampf(16.0 - 0.7 * float(r - PIT_MOVE_START_ROUND), 9.0, 16.0)
	var speed := minf(50.0 + 4.0 * float(r), 110.0)
	var mode := "jump"
	if is_boss_round(r):
		interval = 11.0
		mode = "both"
	elif r >= 3:
		var options := ["jump", "drift"] if r < 6 else ["jump", "drift", "both"]
		mode = options[randi() % options.size()]
	return {"mode": mode, "interval": interval, "speed": speed}

# Tiempo de la ronda r con el contrato cid (si no se pasa, el contrato activo)
func round_time(r: int, cid: String = "") -> float:
	var id := cid if cid != "" else contract_id
	var t := BASE_TIME + start_time_bonus() + contract_val(id, "time_add", 0.0)
	if is_boss_round(r):
		t += BOSS_EXTRA_TIME
	return maxf(t, 10.0)

func quota_for(r: int) -> int:
	return QUOTA_PER_ROUND * r

# Cuota con reliquias y jefe, SIN contrato (para mostrarla en la boutique)
func quota_estimate(r: int) -> int:
	var q := float(quota_for(r))
	if has_relic("blank_check"):
		q *= 1.25
	if is_boss_round(r):
		q *= BOSS_QUOTA_MULT
	return roundi(q)

# Cuota real de la ronda (incluye el contrato elegido, o el cid que se pase)
func current_quota(r: int, cid: String = "") -> int:
	var id := cid if cid != "" else contract_id
	var q := float(quota_for(r))
	if has_relic("blank_check"):
		q *= 1.25
	if is_boss_round(r):
		q *= BOSS_QUOTA_MULT
	q *= contract_val(id, "quota_mult", 1.0)
	return roundi(q)

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

# Cuantos peligros de cada tipo salen en la ronda r (ya con el contrato aplicado)
func hazard_plan(r: int) -> Dictionary:
	var plan := {"puddle": 0, "spikes": 0, "paparazzi": 0}
	var hm := cv("hazard_mult", 1.0)
	if r >= HAZARD_START_ROUND:
		var k := r - HAZARD_START_ROUND
		plan["puddle"] = mini(ceili(float(mini(1 + k, 5)) * hm), 10)
		plan["spikes"] = mini(ceili(float(mini(1 + floori((k + 1) / 2.0), 5)) * hm), 10)
	var pap := 0
	if r >= PAPARAZZI_START_ROUND:
		pap = mini(PAPARAZZI_START_COUNT + (r - PAPARAZZI_START_ROUND), PAPARAZZI_MAX)
	pap += int(cv("extra_pap", 0.0))
	if is_boss_round(r):
		pap = floori(pap / 2.0)   # en la gala hay menos paparazzi: ya esta el jefe
	plan["paparazzi"] = mini(pap, 8)
	return plan

func paparazzi_speed(r: int) -> float:
	var base := minf(90.0 + 10.0 * float(r - PAPARAZZI_START_ROUND), 170.0)
	if has_relic("greed"):
		base *= 1.3
	if has_relic("shades"):
		base *= 0.65
	return base

# ------------------------------------------------------------------ Bolsazo
func bolsazo_radius() -> float:
	return BOLSAZO_RADII[clampi(level("bolsazo"), 0, 3)]

func bolsazo_cooldown() -> float:
	return BOLSAZO_COOLDOWNS[clampi(level("bolsazo"), 0, 3)]

func bolsazo_stun() -> float:
	return BOLSAZO_STUNS[clampi(level("bolsazo"), 0, 3)]

# ------------------------------------------------------------------ Consumibles
func stock_of(id: String) -> int:
	return int(items_stock.get(id, 0))

# Gasta uno si tienes. Devuelve true si lo gasto.
func use_item(id: String) -> bool:
	if stock_of(id) <= 0:
		return false
	items_stock[id] = stock_of(id) - 1
	return true

# ------------------------------------------------------------------ Contratos
func set_contract(id: String) -> void:
	contract_id = id

# La opcion tranquila siempre esta; las otras 2 son al azar
func roll_contracts() -> Array:
	var others: Array = []
	for id in CONTRACTS.keys():
		if id != "calm":
			others.append(id)
	others.shuffle()
	return ["calm", others[0], others[1]]

# ------------------------------------------------------------------ Boutique rotativa
func price_mult() -> float:
	return 1.0 + PRICE_ROUND_GROWTH * float(round_number - 1)

func offer_name(o: Dictionary) -> String:
	match o["kind"]:
		"upgrade":
			return UPGRADES[o["id"]]["name"]
		"relic":
			return RELICS[o["id"]]["name"]
	return CONSUMABLES[o["id"]]["name"]

func offer_desc(o: Dictionary) -> String:
	match o["kind"]:
		"upgrade":
			return UPGRADES[o["id"]]["desc"]
		"relic":
			return RELICS[o["id"]]["desc"]
	return CONSUMABLES[o["id"]]["desc"]

func offer_price(o: Dictionary) -> int:
	if o.get("free", false):
		return 0
	var base := 0.0
	match o["kind"]:
		"upgrade":
			base = float(UPGRADES[o["id"]]["base_cost"]) * pow(1.5, level(o["id"]))
		"relic":
			base = float(RELICS[o["id"]]["price"])
		_:
			base = float(CONSUMABLES[o["id"]]["price"])
	return maxi(1, roundi(base * price_mult()))

# false si ya no se puede comprar (maximo, ya la tienes, stock lleno)
func offer_available(o: Dictionary) -> bool:
	match o["kind"]:
		"upgrade":
			return not is_maxed(o["id"])
		"relic":
			return not has_relic(o["id"])
	return stock_of(o["id"]) < int(CONSUMABLES[o["id"]]["max"])

func can_buy_offer(i: int) -> bool:
	var o: Dictionary = shop_offers[i]
	return not o["sold"] and offer_available(o) and coins >= offer_price(o)

func buy_offer(i: int) -> bool:
	if not can_buy_offer(i):
		return false
	var o: Dictionary = shop_offers[i]
	coins -= offer_price(o)
	match o["kind"]:
		"upgrade":
			levels[o["id"]] = level(o["id"]) + 1
		"relic":
			relics.append(o["id"])
			if o.get("free", false):
				free_relic_pending = false
		_:
			items_stock[o["id"]] = stock_of(o["id"]) + 1
	o["sold"] = true
	return true

func reroll_cost() -> int:
	return roundi(float(REROLL_BASE) * pow(1.5, reroll_count))

func reroll() -> bool:
	var cost := reroll_cost()
	if coins < cost:
		return false
	coins -= cost
	reroll_count += 1
	shop_offers = _roll_offers()
	return true

# Se llama al entrar a la boutique
func new_shop() -> void:
	reroll_count = 0
	shop_offers = _roll_offers()

func _roll_offers() -> Array:
	var offers: Array = []
	var relic_pool: Array = []
	for id in RELICS.keys():
		if not has_relic(id):
			relic_pool.append(id)
	relic_pool.shuffle()
	# premio del jefe: una reliquia gratis; si no, desde la ronda 2 hay siempre una a la venta
	if not relic_pool.is_empty() and (free_relic_pending or round_number >= 2):
		offers.append({"kind": "relic", "id": relic_pool.pop_back(), "sold": false, "free": free_relic_pending})
	var cand: Array = []   # candidatos con peso
	for id in UPGRADES.keys():
		if not is_maxed(id):
			cand.append({"kind": "upgrade", "id": id, "w": 2.0})
	for id in relic_pool:
		cand.append({"kind": "relic", "id": id, "w": 2.0})
	for id in CONSUMABLES.keys():
		if stock_of(id) < int(CONSUMABLES[id]["max"]):
			cand.append({"kind": "consumable", "id": id, "w": 3.0})
	while offers.size() < OFFER_COUNT and not cand.is_empty():
		var total := 0.0
		for entry in cand:
			total += float(entry["w"])
		var r := randf() * total
		var pick := 0
		for i in cand.size():
			r -= float(cand[i]["w"])
			if r <= 0.0:
				pick = i
				break
		var chosen: Dictionary = cand[pick]
		cand.remove_at(pick)
		offers.append({"kind": chosen["kind"], "id": chosen["id"], "sold": false, "free": false})
	return offers
