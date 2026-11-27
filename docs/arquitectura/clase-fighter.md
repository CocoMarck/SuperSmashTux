# Clase: `Fighter`

> Capa de combate de los peleadores: elige y ejecuta `FightMove`, spawnea hitboxes de daño, sostiene escudo/rodada y agarra/lanza a la víctima. Es hija de `Person` (`fighter.gd:1-2`) y base de `PowerFighter`; el rol (jugador/NPC) vive en un controller hijo, no en la herencia.
> Verificado contra el working tree el 2026-11-26.
> Rutas: `scripts/characters/fighter.gd`, `scripts/characters/person.gd`, `scripts/characters/power_fighter.gd`, `scripts/helpers/combat/fight_move.gd`, `scripts/helpers/characters/character_registry.gd`, `scripts/combat/hitbox_grab.gd`, `scripts/match/power_fighter_configurer.gd`, `scripts/ui/fight_hud.gd`, `docs/combate/nota-ataques.md`, `docs/combate/hitbox.md`, `docs/combate/normal-and-power-attacks-moves.md`, `docs/arquitectura/arquitectura-personajes.md`, `docs/arquitectura/nota-power-fighter-configurer.md`.

## Resumen

`Fighter` es la clase que "pelea". `Person` aporta física, movimiento, daño recibido y el ciclo de frame; `Fighter` se engancha a ese ciclo con hooks para meter ataque, escudo, grab y audio. `PowerFighter` hereda de aquí y agrega poderes. Esta ficha es un mapa de estado para el refactor: no repite el contrato de hitbox ni el de configuración, que ya están en los docs enlazados.

## Superficie pública

| Símbolo | Línea orientativa | Nota |
|---|---|---|
| `stream_attack: AudioStreamRandomizer` | `fighter.gd:8` | `@export` propio del grupo `SFX`. Lo usan las dos listas de sonido de ataque. |
| `fight_moves_with_simple_sound: Array[StringName]` | `fighter.gd:12` | `@export` propio. Suena en el primer frame del ataque. |
| `fight_moves_with_hitspawn_sound: Array[StringName]` | `fighter.gd:16` | `@export` propio. Suena al spawnear cada hitbox. |
| `attacks: Attacks` | `fighter.gd:63` | Catálogo público de 15 `FightMove` del moveset normal. `PowerFighterConfigurer` lo reemplaza por asignación directa (`power_fighter_configurer.gd:107`). Los nombres están en [normal-and-power-attacks-moves.md](../combate/normal-and-power-attacks-moves.md). |
| `get_shield_ratio()` | `fighter.gd:760` | API para el HUD (`fight_hud.gd:195`). Devuelve el escudo normalizado. |
| `grabbing_person(p_person, p_hitbox_grab)` | `fighter.gd:821` | API invocada por `HitboxGrab` (`hitbox_grab.gd:54`) cuando conecta. Bloquea inputs de la víctima. |
| `_attack`, `_grab`, `_shield` | `fighter.gd:20-22` | Flags privados por nombre, pero escritos por la subclase en `PowerFighter._collect_controller_input()` (`power_fighter.gd:163-166`). |
| `grabbed` (heredado) | `person.gd:119` | Lo escribe el ciclo de grab de `Fighter` y lo leen `_cancel_attack()` y `_grabbing_move()`. |
| `_current_attack` | `fighter.gd:58` | Estado interno, pero lo consume el hook `_init_power_attack_by_move()` en `PowerFighter` (`power_fighter.gd:143-153`). |

## Hooks y pipeline

El `_physics_process` **sigue en `Person`** (`person.gd:1262-1301`). `Fighter` no lo redefine: se cuelga de los hooks que `Person` deja `pass`/vacíos (`person.gd:1213-1245`). El orden real es controller → frame → acciones → daño → cancelación → visual → animación → first frames → efectos → sonido → commit.

Sobrescrituras presentes en `Fighter`:

