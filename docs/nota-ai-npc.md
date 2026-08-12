# Nota: `_ai_process` — entrada de IA para NPCs

> Propuesta de diseño para que los futuros NPCs (probablemente `NPCPerson`, `NPCFighter`, `NPCPowerFighter`) puedan "jugar" con la misma maquinaria de gameplay de los humanos sin tocar nada. **Aún no aplicado; es anotación de diseño.**

## Idea central

Separar las dos fuentes de entrada:

- **`_collect_input()`** → entrada humana. Vive en el nodo jugador (`TestPlayer`), lee el `Input Map` y llena los bools.
- **`_ai_process(signals: VerticalForceSignals)`** → entrada de IA. **Existe desde `Person`** y, por defecto, es un `pass`. Todos los hijos de `Person` (`Fighter`, `PowerFighter`, `TestPlayer`, y los futuros `NPC*`) lo heredan.

Los NPCs **no sobreescriben `_collect_input`** (lo dejan en `pass`, ya es `pass` en `Person`) y sí sobreescriben `_ai_process`. La IA no toca el gameplay: solo setea los mismos bools que usa el humano (`_move_left`, `_move_right`, `_move_up`, `_move_down`, `_jump`, `_attack`, `_grab`, `_shield`). Todo el pipeline (movimiento, ataques, grab, shield, salto) ya trabaja con esos bools, así que el NPC hereda el gameplay completo sin cambios.

## Dónde va en `_physics_process` y por qué

Se llama **al final del `_physics_process`**, después de `move_and_slide()` (lo último del pipeline actual, `fighter.gd:512` / `person.gd:403`). Razones:

1. **Lee el `on_floor` real, no el del gameplay.** El `signals.on_floor` que circula por el juego sale de `_vertical_force()`, que corre al inicio del frame y usa `is_on_floor()` del `move_and_slide()` anterior — o sea, todo el gameplay vive con 1 frame de retraso (el `is_on_floor()` real solo se actualiza dentro de `move_and_slide()`). Si `_ai_process` corre al final, la IA puede leer `is_on_floor()` recién actualizado por la física del frame actual.
2. **Lee los estados que ya se calcularon este frame.** `_current_attack`, `_grabbing()`, `_with_shield()`, `_knockback_active`, `velocity`, `_x_not_zero_value`, etc., ya tienen valor fresco para que la IA decida mejor.
3. **No hay riesgo de leer el "futuro".** Los bools que setee la IA al final se consumen hasta el `_physics_process` del frame siguiente — 1 frame de latencia entre decisión y acción, que es la misma latencia con la que ya vive todo el gameplay (nada reacciona a la física del frame actual en el mismo frame).

### Ojo con el parámetro `signals`

El `VerticalForceSignals` que recibe es el que ya computó `_vertical_force()` **al inicio** del frame: su `on_floor` es el "viejo" (el del gameplay). Si la IA necesita el `on_floor` recién horneado, usa `is_on_floor()` dentro del propio `_ai_process` en vez de `signals.on_floor`. El parámetro sigue siendo útil para datos como `air_count` o `force` que no requieren frescura frame-perfect.

## Responsabilidades de la IA

- **Flancos:** `_attack`, `_grab` y `_shield` en el humano viajan como `is_action_just_pressed` (flanco puro). La IA debe emular el flanco: setearlos `true` un solo frame y bajarlos al siguiente.
- **Salto:** `_jump` sostenido se lo traga el flanco de `_was_jumping` (`person.gd:151`), así que la IA también lo togglea en el frame justo.
- **Búsqueda de contexto:** el target del NPC se resuelve con `@export` o un grupo (`"fighters"`); la IA lee `global_position`, `velocity`, `is_on_floor()`, `_x_not_zero_value` por sí misma. `_ai_process` no recibe contexto extra por firma — el NPC va a buscarlo.

## Estado

- **No aplicado.** Decisión pendiente: confirmar la firma exacta (`_ai_process(signals: VerticalForceSignals)`) y en qué nivel del pipeline llamarla cuando se implementen los NPCs.
