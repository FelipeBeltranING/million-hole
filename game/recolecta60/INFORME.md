# Millones al agujero — Informe de estado (tras FASE 5.2: más objetos en la gala + código listo para assets)

> Pega este archivo al inicio de un chat nuevo y di: "continuemos con la siguiente fase".

## Concepto
Juego top-down 2D en **Godot 4.2+** (GDScript). Una **heredera mimada** (protagonista original, sin nombre; rosa con tiara)
lleva **cosas de lujo** y las **tira en un agujero** que las convierte en **dinero** (billetes, monedas de oro, lingotes).
Rondas de **30 s**, pedidos ("Caprichos de hoy"), relojes que suman tiempo, **cuota de puntos por ronda**, **peligros** desde la ronda 2,
**boutique rotativa** con mejoras/reliquias/consumibles, **contratos de riesgo** antes de cada ronda y un **jefe cada 5 rondas** (la Gala).
Estilo roguelike: no puedes comprarlo todo, hay que elegir.
Todo dibujado por código (`_draw`), sin assets. **Sin persistencia por diseño:** al cerrar el juego se pierde todo.
(Inspiración original: Princesa Morbucks; se dejó una protagonista original por derechos de autor. Renombrar es trivial.)

## Cómo correrlo
Descomprimir → Godot → Import → `project.godot` → F5. 1280x720.
Controles: WASD/flechas mover · E/Espacio recoger o tirar (dentro del agujero) · **Q** bolsazo (mejora) · **Shift** turbo (consumible) · **F** flash cegador (consumible) ·
**1/2/3** elegir contrato · Enter/Esc en menús y fin de ronda.
**Nota:** el código se escribió sin poder ejecutarlo en Godot desde el chat; el usuario lo prueba y reporta errores. **Esta fase es grande y NO se ha probado: esperar errores y pegarlos.**

## Flujo
Menú → Ronda 1 → fin de ronda:
- **Superada** (cuota, y en la Gala además derrotar al jefe) → pantalla "RONDA N SUPERADA" → Enter → **Boutique** → **Contrato** (elige 1 de 3; NO hay en la Gala) → siguiente ronda ...
- **No superada** → "FIN DE LA PARTIDA" (rondas superadas, mejor ronda de la partida, récord de la sesión) → Enter = jugar de nuevo (reset), Esc = menú.
Esc en resultados o boutique = terminar partida (reset) y volver al menú. **Única forma de perder: cuota (o jefe en la Gala).** Los peligros no matan.
La ronda 1 no tiene contrato (calm).

## Cuota
`Game.quota_for(ronda) = 100 x ronda` (100, 200, 300...). `QUOTA_PER_ROUND` en `game.gd`, **por calibrar**.
Modificadores: Cheque en blanco x1.25 · contrato (`quota_mult`) · Gala x0.8 (`BOSS_QUOTA_MULT`). `Game.current_quota(r)` = cuota real; `quota_estimate(r)` = sin contrato (la boutique la muestra).
La ronda dura siempre lo mismo; al llegar a la cuota sale "¡CUOTA CUMPLIDA!" y se sigue jugando (más puntos = más dinero). HUD: `Puntos: 38 / 100`, verde al alcanzarla.