| Hook | Línea | Qué mete |
|---|---|---|
| `_false_inputs()` | `fighter.gd:329` | Apaga `_attack` y `_grab`; conserva `_shield` a propósito para absorber golpe al poner escudo. |
| `_reset_counts_by_impact()` | `fighter.gd:909` | Reinicia `_attack_jump_count` al recibir impacto (`person.gd:1061`). |
| `_reset_counts_by_move_state()` | `fighter.gd:913` | Resetea y hace tick del combo neutral. |
| `_process_action()` | `fighter.gd:920` | Aquí vive el ciclo de pelea: grab, shield, roll, `_fight_move()`, bloqueo de inputs. |
| `_cancel_action()` | `fighter.gd:985` | Cancela por daño, orilla, rodada, grab o KO; excepción de heavy hitstun en aire. |
| `_need_another_middle_stun()` | `fighter.gd:1005` | Mete blockstun de escudo dentro de `_process_stun()` (`person.gd:1078`). |
| `_not_normal_move_anim()` | `fighter.gd:1011` | Rama de animaciones especiales antes que el movimiento normal. |
| `_process_visual()` | `fighter.gd:1043` | Visibilidad y tamaño del mesh del escudo. |
| `_attack_sounds()` | `fighter.gd:1046` | Dispara `stream_attack` según las dos listas exportadas. |
| `_clean_first_frame_of_event()` | `fighter.gd:1057` | Llama a `super()` y limpia los dos first frames locales. |

Además, `_ready()` (`fighter.gd:893`) llama a `super()` y prepara el mesh del escudo y `_neutral_combo_attacks`.

`Fighter` ya no sobrescribe `_process_attack` ni `_process_stun` como hooks de `Person`: `_process_stun()` sigue en `person.gd:1066` y `Person` no define `_process_attack()`. Lo que hay es un **helper propio**, `Fighter._process_attack()` (`fighter.gd:459`), invocado desde `_set_attack()` (`fighter.gd:477`). Ojo: `../combate/nota-ataques.md:221` describe un override de `_process_attack()` en `PowerFighter` que ya no corresponde al código actual.

Hook propio para la extensión: `_init_power_attack_by_move(direction_buffered, states)` (`fighter.gd:455`) queda con `pass` y se llama justo después de `_init_attack_by_move()` (`fighter.gd:465-466`). `PowerFighter` lo implementa (`power_fighter.gd:138-153`) y puede pisar el ataque normal cuando `_power_attack` está activo.

## Estado interno y game feel

