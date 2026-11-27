# Clase: `Person`

> `Person` (`scripts/characters/person.gd:1`) es la capa base de los peleadores: hereda `GravityBody3D` (`person.gd:2`) y concentra movimiento 2D en mundo 3D, saltos, orillas, one-way platforms, daño recibido, stuns, audio de movimiento y el pipeline del frame. No decide ataques (`Fighter`) ni rol (lo decide un `PersonController3D` hijo).
>
> Verificado contra el working tree el 2026-11-26.
>
> Rutas: `scripts/characters/person.gd`, `scripts/characters/gravity_body_3d.gd`, `scripts/characters/fighter.gd`, `scripts/characters/power_fighter.gd`, `scripts/match/power_fighter_configurer.gd`, `scripts/match/game_manager.gd`, `scripts/match/lives_manager.gd`, `scripts/match/spawn_point.gd`, `scripts/combat/hitbox_damage.gd`, `scripts/ui/fight_hud.gd`, `docs/arquitectura/arquitectura-personajes.md`, `docs/arquitectura/nota-power-fighter-configurer.md`, `docs/combate/nota-knockback-acumulativo.md`, `docs/arte/audio.md`.

## Resumen

`Person` es concreta, no abstracta. Dueña de `_physics_process()` (`person.gd:1262`); `Fighter` y `PowerFighter` no lo reescriben, solo sobreescriben hooks. El cfg no vive aquí: `PowerFighterConfigurer` le aplica `@export` y setters desde `.person.cfg` (`power_fighter_configurer.gd:76-95`). Esta ficha describe el estado actual para refactor; la jerarquía y los contratos de cfg siguen en [arquitectura-personajes.md](arquitectura-personajes.md) y [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md).

## Superficie pública

| Símbolo | Línea orientativa | Quién lo usa | Nota |
|---|---|---|---|
| `id` (`@export`) | `person.gd:18` | `_apply_person_config()` (`power_fighter_configurer.gd:79`), `FightHUD._fighter_name()` (`fight_hud.gd:264`) | Identidad técnica. El prefab trae `&"standard"`. |
| `init_looking_at_right` (`@export`) | `person.gd:23` | `_get_initial_facing()` (`person.gd:191`), `SpawnPoint.spawn()` (`spawn_point.gd:7`, facing en `spawn_point.gd:29`) | Orientación inicial; también se reaplica en `respawn()`. |
| `walking_speed`, `running_speed`, `jump_impulse` (`@export`) | `person.gd:21-26` | `_apply_person_config()` (`power_fighter_configurer.gd:90-92`), `_move()` (`person.gd:546-584`) | Defaults 3 / 8 / 10. `jump_impulse` también se mete en `JumpSignals` (`person.gd:1032`). |
| `hp`, `damage_percentage` (`@export`) | `person.gd:29-30` | `set_damage()` (`person.gd:753`), `FightHUD` (`fight_hud.gd:194`), `GameManager` (`game_manager.gd:148-153`), `Fighter._shield_defence()` (`fighter.gd:744`) | `hp` baja con cada golpe; la HUD y el ranking leen el porcentaje. Muerte por `hp == 0` sigue pendiente. |
| `walk_step_interval`, `run_step_interval`, `crouch_move_step_interval` (`@export`) | `person.gd:33-35` | `_apply_person_config()` (`power_fighter_configurer.gd:93-95`), `_get_step_interval()` (`person.gd:1158`) | Cadencia de pasos; `0.0` significa "sin sonido de paso". |
| `stream_jump`, `stream_step`, `stream_land`, `stream_hit` (`@export`) | `person.gd:38-41` | `_movement_sounds()` (`person.gd:1182-1197`) | `AudioStreamRandomizer`; un solo `AudioStreamPlayer3D` en `person.gd:59`. Detalle en [audio.md](../arte/audio.md). |
| `block_move` | `person.gd:44` | Solo el comentario de `GameManager._set_power_fighters_frozen()` (`game_manager.gd:175`) | Sin lectores reales. El congelamiento usa `process_mode`, no este flag. |
| `grabbed` | `person.gd:119` | `Fighter` (`fighter.gd:831-854`), `_block_inputs()` (`person.gd:448`), `_not_normal_move_anim()` (`person.gd:1109`) | Lo escribe `Fighter`; `Person` lo lee para inputs, animación y KO. |
| `controller` | `person.gd:168-178` | `create()` (`power_fighter_configurer.gd:47-49`), `SpawnPoint` (`spawn_point.gd:23`), `LivesManager` (`lives_manager.gd:108-112`), `FightHUD` (`fight_hud.gd:123-124`) | El setter libera el controller anterior y mete el nuevo como hijo. Lo consume `_process_controller()` (`person.gd:1257`). |
| `set_material()` | `person.gd:223` | Llamada comentada en `game_manager.gd:97` | Asigna `_mesh_instance.material_override` (`person.gd:231`); hoy nadie la invoca en caliente. |
| `set_mesh()` | `person.gd:233` | Sin llamadas; el cfg reemplaza el modelo en `_build_instance()` (`power_fighter_configurer.gd:56-71`) | Cambia `_mesh_instance.mesh` y depende de que `_ready()` ya haya resuelto nodos. |
| `respawn()` | `person.gd:241` | `LivesManager.respawn()` (`lives_manager.gd:85`) | Reinicia posición, `_target_velocity`, daño, saltos, `grabbed`, stuns, orilla y first frames (`person.gd:262`). |
| `set_damage()` | `person.gd:753` | `HitboxDamage` (`hitbox_damage.gd:29`), `set_thrown_move()` (`person.gd:826`) | Si no hay inmunidad: baja hp, suma porcentaje y dispara knockback/hitstun vía `_set_damage_move()`. |
| `set_thrown_move()` | `person.gd:819` | `Fighter._grabbing_move()` (`fighter.gd:876`) | Limpia heavy, saca `grabbed`, llama `set_damage(damage)` sin dirección y luego sobrescribe `_knockback_direction`; fija hitstun base + heavy. |
| `set_momentum()` | `person.gd:1305` | `_apply_person_config()` (`power_fighter_configurer.gd:83`) | Cuatro floats: aceleración/fricción en piso, aceleración en aire y fricción de knockback. |
| `set_duration_of_anims()` | `person.gd:1313` | `_apply_person_config()` (`power_fighter_configurer.gd:82`) | Escribe `_air_jump_duration`. |
| `set_anim_offset()` | `person.gd:1316` | `_apply_person_config()` (`power_fighter_configurer.gd:88`) | Escribe `_hanging_anim_offset`, usado al anclar la orilla (`person.gd:356-358`). |

