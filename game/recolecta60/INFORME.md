# Millones al agujero — Informe de estado (tras FASE 5.8: audio por nombre, igual que los sprites; FASE 5.7: piso del mapa nuevo; FASE 5.6: barra naranja + fondos de menú/fin de partida; FASE 5.5: boutique rediseñada + FASE 5.4: contratos rediseñados, ronda de 30 s y gala de 40 s)

> Pega este archivo al inicio de un chat nuevo y di: "continuemos con la siguiente fase".

## Concepto
Juego top-down 2D en **Godot 4.2+** (GDScript). Una **heredera mimada** (protagonista original, sin nombre; rosa con tiara)
lleva **cosas de lujo** y las **tira en un agujero** que las convierte en **dinero** (billetes, monedas de oro, lingotes).
Rondas de **30 s** (40 s la gala del jefe), pedidos ("Caprichos de hoy"), relojes que suman tiempo, **cuota de puntos por ronda**, **peligros** desde la ronda 2,
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
| `audio.gd` | **Nuevo (5.8).** Autoload `Sound`: reproduce `res://audio/<clave>.ogg/.wav/.mp3` si existe (si no, silencio). `Sound.play()`, `play_near()`, `music()`, `stop_music()` |
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


## FASE 5.8 (SIN probar en Godot)
**Audio listo para recibir archivos, igual que los sprites.** Regla: si existe `res://audio/<clave>.ogg` (o `.wav` / `.mp3`) el juego lo reproduce solo; si no existe, queda en silencio sin error. Poner un audio = copiar el archivo con el nombre exacto. No hay que tocar código.
- **`audio.gd`** (nuevo, autoload `Sound` en `project.godot`): caché de audios, 16 reproductores para efectos, uno aparte para música. Constantes ajustables arriba: `MUSIC_DB`/`SFX_DB`, `VOLUMES` (dB por sonido), `PITCH_RANDOM` (variación de tono), `MIN_GAP` (anti-ametrallado), `FALLBACKS` (`music_boss` → `music_game`, `music_shop` → `music_menu`).
- **45 sonidos** enganchados a los eventos: música (menú, boutique/contratos, ronda, gala), fanfarrias de fin de ronda, menús/boutique, jugador (recoger, tirar, golpe, escudo, bolsazo, turbo, flash, charco), dinero (moneda/billete/lingote, reloj, tic de los últimos 5 s), caprichos/combo/cuota, vórtice (aviso y mudanza), peligros (pinchos, paparazzi) y jefe (aparece, dispara, embestida, golpe, furia, derrota).
- Detalles: `sfx_combo` sube de tono con el combo; pinchos y paparazzi aturdidos se oyen más bajo si están lejos (`Sound.play_near`); al terminar la ronda la música se apaga con fundido, suena `sfx_round_end` y 0.8 s después `jingle_win` / `jingle_lose`; en la gala suena `sfx_boss_intro` en vez de `sfx_round_start`.
- **Lista completa de nombres, cuándo suena cada uno y qué buscar: `INFORME_AUDIO.md`** (y versión corta en `audio/LEEME.txt`).
- **Corregido de paso:** `assets/item_corona_rubies}.png` tenía una `}` en el nombre y no se detectaba; ahora es `item_corona_rubies.png`.
**Archivos tocados:** `audio.gd` (nuevo), `audio/LEEME.txt` (nuevo), `INFORME_AUDIO.md` (nuevo), `project.godot`, `player.gd`, `hazard.gd`, `pit.gd`, `main.gd`, `menu.gd`, `shop.gd`, `contract.gd`, `assets/item_corona_rubies.png` (renombrado), `INFORME.md`.
**Al probar:** que no salgan errores al abrir (hay un autoload nuevo); poner un `.wav` cualquiera como `audio/sfx_coin.wav` y comprobar que suena al recoger una moneda; que la música no se reinicie al pasar de la boutique a los contratos; que las monedas seguidas no suenen ametralladas.

