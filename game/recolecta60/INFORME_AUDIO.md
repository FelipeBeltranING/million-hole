# Millones al agujero — Informe de AUDIO (FASE 5.8)

> Esta fase **no se ha probado en Godot** (el código se escribió sin poder ejecutarlo). Al abrir el proyecto, si sale algún error, pégalo y se corrige.

## Cómo funciona (igual que los sprites)
- Pones el archivo en `res://audio/` con el **nombre exacto** de esta lista y el juego lo reproduce solo en el momento justo. **No hay que tocar código.**
- Si un audio no existe, ese momento queda en silencio (sin errores). Puedes ir agregándolos de a uno.
- Formatos: `.ogg` (recomendado), `.wav` o `.mp3`. Si hay dos con el mismo nombre gana `.ogg`, luego `.wav`, luego `.mp3`.
- Después de copiar archivos nuevos, **abre el proyecto en el editor de Godot una vez** para que los importe (igual que con los PNG).
- Son **45 sonidos**: **12 imprescindibles**, 19 recomendados y 14 de pulido (columna *P*).

## Empieza por estos (prioridad 1)
Con solo estos ya se siente otro juego:

`music_menu`, `music_game`, `jingle_win`, `jingle_lose`, `ui_start`, `sfx_pickup`, `sfx_deposit`, `sfx_hit`, `sfx_coin`, `sfx_time_bonus`, `sfx_round_end`, `sfx_order_complete`

## Reglas para elegir los audios
- **Música:** en bucle, 60–120 s. Que no tenga silencio al principio ni al final.
- **Efectos:** cortos (0.1–1 s; las fanfarrias y el jefe pueden durar más) y en **mono**.
- **Monedas, billetes y lingotes** salen por decenas seguidos: tienen que ser **muy cortos** (≈0.15 s).
- Volumen **parejo** entre archivos. Si uno suena muy fuerte o muy bajo, se corrige en `audio.gd` (`VOLUMES`, en dB), sin tocar el archivo.
- Dónde buscar (revisa la **licencia de cada archivo**; algunos piden dar crédito): freesound.org, pixabay.com (sound effects y music), opengameart.org, kenney.nl (packs de audio), mixkit.co, incompetech.com (música). Anota los créditos en un `CREDITOS.txt`.

## Lista completa
Columna **P** = prioridad (1 imprescindible, 2 recomendado, 3 pulido). En *Qué buscar*, las palabras en inglés son para pegar en el buscador.

### MÚSICA (en bucle)

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `music_menu` | 1 | Menú principal. | Alegre y con aire de lujo (jazz suave, lounge). Busca: luxury lounge loop, upbeat jazzy menu loop | 60-120 s, loop |
| `music_game` | 1 | Cada ronda normal (30 s de presión). | Rápida y animada, de arcade. Busca: fast upbeat arcade loop, frantic shopping music | 60-120 s, loop |
| `music_boss` | 2 | La gala con el jefe (rondas 5, 10, 15...). Si no existe, suena music_game. | Intensa y dramática. Busca: boss battle loop, tense chase music | 60-120 s, loop |
| `music_shop` | 2 | Boutique y pantalla de contratos. Si no existe, suena music_menu. | Calmada, elegante, tipo tienda fina. Busca: boutique shop music, bossa nova elevator | 60-120 s, loop |

### FANFARRIAS DE FIN DE RONDA (suenan una vez; la música se apaga antes)

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `jingle_win` | 1 | Ronda superada (sale la pantalla RONDA N SUPERADA). | Fanfarria alegre corta. Busca: level complete jingle, short victory fanfare | 2-3 s |
| `jingle_lose` | 1 | Fin de la partida (perdiste la cuota o el jefe). | Triste pero cómica. Busca: sad trombone, game over jingle | 2-3 s |

### MENÚS Y BOUTIQUE

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `ui_start` | 1 | Jugar (menú), Siguiente ronda (boutique) y volver a jugar tras perder. | Confirmación con whoosh + campanita. Busca: game start confirm, whoosh chime | 0.5 s |
| `ui_buy` | 2 | Compraste algo en la boutique. | Caja registradora. Busca: cash register cha-ching | 0.5-1 s |
| `ui_click` | 3 | Pasar de la pantalla 'Ronda superada' a la boutique (Enter). | Clic suave. Busca: ui click soft | 0.1 s |
| `ui_reroll` | 3 | Renovar ofertas de la boutique. | Barajar cartas o rodillo de tragamonedas. Busca: card shuffle, slot reel spin | 0.4 s |
| `ui_contract` | 3 | Elegir un contrato (1/2/3 o clic). | Sello sobre papel. Busca: paper stamp, contract sign | 0.4 s |
| `ui_back` | 3 | Esc / Terminar partida. | Blip de cancelar suave. Busca: menu back soft blip | 0.2 s |

