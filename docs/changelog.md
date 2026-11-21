# Changelog

#### Orden de changelog:
- Arriba va lo listo.
- Abajo va lo que falta.
- Se ordena por mes.
- Se escribe al principio de cada punto un **FALTA** o **LISTO** según se requiera. Si no lo necesita, simplemente no escribirlo.
- Se pueden crear las categorías que se quieran, pero respetar los demás puntos.


## Resumen de lo listo (2026-08 a 2026-10)

> Nota histórica (`2026-08-19`): Apenas me di cuenta, pero gdscirpt no tiene para variables privadas. Pero weno, igual es bueno marcarlas como `_var_private`, ya que indica que eso no se toco fuera de la clase dueña. Es una forma de documentar.

### Personajes y combate
- Refactor de hitboxes **LISTO**: `AreaGravity3D`, `Hitbox`, `HitboxDamage` y `HitboxGrab`, con daño, knockback, debug y lifetime; varios hitboxes de daño por movimiento.
- Movimiento base de `Person` **LISTO**: caminar, correr, caminar agachado, salto y salto en el aire.
- Tercer salto de `PowerFighter` **LISTO**: animaciones para salto en piso y aire, con bloqueo de saltos hasta tocar el piso.
- Daño y stun **LISTO**: hitstun normal, heavy hitstun, knockout, mejoras de knockback/hitstun y bloqueo de inputs mientras dura el estado.
- Escudo de `Fighter` **LISTO**: blockstun, pushback, animación placeholder, sin regeneración mientras se rueda y sin gastar capacidad durante el blockstun.
- Ataques de `Fighter` **LISTO**: grab como ataque, ataques con salto, tres ataques neutrales en piso, cancelación de heavy hitstun en ataques aéreos y margen de error para inputs de dirección.
- Animaciones placeholder **LISTO**: knocked out, grabbed/grabbing y escudo.
- Animación de caída al piso **LISTO**: cooldown corto según la velocidad vertical previa, cancelable al recibir daño.
- Corrección de `Person` **LISTO**: bug al combinar mirar arriba/agacharse con movimiento horizontal.

### Arquitectura y refactor
- `Person._physics_process` modular **LISTO**: `Fighter` reutiliza el flujo sin reemplazarlo por completo.
- Funciones de estado **LISTO**: reemplazo de bools redundantes por funciones que consultan sus timers.
- `GravityBody3D` **LISTO**: ancho y alto públicos con `get_width()`/`get_height()`, y eliminación del helper legacy de media altura.
- Constantes de juego **LISTO**: duraciones de stun, efectos, movimientos compartidos y márgenes de perdón en `GameBalance`.
- One-way platforms **LISTO**: lógica movida de `GravityBody3D` a `Person`.
- Archivos **LISTO**: `gravity_body_3d.gd` movido a `characters/`, `area_gravity_3d.gd` movido a `combat/` y carpeta `physics/` eliminada.

### UI y escenas
- Menú principal **LISTO**: menú como escena principal, configuración de controles y regreso al menú desde el juego.
- Interfaz responsiva **LISTO**: menú, controles y HUD ajustables.
- Reorden de escenas/UI **LISTO**: `scenes/levels/`, `scenes/main.tscn` y pantallas de UI en `ui/`; `scripts/menu/` renombrado a `scripts/ui/`.

### Documentación y limpieza
- Limpieza de legacy **LISTO**: eliminación de scripts, escenas, prefabs, animaciones y notas históricas en desuso.
- Docs ordenados **LISTO**: reorganización por dominio (`arquitectura/`, `combate/`, `ia/`, `controles/`, `ui/`, `arte/`) y fusión de notas de controles.
- Scripts ordenados por dominio **LISTO**: `characters/`, `combat/`, `platforms/`, `match/`, `ui/`, y helpers en `combat/`, `frame/`, `input/`.

---

## Pendientes anteriores a noviembre de 2026

### `2026-08-28`
> Aveces ando en modo automático, y pongo cosas redundantes

