# Millones al agujero — Informe de estado (tras FASE 4b: cuota x100, peligros y herramientas)

> Pega este archivo al inicio de un chat nuevo y di: "continuemos con la siguiente fase".

## Concepto
Juego top-down 2D en **Godot 4.2+** (GDScript). Una **heredera mimada** (protagonista original, sin nombre; rosa con tiara)
lleva **cosas de lujo** y las **tira en un agujero** que las convierte en **dinero** (billetes, monedas de oro, lingotes).
Rondas de **30 s**, pedidos ("Caprichos de hoy"), relojes que suman tiempo, **cuota de puntos por ronda**, boutique entre rondas
y **peligros** (charcos, pinchos, paparazzi) desde las primeras rondas.
Todo dibujado por código (`_draw`), sin assets. **Sin persistencia por diseño:** al cerrar el juego se pierde todo.
(Inspiración original: Princesa Morbucks; se dejó una protagonista original por derechos de autor. Renombrar es trivial.)

## Cómo correrlo
Descomprimir → Godot → Import → `project.godot` → F5. 1280x720.
Controles: WASD/flechas mover · E/Espacio recoger o tirar (dentro del agujero) · **Q bolsazo** (si lo compraste) · **Shift turbo** (consumible) · Enter/Esc en menús y fin de ronda.
**Nota:** el código se escribió sin poder ejecutarlo en Godot desde el chat; el usuario lo prueba y reporta errores.

## Flujo
Menú → Ronda → fin de ronda:
- **Cuota superada** → pantalla "RONDA N SUPERADA" → Enter → Boutique → Siguiente ronda ...
- **Cuota NO superada** → pantalla "FIN DE LA PARTIDA" (rondas superadas, mejor ronda de la partida, récord de la sesión) → Enter = jugar de nuevo (reset), Esc = menú.
Esc en la pantalla de resultados o en la boutique = terminar partida (reset) y volver al menú.
**Única forma de perder: no llegar a la cuota.** Los peligros no matan.

## Cuota
`Game.quota_for(ronda) = QUOTA_PER_ROUND * ronda` → 100, 200, 300, 400... (`QUOTA_PER_ROUND = 100` en `game.gd`, **por calibrar jugando**).
La ronda dura siempre lo mismo; la cuota se comprueba al acabar el tiempo. Al llegarle sale "¡CUOTA CUMPLIDA!" y se sigue jugando (más puntos = más dinero).
HUD: `Puntos: 38 / 100`, verde al alcanzarla. La boutique muestra la próxima cuota.
Si se quieren saltos tipo "100 → 1k", basta cambiar el cuerpo de `quota_for()`.

## Archivos (todos en la raíz `res://`)
| Archivo | Responsabilidad |
|---|---|
| `project.godot` | Config; escena principal `menu.tscn`; **autoload `Game`** |
| `game.gd` | Autoload `Game`: dinero, niveles de mejoras, **stock de consumibles**, ronda, récords, cuota, plan de peligros, efectos del bolsazo, `TITLE`/`SUBTITLE` |
| `menu.tscn/.gd` | Menú principal |
| `shop.tscn/.gd` | Boutique en 2 columnas: mejoras (izq.) y consumibles + botones (der.) |
| `main.tscn/.gd` | Ronda: mapa, spawns, caprichos, combo, dinero, relojes, cuota, peligros, fin de ronda |
| `player.gd` | Movimiento, recoger/tirar, auto-recoger dinero y relojes, imán, **golpes de peligros, bolsazo (Q), turbo (Shift), escudo** |
| `hazard.gd` | **Peligros**: `puddle`, `spikes`, `paparazzi` (grupo `hazards`) |
| `item.gd`, `item_database.gd` | Cosa del mapa / lista de 12 cosas + `pick_weighted()` + `draw_shape()` |
| `pit.gd` | El agujero (`radius`, `contains()`) |
| `coin.gd` | Dinero: `kind` = bill / gold / bar, `value`, `lifetime` |
| `time_bonus.gd` | Reloj +2 s |
| `order_panel.gd`, `hud.gd` | Panel de caprichos; HUD (puntos/cuota, combo, herramientas), `toast()`, pantalla de resultados `show_round_result(info)` |

## Convenciones técnicas
Sin `class_name` (usar `preload`). Nodos por código. Grupos `items`, `coins`, `time_bonuses`, `hazards`. Recogida por distancia (sin Area2D).
Estado entre escenas solo en `Game`. Señales del jugador: `carry_changed`, `items_deposited`, `coin_collected`, `time_bonus_collected`, `hit_taken(dropped)`, `shield_blocked`.
Formas disponibles en `draw_shape`: circle, square, triangle, diamond, card, bear, sack, rocket, hex, crown, star.

## Cosas (item_database.gd): nombre — puntos — rareza
Collar de perlas 1 común · Tarjeta platino 1 común · Osito bañado en oro 2 · Busto de mármol 2 · Guantelete de repuesto 2 ·
Poni de cristal 3 media · Saco con $ 3 media · Mochila cohete 4 rara · Dron carísimo 4 rara · Corona con rubíes 5 rara ·
**Cofre sin abrir 8 legendaria · Estatua de oro 10 legendaria** (points >= 8 = halo dorado).