## Archivos (todos en la raíz `res://`)
| Archivo | Responsabilidad |
|---|---|
| `project.godot` | Config; escena principal `menu.tscn`; **autoload `Game`** |
| `game.gd` | Autoload `Game`: dinero, niveles, **stock de consumibles, reliquias, contrato actual, ofertas de la boutique**, cuota, plan de peligros, jefe, todos los efectos de mejoras/reliquias/contratos |
| `menu.tscn/.gd` | Menú principal |
| `shop.tscn/.gd` | Boutique rotativa: 5 ofertas, renovar, lo que tienes |
| `contract.tscn/.gd` | **Nuevo.** Elegir contrato de riesgo (3 tarjetas, teclas 1/2/3) |
| `main.tscn/.gd` | Ronda: mapa, spawns, caprichos, combo, dinero, relojes, cuota, peligros, **jefe**, fin de ronda |
| `player.gd` | Movimiento, recoger/tirar, dinero, imán, golpes, bolsazo (Q), turbo (Shift), flash (F), escudo |
| `hazard.gd` | Peligros: `puddle`, `spikes`, `paparazzi`, **`boss`**, **`orb`** (grupo `hazards`) |
| `item.gd`, `item_database.gd` | Cosa del mapa / 12 cosas + `pick_weighted(mults)` (rareza ajustable) + `draw_shape()` |
| `pit.gd` | El agujero (`radius`, `contains()`); main lo agranda con `Game.pit_scale()` |
| `coin.gd`, `time_bonus.gd` | Dinero (bill/gold/bar) y reloj +2 s |
| `order_panel.gd`, `hud.gd` | Panel de caprichos; HUD (puntos/cuota, combo, herramientas, barra del jefe, reliquias, contrato), `toast()`, `show_round_result(info)` |

## Convenciones técnicas
Sin `class_name` (usar `preload`). Nodos por código. Grupos `items`, `coins`, `time_bonuses`, `hazards`. Recogida por distancia (sin Area2D).
Estado entre escenas solo en `Game`. Señales del jugador: `carry_changed`, `items_deposited`, `coin_collected`, `time_bonus_collected`, `hit_taken(dropped)`, `shield_blocked`.
Formas en `draw_shape`: circle, square, triangle, diamond, card, bear, sack, rocket, hex, crown, star.
`hazard.gd` crea los destellos del jefe con `get_script().new()`.

## Cosas (item_database.gd): nombre — puntos — rareza
Collar de perlas 1 común · Tarjeta platino 1 común · Osito bañado en oro 2 · Busto de mármol 2 · Guantelete de repuesto 2 ·
Poni de cristal 3 media · Saco con $ 3 media · Mochila cohete 4 rara · Dron carísimo 4 rara · Corona con rubíes 5 rara ·
**Cofre sin abrir 8 legendaria · Estatua de oro 10 legendaria** (points >= 8 = halo dorado).
Suerte/Tiara: raras (4-7 pts) x `rarity_mults().x`, legendarias (>= 8 pts) x `.y`.

## Dinero
Al tirar cosas salen muchas piezas (una por punto x combo): **moneda** (1, ~80%), **billete** (2, 16%), **lingote** (3, 4%).
Constantes en `main.gd`. Valor medio ~1.24. El dinero NO da puntos. Al recogerlo se multiplica por `Game.money_mult()` (contrato x reliquias), acumulando decimales.
**Economía nueva:** ya no se puede comprar todo (boutique de 5 ofertas, precios +12% por ronda, renovar cuesta 20 x 1.5^n). Hay que calibrar si el dinero ahora sobra o falta.

## Peligros (desde ronda 2)
`Game.hazard_plan(ronda)` (con contrato aplicado):
- **Charco de champán** (ronda 2+): frena 50% dentro. 1 en la ronda 2, +1 por ronda, tope 5.
- **Pinchos** (ronda 2+): apagado 1.8 s → aviso naranja 0.7 s → activo rojo 1.2 s. 1, luego +1 cada 2 rondas, tope 5.
- **Paparazzi** (ronda 3+): **1 en la ronda 3, +1 por ronda**, tope 6 (`PAPARAZZI_MAX`); velocidad 90 +10/ronda (tope 170). Al tocarte: flash, se retira 1.8 s.
Contratos pueden multiplicar charcos/pinchos (x2, x3, tope 10) y sumar paparazzi (tope 8). En la Gala los paparazzi se reducen a la mitad.
**Golpe:** suelta lo que llevas (cae cerca), aturdido 0.5 s (x2 con Zapatos de cristal), 1.5 s invulnerable (parpadea). El Escudo lo bloquea.
Avisos al aparecer por primera vez (rondas 2 y 3).