- Arreglar Bug **FALTA**: hacer ataque con salto mientras `_holding_onto_the_ledge()`, sucede bug visual, porque se eleva first frame del ataque con salto y luego cancela. 
- Efecto visual al hacer movimientos especiales **FALTA**: Ejemplo: Moverse hacia abajo mas rápido. Al bajarse de plataforma.

- `process_sound` **FALTA**: modulo que obtiene señales, para reproducir sonidos, sonido de pasos, de daño recibido, y etc.
    - Contar tiempo al moverse en el piso o en el aire. (Solo cuando no se recibe daño)
    - Obtener señal frame uno al recibir daño.
    - Obtener señal frame uno al caer en el piso.
    - Obtener señal frame uno al saltar en el piso o en el aire.
    - Obtener señal frame uno al caer en cealing/techo o en wall.

- Bug **TESTEAR**: Por alguna extraña razón el `heavy_hitstun`, queda fijado de forma rara. Aun no identifico que lo deja siempre activo. hasta parece random. Ya lo cambie, párese jalar. El pedo era el flag/bool de wait heavy hitstun get up.

- Aceleración horizontal **TESTEAR**: al tener poca, si se mueve rapido, pero queda raro cuando se mueve en el aire aveces, ya que al ser poca, aveces se mueve muy rapido en el aire.

### `2026-09-28`
- **FALTA** `Person` `GravityBody3D` Arraglar **BUG**: Cuando se colisiona en position perfecta, mismo `x, y, z`, salen volando. Cuando saltan, hago que su colision desaparesca `_toggle_body_collisions`, si sucede que cuando caen, y tienen ambos bodys el mismo `x y z`, salen volando hacia arriba.

---
## `2026-11`

### LISTO

#### Modularización de `GameManager`
- Vidas, tiempo de partida y conteo inicial como módulos separados: `LivesManager`, `MatchTime` y `MatchCountdown` (`2026-11-08`).
- `PowerFighterSlots` (usa `PowerFighterData`) define quién pelea, sus vidas y su tipo; reemplaza `MatchSlots` (`2026-11-09`).

#### Controladores por composición
> Refactor del `2026-11-15` al `2026-11-16` (commits `6c4c4ec`, `70891cd`, `b2cb0a6`). El rol deja de ser herencia (`Player`/`NPC extends PowerFighter`) y pasa a ser un nodo hijo. Detalle en `docs/arquitectura/nota-power-fighter-controller.md` y `docs/ia/nota-ai-npc.md`.

- `PersonController3D`: base `Node3D` que solo decide inputs con `get_input(delta, frame) -> MoveInput` y un `MoveInput` reutilizado. No conoce a `Person`/`Fighter`/`PowerFighter`.
- `MoveInput`: `RefCounted` con los 10 flags (`move_left/right/up/down`, `jump`, `walk`, `attack`, `grab`, `shield`, `power_attack`).
- `PlayerController`: lee `Input` con `player_input_map` según `player_id`; reemplazó a `player.gd` en partida.
- `NpcController`: trae la `Area3D` de detección, los helpers, los timers y la IA de `npc.gd`. `get_input()` arranca con `reset_input()` y lee `frame.jump_signals` y `frame.move_states.hanging`.
- `Person`: propiedad `controller` con setter que hace `add_child`; `_physics_process` llama `_process_controller(delta, _last_frame)`. Los hooks `_collect_input`/`_process_ai` se borraron.
- `PowerFighter`: `_collect_controller_input` copia los 10 campos (la base copia 6: movimiento + salto + caminar).
- `PowerFighterConfigurer`: `PLAYER` -> `PlayerController.new()`, `NPC` -> `NpcController.new()`, `NONE` -> `pass`. Sin `POWER_FIGHTER_SCRIPT`.
- `SpawnPoint`, `LivesManager` y `FightHUD`: `player_id`/`is Player` migrados al controller.
- `standard_power_fighter.tscn`: root con `script = power_fighter.gd`, para que los `@export` sobrevivan sin `set_script`.
- `main_menu.gd`: slot de NPC de debug agregado.
- Prueba en partida 1 player + 1 NPC: movimiento, recovery, vagabundeo y ataque por cercanía.