### LA HEREDERA (jugador)

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `sfx_pickup` | 1 | Recoges un objeto de lujo (E / Espacio). | Pop o bolsa que se agarra. Busca: pop grab item, bag rustle | 0.2 s |
| `sfx_deposit` | 1 | Tiras lo que llevas al vórtice. | Succión o tragada mágica. Busca: suction whoosh, magic vortex swallow | 0.6-1 s |
| `sfx_hit` | 1 | Te golpea un peligro (pinchos, paparazzi, jefe, destello). Sin escudo. | Bonk de caricatura / 'auch'. Busca: cartoon bonk, boing hit | 0.4 s |
| `sfx_carry_full` | 3 | Intentas recoger con las manos llenas y hay algo al alcance. | Error suave, 'no se puede'. Busca: denied buzz, soft error blip | 0.3 s |
| `sfx_shield` | 2 | El Escudo de diamantes bloquea un golpe. | Ping de cristal o escudo. Busca: shield block, crystal ping | 0.5 s |
| `sfx_swing` | 2 | Bolsazo (Q). | Bolsazo: whoosh + golpe sordo. Busca: bag swing whoosh thud | 0.4 s |
| `sfx_turbo` | 2 | Turbo de lujo (Shift). | Impulso de velocidad. Busca: speed boost whoosh | 0.6 s |
| `sfx_flash` | 2 | Flash cegador (F). | Flash de cámara con carga. Busca: camera flash charge pop | 0.5 s |
| `sfx_puddle` | 3 | Entras a un charco de champán (suena al entrar, no todo el rato). | Chapoteo. Busca: water splash step | 0.3 s |

### DINERO Y TIEMPO

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `sfx_coin` | 1 | Recoges una moneda. Salen muchas seguidas: que sea CORTO. El código le varía el tono solo. | Moneda clásica. Busca: coin pickup | 0.15 s |
| `sfx_bill` | 2 | Recoges un billete. | Papel de billete. Busca: paper money rustle | 0.2 s |
| `sfx_bar` | 2 | Recoges un lingote. | Metal dorado que tintinea. Busca: gold bar clink, metal chime | 0.3 s |
| `sfx_time_bonus` | 1 | Recoges el reloj de +2 s. | Ding de reloj / power-up. Busca: time bonus chime, clock ding | 0.5 s |
| `sfx_time_tick` | 2 | Cada segundo de los últimos 5 de la ronda. | Tic de reloj o pitido corto. Busca: clock tick, countdown beep | 0.2 s |
| `sfx_round_start` | 2 | Empieza una ronda normal (en la gala suena sfx_boss_intro en su lugar). | Campana o silbato de 'listos, ya'. Busca: round start bell, ready go | 1 s |
| `sfx_round_end` | 1 | Se acaba el tiempo (justo antes de la fanfarria). | Bocina o gong. Busca: time up buzzer, gong | 1-1.5 s |

### CAPRICHOS, COMBO Y CUOTA

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `sfx_combo` | 2 | Cada vez que tiras algo con combo x2 o más. El código sube el tono con el combo. | Campanita corta. Busca: combo ding bell | 0.3 s |
| `sfx_order_item` | 3 | Un objeto del capricho se marca como entregado. | Tic de tarea hecha. Busca: check mark ding, task tick | 0.3 s |
| `sfx_order_complete` | 1 | Capricho completo (+4 s). | Éxito alegre. Busca: success chime, achievement | 1 s |
| `sfx_quota` | 2 | Llegas a la cuota (sale '¡CUOTA CUMPLIDA!'). | Meta lograda. Busca: goal reached, level up, short applause | 1-1.5 s |

### EL VÓRTICE

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `sfx_vortex_warn` | 2 | Aviso de que el vórtice se muda (2 s antes). | Alarma o pulso de advertencia. Busca: warning alarm pulse, portal warning | 1-2 s |
| `sfx_vortex_move` | 3 | El vórtice se cierra y salta a otro sitio. | Teletransporte. Busca: portal whoosh, teleport | 0.7 s |