## Herramientas
- **Bolsazo** (mejora, 3 niveles, Q): aturde y empuja paparazzi cercanos. Radio 110/150/190, enfriamiento 8/6/4 s, aturdimiento 2.5/3/3.5 s. No afecta al jefe.
- **Escudo de diamantes** (consumible 25, máx 3): bloquea el próximo golpe automáticamente.
- **Turbo de lujo** (15, máx 3, Shift): +70% velocidad 3 s.
- **Flash cegador** (30, máx 3, F): aturde a TODOS los paparazzi 5 s (jefe inmune).
Los consumibles duran entre rondas (se pierden al acabar la partida).

## Boutique rotativa
5 ofertas por visita (`OFFER_COUNT`), mezcla al azar de **mejoras** (peso 2), **reliquias** (2) y **consumibles** (3). Desde la ronda 2 siempre hay al menos 1 reliquia a la venta.
Cada oferta se compra una sola vez por visita. **Renovar ofertas** cuesta 20, 30, 45... (`REROLL_BASE` x 1.5^n, se reinicia al entrar).
Precio = base (x1.5^nivel en mejoras) x (1 + 0.12 x (ronda-1)) (`PRICE_ROUND_GROWTH`).
**Mejoras (11):** Zapatillas (+10% vel, 5 niv, 25) · Bolso de marca (+1 carga, 2, 40) · Imán (3, 30) · Dinero duradero (3, 25) · Racha de caprichos (+2 s combo, 3, 25) ·
Reloj de pulsera (+5 s, 4, 35) · Bolsazo (3, 60) · **Manos largas** (+15 alcance, 3, 30) · **Pozo grande** (+15% radio, 3, 45) · **Suerte de heredera** (+50% raras/legendarias por nivel, 3, 40) · **Bonus de capricho** (+25% recompensa, 3, 50).
**Consumibles (3):** Escudo, Turbo, Flash.

## Reliquias (8, únicas, ventaja Y desventaja; se quedan toda la partida)
| Reliquia | Precio | Efecto |
|---|---|---|
| Collar de la codicia | 140 | Dinero x2 · paparazzi +30% vel |
| Anillo del combo | 120 | Combo máx x5 · ventana −3 s (mín 2 s) |
| Gafas oscuras | 110 | Paparazzi −35% vel · −5 s al empezar |
| Cheque en blanco | 130 | +50% puntos · cuota +25% |
| Tiara de la reina | 125 | Legendarias x3 · cargas −1 (mín 1) |
| Perfume carísimo | 120 | Paparazzi dormidos 12 s · dinero −30% |
| Zapatos de cristal | 115 | +25% velocidad · aturdimiento x2 |
| Reloj de oro macizo | 100 | +10 s al empezar · no salen relojes de bonus |
Aparecen en el HUD abajo a la izquierda. Todo el código de efectos está en `game.gd` (funciones tipo `money_mult()`, `score_mult()`, `speed_mult()`...).

## Contratos de riesgo (antes de cada ronda, excepto 1 y la Gala)
Siempre está **Ronda tranquila** (sin cambios) + 2 al azar de: **Doble o nada** (peligros x2, +1 paparazzi, cuota +30%, dinero x2) · **Prisa de compras** (−10 s, puntos +30%, dinero x1.5) ·
**Paparazzi VIP** (+2 paparazzi, dinero x1.75) · **Cuota de lujo** (cuota +50%, dinero x2.5) · **Piso de champán** (charcos y pinchos x3, dinero x1.5).
Cada tarjeta muestra la cuota resultante. El contrato activo se ve en el HUD y en los resultados. Definidos en `Game.CONTRACTS`.

