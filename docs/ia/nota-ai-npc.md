# Nota: `_process_ai` — entrada de IA para NPCs

> **Aplicado.** Nació como propuesta (`_ai_process(signals)` llamado al final del frame); quedó implementado distinto: el hook se llama `_process_ai(delta, frame)`, vive en `Person` y lo sobreescribe `NPC` (`scripts/characters/npc.gd`). Esta nota explica el diseño real y por qué.

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