### PELIGROS (los pinchos se oyen más bajo cuanto más lejos estás)

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `sfx_spikes_warn` | 3 | Los pinchos empiezan a avisar (parpadean naranja). | Clic de trampa armándose. Busca: trap arming click | 0.4 s |
| `sfx_spikes_on` | 2 | Los pinchos salen. | Metal que se clava. Busca: spikes out, trap snap | 0.4 s |
| `sfx_pap_flash` | 2 | Un paparazzi (o el jefe) te toca y hace flash. Suena junto a sfx_hit. | Obturador + flash. Busca: camera shutter flash | 0.4 s |
| `sfx_pap_stun` | 3 | Un paparazzi queda aturdido por el Bolsazo o el Flash. | Mareo de caricatura. Busca: cartoon dizzy stars bonk | 0.5 s |

### JEFE: PAPARAZZI SUPREMO

| Nombre exacto | P | Cuándo suena | Qué buscar | Duración |
|---|:-:|---|---|---|
| `sfx_boss_intro` | 2 | Empieza la gala (aparece el jefe). | Golpe dramático o risa malvada. Busca: boss appears, dramatic sting, evil laugh | 2 s |
| `sfx_boss_shoot` | 3 | El jefe dispara un destello. | Disparo de energía. Busca: energy shot pew | 0.3 s |
| `sfx_boss_dash_warn` | 3 | El jefe avisa la embestida (línea roja, dura 0.55-0.7 s). | Carga que sube. Busca: charging up, rising alarm, bull snort | 0.5-0.7 s |
| `sfx_boss_dash` | 3 | El jefe embiste (dura 0.55 s). | Whoosh pesado. Busca: heavy dash whoosh | 0.5 s |
| `sfx_boss_hit` | 2 | Un capricho completado le quita vida al jefe. | Impacto grande de caricatura. Busca: heavy cartoon smack, boss damaged | 0.5 s |
| `sfx_boss_rage` | 3 | El jefe se enfurece (le queda la mitad de vida). | Rugido o power-up enojado. Busca: monster roar, angry power up | 1-1.5 s |
| `sfx_boss_defeated` | 2 | El jefe cae derrotado (salen 40 monedas). | Explosión + victoria. Busca: boss defeated, big explosion coins | 2-3 s |

## Cosas que el código ya hace solo
- **Variación de tono al azar** en monedas, billetes, lingotes, recoger, tirar, golpe y paparazzi aturdido (para que no suenen siempre idénticos). Ajustable en `audio.gd` → `PITCH_RANDOM`.
- **`sfx_combo` sube de tono** con cada combo seguido.
- **Pinchos y paparazzi aturdidos se oyen más bajo cuanto más lejos** está la heredera.
- **Anti-ametrallado:** el mismo sonido no se repite más de una vez cada 0.03 s (monedas 0.05 s, tic de reloj 0.5 s). `audio.gd` → `MIN_GAP`.
- **Hasta 16 efectos a la vez.** La música va aparte y es más baja que los efectos (`MUSIC_DB = -8`).
- **Respaldos de música:** sin `music_boss` suena `music_game`; sin `music_shop` suena `music_menu`.
- **Fin de ronda:** la música se apaga con fundido, suena `sfx_round_end` y 0.8 s después `jingle_win` o `jingle_lose`.
- **Gala:** en vez de `sfx_round_start` suena `sfx_boss_intro`.
- Cuando te pega un paparazzi o el jefe suenan **a la vez** `sfx_hit` (el golpe) y `sfx_pap_flash` (el flash): conviene que combinen.

## Notas técnicas
- **Bucle de la música:** el código la repite al terminar (`finished`), así que funciona con `.ogg`, `.wav` y `.mp3` sin configurar nada; puede notarse un cortecito en el empalme. Para un bucle perfecto: doble clic al archivo en Godot → pestaña *Import* → marcar **Loop** → *Reimport*.
- **Versión web** (el proyecto tiene preset de exportación Web): el navegador no deja sonar nada hasta el primer clic o tecla, así que la música del menú arranca cuando el jugador interactúa. Es normal.
- **Prueba rápida:** copia cualquier `.wav` a `res://audio/` con el nombre `sfx_coin.wav`, juega y recoge una moneda. Si suena, todo el sistema funciona.

## Qué se tocó en el código
- **Nuevo:** `audio.gd` (autoload `Sound`, registrado en `project.godot`) y la carpeta `audio/` con su `LEEME.txt`.
- **Con llamadas a `Sound.play(...)` / `Sound.music(...)`:** `player.gd`, `hazard.gd`, `pit.gd`, `main.gd`, `menu.gd`, `shop.gd`, `contract.gd`.
- **Corregido de paso:** el sprite `assets/item_corona_rubies}.png` tenía una `}` de más en el nombre y el juego no lo detectaba (buscaba `item_corona_rubies.png`). Se renombró a `item_corona_rubies.png`.