#### Frame y señales
- `JumpSignals`: `RefCounted` con `count`, `max`, `impulse` y `fall_acceleration`; cuelga de `FrameMotionSignals` y lo llena `Person._build_frame`.
- `PersonController3D.reset_input()`: baja los 10 flags del `MoveInput` reutilizado para que nada quede pegado entre frames.
- Orilla en el frame: `holding_onto_the_ledge` salió de `FrameMotionSignals` y ahora vive en `MoveStates.hanging` (lo llena `Person._build_frame`, lo lee `NpcController`).

#### Person y limpieza
- `player.gd`, `player_legacy.gd` y `npc.gd` eliminados.
- `Person`: fuera `@export material`/`mesh` y `_get_default_material()`; `_set_material`/`_set_mesh` pasaron a `set_material`/`set_mesh` y ahora sí aplican. `GameManager` ya no asigna material.
- `Person`: hard landing con duración escalada y bloqueo de inputs, y animación de cooldown al caer en el piso (`2026-11-12`).

#### Identidad y configuración de personajes
- `Person.id` **LISTO**: `StringName` en vez de `character_name`; el prefab trae `id = &"standard"` y `HitboxDamage` loguea `body.id` (`2026-11-20`).
- `PersonConfig` **LISTO**: `RefCounted` con `id`, `character_name`, `model`, `position_offset`; momentum (`ground_acceleration`, `ground_friction`, `air_acceleration`, `knockback_friction`); `walking_speed`, `running_speed`, `jump_impulse`; `walk_step_interval`, `run_step_interval`, `crouch_move_step_interval` y `air_jump_duration` (`2026-11-21`).
- `PowerFighterConfigurer` **LISTO**: `TUX_PERSON_CONFIG` apunta a `data/power_fighters/tux.person.cfg`; `_load_person()` usa `ConfigFile` y no valida nada a propósito (data mala = crash) (`2026-11-21`).
- `tux.person.cfg` **LISTO**: secciones `[identity]`, `[momentum]`, `[horizontal_movement]`, `[vertical_movement]`, `[interval]` y `[duration_of_anims]` (`2026-11-21`).
- Movimiento desde cfg **LISTO**: `_apply_tux_config()` aplica momentum, velocidades, `jump_impulse`, intervalos de pasos y `air_jump_duration`; `_build_instance()` toma `model` y `position_offset` del cfg (`2026-11-21`).
- Nombre visible **LISTO**: se queda en `power_fighter.id` (p. ej. `tux`). `PersonConfig.character_name` (`"Tux"`) queda disponible para uso futuro; hoy HUD/menu no lo consumen (`2026-11-21`).
- Plantillas de persona **LISTO**: `name.person.cfg` usa secciones válidas (`[horizontal_movement]`, `[vertical_movement]`, `[interval]`) y sirve de base para copiar (`2026-11-21`).

### FALTA / en progreso

#### `2026-11`
- `GameManager` **FALTA**: módulo de velocidad de juego (cámara lenta, freeze al golpe killer).
- `GameManager` **FALTA**: módulo del HUD de partida.

- `GameManager` **FALTA**: tratar `Person` (el papá) en vez de `PowerFighter`, para crecer a más modos de juego.

- SFX de `Person` **EN PROGRESO**: bandera `_first_jump_frame` (en `_move`) ya dispara el sonido de salto sin inferirlo de `last_force <= 0`; `_process_sound` asigna `stream_*` y hace `play()`, pero sigue con `print` de placeholder. Falta decidir 1 vs 3 `AudioStreamPlayer3D`. Los `.wav` ya entraron (commit `7a2ff1f`).

- `PowerFighterConfigurer` **FALTA**: los ataques siguen hardcodeados en `_apply_tux_config()` (desde ~línea 120); `name.fighter.cfg` y `name.power_fighter.cfg` existen, pero el configurer no las carga (`2026-11-21`).

- **FALTA** `NpcController`: Detección de posiciones con `AABB detection`.