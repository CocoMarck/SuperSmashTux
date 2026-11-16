# Nota: `_process_ai` — entrada de IA para NPCs

> **Aplicado.** Nació como propuesta (`_ai_process(signals)` llamado al final del frame); quedó implementado distinto: el hook se llama `_process_ai(delta, frame)`, vive en `Person` y lo sobreescribe `NPC` (`scripts/characters/npc.gd`). Esta nota explica el diseño real y por qué.
>
> **En migración (2026-11-15).** La IA se está moviendo a `NPCController`
> (`scripts/characters/npc_controller.gd`), un controller por composición. Ver la última sección,
> "Migración a `NPCController`".

## Idea central

Separar las dos fuentes de entrada:

- **`_collect_input()`** → entrada humana. `Player` lee el `Input Map` y llenan los bools.
- **`_process_ai(delta, frame: FrameMotionSignals)`** → entrada de IA. Existe en `Person` como `pass`; todos sus hijos lo heredan y solo `NPC` lo sobreescribe.

La IA **no toca el gameplay**: solo setea los mismos bools que usa el humano (`_move_left`, `_move_right`, `_move_up`, `_move_down`, `_jump`, `_walk`, `_attack`, `_power_attack`). Todo el pipeline (movimiento, ataques, escudo, saltos) ya trabaja con esos bools, así que el NPC hereda el gameplay completo sin cambios.

`NPC._collect_input()` baja todos los bools a `false` al inicio de cada frame; luego `_process_ai` sube los que necesite. Así nada se queda "pegado" de un frame a otro.

## Dónde va en `_physics_process` y por qué

```
_collect_input()
_process_ai(delta, _last_frame)   # <- aquí
frame = _build_frame(delta)
... (acción, daño, animación) ...
_commit_frame(delta, frame)       # move_and_slide()
_last_frame = frame
```

Se llama **justo después de `_collect_input()` y antes de construir el frame**, no al final como se propuso al inicio. Razones:

1. **Los bools se consumen en el mismo frame.** Al ir antes de `_build_frame`, lo que decide la IA se aplica ya en este `_physics_process`, igual que una tecla del humano. Cero frames de latencia extra.
2. **Contexto sin tocar el pipeline.** `Person` guarda el `FrameMotionSignals` del frame anterior en `_last_frame` y se lo pasa a la IA (`vertical_force_signals`, `move_signals`, `move_states`). Es lo más fresco que existe antes de calcular el frame nuevo.
3. **`_last_frame` es `null` en el primer frame**, por eso `NPC._process_ai` revisa `frame == null` y sale.

## Qué hace `NPC` hoy

- **Detección**: `DetectionArea` (`Area3D` creada en `_ready`), revisada cada `_detection_interval` (0.1 s). Separa `Platform` y `Person`.
- **Recovery**: en el aire o colgado de una orilla, camina hacia la plataforma más cercana y, si está arriba de él, activa `_turbo_jump`: salto en el piso, saltos en el aire al llegar a la altura máxima estimada (`_calcule_max_jump_height_frames`) y, con los saltos agotados, `_move_up` + `_power_attack` (ataque de poder hacia arriba con `jump_power`, el "tercer salto").
- **Vagabundeo**: fuera del recovery, cambia dirección y velocidad (idle, run, walk, crouch) con temporizadores aleatorios.
- **Ataque por cercanía**: si hay un `Person` a diferencia promedio XYZ <= 0.4 (`_get_very_close_person_position`), se queda quieto y pone `_attack = true`.

El `_attack` ya viaja como bool de un frame porque `_collect_input` lo baja cada frame; la IA lo vuelve a subir solo mientras haya alguien cerca.

## Pendiente

- **Escudo y agarre**: el NPC aún no usa `_shield` ni `_grab`.
- **Detección con bordes reales** (AABB en vez de solo el centro): ver `docs/ia/nota-npc-aabb-deteccion.md`.
- **Modularizar** `_process_ai`: hoy es un solo método largo (así lo marca el propio comentario en `npc.gd`).

## Migración a `NPCController` (2026-11-15)

`npc.gd` se parte en un controller por composición. `NPCController`
(`scripts/characters/npc_controller.gd`, `extends PersonController3D`) ya tiene copiados la detección,
los helpers y los timers, **pero la IA todavía no**. Por eso el configurer sigue usando `set_script(npc.gd)`
y `NPCController` **aún no se instancia en partida**. Ver el diseño general en
[../arquitectura/nota-power-fighter-controller.md](../arquitectura/nota-power-fighter-controller.md).

### Qué le falta a `NPCController`

1. **`get_input(delta, frame)` es un stub** (`return _input`). Hay que migrarle:
   - El **reset** de los 10 flags de `_input` al inicio de cada frame (equivale al `_collect_input()`
     de `npc.gd`). Como `_input` es la **misma instancia reutilizada**, si no se limpia cada frame los
     valores se quedan "pegados".
   - El **cuerpo de `npc.gd:_process_ai()`** (líneas 305-395), escribiendo `_input.move_left = _pin_left`,
     `_input.jump = true`, etc., en vez de los campos `_move_left`/`_jump` del `Person`.
   - El guard **`if frame == null: return`** (el primer frame `_last_frame` es `null`).
2. **Datos que la IA saca de `self` y no están en el `frame`.** Decidido: van por el `frame`.
   - `_jump_count` y `_max_jumps` (se usan en `_jump_count >= _max_jumps`).
   - `jump_impulse` y `fall_acceleration` (cálculo de la altura de salto, `_calcule_max_jump_height_frames`).
   - `_holding_onto_the_ledge()` (recuperación de orilla).
   - **Propuesta**: un `JumpSignals { jump_count, max_jumps, jump_impulse, fall_acceleration }`
     (`scripts/helpers/frame/jump_signals.gd`) colgado de `FrameMotionSignals`, y `MoveStates.hanging`
     para la orilla. `Person._build_frame` los llena; `Person._get_move_states` llena `hanging`.
3. **Configurer**: la rama `NPC` debe pasar a `power_fighter.controller = NPCController.new()` y borrar
   las constantes `NPC_SCRIPT`/`POWER_FIGHTER_SCRIPT`.
4. **Limpiar los hooks viejos** en `Person` (`_collect_input` y `_process_ai`) y borrar `npc.gd`.

### Pasos sugeridos

1. `JumpSignals` + `FrameMotionSignals.jump_signals` + `Person._build_frame` lo llena.
2. `MoveStates.hanging` + `Person._get_move_states` lo llena.
3. Migrar el reset y la IA a `NPCController.get_input`, usando `frame.jump_signals` y
   `frame.move_states.hanging`.
4. Configurer: rama `NPC` al controller.
5. Borrar los hooks viejos de `Person` y luego `npc.gd`.
6. Probar 1 player + 1 NPC: movimiento, recovery, vagabundeo y ataque por cercanía.

### Ya resuelto en el controller

- **`global_position`**: el controller es `Node3D` hijo del peleador, así que su `global_position`
  coincide con la del personaje.
- **`Area3D` de detección**: la arma el propio `NPCController._ready()` como hija suya (no la base
  `PersonController3D`).
- **Filtro del dueño**: `_get_nodes_positions()` salta `self.get_parent()` (el peleador), para que el
  NPC no se detecte a sí mismo como "persona cercana".

### Detalles menores

- `get_input` devuelve el `MoveInput` **reutilizado** del controller (`_input`), igual que
  `PlayerController`. No crear uno nuevo por frame.
- El nombre de clase es `NPCController` (no `NpcController`); el player es `PlayerController`.
