# Nota: entrada de IA para NPCs (`NpcController`)

> **Aplicado y migrado (2026-11-16).** Nació como propuesta (`_ai_process(signals)` al final del frame)
> y quedó implementado como hook `_process_ai(delta, frame)` en `Person` que sobreescribía `NPC`
> (`npc.gd`). Hoy ese hook se borró: la IA vive en `NpcController`
> (`scripts/controllers/npc_controller.gd`), un controller por composición. Esta nota explica el diseño
> y la migración. Ver la última sección, "Migración a `NpcController`".

## Idea central

Separar las dos fuentes de entrada:

- **`PlayerController`** → entrada humana. Lee el `Input Map` y llena su `MoveInput`.
- **`NpcController`** → entrada de IA. Escribe los mismos flags en su `MoveInput`.

Antes esto eran dos hooks dentro de `Person`/`NPC`: `_collect_input()` (humano) y
`_process_ai(delta, frame)` (IA). Hoy ambos se borraron y el input viene de los controllers. Ver
[../arquitectura/nota-power-fighter-controller.md](../arquitectura/nota-power-fighter-controller.md).

La IA **no toca el gameplay**: solo setea los mismos bools que usa el humano (`_move_left`, `_move_right`, `_move_up`, `_move_down`, `_jump`, `_walk`, `_attack`, `_power_attack`). Todo el pipeline (movimiento, ataques, escudo, saltos) ya trabaja con esos bools, así que el NPC hereda el gameplay completo sin cambios.

`NpcController.get_input()` arranca con `reset_input()`, que baja los 10 flags del `MoveInput` a
`false`; luego la IA sube los que necesite. Así nada se queda "pegado" de un frame a otro.

## Dónde va en `_physics_process` y por qué

```
_process_controller(delta, _last_frame)   # <- aquí (input del controller)
frame = _build_frame(delta)
... (acción, daño, animación) ...
_commit_frame(delta, frame)               # move_and_slide()
_last_frame = frame
```

Se llama **antes de construir el frame**, no al final como se propuso al inicio. Razones:

1. **Los bools se consumen en el mismo frame.** Al ir antes de `_build_frame`, lo que decide la IA se aplica ya en este `_physics_process`, igual que una tecla del humano. Cero frames de latencia extra.
2. **Contexto sin tocar el pipeline.** `Person` guarda el `FrameMotionSignals` del frame anterior en `_last_frame` y se lo pasa al controller (`vertical_force_signals`, `move_signals`, `move_states`, `jump_signals`). Es lo más fresco que existe antes de calcular el frame nuevo.
3. **`_last_frame` es `null` en el primer frame**, por eso `NpcController.get_input` revisa `frame == null` y sale.

## Qué hace `NpcController` hoy

- **Detección**: `DetectionArea` (`Area3D` creada en `_ready`), revisada cada `_detection_interval` (0.1 s). Separa `Platform` y `Person`.
- **Recovery**: en el aire o colgado de una orilla, camina hacia la plataforma más cercana y, si está arriba de él, activa `_turbo_jump`: salto en el piso, saltos en el aire al llegar a la altura máxima estimada (`_calcule_max_jump_height_frames`) y, con los saltos agotados, `_move_up` + `_power_attack` (ataque de poder hacia arriba con `jump_power`, el "tercer salto").
- **Vagabundeo**: fuera del recovery, cambia dirección y velocidad (idle, run, walk, crouch) con temporizadores aleatorios.
- **Ataque por cercanía**: si hay un `Person` a diferencia promedio XYZ <= 0.4 (`_get_very_close_person_position`), se queda quieto y pone `_attack = true`.

El `_attack` viaja como bool de un frame porque `reset_input()` lo baja cada frame; la IA lo vuelve a subir solo mientras haya alguien cerca.

## Pendiente

- **Escudo y agarre**: el NPC aún no usa `_shield` ni `_grab`.
- **Detección con bordes reales** (AABB en vez de solo el centro): ver `docs/ia/nota-npc-aabb-deteccion.md`.
- **Modularizar** `NpcController.get_input`: hoy es un solo método largo.

## Migración a `NpcController` (aplicada, 2026-11-16)

`npc.gd` se partió en un controller por composición. `NpcController`
(`scripts/controllers/npc_controller.gd`, `extends PersonController3D`) ya tiene la detección, los
helpers, los timers **y la IA**. El configurer ya usa `NpcController.new()` y `npc.gd` se borró. Diseño
general en [../arquitectura/nota-power-fighter-controller.md](../arquitectura/nota-power-fighter-controller.md).

### Qué se hizo

1. **`get_input(delta, frame)` migrado**: arranca con `reset_input()` (baja los 10 flags de `_input`),
   sigue el guard `if frame == null: return _input` y luego el cuerpo de la IA escribiendo
   `_input.move_left = _pin_left`, `_input.jump = true`, etc.
2. **Datos que la IA sacaba de `self`** ahora viajan por el `frame`:
   - `frame.jump_signals.count` / `.max` (antes `_jump_count` / `_max_jumps`).
   - `frame.jump_signals.impulse` / `.fall_acceleration` (cálculo de altura de salto,
     `_calcule_max_jump_height_frames`).
   - La orilla: `frame.move_states.hanging` (antes bool temporal en `FrameMotionSignals`; ya migrado).
3. **Configurer**: rama `NPC` -> `power_fighter.controller = NpcController.new()`; se borró `NPC_SCRIPT`.
4. **Hooks viejos de `Person`** (`_collect_input` y `_process_ai`) borrados.

### Ya resuelto en el controller

- **`global_position`**: el controller es `Node3D` hijo del peleador, así que su `global_position`
  coincide con la del personaje.
- **`Area3D` de detección**: la arma el propio `NpcController._ready()` como hija suya (no la base
  `PersonController3D`).
- **Filtro del dueño**: `_get_nodes_positions()` salta `self.get_parent()` (el peleador), para que el
  NPC no se detecte a sí mismo como "persona cercana".

### Detalles menores

- `get_input` devuelve el `MoveInput` **reutilizado** del controller (`_input`), igual que
  `PlayerController`. No crear uno nuevo por frame.
- El nombre de clase es `NpcController` (no `NPCController`); el player es `PlayerController`.

### Ya resuelto (2026-11-16)

- ~~Mover la orilla de `FrameMotionSignals.holding_onto_the_ledge` a `MoveStates.hanging`.~~
- ~~Borrar `POWER_FIGHTER_SCRIPT` (sin uso) en el configurer.~~
- ~~Probar 1 player + 1 NPC en partida: movimiento, recovery, vagabundeo y ataque por cercanía.~~