- **Ciclo de ataque**: `_process_action()` (`fighter.gd:920`) → `_fight_move()` (`fighter.gd:533`) → `_set_attack()` (`fighter.gd:468`) → `_cancel_attack()` (`fighter.gd:488`) → ejecución en `_fight_move()` (`fighter.gd:552-620`). `_set_attack()` exige `_attack` y `_current_attack == null`, elige por `MoveStates`, reinicia `_attack_count`, limpia `_spawned_hitbox_ids` y apaga la anim de air jump (`fighter.gd:423-485`). El detalle de selección y timing está en [nota-ataques.md](../combate/nota-ataques.md).
- **Gate `_can_attack()`** (`fighter.gd:417-421`): bloquea iniciar ataque mientras `_having_to_detect_attack_jump` y el último ataque sea saltarín; en el primer frame en piso libera el flag.
- **Castigo por ataque saltarín**: se detecta con `jump_power > 0` en `_is_attack_jump()` (`fighter.gd:411`). En el primer frame se guardan `_last_attack` y `_having_to_detect_attack_jump` (`fighter.gd:623-625`). En ejecución, si pasa el límite se corta el ataque (`fighter.gd:569-571`); si no, aplica `jump_power` a `_target_velocity.y`, fuerza dirección y agota los saltos (`fighter.gd:574-591`).
- **Conteo/límite de attack jumps**: `_attack_jump_count` (`fighter.gd:60`), `_attack_jump_limit_reached()` (`fighter.gd:409`), incremento en first frame (`fighter.gd:566-567`) y reseteos al tocar piso (`fighter.gd:544-545`), al recibir impacto (`fighter.gd:909-911`) y al colgarse de una orilla (`fighter.gd:981-983`).
- **Combo neutral**: `_neutral_combo_attacks` se arma en `_ready()` (`fighter.gd:905`) con las referencias de `attacks.neutral1/2/3`; `_process_neutral_combo()` (`fighter.gd:522`) cuenta en el primer frame, y `_reset_neutral_combo_count()` / `_tick_neutral_combo_reset()` (`fighter.gd:514-520`) lo reinician por estado o por tiempo.
- **Spawn de hitboxes**: por cada `HitboxMove`, `get_time_ratio()` (`fight_move.gd:83`) define la ventana y `_spawn_hitboxes_damages()` (`fighter.gd:336`) crea el `HitboxDamage`. Los ids se controlan con `_spawned_hitbox_ids` (`fighter.gd:322`), limpios al arrancar ataque (`fighter.gd:484`) y con guard de spawn en `fighter.gd:617-620`. Contrato completo en [hitbox.md](../combate/hitbox.md).
- **Limpieza**: `_clear_hitboxes_damages()` (`fighter.gd:371`) hace `queue_free()` de los hitboxes no-gravedad y vacía el arreglo; `_clean_hitboxes_damages()` (`fighter.gd:382`) solo filtra referencias nulas del arreglo. No son intercambiables.
- **Shield / blockstun / pushback / regeneración**: `_with_shield()` (`fighter.gd:766`) define cuándo está activo; `_shield_defence()` (`fighter.gd:737`) anula daño y cobra duración; `_shield_blockstun_active()` (`fighter.gd:671`) y `_apply_shield_pushback()` (`fighter.gd:748`) gobiernan el bloqueo; `_shield_regeneration()` (`fighter.gd:674`) y `_shield_move()` (`fighter.gd:693`) manejan desgaste y recarga.
- **Roll**: `_roll_move()` (`fighter.gd:781`) elige forward/backward, cobra escudo y da inmunidad a daño y colisión de cuerpo (`fighter.gd:799-812`); `_rolling()` (`fighter.gd:778`) y `_roll_anim()` (`fighter.gd:814`) son sus consultas/visual.
- **Grab / lanzamiento**: `_grab_move()` (`fighter.gd:641`) spawnea `HitboxGrab` en el piso; `grabbing_person()` (`fighter.gd:821`) coloca a la víctima; `_grabbing_move()` (`fighter.gd:860`) cancela el agarre o llama `set_thrown_move()` (`person.gd:819`) al presionar dirección.
- **Prioridad de animaciones**: `_not_normal_move_anim()` (`fighter.gd:1011-1041`) decide en orden hitstun, heavy hitstun, KO, grabbed, hard landing, orilla, ataque, roll, grab y escudo; si nada aplica, `Person` usa la anim de movimiento (`person.gd:1125-1126`).
- **SFX de ataque**: `_attack_sounds()` (`fighter.gd:1046`) usa `fight_moves_with_simple_sound` en `_first_attack_frame` y `fight_moves_with_hitspawn_sound` en `_first_frame_of_spawned_hitbox`, ambos con `stream_attack`.

## First frames locales

`Fighter` tiene dos first frames propios que **no están centralizados en `Person`**:

| Flag | Declaración | Se prende | Se apaga |
|---|---|---|---|
| `_first_attack_frame` | `fighter.gd:325` | `fighter.gd:552` (`_attack_count == 0`) | `fighter.gd:948` y `fighter.gd:1060` |
| `_first_frame_of_spawned_hitbox` | `fighter.gd:326` | `fighter.gd:620` | `fighter.gd:949` y `fighter.gd:1059` |

`Person._process_first_frame_of_event()` (`person.gd:1145-1155`) solo calcula daño y caída al piso; el salto se calcula en `_move()` (`person.gd:582`) y `on_foot` se prende en hard landing, get-up y `_process_stun()` (`person.gd:844`, `person.gd:908`, `person.gd:1071`). Su `_clean_first_frame_of_event()` (`person.gd:1240-1245`) limpia los suyos. El hook de `Fighter` (`fighter.gd:1057-1060`) llama a `super()` y remata los dos flags de arriba. Cualquier refactor que centralice first frames tiene que contemplarlos.

