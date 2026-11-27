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
- `PersonConfig` **LISTO**: `RefCounted` con `id`, `model`, `position_offset`; momentum (`ground_acceleration`, `ground_friction`, `air_acceleration`, `knockback_friction`); `walking_speed`, `running_speed`, `jump_impulse`; `walk_step_interval`, `run_step_interval`, `crouch_move_step_interval` y `air_jump_duration`. El campo `character_name` sigue en la clase como deuda, pero ya no se lee del cfg (`2026-11-21`).
- `identities.cfg` **LISTO**: manifiesto global en `data/characters/identities.cfg`; la sección es el id y `name` es el texto visible. Hoy trae `[tux]`; `standard` no vive en el archivo (`2026-11-21`).
- `CharacterRegistry` **LISTO**: helper que valida ids `snake_case`, expone `playable_ids()`, `display_name()`, rutas de `.person.cfg` y carga configs con `ConfigFile` sin validación a propósito. `standard` y su nombre quedan hardcoded porque no tienen cfg (`2026-11-21`).
- `CharacterCatalog` **LISTO**: reemplaza al enum `PowerFighterConfig`. `Entry` usa `config_id: StringName`, `display_name`, `glyph` y `model`; los nombres vienen del registry (`2026-11-21`).
- `config_id` **LISTO**: `PowerFighterData`, `PowerFighterSlots`, `GameManager`, `SpawnPoint`, `PowerFighterConfigurer` y `CharacterMenu` migrados de enum a `config_id: StringName` (`2026-11-21`).
- `FightHUD` **LISTO**: resuelve el nombre con `CharacterCatalog.get_entry_by_config_id(power_fighter.id)`; dejó de mostrar el id crudo (`2026-11-21`).
- `CharacterMenu` **LISTO**: tablas y datos por `entry.config_id`; el preview de `SlotCard` ya no tiene el offset/hardcodeo de Tux (`2026-11-21`).
- `tux.person.cfg` y plantillas **LISTO**: `character_name` salió del cfg; quedan `[identity]`, `[momentum]`, `[horizontal_movement]`, `[vertical_movement]`, `[interval]`, `[duration_of_anims]` y `[anim_offset]` (`2026-11-21`).
- Movimiento desde cfg **LISTO**: `_apply_person_config()` aplica momentum, velocidades, `jump_impulse`, intervalos de pasos y `air_jump_duration`; `_build_instance()` toma `model` y `position_offset` del cfg (`2026-11-21`).
- Offset de colgamiento **LISTO**: `hanging_anim_offset` se lee de `[anim_offset]` en `.person.cfg`, vive en `PersonConfig` y lo aplica `PowerFighterConfigurer` con `set_anim_offset()`; antes estaba quemado en el configurer (`2026-11-22`).
- `FighterConfig` **LISTO**: los 15 ataques normales salen de `data/characters/tux.fighter.cfg`, con loader único en `CharacterRegistry` y asignación directa vía `_apply_fighter_config()`; la plantilla `data/templates/name.fighter.cfg` quedó alineada con el loader (`2026-11-23`).
- Config de peleador **LISTO**: `FighterConfig` cubre fighter y `PowerFighterConfig` cubre power attacks; la separación dejó de estar diferida (`2026-11-23`, actualizado `2026-11-25`).

#### Audio y cfg de peleador (`2026-11-24`)
- SFX de ataque **LISTO (parcial)**: `Fighter` implementa `_attack_sounds()` con `stream_attack` y las listas `fight_moves_with_simple_sound` / `fight_moves_with_hitspawn_sound`; `Person::_process_sound()` corre `_movement_sounds()` y luego el hook. Known issue vigente: hit suena al spawnear y escudo suena hit aunque bloquee (`2026-11-24`, actualizado `2026-11-25`).
- Secciones `*_attack` renombradas en fighter cfg **LISTO**: la sección es la anim y ya no se lee `name`; `CharacterRegistry._fight_move()` arma `name` desde la key de sección (`2026-11-24`).
- `set_damage(dmg, dir)` **LISTO**: entrada única de daño en `Person`; `HitboxDamage` ya manda daño + dirección y el primer frame de daño dispara el SFX de golpe (`2026-11-24`).

