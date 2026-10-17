# Million Hole — Glosario de la traducción al inglés (FASE 5.9)

> Todo el texto visible dentro del juego está en inglés. **El código, los comentarios, los ids, los nombres de archivo y los informes siguen en español** (a propósito).

## Nombre y eslogan

- Título: **MILLION HOLE** (antes *Millones al agujero*). Se cambia en `game.gd` → `TITLE` y en `project.godot` → `config/name` (título de la ventana).
- Eslogan del menú: *Throw away your luxury whims and turn it all into cash* (`game.gd` → `SUBTITLE`).

## Términos clave (para que todo el juego suene igual)

| Español | English |
|---|---|
| heredera | heiress |
| vórtice | vortex |
| caprichos / pedido | **whims** ("TODAY'S WHIMS", "Whim +N", "WHIM COMPLETE!") |
| cuota | quota |
| dinero | cash |
| puntos | score / points |
| ronda | round |
| gala | gala ("GALA NIGHT!") |
| jefe / Paparazzi Supremo | boss / Supreme Paparazzi |
| boutique | boutique |
| reliquia | relic |
| mejora | upgrade |
| consumible | consumable |
| contrato | contract |
| bolsazo | bag smack |
| escudo | shield |

## Nombres y descripciones (editables en `game.gd` e `item_database.gd`)

### Cosas de lujo (`item_database.gd`)

| Español (antes) | English (ahora) |
|---|---|
| Collar de perlas | Pearl Necklace |
| Tarjeta platino | Platinum Card |
| Osito bañado en oro | Gold-Plated Teddy |
| Busto de mármol | Marble Bust |
| Guantelete de repuesto | Spare Gauntlet |
| Poni de cristal | Crystal Pony |
| Saco con $ | Money Sack |
| Mochila cohete | Rocket Backpack |
| Dron carísimo | Overpriced Drone |
| Corona con rubíes | Ruby Crown |
| Cofre sin abrir | Unopened Chest |
| Estatua de oro | Golden Statue |

### Mejoras (`game.gd` → UPGRADES)

| Nombre | Descripción |
|---|---|
| Zapatillas de diseñador → **Designer Sneakers** | +10% de velocidad → +10% speed |
| Bolso de marca → **Designer Tote** | Cargas 1 objeto mas → Carry 1 more item |
| Imán de billetes → **Cash Magnet** | El dinero cercano vuela hacia ti → Nearby cash flies toward you |
| Dinero duradero → **Durable Cash** | +2 s de vida al dinero → +2 s cash lifetime |
| Racha de caprichos → **Whim Streak** | +2 s para mantener el combo → +2 s to keep your combo |
| Reloj de pulsera → **Wristwatch** | +5 s al empezar cada ronda → +5 s at the start of each round |
| Bolsazo de diseñador → **Designer Bag Smack** | Q: aturde a los paparazzi cercanos → Q: stuns nearby paparazzi |
| Manos largas → **Long Arms** | +15 de alcance al recoger cosas → +15 pickup reach |
| Vórtice grande → **Big Vortex** | El vórtice es 15% mas ancho → The vortex is 15% wider |
| Suerte de heredera → **Heiress Luck** | Salen mas cosas raras y legendarias → More rare and legendary items |
| Bonus de capricho → **Whim Bonus** | +25% de recompensa al completar caprichos → +25% reward for completing whims |

### Consumibles (`game.gd` → CONSUMABLES)

| Nombre | Descripción |
|---|---|
| Escudo de diamantes → **Diamond Shield** | Bloquea el proximo golpe (automatico) → Blocks the next hit (automatic) |
| Turbo de lujo → **Luxury Turbo** | Shift: +70% de velocidad durante 3 s → Shift: +70% speed for 3 s |
| Flash cegador → **Blinding Flash** | F: aturde a TODOS los paparazzi durante 5 s → F: stuns ALL paparazzi for 5 s |

### Reliquias (`game.gd` → RELICS)

| Nombre | Descripción |
|---|---|
| Collar de la codicia → **Necklace of Greed** | Dinero x2, pero los paparazzi van 30% mas rapido → Cash x2, but paparazzi are 30% faster |
| Anillo del combo → **Combo Ring** | El combo llega a x5, pero dura 3 s menos → Combo reaches x5, but lasts 3 s less |
| Gafas oscuras → **Dark Shades** | Paparazzi 35% mas lentos, pero empiezas con 5 s menos → Paparazzi 35% slower, but you start with 5 s less |
| Cheque en blanco → **Blank Check** | +50% de puntos, pero la cuota sube 25% → +50% points, but the quota rises 25% |
| Tiara de la reina → **Queen's Tiara** | Legendarias x3 mas comunes, pero cargas 1 objeto menos → Legendaries 3x more common, but you carry 1 item less |
| Perfume carisimo → **Pricey Perfume** | Paparazzi dormidos 12 s, pero ganas 30% menos de dinero → Paparazzi sleep for 12 s, but you earn 30% less cash |
| Zapatos de cristal → **Glass Slippers** | +25% de velocidad, pero los golpes te aturden el doble → +25% speed, but hits stun you twice as long |
| Reloj de oro macizo → **Solid Gold Watch** | +10 s al empezar, pero ya no salen relojes de bonus → +10 s at the start, but no more bonus clocks |

### Contratos (`game.gd` → CONTRACTS)

| Nombre | Descripción |
|---|---|
| Ronda tranquila → **Calm Round** | Sin cambios. La opción segura. → No changes. The safe option. |
| Doble o nada → **Double or Nothing** | Peligros x2, +1 paparazzi, cuota +30%. / Dinero x2. → Hazards x2, +1 paparazzi, quota +30%. / Cash x2. |
| Prisa de compras → **Shopping Rush** | 10 s menos de tiempo. / Puntos +30%, dinero x1.5. → 10 s less time. / Points +30%, cash x1.5. |
| Paparazzi VIP → **VIP Paparazzi** | +2 paparazzi. / Dinero x1.75. → +2 paparazzi. / Cash x1.75. |
| Cuota de lujo → **Luxury Quota** | Cuota +50%. / Dinero x2.5. → Quota +50%. / Cash x2.5. |
| Piso de champán → **Champagne Floor** | Charcos y pinchos x3. / Dinero x1.5. → Puddles and spikes x3. / Cash x1.5. |

## Dónde está el resto del texto

- `hud.gd`: barra superior, tarjeta de ronda, "Carrying", combo, herramientas, barra del jefe, pantallas de **ROUND CLEARED** y **GAME OVER**.
- `main.gd`: avisos grandes que suben (OUCH!, SHIELD!, QUOTA REACHED!, BOSS DEFEATED!...).
- `menu.gd`, `shop.gd`, `contract.gd`, `order_panel.gd`: menú, boutique, contratos y panel de whims.

## Notas

- En la boutique, el nombre corto de los consumibles de la fila de abajo ahora usa la **última** palabra del nombre (Shield / Turbo / Flash); antes usaba la primera. Cambio mínimo en `shop.gd` necesario para que se lea bien en inglés.
- Los sprites no tienen texto pintado en español (el "+2 s" del reloj sirve igual en inglés).
- Corregido de paso: se eliminó `assets/item_corona_rubies}.png` (nombre con `}` de más); queda `item_corona_rubies.png`.
- **Sin probar en Godot:** al abrir el juego revisa que ningún texto se salga de su tarjeta (los más largos: descripciones de reliquias y nombres como *Designer Bag Smack* en la boutique).