## Jefe: la Gala (rondas 5, 10, 15...)
**Paparazzi Supremo** (`hazard.gd` kind `boss`, radio 46, corona, barra de vida): te persigue (velocidad 70 +8 por jefe) y **dispara destellos** (`orb`) hacia ti cada 3.4 s (−0.3 por jefe, mín 1.8 s).
Tocarlo o recibir un destello = golpe normal (suelta lo que llevas, aturde). **Se le hace daño completando caprichos:** en la Gala el capricho es de **2 objetos** (`BOSS_ORDER_SIZE`) y cada uno completado le quita 1 de vida, lo aturde 2.5 s y lo despide lejos del pozo.
Vida 3 (+1 por jefe, tope 6). Bolsazo/Flash no le afectan. La Gala dura +15 s, cuota x0.8, sin contrato, con la mitad de paparazzi.
**Superar la Gala exige cuota Y derrotar al jefe.** Premio: 40 piezas de dinero al derrotarlo + **una reliquia GRATIS** en la boutique siguiente (`free_relic_pending`).


## FASE 5.2 (cambios nuevos, SIN probar en Godot)
**1. Más objetos en la gala del jefe** (`main.gd`): ronda normal sigue igual (18 objetos, reaparece uno cada 1.5 s). En la gala: `BOSS_ITEMS_ON_MAP = 36` y `BOSS_ITEM_RESPAWN = 0.45 s`
(antes eran 18 y 1.5 s). El tiempo de la gala NO se tocó (+25 s). Si aún faltan objetos: subir esas dos constantes; si sobran, bajarlas.
**2. Código listo para assets** — nuevo **`assets.gd`** (registro central). Regla: si existe `res://assets/<clave>.png` el juego lo usa solo; si no, dibuja el provisional.
Poner un asset = copiar el PNG con el nombre exacto a `res://assets/`. No hay que tocar código. Lista completa y reglas de arte en `assets/LEEME.txt`.
- **Un solo dibujo que gira:** `player`, `paparazzi` y `boss` se dibujan mirando a la DERECHA y el código los gira hacia donde se mueven / hacia el jugador (`body_angle` en `player.gd`, `face` en `hazard.gd`; el jefe también gira hacia donde embiste). Lo que lleva la heredera sale siempre arriba de la cabeza, sin girar.
- Los objetos del mapa reciben un pequeño giro fijo al azar (`tilt` en `item.gd`) para que no se vean todos iguales. El vórtice gira solo. La moneda gira achatándose (como el provisional). El destello del jefe gira.
- Cada cosa de lujo tiene ahora `"id"` en `item_database.gd`; su asset es `item_<id>.png`. Se dibujan con `ItemDB.draw_item()` en el mapa, en las manos de la heredera y en el panel de caprichos.
- Pinchos: 2 imágenes (`spikes_off`, `spikes_on`); el aviso parpadea entre las dos con tinte naranja (por código). El jefe furioso usa `boss.png` con tinte rojo (opcional `boss_rage.png`).
- Tamaños en pantalla en `assets.gd` → `SIZES` (los de radio variable —vórtice, charco, pinchos, jefe— se calculan solos).
- Siguen por código (no necesitan asset): halos y aro dorado de los pedidos, efectos de bolsazo/turbo/flash, aturdimiento, destello de foto, barra de vida del jefe.
- Pendiente (fase posterior, opcional): iconos para boutique/contratos/reliquias (hoy son texto), menú y fondo de menú.
**Archivos tocados:** `assets.gd` (nuevo), `assets/LEEME.txt` (nuevo), `main.gd`, `item.gd`, `item_database.gd`, `order_panel.gd`, `player.gd`, `coin.gd`, `time_bonus.gd`, `pit.gd`, `hazard.gd`.
**Al probar, revisar:** que no salgan errores al abrir (hay un script nuevo y `static var`, requiere Godot 4.2+); que la gala se sienta con objetos de sobra; y, con un PNG de prueba (por ejemplo `player.png`), que gire bien.

