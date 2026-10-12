# Arquitectura de personajes — `Person`, `Fighter` y `PowerFighter`

> Jerarquía real (aplicada) de los personajes. Reemplazó al viejo `Character` (ya borrado) con tres capas: `Person` (moverse y recibir daño), `Fighter` (dar trancazos) y `PowerFighter` (golpes con poder + doble salto). El mapa de clases completo vive en `docs/arquitectura/uml-arquitectura.md`.

## Jerarquía

```
CharacterBody3D
└─ GravityBody3D        → física: gravedad 2D + colisiones normales y entre cuerpos
   └─ Person            → moverse, saltar, agarrarse de orillas, recibir daño, respawn
	  └─ Fighter        → trancazos (FightMove), protegerse, agarres
		 └─ PowerFighter → doble salto + ataques de poder (`PowerAttacks`)
			├─ Player       → jugador real, con `player_id` e `input_map`
			└─ NPC          → con IA propia (`_process_ai`)
```

> `Character` (la clase vieja) y `OldFightMove` ya se borraron del proyecto (quedan en el historial de git).

---

## `GravityBody3D` — la física

Hijo de `CharacterBody3D`. No sabe pelear ni moverse: solo sabe de **gravedad 2D y colisiones**.

- **Gravedad 2D** (`_vertical_force(delta, multiplier = 1)`): imita gravedad en el eje Y, dentro de un mundo 3D. Devuelve `VerticalForceSignals` (`on_floor`, `on_ceiling`, `on_wall`, `air_count`, `force`).
- **Colisión con plataformas normales**: las de siempre, vía `move_and_slide()`.
- **Colisión entre cuerpos** (`_toggle_body_collisions`).
- **Medidas del cuerpo** (`get_width`, `get_height`, `_get_feet_position`, `_get_head_y`): derivadas del `$CollisionShape3D`.
- **No sabe de `OneWayPlatform`**: esa lógica vive en `Person` (ver abajo). Así la base queda limpia para cuerpos sin gameplay.
- Tiene un `_physics_process` default (gravedad + `move_and_slide()`) que sirve de ejemplo y de base para cuerpos sin gameplay (futuro ragdoll, por ejemplo).

## `Person` — el papá de todos

Hijo de `GravityBody3D`. Tiene los métodos y propiedades para **moverse y recibir daño**.

- **Moverse**: camina (`walking_speed`), corre (`running_speed`), camina agachado (crouch move), y salta (`jump_impulse`).
- **Multi-salto**: compatible con más de un salto, pero por defecto salta **una sola vez** (`_max_jumps = 1`). Los hijos lo cambian (`PowerFighter` pone 2).
- **Agarre de orillas** (`_ledge_grab`, `_hanging_ledge`, `_hang_position`): estilo Smash, solo `GroundPlatform` con esquinas tiene orillas agarrables. Colgado, arriba te subes con impulso y abajo te sueltas.
- **Vida y daño**: `hp` y `damage_percentage` (`@export`). Recibe golpes con `set_damage*`, knockback (`_damage_move`) y animación de daño (`_damage_anim`), incluyendo el giro "tumble" del cuerpo.
- **Respawn** (`respawn(at_position)`): limpia posición, velocidad, daño, saltos, orilla agarrada y orientación, para reaparecer como nuevo.
- **Entrada por capas**:
  - `_collect_input()` → **para players**. Por defecto es `pass`; lo llenan los hijos que leen teclado.
  - `_process_ai(delta, frame)` → **para NPCs**. Hook virtual (por defecto `pass`) que `NPC` sobreescribe; recibe el `FrameMotionSignals` del frame anterior (`_last_frame`). Ver `docs/ia/nota-ai-npc.md`.
- **Plataformas one-way** (`_one_way_platforms()`, `_get_floor_one_way()`, estado `_drop_through_count`, `_one_way_ignored`, `_last_floor_one_way`, `_one_way_coyote_count`): se atraviesan de abajo hacia arriba pero son sólidas al caer encima, con drop-through voluntario (tap abajo) y coyote time. Vive aquí y no en `GravityBody3D` porque depende del input (`_down_pressed`) y de Person; `Person` llama `_one_way_platforms(...)` justo antes de `_vertical_force(...)`.
- **Flancos de input**: `_up_pressed` / `_down_pressed` (con su memoria `_was_move_up` / `_was_move_down`) y `_was_jumping` para el salto. Sirven para drop-through y para acciones especiales simultáneas con dos teclas.
- **Disabled**: Estado en el cual esta incapacitado para moverse adecuadante el person (Solo puede moverse horizontalmente en el aire). Se desbloquea movimiento adecuado en el piso, por x tiempo, o porque se recibio input de moverse.
- **Knocked out**: Estado en cual esta inmobil el jugador por x cantidad de tiempo.

**Pipeline `_physics_process`** (vive en `Person`; los hijos no lo reescriben, sobreescriben los hooks `_process_*`). Cada hook es `pass` en `Person` salvo donde se indica:

```
_collect_input()                 # humano (NPC lo usa para limpiar bools)
_process_ai(delta, _last_frame)  # IA, con el frame ANTERIOR
frame = _build_frame(delta)      # gravedad + _move + _get_move_states
_tick_frame(delta, frame)        # orillas, cooldowns, dirección
_process_action(delta, frame)    # Fighter: ataque, shield, grab
_process_damage(delta, frame)    # stuns, knockout
_cancel_action(frame)            # Fighter
_process_visual(frame)           # Fighter
_animate(delta, frame)
_process_effects(delta)
_commit_frame(delta, frame)      # empuje, velocity, move_and_slide()
_last_frame = frame              # lo lee la IA el próximo frame
```