## Dinero
Al tirar cosas salen **muchas piezas** (una por punto x combo). Cada pieza: **moneda** (valor 1, ~80%), **billete** (valor 2, 16%), **lingote** (valor 3, 4%).
Constantes en `main.gd`: `COIN_VALUE`, `BILL_VALUE`, `BAR_VALUE`, `BILL_CHANCE` (0.16), `BAR_CHANCE` (0.04), `ORDER_COMPLETE_COINS` (8).
Valor medio por pieza ~1.24 (recortado ~7% porque la ronda 2 ya daba demasiado).
**Meta de diseño:** a la ronda 3 se puede comprar casi todo lo "mayor posible" para que desde la 4 entren trampas/armas. El dinero NO da puntos.
**Ojo:** con el Bolsazo la boutique completa de mejoras cuesta ~1385 (antes ~1100) + consumibles; si se quiere "todo en 3 rondas", revisar la economía.

## Peligros (hazard.gd)
`Game.hazard_plan(ronda)`:
- **Charco de champán** (desde ronda **3**): frena al 50% mientras estás dentro (`PUDDLE_SLOW`). Cantidad: 2 en la ronda 3, +1 por ronda, tope 5.
- **Pinchos** (desde ronda **3**): ciclo apagado 1.8 s → aviso naranja parpadeante 0.7 s → activo rojo 1.2 s (golpea). Cada uno con fase aleatoria. Cantidad: 2, +1 cada 2 rondas, tope 5.
- **Paparazzi** (desde ronda **4**, **2 al inicio y +1 por ronda**, tope `PAPARAZZI_MAX` = 6): te persiguen; velocidad 90 +10/ronda (tope 170; tú ~280). Al tocarte hacen flash y se retiran 1.8 s.
Colocación: charcos/pinchos lejos del pozo y de ti; paparazzi a >350 px de ti. Toast de aviso al aparecer cada tipo por primera vez (rondas 3 y 4).
**Golpe** (`player.gd`): suelta lo que llevas (cae al suelo cerca), aturdido `STUN_TIME` 0.5 s, `INVULN_TIME` 1.5 s invulnerable (parpadea). Si tienes **Escudo**, lo bloquea (1 s de invulnerabilidad, sin soltar nada).

## Herramientas (fase 4b)
- **Bolsazo de diseñador** (mejora de boutique, 3 niveles, base 60, tecla **Q**): onda que **aturde y empuja** a los paparazzi cercanos. Radio 110/150/190, enfriamiento 8/6/4 s, aturdimiento 2.5/3/3.5 s. Los pinchos y charcos no les afecta. HUD: `Q Bolsazo: LISTO / 4.2s`.
- **Escudo de diamantes** (consumible, 25, máx. 3, automático): bloquea el próximo golpe.
- **Turbo de lujo** (consumible, 15, máx. 3, tecla **Shift**): +70% de velocidad durante 3 s.
Los consumibles duran entre rondas hasta usarse (se pierden al terminar la partida). Datos en `Game.CONSUMABLES`; stock en `Game.items_stock`.

## Assets (pendiente)
**Todos los dibujos son PROVISIONALES** (formas con `_draw`). Cuando existan los assets: reemplazar `_draw()` por `Sprite2D`/texturas en
`item.gd` + `item_database.gd` (`draw_shape`, 12 cosas), `coin.gd` (moneda/billete/lingote), `player.gd` (heredera + efectos de bolsazo/turbo),
`pit.gd` (agujero), `time_bonus.gd` (reloj), **`hazard.gd` (charco, pinchos, paparazzi)** y el fondo en `main.gd`.
Cada entidad dibuja en un solo sitio, así que el cambio es local.

## Mecánicas
Ronda 30 s (tope 60). Combo ventana 6 s (+0.5/entrega, máx x3). Caprichos: 3 cosas pedidas (bonus puntos x3 c/u;
completo: +25 pts, +4 s, +8 de dinero, nuevo pedido). Respawn cada 1.5 s (máx 18). Relojes +2 s cada 7 s (máx 2).
**Boutique** (mejoras: coste = base x 1.5^nivel; solo dura la partida): Zapatillas de diseñador (+10% vel, 5 niv, 25) ·
Bolso de marca (+1 carga, 2, 40) · Imán de billetes (radio 90/150/220, 3, 30) · Dinero duradero (+2 s vida, 3, 25) ·
Racha de caprichos (+2 s combo, 3, 25) · Reloj de pulsera (+5 s inicio, 4, 35) · **Bolsazo de diseñador (3, 60)**.
Consumibles: Escudo (25) · Turbo (15).

## Decisiones tomadas
Economía generosa pero recortada un poco (ver Dinero). Sin guardado. Puntos y dinero separados. Tema de lujo con protagonista original.
Cuota = 100 x ronda (estilo "números grandes"). Peligros desde la ronda 3; 2 perseguidores desde la 4 (+1 por ronda). Perder = solo por cuota.
Pantalla de resultados sencilla con la mejor ronda. Al perder se vuelve a jugar con Enter (reset) o al menú con Esc.
Cada vez que se desarrolla una fase se entrega un informe nuevo como este.

## Por calibrar jugando (pendiente de feedback)
Cuota 100xN (¿cuántos puntos se hacen por ronda de verdad?) · dificultad de las rondas 3-6 con peligros · cuánto cuesta/vale el Bolsazo, Escudo y Turbo ·
si 6 paparazzi como tope es demasiado.

## Hoja de ruta
- **Fase 4c (siguiente, propuesta):** más consumibles (Doble puntos, Radar, Segunda oportunidad), mejoras nuevas (Manos largas, Pozo grande, Suerte, Bonus de capricho),
  más peligros (muros móviles, cosas que se mueven), eventos aleatorios, dificultad creciente en el mapa.
- **Fase 4d:** sonidos, partículas, temblor de pantalla, tutorial.