## FASE 5.7 (SIN probar en Godot)
**Piso del mapa nuevo** (antes verde liso): piso de baldosas índigo estilo mármol de lujo, para que destaquen el oro, la heredera rosa y los pinchos rojos. En `main.gd`, arriba, constantes para cambiarlo: `FLOOR_A` / `FLOOR_B` (las 2 baldosas alternadas), `FLOOR_TILE` (tamaño, 64 px), `FLOOR_OUTSIDE` (lo que queda detrás del HUD) y `FLOOR_EDGE` (línea dorada fina del borde). Para un fondo liso: poner `FLOOR_A` y `FLOOR_B` iguales. Si existe `assets/background.png` sigue mandando ese. `project.godot`: color de limpieza ajustado a juego.
**Archivos tocados:** `main.gd`, `project.godot`, `INFORME.md`.

## FASE 5.6 (SIN probar en Godot)
**1. Barra superior del HUD más naranja:** nueva constante `UI.ORANGE_SOFT = #FF8A1F` en `ui.gd`, usada solo por la barra de arriba (`hud.gd` → `_build_top_bar`). `UI.ORANGE` (#F04800, rojo-naranja) sigue para el combo. Para ajustar el tono: cambiar ese hex.
**2. Fondos de pantalla** (`assets/fondo.jpg`, subido por el usuario, 1600x900):
- `assets.gd`: ahora acepta **PNG o JPG**; nueva `Assets.background(kind)` busca `bg_<kind>` y, si no existe, `fondo` (si tampoco, null = color liso).
- **Menú** (`menu.gd`): usa `Assets.background("menu")` a pantalla completa + **panel oscuro centrado** con borde amarillo para que el texto se lea sobre el fondo naranja. Título con `UI.label`.
- **Fin de la partida** (`hud.gd` → `show_round_result`): si `passed` es false (perdiste), muestra `Assets.background("gameover")` en vez de la partida oscurecida (`end_bg`). **"RONDA N SUPERADA" NO lleva fondo** (sigue el oscurecido); si se quiere, quitar la condición `not info["passed"]`.
- Fondos distintos por pantalla: poner `bg_menu.png` y/o `bg_gameover.png` en `assets/` (tienen prioridad sobre `fondo.jpg`). En la partida normal no se usa ninguno.
**Archivos tocados:** `ui.gd`, `hud.gd`, `assets.gd`, `menu.gd`, `assets/LEEME.txt`, `assets/fondo.jpg` (nuevo), `INFORME.md`.
**Al probar:** que Godot importe `fondo.jpg` (abre el proyecto en el editor una vez), que el menú se lea bien sobre el fondo, y que el fin de partida se vea bien con el panel encima.

## FASE 5.5 (SIN probar en Godot)
**Boutique rediseñada** (`shop.gd`, reescrito desde el mockup de Figma "BOUTIQUE"; `shop.tscn` no cambió; misma lógica de compra/renovar/siguiente ronda de siempre, solo cambió lo visual). Estilo de `ui.gd` (Lilita One, amarillo/cian, bordes gruesos), posiciones absolutas en 1280x720:
- **Arriba izquierda:** "BOUTIQUE" y "Ronda N superada - X puntos | Próxima cuota: Y". **Arriba derecha:** panel "Dinero: $N".
- **Aviso rojo "¡LA PRÓXIMA RONDA ES UNA GALA CON JEFE!"** (solo si la ronda siguiente es la gala).
- **Ofertas:** cuadrícula de 3 columnas de tarjetas 288x208. Cada tarjeta: tipo (MEJORA blanco / RELIQUIA amarillo / CONSUMIBLE cian), `Nivel a/max` (solo mejoras), **icono 96 px** (`icon_box.gd`) + nombre + descripción, y botón: `Comprar N` / `GRATIS` (amarillo), gris si no te alcanza, `VENDIDO` (tarjeta al 40%), `MÁXIMO` (mejora al tope) o `LLENO` (consumible). Si el nombre/descripción no cabe se corta con "…" (nombre 2 líneas, descripción 3). El hueco 6 de la cuadrícula es el texto "El lujo tiene límites."
- **Panel derecho** "¿Lista para más?": `Renovar ofertas (N)` (gris si no alcanza), `Siguiente ronda` + "Enter para continuar", `Terminar partida (Esc)`. Mismas teclas: Enter / Esc.
- **Abajo:** "TUS RELIQUIAS" (chips con icono; si tienes más de 2 solo iconos y el nombre/efecto sale al pasar el mouse) y "CONSUMIBLES" (Turbo x2, Flash x1... solo los que tienes). Abajo a la derecha el título del juego.
- Ya no está la lista de texto de reliquias con descripción: ahora es por tooltip.
- **Iconos opcionales:** `upgrade_<id>.png` (boots, backpack, magnet, durable, combo, pocket, reach, pitwide, luck, orderbonus; el bolsazo usa `tool_bolsazo.png`), `relic_<id>.png`, `tool_<id>.png`. Sin PNG sale la letra inicial. Añadidos a `assets/LEEME.txt`.
**Archivos tocados:** `shop.gd`, `assets/LEEME.txt`, `INFORME.md`.
**Pendiente (mockups ya recibidos):** "RONDA N SUPERADA" y "FIN DE LA PARTIDA" (están dentro de `hud.gd` → `show_round_result`) y el menú.
**Al probar:** que ningún texto se corte feo en las tarjetas (si molesta, bajar la letra de la descripción o agrandar la tarjeta: `CARD_SIZE` en `shop.gd`), que la fuente cargue, y que con 6+ ofertas/reliquias nada se salga de la pantalla.

## FASE 5.4 (SIN probar en Godot)
**1. Pantalla de contratos rediseñada** (`contract.gd`, reescrito desde el mockup de Figma "CONTRATO DE LA RONDA N"; la escena `contract.tscn` no cambió). Mismo estilo que el HUD (`ui.gd`: Lilita One, amarillo/cian/verde, bordes gruesos):
- Cabecera "CONTRATO DE LA RONDA N" + subtítulo; **3 tarjetas** iguales (alto 470) y pie con el título del juego y "Pulsa la tecla de tu contrato para elegir."
- Cada tarjeta: **nivel de riesgo** (SIN RIESGO en cian / RIESGO 1 · MEDIO / RIESGO 2 · ALTO en amarillo), **icono de 96 px** (`icon_box.gd`) + nombre, descripción, y los números ya calculados **con tus mejoras y reliquias**: `Cuota: N puntos` (verde) y `Dinero xN · Tiempo: Ns`. Botón `Elegir (n)`: oscuro con borde amarillo en el tranquilo, amarillo lleno en los de riesgo. Teclas 1/2/3 (y teclado numérico) o clic.
- **Iconos opcionales:** `res://assets/contract_<id>.png` (`calm`, `double`, `rush`, `vip`, `high`, `slippery`). Sin PNG sale una letra provisional (R, x2, P, V, $, ~). Añadidos a `assets/LEEME.txt`.
- `game.gd`: cada contrato tiene ahora `"risk"` (0 ninguno, 1 medio, 2 alto): doble o nada 2, cuota de lujo 2, prisa 1, VIP 1, piso de champán 1. Nuevas `contract_val(id, key, default)`, y `round_time(r, cid)` / `current_quota(r, cid)` aceptan un contrato cualquiera (las tarjetas muestran los 3 sin activarlos). Se corrigieron acentos en nombres/descripciones ("Piso de champán", "La opción segura").
- Se quitó el "Dinero: $N" de esa pantalla (no está en el mockup).
**2. Tiempo de ronda (se cambia en `game.gd`, arriba del todo):** `BASE_TIME` = **30 s** en toda ronda normal (no crece con las rondas) y `BOSS_EXTRA_TIME` = **10 s** extra en la gala, o sea **40 s** con el jefe. Solo cambia con contratos (Prisa −10 s), mejoras (Reloj de pulsera +5 s/nivel) y reliquias (Reloj de oro +10 s, Gafas −5 s). El tope del reloj al sumar bonus (relojes +2 s, pedidos +4 s) es `MAX_TIME` = 60 en `main.gd`.
**Archivos tocados:** `contract.gd`, `game.gd`, `main.gd` (solo constante/comentario), `assets/LEEME.txt`, `INFORME.md`.
**Pendiente (mockups ya recibidos):** "RONDA N SUPERADA" y "FIN DE LA PARTIDA" con este mismo estilo; menú. (La boutique se hizo en 5.5.)
**Al probar:** que la fuente cargue, que los textos de las tarjetas no se corten (nombres largos se parten en 2 líneas) y que "Dinero x2.5 · Tiempo: 40s" quepa en una línea; que la cuota/tiempo mostrados coincidan con la ronda real.

## FASE 5.3 (HUD rediseñado desde el mockup de Figma, SIN probar en Godot)
- **Estilo:** paleta de la heredera (naranja `#F04800`, amarillo `#FFE61A`, piel `#F8B080`, contorno casi negro), paneles con borde grueso y sombra dura, fuente **Lilita One** (`fonts/LilitaOne-Regular.ttf`, licencia OFL en `fonts/OFL.txt`). Todo el estilo compartido vive en **`ui.gd`** (colores, `font()`, `panel_style()`, `label()`).
- **`hud.gd` reescrito** con el layout del mockup (1280x720): barra superior naranja (tiempo · puntos con barra hacia la cuota · dinero), tarjeta de ronda/contrato, "Llevas X/Y" con casillas, combo con barra, reliquias abajo al centro, herramientas abajo a la derecha (Q Bolsazo con recarga, Shift Turbo, F Flash, Escudo automático), barra del jefe por segmentos, pantalla de resultados con panel. La API que usa `main.gd` no cambió.
- **`order_panel.gd`** (Caprichos de hoy) rehecho: esquina inferior izquierda, icono + nombre + casilla verde al entregar. **`icon_box.gd`** (nuevo): cuadrito de icono reutilizable (cosa de lujo, asset o letra provisional).
- **El mapa cambió de tamaño:** ahora `MAP_RECT = Rect2(48, 100, 1184, 528)` en `main.gd` (antes 50px de margen, 1180x620). El HUD tapa parte del mapa a la izquierda y abajo a la derecha, así que `hud.gd` define `ZONES` y `main.gd`/`pit.gd` evitan poner objetos, peligros y vórtice debajo. Si estorba: paneles más transparentes o achicar el mapa.
- No se incluyó "Esc · Pausa" del mockup (no existe pausa). El escudo es automático (no tiene tecla).
- Assets opcionales nuevos (iconos del HUD: `icon_time`, `icon_money`, `tool_*`, `relic_*`) en `assets/LEEME.txt`.
- **Al probar:** que cargue la fuente (si no, usa la de Godot), que ningún panel tape cosas importantes, y que el tamaño de la ventana no descuadre nada.
- Pendiente: tienda (hecha en 5.5) y contratos (hecho en 5.4).

## FASE 5.2 (SIN probar en Godot)
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
**furia** con la mitad de vida: +30% velocidad, dispara 3 destellos en abanico y más seguido · aturdido por daño 1.6 s (antes 2.5) · la Gala dura +25 s en esa fase (ahora +15 sobre 40 s = 55 s, ver 5.4).
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
- **Fase 5c:** (sonidos: código listo en 5.8, faltan los archivos) partículas, temblor de pantalla, tutorial/explicación de contratos y reliquias, balance final.