## Hooks y pipeline

Orden exacto de `_physics_process()` (`person.gd:1262-1301`):

```text
_process_controller(delta, _last_frame)   # person.gd:1267
_build_frame(delta)                       # person.gd:1270
_tick_frame(delta, frame)                 # person.gd:1271
_process_action(delta, frame)             # person.gd:1274
_process_damage(delta, frame)             # person.gd:1277
_cancel_action(frame)                     # person.gd:1280
_process_visual(frame)                    # person.gd:1283
_animate(delta, frame)                    # person.gd:1286
_process_first_frame_of_event(delta, frame) # person.gd:1289
_process_effects(delta)                   # person.gd:1292
_process_sound(delta, frame)              # person.gd:1295
_commit_frame(delta, frame)               # person.gd:1298
_last_frame = frame                       # person.gd:1301
```

`_build_frame()` (`person.gd:1020`) corre one-way → `_vertical_force()` → `_move()` → `_get_move_states()` (`person.gd:1025-1030`). `_commit_frame()` (`person.gd:1133`) empuja bodies, copia `_target_velocity` a `velocity`, hace `move_and_slide()` y fija la Z. `_last_frame` (`person.gd:162`) se asigna al final para que lo lea el controller en el próximo frame.

Hooks overridables por `Fighter`:

- `_false_inputs()` (`person.gd:450`) → `fighter.gd:329`, y `power_fighter.gd:133` suma `_power_attack = false`.
- `_reset_counts_by_impact()` (`person.gd:1040`) → `fighter.gd:909`.
- `_reset_counts_by_move_state()` (`person.gd:1046`) → `fighter.gd:913`.
- `_process_action()` (`person.gd:1214`) → `fighter.gd:920`.
- `_cancel_action()` (`person.gd:1220`) → `fighter.gd:985`.
- `_process_visual()` (`person.gd:1226`) → `fighter.gd:1043`.
- `_attack_sounds()` (`person.gd:1232`) → `fighter.gd:1046`.
- `_need_another_middle_stun()` (`person.gd:1236`) → `fighter.gd:1005` (blockstun de escudo).
- `_not_normal_move_anim()` (`person.gd:1097`) → `fighter.gd:1011`.
- `_clean_first_frame_of_event()` (`person.gd:1240`) → `fighter.gd:1057`.