## FASE 5.1 (SIN probar en Godot)
**El "agujero/pozo" ahora es el VÓRTICE** (`pit.gd`, dinámico). Ronda 1 fijo. Desde la ronda 2 (`Game.pit_plan(r)`):
- `jump`: cada 16 s (baja 0.7 por ronda, mín 9 s) avisa 2 s con una marca fantasma dorada y se muda; mientras cierra/abre (0.35 s c/u) no se puede tirar nada.
- `drift`: se desliza despacio (50+4/ronda, tope 110) por el mapa. `both`: las dos cosas (ronda 6+ al azar y SIEMPRE en la Gala, salto cada 11 s).
- Elige sitio lejos del anterior (320 px) y de charcos/pinchos; empuja fuera las cosas que quedaron debajo. Señales `relocating` / `relocated`.
**Jefe reforzado** (`hazard.gd` + `game.gd`): radio 70 (+4/jefe, tope 90; antes 46) · vida 5 (+1/jefe, tope 9; antes 3) · velocidad 115 (+12, tope 210; antes 70) ·
disparo cada 2.4 s (−0.25, mín 1.2) · destellos 310 px/s y más grandes, **apuntan por delante de ti** · **embestida** (aviso rojo 0.7 s y carga x3.4 de velocidad) ·
**furia** con la mitad de vida: +30% velocidad, dispara 3 destellos en abanico y más seguido · aturdido por daño 1.6 s (antes 2.5) · la Gala dura +25 s (antes +15).
Bolsazo/Flash ahora hacen que el jefe **trastabille** (≤1 s, pierde la embestida) pero no le quitan vida.
Textos: "agujero/pozo" → "vórtice" (título del juego y archivo del proyecto sin cambiar).
**Por calibrar:** ¿vida 5 + caprichos de 2 objetos en 55 s es justo? ¿el salto del vórtice cada 16 s es molesto o divertido? ¿la embestida se esquiva bien?

## Assets
El código ya está preparado (ver FASE 5.2): se entregan PNG con nombre exacto en `res://assets/` y se usan solos. Lista y reglas: `assets/LEEME.txt`.
Los dibujos provisionales (`_draw`) siguen como respaldo. Las tarjetas de contrato y filas de la boutique son texto/botones sin iconos.

## Decisiones tomadas
Economía generosa pero recortada. Sin guardado. Puntos y dinero separados. Tema de lujo con protagonista original. Perder = solo por cuota (o jefe).
Cuota = 100 x ronda. Peligros desde la ronda 2, paparazzi desde la 3 (+1 por ronda). Pantalla de resultados sencilla; al perder se juega de nuevo con Enter.
La boutique es rotativa y NO se puede comprar todo (decisión: "punto 1 obligatorio"). Reliquias con desventaja. Contratos tipo roguelike. Jefe cada 5 rondas que se derrota con caprichos.
Cada vez que se desarrolla una fase se entrega un informe nuevo como este.

## Por calibrar jugando (pendiente de feedback)
- Cuota 100xN con el nuevo ritmo de dinero y peligros (rondas 2-4).
- ¿El dinero alcanza para 1-2 cosas por visita y para renovar? ¿Los precios (+12%/ronda) y reliquias (100-140) están bien?
- Dificultad del jefe de la ronda 5 (¿vida 3 y caprichos de 2 objetos en ~45 s es justo? ¿destellos muy rápidos?).
- ¿Contratos muy buenos o muy malos? (Cuota de lujo x2.5 dinero puede ser demasiado tentador).
- Reliquias rotas o inútiles (Cheque en blanco, Perfume, Tiara).

## Hoja de ruta
- **Siguiente:** probar 5.2 en Godot y calibrar; meter los primeros assets cuando lleguen.
- **Fase 5b (propuesta):** más tipos de jefe (uno por tier), eventos aleatorios en ronda, peligros nuevos (muros móviles, cosas que se mueven), más reliquias/contratos, consumible Soborno / Segunda oportunidad.
- **Fase 5c:** sonidos, partículas, temblor de pantalla, tutorial/explicación de contratos y reliquias, balance final.
