# Recolecta 60 — Informe de estado (actualizado tras FASE 3)

> Pega este archivo al inicio de un chat nuevo y di: "continuemos con la siguiente fase".

## Concepto
Juego top-down 2D en **Godot 4.2+** (GDScript) inspirado en *60 Seconds*. Rondas cortas (**30 s**): recoges objetos,
los sueltas en el **pozo** central, cumples **pedidos**, recoges **monedas** (dinero) y **relojes** (+tiempo).
Entre rondas hay una **tienda** con mejoras. Todo se dibuja por código, sin assets externos.
**SIN persistencia por diseño:** al cerrar el juego se pierde todo el progreso (el record solo dura la sesión).

## Cómo correrlo
Descomprimir → Godot → Import → `project.godot` → F5. Resolución 1280x720.
Controles: WASD/flechas mover · E/Espacio recoger o soltar (dentro del pozo) · Enter/Esc en menús y fin de ronda.
**Nota:** el código se escribió sin poder ejecutarlo en Godot; si hay errores de consola, corregirlos primero.

## Flujo
Menú (`menu.tscn`) → Ronda (`main.tscn`) → fin de ronda (Enter) → Tienda (`shop.tscn`) → Siguiente ronda → ...
Esc en fin de ronda o en tienda = terminar partida (reset) y volver al menú. Rondas infinitas por ahora (sin cuota ni derrota).

## Archivos (todos en la raíz `res://`)
| Archivo | Responsabilidad |
|---|---|
| `project.godot` | Config; escena principal `menu.tscn`; **autoload `Game`** |
| `game.gd` | **Autoload `Game`**: cartera de monedas, niveles de mejoras, ronda actual, record de sesión, efectos de mejoras |
| `menu.tscn/.gd` | Menú principal (UI creada por código) |
| `shop.tscn/.gd` | Tienda: lista de mejoras, compra, siguiente ronda / terminar |
| `main.tscn/.gd` | Ronda: mapa, spawns, pedido, combo, monedas, relojes, fin de ronda |
| `player.gd` | Movimiento, recoger/soltar, auto-recoger monedas/relojes, imán. Lee mejoras de `Game` |
| `item.gd` / `item_database.gd` | Objeto del mapa / lista finita (name, shape, color, points, weight) + `pick_weighted()` + `draw_shape()` |
| `pit.gd` | Pozo central |
| `coin.gd` | Moneda (vuela del pozo, `lifetime` configurable por mejora) |
| `time_bonus.gd` | Reloj +2 s |
| `order_panel.gd` | Panel del pedido en el HUD |
| `hud.gd` | Labels, combo, ronda, `toast()`, pantalla de fin de ronda |

## Convenciones técnicas
- **Sin `class_name`**: `preload("res://x.gd")` en constantes. Nodos por código (`Script.new()` + `add_child`).
- Grupos: `items`, `coins`, `time_bonuses`. Recogida por distancia (sin Area2D). Input con `Input.is_physical_key_pressed`.
- Menús/tienda: `Control` raíz + `ColorRect` + `VBoxContainer`; botones con `focus_mode = FOCUS_NONE` y atajos por teclado.
- Cambio de escena: `get_tree().change_scene_to_file(...)`. Estado entre escenas SOLO en el autoload `Game`.
- Señales del jugador: `carry_changed`, `items_deposited`, `coin_collected`, `time_bonus_collected`.

## Mecánicas implementadas
- **Ronda:** 30 s (+ Reloj de bolsillo), tope 60 s. **Monedas ya NO dan puntos**: son dinero (`Game.coins`).
  Puntos = entregas (x combo) + bonos de pedido. Monedas al entregar = puntos x multiplicador.
- **Combo:** ventana 6 s (+ mejora), +0.5 por entrega, máx x3.
- **Pedido del pozo:** 3 objetos; aro dorado en mapa. Bonus por objeto pedido = puntos x3. Completo: +25 pts, +4 s, +10 monedas, pedido nuevo.
- **Rareza** por `weight`; respawn cada 1.5 s (máx 18). **Relojes** +2 s cada 7 s (máx 2).
- **Tienda (sesión):** coste = base x 1.5^nivel.
  Botas (+10% vel, 5 niv, 25) · Mochila (+1 carga, 2, 40) · Imán (radio 90/150/220, 3, 30) ·
  Monedas duraderas (+2 s vida, 3, 25) · Ventana de combo (+2 s, 3, 25) · Reloj de bolsillo (+5 s inicio, 4, 35).

## Constantes para balancear
`main.gd`: `GAME_TIME`, `MAX_TIME`, `ITEMS_ON_MAP`, `COMBO_*`, `ORDER_*`, `BONUS_*`. `game.gd`: `UPGRADES` (max, base_cost), `MAGNET_RADII`.
`player.gd`: `BASE_SPEED`, `pickup_radius`. `coin.gd`: `BASE_LIFETIME`.
**Pendiente calibrar la economía jugando:** estimado 30-50 monedas por ronda; ajustar `base_cost` si la tienda se siente lenta o regalada.

## Decisiones tomadas
- Rondas de 30 s; tiempo se alarga con pedidos y relojes. Puntos y monedas separados.
- **No hay guardado en disco**: mejoras y monedas viven en `Game` solo mientras el juego está abierto.

## Hoja de ruta
- **Fase 3c (siguiente):** dificultad creciente y razón para perder. Propuesta: **cuota de puntos por ronda** que sube cada ronda
  (si no la alcanzas, fin de partida), menos tiempo base o más "objetos basura" sin valor en rondas altas; consumibles de una ronda
  (Doble puntos, Radar, Turbo, Segunda oportunidad); mejora "Manos largas".
- **Fase 4:** sonidos, partículas, temblor de pantalla, obstáculos (charcos/muros), objetos que se mueven, tutorial corto.