`_process_stun()` (`person.gd:1066`) está centralizado en `Person` y `Fighter` ya no lo sobrescribe: el punto de extensión es `_need_another_middle_stun()` (`person.gd:1078`). La cadena es hitstun → heavy → hook → hard landing, con `_first_frame_on_foot = false` al entrar (`person.gd:1071`).

## Estado interno y game feel

- **Movimiento/salto**: aceleraciones y fricciones `person.gd:70-73`; `_max_jumps` / `_jump_count` `person.gd:76-77`; animación de salto aéreo `person.gd:64-67`; compuertas `_horizontal_move` / `_allow_jump` `person.gd:93-94`; dirección y facing `person.gd:85-87` (`_set_x_not_zero_value()` en `person.gd:209`).
- **Flancos de input y buffer**: `_walk`, `_move_*`, `_jump` `person.gd:122-129`; memoria `_was_*` y flancos `_down_pressed` / `_up_pressed` / `_left_pressed` / `_right_pressed` `person.gd:136-144`; `_direction_buffer_timer` `person.gd:147`. El cálculo vive en `_move()` (`person.gd:479-503`) y `GameBalance.INPUT_BUFFER_WINDOW`.
- **Ledges**: `_hanging_ledge`, `_hanging_right_side`, `_hang_position`, `_ledge_release_count` `person.gd:150-153`; `_hanging_anim_offset` `person.gd:181`; soltar `person.gd:267`; agarrar por zona espacial `person.gd:276-360`.
- **One-way platforms**: `_drop_through_count`, `_one_way_ignored`, `_last_floor_one_way`, `_one_way_coyote_count` `person.gd:156-159`; resolución en `_one_way_platforms()` (`person.gd:382-441`).
- **Daño / hitstun / heavy / KO / grabbed**: `_normal_damage_power`, `_knockback_direction`, `_hitstun_time`, `_knockback_decay_time`, `_damage_degrees`, `_last_damage`, `_last_damage_percentage`, `_taking_damage_count` `person.gd:97-104`; `_heavy_hitstun_*` `person.gd:107-109`; `_knockout_time` `person.gd:132`; `grabbed` `person.gd:119`; inmunidad y parpadeo `person.gd:115-116`. El knockback hoy se reinicia por golpe; ver [nota-knockback-acumulativo.md](../combate/nota-knockback-acumulativo.md).
- **Hard landing**: `_hard_landing_time` `person.gd:112`, active check `person.gd:838`, descuento `person.gd:841`, detección por fuerza/tiempo de caída en `_move()` `person.gd:592-611`.
- **`_first_frame_on_foot`**: declarado en `person.gd:187`. Se prende al terminar (o cancelarse fuera del piso) el hard landing en `_apply_hard_landing()` (`person.gd:844`) y al completar el get-up del heavy hitstun en `_heavy_hitstun_get_up_move()` (`person.gd:908`). Se consulta en `can_jump`, dentro de `_move()` (`person.gd:484`), y se limpia en `_process_stun()` (`person.gd:1071`) y en `_clean_first_frame_of_event()` (`person.gd:1242`). Su propósito es de game feel: si el jugador traía el input de salto sostenido durante el stun o el aterrizaje, ese frame no debe leerse como flanco nuevo apenas se levanta; el frame siguiente ya puede saltar con el mismo botón.
- **Audio**: `_step_time` / `_was_stepping` `person.gd:47-48`, `_get_step_interval()` `person.gd:1158`, `_movement_sounds()` `person.gd:1164`, `_process_sound()` `person.gd:1205`. Los first frames de daño y caída se calculan en `_process_first_frame_of_event()` (`person.gd:1145-1155`), pero `_first_jump_frame` sigue calculándose en `_move()` (`person.gd:582`) y se consume en audio `person.gd:1191`.

## Invariantes