## Invariantes

- **Un ataque activo**: `_current_attack` es un solo `FightMove`; `_set_attack()` sale temprano si ya hay uno (`fighter.gd:468-473`). No hay encolado de ataques: el input durante un ataque se pierde.
- **Ids de hitbox únicos por ataque**: `_spawned_hitbox_ids` se limpia al iniciar cada ataque (`fighter.gd:484`) y evita spawnear dos veces el mismo `id` (`fighter.gd:617-619`). Ataques con varios hitboxes dependen de ids distintos.
- **Grab / shield / roll excluyen ataque**: `_process_action()` anula `_current_attack` y limpia hitboxes si hay grab, escudo o rodada (`fighter.gd:932-956`); `_cancel_attack()` también lo anula si está agarrando o agarrado (`fighter.gd:498-500`).
- **`standard` sin cfg**: es base/dummy jugable a propósito; sus defaults viven en código y en el prefab, no en `.cfg`. Detalle y motivo en [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md).
- **Config por asignación directa sin validación profunda**: `attacks` y las listas de sonido son públicas; el configurador las asigna y no valida cada `FightMove` (`power_fighter_configurer.gd:107`). Contrato completo en [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md).

## Deudas / puntos de refactor

- **Hitboxes con `use_gravity` no se liberan en `_clear_hitboxes_damages()`**: se crean como hijos de `current_scene` (`fighter.gd:361-369`), pero la limpieza solo hace `queue_free()` a los que no usan gravedad (`fighter.gd:371-380`). Quedan a merced de su `lifetime`/escena, incluso al cancelar ataque o respawnear.
- **Dirección Y del hitbox escalada `*0.1`**: magic number en `fighter.gd:614` (`direction.y = hitbox_move.direction.y * 0.1`). Conviene moverlo a data o a una constante con nombre antes de tocar tuneo.
- **`grab_attack` / `immortal` en data sin aplicación clara**: existen en `FightMove` (`fight_move.gd:38`, `fight_move.gd:41`), el loader los lee del cfg (`character_registry.gd:177`, `character_registry.gd:182`, `character_registry.gd:193-196`) y los defaults del catálogo los ponen en `false`, pero el ciclo de `Fighter` nunca los consulta. El grab real sale del input `_grab`, no de un `FightMove`.
- **Prints de debug**: `print(_current_attack.jump_power)` (`fighter.gd:576`) y `print(_current_attack.name)` (`fighter.gd:626`) siguen en la ruta caliente del ataque.
- **Castigo de ataque saltarín colgable**: si el aterrizaje ocurre recibiendo daño, `_first_frame_on_floor` queda en `false` porque `Person` lo excluye con `not taking_damage()` (`person.gd:1152-1155`). Como `_can_attack()` solo libera `_having_to_detect_attack_jump` en ese first frame (`fighter.gd:419-421`), el flag se queda prendido y bloquea nuevos ataques hasta otro aterrizaje limpio.

## Ver también

- [clase-person.md](clase-person.md) — base de movimiento, daño recibido y pipeline del frame.
- [clase-power-fighter.md](clase-power-fighter.md) — extensión con poderes y hook `_init_power_attack_by_move()`.
- [arquitectura-personajes.md](arquitectura-personajes.md) — jerarquía `Person` → `Fighter` → `PowerFighter` y papel de cada capa.
- [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md) — configuración por `.cfg`, defaults de `standard` y contrato de `attacks`.
- [nota-ataques.md](../combate/nota-ataques.md) — ciclo detallado del ataque, selección por `MoveStates` y cancelaciones.
- [hitbox.md](../combate/hitbox.md) — construcción y ciclo de vida de `HitboxDamage` / `HitboxGrab`.
- [normal-and-power-attacks-moves.md](../combate/normal-and-power-attacks-moves.md) — nombres de los movimientos normales y de poder.
- [nota-power-fighter-controller.md](nota-power-fighter-controller.md) — de dónde salen `_attack`, `_grab` y `_shield`.
- [uml-arquitectura.md](uml-arquitectura.md) — mapa de clases completo.
