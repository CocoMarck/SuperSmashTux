# Arquitectura de personajes — `Person`, `Fighter` y `PowerFighter`

> Jerarquía real (aplicada) de los personajes. Divide el viejo `Character` en tres capas: `Person` (moverse y recibir daño), `Fighter` (dar trancazos) y `PowerFighter` (golpes con poder + doble salto). El mapa de clases completo vive en `docs/uml-arquitectura.md`.

## Jerarquía

```
CharacterBody3D
└─ GravityBody3D        → física: gravedad 2D + colisiones (normales y OneWayPlatform)
   └─ Person            → moverse, saltar, agarrarse de orillas, recibir daño, respawn
      └─ Fighter        → trancazos (FightMove), protegerse, agarres
         └─ PowerFighter → doble salto + (pendiente) poderes
            ├─ Player       → jugador real, con `player_id` e `input_map`
            ├─ TestPlayer   → jugador de prueba, input directo `player1_*`
            └─ NPC          → sin IA todavía (placeholder que salta)
```

> `Character` (`scripts/character.gd`) es la clase vieja: ya nadie la extiende. `OldFightMove` (`scripts/helpers/old_fight_move.gd`) es el antepasado de `FightMove`. Ambos son legacy.

---

## `GravityBody3D` — la física

Hijo de `CharacterBody3D`. No sabe pelear ni moverse: solo sabe de **gravedad 2D y colisiones**.

- **Gravedad 2D** (`_vertical_force(delta, ignore_one_way_platforms, multiplier)`): imita gravedad en el eje Y, dentro de un mundo 3D. Devuelve `VerticalForceSignals` (`on_floor`, `on_ceiling`, `on_wall`, `air_count`, `force`).
- **Colisión con plataformas normales**: las de siempre, vía `move_and_slide()`.
- **Colisión con `OneWayPlatform`**: se atraviesan de abajo hacia arriba pero sólidas al caer encima, con drop-through voluntario y coyote time.
- **Medidas del cuerpo** (`_get_feet_position`, `_get_body_half_height`): derivadas del `$CollisionShape3D`.
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
  - `_ai_process(signals)` → **para NPCs**. Propuesto, ver `docs/nota-ai-npc.md`. Aún no existe en el código.
- **Flancos de input**: `_up_pressed` / `_down_pressed` (con su memoria `_was_move_up` / `_was_move_down`) y `_was_jumping` para el salto. Sirven para drop-through y para acciones especiales simultáneas con dos teclas.

**Pipeline `_physics_process`** (vive en `Person`, los hijos lo sobreescriben para meter su gameplay):

```
_collect_input()
_vertical_force(delta, _down_pressed, _fall_acceleration_multiplier)  # gravedad + one-way
_move(delta, gravity_signals)                                         # velocidad + salto
_get_move_states(move_signals)                                        # estados de movimiento
_ledge_grab(delta, gravity_signals, move_signals)                     # orillas
_damage_move / _damage_anim / _ledge_grab_anim / _move_anim           # daño y animación
_set_pivot_direction(move_signals)
velocity = _target_velocity; move_and_slide()
```

**Pendiente**: morir cuando `hp` llega a 0 (ragdoll + respawn por KO). Hoy la muerte real es del `GameManager` cuando alguien se sale del área jugable.

## `Fighter` — el que pelea

Hijo de `Person`. Salta una sola vez (hereda `_max_jumps = 1`). Tiene los métodos para **dar trancazos, protegerse y agarrar**.

- **Dar trancazos**: catálogo `_attacks` (`Attacks`, 13 `FightMove`). `_fight_move()` elige el ataque según el estado de movimiento, lo sostiene mientras dure y spawnea/cierra el hitbox. `_spawn_hitbox(p_size, p_position, p_damage, p_direction)` crea un `Hitbox` como hijo del `Pivot`.
- **Protegerse** (`_shield`, `_shield_move`, `_with_shield()`): escudo con durabilidad por tiempo (`_shield_time` / `_shield_duration`). Mientras está activo bloquea movimiento y salto y cancela el ataque en curso.
- **Agarres** (`_grab`, `_grab_move`, `_grabbing()`): agarre por temporizador (`_grab_time` / `_grab_duration`). El grab y el shield se cancelan entre sí y el daño los anula.

**Pendiente**: el grab todavía no spawnea grab box ni lanza contrincantes, y el shield no absorbe golpes todavía — son la "buena entrada" con temporizadores, listos para conectarse a un `GrabBox` y a un `Shield` reales.

## `PowerFighter` — el que tiene poderes

Hijo de `Fighter`. Tiene **doble salto** (`_max_jumps = 2`, aplicado en `_init()`) y un `_power_attack` como placeholder de sus poderes.

**Pendiente**: el salto de poder adicional y los ataques de poder (`_power_attack`) están definidos como variables, pero aún no tienen mecánica.

---

## Entrada de los hijos terminales

| Clase | `_collect_input` | Estado |
|---|---|---|
| `Player` | Lee `input_map` (`player1_*` / `player2_*`), incluye `walk`, `grab` y `shield` | Jugador real |
| `TestPlayer` | Lee acciones `player1_*` directo | Pruebas en `main.tscn` |
| `NPC` | Placeholder: alterna `_jump` (salta como loquita) | Sin IA; usará `_ai_process` |

## Estado

| Pieza | Person | Fighter | PowerFighter |
|---|---|---|---|
| Moverse / saltar / agacharse | ✅ | — | — |
| Ledge grab | ✅ | — | — |
| Recibir daño + knockback | ✅ | — | — |
| `respawn(at_position)` | ✅ | — | — |
| Trancazos (13 `FightMove`) | — | ✅ | — |
| Grab box + lanzar (throw) | — | 🕓 (temporizador listo) | — |
| Shield (bloquear golpes) | — | 🕓 (temporizador listo) | — |
| Doble salto | — | — | ✅ |
| Salto de poder / ataques de poder | — | — | 🕓 |
| Muerte por `hp == 0` (ragdoll) | 🕓 (planeado) | — | — |
| `_ai_process` para NPCs | 🕓 (propuesto) | — | — |