- **`$CollisionShape3D`**: lo exige `GravityBody3D._ready()` (`gravity_body_3d.gd:112-115`). De ahí salen `get_width()`, `get_height()`, `_get_feet_position()` y `_get_head_y()` (`gravity_body_3d.gd:24-41`, `gravity_body_3d.gd:104-109`).
- **`_target_velocity`**: pertenece a `GravityBody3D` (`gravity_body_3d.gd:14`). `Person` la escribe en `_move()` (`person.gd:568`), `_apply_hitstun()` (`person.gd:856-861`), `respawn()` (`person.gd:247`) y `_commit_frame()` (`person.gd:1139`); `velocity` solo se asigna en el commit (`person.gd:1139`).
- **Z segura**: `_safe_z_coord` (`person.gd:51`) se captura en `_ready()` (`person.gd:1002`) y se fuerza en `_ensure_safe_z_coord()` (`person.gd:964`), llamado desde `_commit_frame()` (`person.gd:1141`).
- **Jerarquía del modelo**: `Visual → get_child(0) → Pivot → Skeleton3D → MeshInstance3D`, con `AnimationPlayer` hijo del modelo (`person.gd:1008-1013`). `_build_instance()` (`power_fighter_configurer.gd:56-71`) depende del mismo orden. Contrato en [asset-personaje.md](../arte/asset-personaje.md).
- **`standard` sin cfg**: es base/dummy a propósito; no migrar sus defaults a cfg "por higiene". Detalle y invariante completa en [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md).

## Deudas / puntos de refactor

- `block_move` (`person.gd:44`) no lo lee nadie; `GameManager` lo menciona solo para decir que no lo usa (`game_manager.gd:175`). Decidir si se elimina o se integra en `_block_inputs()` (`person.gd:448`).
- Comparaciones float exactas: `_air_count == delta` (`person.gd:527`) y `_taking_damage_count == delta` (`person.gd:1151`). Con `delta` variable son frágiles; mejor contador explícito o `is_zero_approx()`.
- `_false_inputs()` (`person.gd:450-459`) limpia dirección, `_jump` y flancos, pero no limpia `_walk` (lo escribe `_collect_controller_input()` en `person.gd:1254`). `Fighter` suma `_attack` / `_grab` (`fighter.gd:329-333`) y `PowerFighter` suma `_power_attack` (`power_fighter.gd:133-135`); falta una única lista de inputs a cancelar.
- Caída rápida aplicada un frame después: `_build_frame()` consume `_fall_acceleration_multiplier` y `_last_can_down_hard` en `_one_way_platforms()` / `_vertical_force()` (`person.gd:1025-1028`), pero ambos se calculan en `_move()`, que corre después (`person.gd:521-534`). El empujoncito de drop-through y la gravedad x2 llegan un frame tarde.
- `_push_bodies_apart()` (`person.gd:969-993`) muta `collider.position.x` ajeno; el propio doc lo tilda de "muy tosco" (`person.gd:972`) y propone un `set_push_move` público (`person.gd:974`).
- Prints de debug: `_movement_sounds()` (`person.gd:1202`) y el cálculo de hard landing (`person.gd:610-611`); además `HitboxDamage` (`hitbox_damage.gd:28`). [audio.md](../arte/audio.md) ya lo marca como known issue.
- Centralización de first frames incompleta: `_process_first_frame_of_event()` (`person.gd:1145`) solo calcula daño y caída; `_first_jump_frame` sigue en `_move()` (`person.gd:582`) y `_first_frame_on_foot` se reparte entre hard landing, get-up y `_process_stun()` (`person.gd:844`, `person.gd:908`, `person.gd:1071`). Además `_clean_first_frame_of_event()` (`person.gd:1240`) solo se llama desde `respawn()` (`person.gd:262`), aunque su doc diga que se usa en `_process_first_frame_of_event()`; `Fighter` mantiene los suyos en `fighter.gd:325-326`.

## Ver también

- [clase-fighter.md](clase-fighter.md) — ficha de estado de `Fighter`, el primer consumidor de hooks.
- [clase-power-fighter.md](clase-power-fighter.md) — ficha de estado de `PowerFighter`, doble salto y power attacks.
- [arquitectura-personajes.md](arquitectura-personajes.md) — jerarquía `Person` / `Fighter` / `PowerFighter`.
- [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md) — contratos de `.cfg`, `standard` sin cfg y orden de nodos.
- [nota-knockback-acumulativo.md](../combate/nota-knockback-acumulativo.md) — deuda del reset de knockback en `set_damage()`.
- [audio.md](../arte/audio.md) — SFX placeholders, prioridad de streams y print pendiente.
- [nota-power-fighter-controller.md](nota-power-fighter-controller.md) — rol por nodo hijo y uso de `_last_frame`.
- [asset-personaje.md](../arte/asset-personaje.md) — contrato de nodos del `.glb`.
- [uml-arquitectura.md](uml-arquitectura.md) — mapa de clases completo.