Por qué `_process_ai` va **antes** de construir el frame: la IA solo setea los mismos bools que el humano (`_move_left`, `_jump`, `_attack`...), y esos se consumen en el mismo `_physics_process`. Lee el frame anterior (`_last_frame`) para saber si estaba en el piso, colgado, etc.

**Pendiente**: morir cuando `hp` llega a 0 (ragdoll + respawn por KO). Hoy la muerte real es del `GameManager` cuando alguien se sale del área jugable.

## `Fighter` — el que pelea

Hijo de `Person`. Salta una sola vez (hereda `_max_jumps = 1`). Tiene los métodos para **dar trancazos, protegerse y agarrar**.

- **Dar trancazos**: catálogo `_attacks` (`Attacks`, 15 `FightMove`). `_fight_move()` elige el ataque según el estado de movimiento, lo sostiene mientras dure y spawnea/cierra el hitbox. `_spawn_hitbox(p_size, p_position, p_damage, p_direction)` crea un `Hitbox` como hijo del `Pivot`.
- **Protegerse** (`_shield_move`, `_with_shield()`, `_shield_defence()`): escudo con durabilidad (`_shield_time` vs `GameBalance.SHIELD_DURATION`) que **sí anula el daño** y se desgasta según el golpe, con blockstun, pushback y regeneración. Desde el escudo se puede rodar (`_roll_move`).
- **Agarres** (`_grab_move`, `grabbing_person()`, `_grabbing_move()`): en el piso spawnea un `HitboxGrab`; si conecta, la víctima queda `grabbed` y, al presionar izquierda/derecha, se le lanza con `set_thrown_move()`.

## `PowerFighter` — el que tiene poderes

Hijo de `Fighter`. Tiene **doble salto** (`_max_jumps = 2`, aplicado en `_init()`) y un catálogo `_power_attacks` (`PowerAttacks`, 6 `FightMove`: `standard`, `down`, `up` y sus versiones `air_*`), activado con el bool `_power_attack`.

**"Tercer salto"**: no es un salto del contador `_jump_count`. Es el ataque de poder hacia arriba (`up` / `air_up`, con `jump_power: 12.0`): `Fighter._fight_move()` aplica ese `jump_power` a `_target_velocity.y`. Cuando se agotan los saltos, el NPC lo dispara (`_move_up` + `_power_attack`) para recuperarse.

**Pendiente**: un poder propio por personaje; hoy todos comparten el mismo catálogo `_power_attacks`.

---

## Entrada de los hijos terminales

| Clase | `_collect_input` | Estado |
|---|---|---|
| `Player` | Lee `input_map` (`player1_*` / `player2_*`), incluye `walk`, `grab` y `shield` | Jugador real |
| `NPC` | Limpia todos los bools; luego `_process_ai` los llena | Con IA (ver abajo) |

## `NPC` — la IA

Hijo de `PowerFighter` (`scripts/characters/npc.gd`). No toca el gameplay: sobreescribe `_collect_input()` (limpia bools) y `_process_ai()` (los setea), así hereda ataques, escudo y saltos sin cambios.

- **Detección**: un `Area3D` hijo (`DetectionArea`, caja 16x9x0.5) revisado cada 0.1 s. Guarda `Platform` y `Person` cercanos (`_detected_platforms`, `_detected_persons`).
- **Recovery**: si está en el aire o colgado de una orilla, apunta a la plataforma más cercana (`_get_nearest_platform_position`), se mueve hacia ella y, si está por encima, activa `_turbo_jump`: salta en el piso, vuelve a saltar al llegar a la altura máxima estimada (`_calcule_max_jump_height_frames`) y, agotados los saltos, usa el ataque de poder hacia arriba (el "tercer salto").
- **Vagabundeo**: fuera del recovery, cambia dirección y velocidad (idle/run/walk/crouch) por temporizadores aleatorios.
- **Ataque**: si hay un `Person` muy cerca (`_get_very_close_person_position`, diferencia promedio XYZ <= 0.4), se queda quieto y ataca.

Detalle y por qué del hook en `docs/ia/nota-ai-npc.md`; plan de mejora de detección en `docs/ia/nota-npc-aabb-deteccion.md`.

## Estado

| Pieza | Person | Fighter | PowerFighter |
|---|---|---|---|
| Moverse / saltar / agacharse | ✅ | — | — |
| Ledge grab | ✅ | — | — |
| Recibir daño + knockback | ✅ | — | — |
| `respawn(at_position)` | ✅ | — | — |
| Trancazos (15 `FightMove`) | — | ✅ | — |
| Grab box + lanzar (throw) | — | ✅ | — |
| Shield (bloquear golpes) + roll | — | ✅ | — |
| Doble salto | — | — | ✅ |
| Ataques de poder (6 `FightMove`) + "tercer salto" (`up`) | — | — | ✅ |
| Poder propio por personaje | — | — | 🕓 |
| Muerte por `hp == 0` (ragdoll) | 🕓 (planeado) | — | — |
| Hook `_process_ai` para NPCs | ✅ (virtual; `NPC` lo implementa) | — | — |
