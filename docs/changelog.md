# Changelog

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

#### `2026-11-08`
- `GameManager` **LISTO**: Que el manejo de vidas sea otro modulo. `LivesManager`
- `GameManager` **LISTO**: Que el manejo de tiempo limite o conteo de partida sea otro modulo. Posiblemente se llamara `MatchTime`.
- `GameManager` **LISTO**: Que el conteo regresivo para empezar a jugar, sea otro modulo. `MatchCountdown`
- `GameManager` **FALTA**: Modulo de manejo velocidad de juego. Para hacer efectos de velocidad lenta, o hacer un freaze al dar un golpe killer.
- `GameManager` **FALTA**: Que el manejo de HUD de juego sea otro modulo.

#### `2026-11-09`
- `GameManager` **LISTO**: `PowerFighterSlots` (usa `PowerFighterData`), información del como seran los peleadores, sus vidas, que tipo de peleadores seran etc. Remplazo `MatchSlots`.
- `GameManager` **FALTA**: Tratar `Person` (el papá) en vez de `PowerFighter`, para crecer a más modos de juego. (Por ahora `2026-11-10` medio enredado de hacer, pero posible)

- Helper de nombres **FALTA**: utilidad estática enfocada a `Person` (cubre `PowerFighter` y futuros hijos). Usará `Node.name` directamente; **no** se agrega una propiedad `name` nueva.

#### `2026-11-15`
> Refactor a **controladores por composición**: el rol (jugador/NPC) deja de ser herencia (`Player`/`NPC extends PowerFighter`) y pasa a ser un nodo hijo. Detalle del diseño en `docs/arquitectura/nota-power-fighter-controller.md` y de la IA en `docs/ia/nota-ai-npc.md`.

- `PersonController3D` **LISTO**: base `Node3D` que solo decide inputs. Expone `get_input(delta, frame) -> MoveInput` y guarda un `MoveInput` reutilizado. No conoce a `Person`/`Fighter`/`PowerFighter`. (`scripts/characters/person_controller_3d.gd`)
- `MoveInput` **LISTO**: `RefCounted` con los 10 flags (`move_left/right/up/down`, `jump`, `walk`, `attack`, `grab`, `shield`, `power_attack`). (`scripts/helpers/frame/move_input.gd`)
- `PlayerController` **LISTO**: lee `Input` con `player_input_map` según `player_id`. Ya reemplaza a `player.gd` en partida.
- `NpcController` **LISTO** (2026-11-16): trae la detección (`Area3D` propia), los helpers y los timers de `npc.gd`, y su `get_input()` migró el reset y la IA completa. Ya se usa en partida.
- `Person` **LISTO**: propiedad `controller` con setter que hace `add_child`; `_collect_controller_input`/`_process_controller`; `_physics_process` llama al controller. Los hooks viejos `_collect_input`/`_process_ai` se borraron (2026-11-16).
- `PowerFighter` **LISTO**: `_collect_controller_input` copia los 10 campos (la base de `Person` solo copia 6: movimiento + salto + caminar).
- `PowerFighterConfigurer` **LISTO** (2026-11-16): `PLAYER` -> `PlayerController.new()`; `NPC` -> `NpcController.new()`; `NONE` -> `pass`. (Queda `POWER_FIGHTER_SCRIPT` sin uso, pendiente de borrar.)
- `SpawnPoint`, `LivesManager`, `FightHUD` **LISTO**: `player_id`/`is Player` migrados al `PlayerController`.
- `standard_power_fighter.tscn` **LISTO**: root con `script = power_fighter.gd`, para que existan los `@export` sin `set_script`.
- `player.gd` **LISTO**: eliminado. `player_legacy.gd` también se borró (2026-11-16).

- SFX de personaje **EN PROGRESO**: bandera `_first_jump_frame` (seteada en `_move`) para disparar el sonido de salto; ya no se infiere de `last_force <= 0`. `_process_sound` asigna `stream_*` y hace `play()`, pero sigue con `print` de placeholder. Falta decidir 1 vs 3 `AudioStreamPlayer3D`.

- Limpieza de `Person` **LISTO**: fuera `@export material`/`mesh` y `_get_default_material()`; `_set_material`/`_set_mesh` -> públicas `set_material`/`set_mesh`, ahora sí aplican (`material_override`/`mesh`); `_ready` ya no asigna mesh/material y `GameManager` ya no asigna material.

#### `2026-11-16`
> Commit `70891cd`. `NpcController` queda funcional leyendo `JumpSignals`; se borran las clases legacy `npc.gd` y `player_legacy.gd`. Detalle en `docs/arquitectura/nota-power-fighter-controller.md` y `docs/ia/nota-ai-npc.md`.

- `JumpSignals` **LISTO**: `RefCounted` con `count`, `max`, `impulse` y `fall_acceleration`. Se quitó el prefijo `jump_` porque el objeto ya se llama `jump_signals`. Cuelga de `FrameMotionSignals.jump_signals` y `Person._build_frame` lo llena. (`scripts/helpers/frame/jump_signals.gd`)
- `NpcController` **LISTO**: `get_input()` migró el reset de `_input` y toda la IA (`frame.jump_signals.*` y `frame.holding_onto_the_ledge`). Se instancia con `NpcController.new()`.
- `PersonController3D.reset_input()` **LISTO**: baja los 10 flags del `MoveInput` reutilizado, para que no se queden pegados entre frames.
- `FrameMotionSignals` **LISTO**: se le agregó `jump_signals` y `holding_onto_the_ledge` (bool temporal) en `_defaults`/`_init`.
- `main_menu.gd` **LISTO**: slot de NPC de debug agregado.
- Legacy **LISTO**: `npc.gd` y `player_legacy.gd` eliminados.
- Hooks legacy de `Person` **LISTO**: `_collect_input` y `_process_ai` borrados; `_physics_process` ya solo llama `_process_controller(delta, _last_frame)`.
- Orilla en el frame **DECIDIDO**: mover `holding_onto_the_ledge` de bool suelto en `FrameMotionSignals` a `MoveStates.hanging` (encaja con los demás estados que sirven para animar). **FALTA** implementar.
- `POWER_FIGHTER_SCRIPT` **FALTA**: constante sin uso en `PowerFighterConfigurer`; borrar.
- Prueba en partida 1 player + 1 NPC **FALTA**: movimiento, recovery, vagabundeo y ataque por cercanía.