#### Registry, configurer y audio (`2026-11-25`)
- `PowerFighterConfig` **LISTO**: existe `scripts/helpers/characters/power_fighter_config.gd`, `CharacterRegistry.load_power_fighter_config()` lee `<id>.power_fighter.cfg` y `PowerFighterConfigurer` aplica `power_attacks` sin overrides de Tux (`2026-11-25`).
- Tux sin hardcode **LISTO**: usa `.person.cfg`, `.fighter.cfg` y `.power_fighter.cfg`; `standard` sigue siendo base/dummy sin cfg, con defaults en prefab/code (`2026-11-25`).
- `[fight_moves]` **LISTO**: `FighterConfig` trae `fight_moves_with_simple_sound` y `fight_moves_with_hitspawn_sound`; el prefab ya no guarda esos defaults y `tux.fighter.cfg` es la fuente (`2026-11-25`).
- SFX de power attacks **LISTO (parcial)**: en Tux suenan cuatro al spawnear (`down`, `up`, `air_down`, `air_up`); siguen mudos `power_attack` y `air_power_attack` (`2026-11-25`).
- Ideas de audio y combate **IDEA / NO IMPLEMENTADO**: `AudioStreamLayerPlayer3D`, tipo de hitbox y carga de ataques registrados en [docs/ideas/audio-y-combate.md](ideas/audio-y-combate.md) (`2026-11-25`).

#### Fichas de estado de clases (`2026-11-26`)
- `Person`, `Fighter` y `PowerFighter` **LISTO**: fichas nuevas en [clase-person.md](arquitectura/clase-person.md), [clase-fighter.md](arquitectura/clase-fighter.md) y [clase-power-fighter.md](arquitectura/clase-power-fighter.md), con hooks, estado interno, invariantes y deudas de refactor; enlaces cruzados mínimos.

### FALTA / en progreso

#### `2026-11`
- `GameManager` **FALTA**: módulo de velocidad de juego (cámara lenta, freeze al golpe killer).
- `GameManager` **FALTA**: módulo del HUD de partida.

- `GameManager` **FALTA**: tratar `Person` (el papá) en vez de `PowerFighter`, para crecer a más modos de juego.

- SFX de movimiento **EN PROGRESO**: bandera `_first_jump_frame` (en `_move`) ya dispara el sonido de salto sin inferirlo de `last_force <= 0`; `_process_sound()` asigna `stream_*` y hace `play()`, pero sigue con `print` de placeholder. Falta decidir players fijos vs `AudioStreamLayerPlayer3D`. Ya hay 18 `.wav` y 5 randomizers; `whip_01/02/03.wav` son placeholders sin uso.

- Known issues de SFX de ataque: en Tux siguen mudos `power_attack` y `air_power_attack`; el hit suena al spawnear hitbox y el escudo suena hit aunque bloquee (`2026-11-25`).

- Audio centralizado y carga de ataques **IDEA / NO IMPLEMENTADO**: ver [docs/ideas/audio-y-combate.md](ideas/audio-y-combate.md) (`2026-11-25`).

- Heavy hitstun **KNOWN ISSUE / TUNEO**: el umbral actual no es una decisión fija; puede migrar a porcentaje de daño o a una propiedad dedicada para hitstun acumulativo (`2026-11-24`).

- UI full inglés **FALTA**: la UI ya trae textos en inglés sueltos (`Start`, `Controls`, `Back to menu`), pero siguen muchos literales en español en `.gd` y `.tscn` (`2026-11-21`).

- **FALTA** `NpcController`: Detección de posiciones con `AABB detection`.