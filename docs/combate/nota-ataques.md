# Nota: Sistema de ataques

> Cómo se elige, ejecuta y termina un ataque (`FightMove`). Para el hitbox en sí (construcción, ciclo
> de vida) ver `docs/combate/hitbox.md`. Para dónde encaja esto en la jerarquía de clases ver
> `docs/arquitectura/arquitectura-personajes.md`.

El sistema de ataques vive en **`scripts/characters/fighter.gd`** (clase `Fighter`, hija de `Person`). Lo
extienden `PowerFighter` → `Player` / `NPC`. Todo lo de este doc sale de `Fighter`
salvo que se diga otra cosa.

## Piezas

- **`FightMove`** (`scripts/helpers/combat/fight_move.gd`): describe UN movimiento. Se construye con un
  `Dictionary` que se mergea sobre `_defaults` (lo no especificado cae al default). Propiedades:
  `name`, `duration`, `speed`, `direction`, `jump_power`, `air_attack`, `grab_attack`,
  `override_horizontal_move` (default `true`), `override_vertical_move` (default `false`), `immortal`
  y `hitboxes_moves`.
- **`HitboxMove`** (`scripts/helpers/combat/hitbox_move.gd`): describe UN hitbox dentro de un `FightMove`.
  Propiedades: `id`, `damage`, `position`, `size`, `direction`, `rotation`, `init_time_ratio`,
  `duration`, y las de `AreaGravity3D` (`use_gravity`, `fall_acceleration`, `bounce`,
  `bounce_impulse`, `speed`). **El hitbox ya no vive en el `FightMove`**: cada ataque trae un arreglo
  `hitboxes_moves`, así que un ataque puede lanzar varios hitboxes (ej. `air_neutral` lanza 4).
- **`Attacks`** (`scripts/helpers/combat/attacks.gd`): catálogo fijo de **15 `FightMove`** — 10 en piso
  (`neutral1`, `neutral2`, `neutral3`, `down`, `up`, `dash`, `forward`, `heavy_side`, `heavy_up`,
  `heavy_down`) y 5 en aire (`air_neutral`, `air_down`, `air_up`, `air_forward`, `air_back`). `Fighter`
  lo declara como `var _attacks: Attacks = Attacks.new(...)`, propiedad de instancia.
  Los 3 neutrales son el combo de piso; los otros 12 son "un ataque = un estado".
- **`Fighter._fight_move(delta, signals, states)`**: la máquina que decide cuándo arranca un ataque, lo
  sostiene mientras dura, y lanza/cierra los hitboxes. Se llama desde `_process_action()`.
- **`PowerAttacks`** (`scripts/helpers/combat/power_attacks.gd`): catálogo aparte de `PowerFighter` (ver
  sección al final). No son parte de los 15.

## Cómo se elige el ataque

Un ataque arranca solo si `_current_attack == null` y `_attack` es `true`. `_attack` es el flanco
`is_just_pressed` del botón (en `Player`), así que mantener apretado no repite.
`_set_attack()` llama a `_process_attack()` (reemplazable: `PowerFighter` lo sobrescribe) y si salió
un ataque, reinicia `_attack_count = 0`, limpia `_spawned_hitbox_ids` y apaga la animación de salto
aéreo (`_air_jump_time = 0`).

`_init_attack_by_move()` evalúa de arriba abajo, **el primero que cumple gana**:

| Orden | Condición (`MoveStates`) | Ataque | Contexto |
|---|---|---|---|
| 1 | `neutral` | combo neutral (`neutral1/2/3`) | piso, quieto |
| 2 | `moving` y no `crouch_move` y dirección con buffer | `heavy_side` | piso, direccion + ataque |
| 3 | `walking` | `forward` | piso, caminando |
| 4 | `running` | `dash` | piso, corriendo |
| 5 | `neutral_crouch` y dirección con buffer | `heavy_down` | piso, abajo + ataque |
| 6 | `neutral_crouch` o `crouch_move` | `down` | piso, agachado |
| 7 | `neutral_up` y dirección con buffer | `heavy_up` | piso, arriba + ataque |
| 8 | `neutral_up` | `up` | piso, mirando arriba |
| 9 | `neutral_air` | `air_neutral` | aire, quieto |
| 10 | `air_down` | `air_down` | aire, abajo |
| 11 | `air_up` | `air_up` | aire, arriba |
| 12 | `air_forward` | `air_forward` | aire, moviéndose hacia donde mira |
| 13 | `air_back` | `air_back` | aire, moviéndose en sentido contrario |

Los 15 ataques son alcanzables. `walking` vs `running` sale de `_walk` (`Person`): `walking = _walk and
moving`, `running = moving and not walking`. `air_forward`/`air_back` comparan la dirección de
movimiento contra `_last_x_direction`.

### Input buffer de dirección (ataques "heavy")

`Person._move()` abre una ventana de `GameBalance.INPUT_BUFFER_WINDOW` (0.15 s) cada vez que hay un
flanco de dirección (`_down_pressed`, `_up_pressed`, `_left_pressed`, `_right_pressed`).
`_is_direction_buffer()` es `true` mientras corre esa ventana. **Por eso** los `heavy_*` no exigen que
dirección y ataque lleguen en el mismo frame: basta con tocar la dirección hasta 0.15 s antes del
botón de ataque. Sin buffer, "arriba + ataque" casi nunca saldría heavy por errores de timing humano.

Efecto colateral que se maneja a propósito: `_move_up` también cuenta como querer saltar. Por eso
`_process_action()` hace `_target_velocity.y = 0` si hay buffer de dirección + ataque + piso, para
que el heavy no te lance al aire.

**El botón de ataque en sí NO tiene buffer.** Si se aprieta mientras `_current_attack != null`, esa
pulsación se pierde (el buffer es solo de dirección).

## Combo neutral en piso (3 golpes)

`neutral1` → `neutral2` → `neutral3`, elegidos por `_neutral_combo_count`:

- `_get_current_neutral_combo_move()` devuelve `_neutral_combo_attacks[_neutral_combo_count]`, o el
  último si el contador ya llegó al límite. El arreglo se arma en `_ready()`.
- `_process_neutral_combo()`: en el **primer frame** de un neutral, suma 1 al contador y reinicia
  `_neutral_combo_reset_time = _neutral_combo_reset_duration` (1.5 s). Si ya se llegó al límite
  (3), el contador se pone en 0 antes de sumar, así que el cuarto golpe vuelve a `neutral1`.
- `_reset_neutral_combo_count()` (se llama cada frame vía `_reset_counts_by_move_state`) pone el
  contador en 0 si el personaje deja de estar en `neutral` o si se acabó el tiempo de 1.5 s
  (`_tick_neutral_combo_reset` lo va bajando).

Por qué así: el combo se encadena por **ventana de tiempo** desde el inicio del golpe anterior (1.5 s),
no por input perfecto. Si te mueves o te tardas más de 1.5 s, el combo se reinicia.

## El ataque manda sobre el movimiento

- `override_horizontal_move` → si es `true`, `_target_velocity.x = speed.x * _last_x_direction`
  (la velocidad sale del ataque, no del input). Todos los ataques de piso lo tienen en `true`; los de
  aire en `false` (en aire se conserva el control horizontal).
- `override_vertical_move` → mismo trato con `_target_velocity.y = speed.y`. Ningún ataque del
  catálogo normal lo pone en `true`.
- En `_process_action()` se bloquean inputs mientras se ataca: `_allow_jump = false` siempre que hay
  ataque, y `_horizontal_move = false` si es ataque de piso (`air_attack == false`).
- Hacer grab, escudo o rodar **anula** el ataque en curso y limpia sus hitboxes
  (`_fight_move` ni se llama en ese frame).

Cuando `_attack_count >= duration`, el ataque termina (`_current_attack = null`). Si no, se suma
`delta` a `_attack_count`.

## Hitboxes: cuándo y cómo salen

Por cada `HitboxMove` del ataque, en cada frame:

1. `time_ratio = duration_del_ataque * init_time_ratio` (`FightMove.get_time_ratio`).
2. `hitbox_time = _attack_count - delta`.
3. Si `hitbox_time >= time_ratio` **y** `hitbox_time < time_ratio + hitbox_move.duration` **y** el `id`
   no está en `_spawned_hitbox_ids`, se spawnea y se marca el `id`.

Es decir, el hitbox sale `init_time_ratio` del camino dentro del ataque y solo una vez por `id` por
ataque (el diccionario se limpia al arrancar cada ataque). El hitbox vive `hitbox_move.duration`
segundos (su `lifetime`). Por eso los ataques con varios hitboxes (como `air_neutral`) usan `id`
distintos: si no, el segundo nunca saldría.

Detalles de `_spawn_hitboxes_damages()`:

- Crea un `HitboxDamage` con `damage`, `size`, `lifetime = duration` y `parent = self` (para no
  pegarse a sí mismo). Ver `docs/combate/hitbox.md`.
- **Swap de ejes**: el "adelante" (x) del `FightMove` cae en `z` del `Pivot`, así que
  `fixed_position = Vector3(pos.z, pos.y, pos.x)`. Se agrega como hijo de `_pivot`, por lo que gira
  con el personaje.
- **Dirección de empuje**: `direction.x = hitbox_move.direction.x * _last_x_direction` (para que
  empuje hacia donde mira) y `direction.y = hitbox_move.direction.y * 0.1`.
- Si el hitbox tiene `use_gravity`, en vez de hijo del `Pivot` se vuelve nodo libre de la escena
  (`current_scene.add_child`) en posición global, para que se mueva solo (proyectiles; los usa
  `PowerFighter`). `_clear_hitboxes_damages()` solo borra los que NO usan gravedad.

## Ataques saltarines (`jump_power`)

Si `jump_power > 0`, el ataque es "saltarín" (`_is_attack_jump()`): en su **primer frame** pone
`_target_velocity.y = jump_power`, restaura los saltos al máximo (`_set_jumps_to_max()`) y fuerza la
dirección según `_move_left/_move_right`. Llevan cuenta en `_attack_jump_count`; si pasa de 1 (o sea,
el segundo intento seguido sin tocar piso) el ataque se corta (`_attack_count = duration`). El
contador se reinicia al tocar piso, al recibir golpe (`_reset_counts_by_impact`) y al agarrarse de
una orilla.

**Ningún ataque de `Attacks` tiene `jump_power`** (todos usan el default `0.0`): hoy solo lo usan los
power attacks `up` y `air_up` de `PowerFighter`.

## Cancelación de ataques

`_cancel_attack()` corre justo después de `_set_attack()`, y si el ataque se anula limpia hitboxes.
Casos:

| Situación | Resultado |
|---|---|
| Recibiendo daño y en piso | se cancela |
| Agarrando (`_grabbing()`) o agarrado (`grabbed`) | se cancela |
| En piso con ataque aéreo | se cancela |
| En el aire con ataque de piso **sin** `jump_power` | se cancela |
| En el aire con ataque de piso con `jump_power` | sigue (así funcionan los saltarines) |
| Ataque aéreo en el aire | sigue; además `_direction.x = 0` |

Otras cancelaciones, en `_cancel_action()` (corre al final del `_physics_process`): hitstun
(`taking_damage()`), colgado de orilla, rodando, agarrando o KO anulan el ataque y limpian hitboxes.
Excepción: con **heavy hitstun en el aire** y un ataque aéreo, solo se limpia el estado de heavy
hitstun una vez que lleva `GameBalance.ABLE_TO_ATTACK_WITH_HITSTUN_DURATION` (0.5 s) en el aire —
permite contraatacar en el aire después de un golpe fuerte.

El orden en `Person._physics_process` es: `_process_action` (aquí se pelea) → `_process_damage` →
`_cancel_action` (aquí se anula por daño/orilla/etc.). Por eso un ataque puede "arrancar" un frame
y anularse en el mismo: el mecanismo es "corre y luego se anula". En el bloque de animación
(`_not_normal_move_anim`), `_holding_onto_the_ledge()` va antes que `_attacking()`, así que la anim
de colgado siempre gana.

## Animación de ataque

`_attack_anim()` reproduce `_current_attack.name` en el `AnimationPlayer` (si el nombre estuviera
vacío, lo detiene). Los nombres de animación son los de `docs/arte/asset-personaje.md` (fuente de verdad);
el `name` del `FightMove` **es** el nombre de la animación, por eso son `snake_case`.

## Daño recibido

`HitboxDamage._on_hitbox_body_entered` (`scripts/combat/hitbox_damage.gd`), si el cuerpo es `Person` y no es
su propio `_parent`, llama:

```gdscript
body.set_damage_percentage( _damage )
body.set_damage_move( _damage, _direction )
```

`Person.set_damage_move()` fija la dirección de knockback, calcula el hitstun
(`BASE_HITSTUN_DURATION` + `damage * damage_percentage * 0.02`, tope `MAX_HITSTUN_DURATION`) y, si el
daño supera `STUN_DAMAGE_THRESHOLD * hp`, activa heavy hitstun (tumbado en piso,
`STUN_DURATION_ON_FLOOR`). Durante `KNOCKBACK_DECAY_TIME` la velocidad se acelera con
`_normal_damage_power * damage_percentage`, así que **mientras más `damage_percentage` acumulado,
más lejos vuela**. Los valores están en `scripts/helpers/game_balance.gd`.

## Los 15 ataques — valores reales

Todos tienen **un solo `HitboxMove`** salvo `air_neutral` (4). `hitbox_size` es `(0.5,0.5,0.5)` salvo
las excepciones de abajo. `override_vertical_move = false` en todos, `speed` es `(0,0,0)` salvo donde
se indica. Cada fila: `init_time_ratio` (cuándo sale el hitbox, fracción de la duración) y `dur.
hitbox` (cuánto vive el hitbox).

| Ataque | Animación (`name`) | `duration` | `air_attack` | `override_h` | `speed` | daño | `hitbox_position` | `direction` | `init_time_ratio` | dur. hitbox |
|---|---|---|---|---|---|---|---|---|---|---|
| `neutral1` | `neutral_attack1` | 0.5 | no | sí | (0,0,0) | 10 | (0.8, 0.3, 0) | (0.25, 0.3, 0) | 0.6 | 0.2 |
| `neutral2` | `neutral_attack2` | 0.5 | no | sí | (0.25,0,0) | 10 | (1.0, 0.3, 0) | (0.25, 0.3, 0) | 0.6 | 0.2 |
| `neutral3` | `neutral_attack3` | 0.6667 | no | sí | (0.25,0,0) | 15 | (0.8, 0.1, 0) | (0.4, 0.5, 0) | 0.5 | 0.2 |
| `down` | `down_attack` | 0.5 | no | sí | (0,0,0) | 8 | (1.0, -1.0, 0) | (0.25, 0.75, 0) | 0.5 | 0.2 |
| `up` | `up_attack` | 0.4583 | no | sí | (0,0,0) | 7 | (0.3, 0.9, 0) | (0.25, 1.0, 0) | 0.5 | 0.2 |
| `dash` | `dash_attack` | 0.8333 | no | sí | (7,0,0) | 5 | (0.8, -1.0, 0) | (0.5, 0.8, 0) | 0.2 | 0.3 |
| `forward` | `forward_attack` | 0.4583 | no | sí | (0,0,0) | 6 | (1.0, -0.2, 0) | (1.0, 0.5, 0) | 0.5 | 0.1 |
| `heavy_side` | `heavy_side_attack` | 0.7083 | no | sí | (0,0,0) | 20 | (0.8, 0.1, 0) | (1, 0.75, 0) | 0.5 | 0.2 |
| `heavy_up` | `heavy_up_attack` | 0.5833 | no | sí | (0,0,0) | 20 | (0.1, 0.8, 0) | (0.25, 1.0, 0) | 0.5 | 0.2 |
| `heavy_down` | `heavy_down_attack` | 0.625 | no | sí | (0,0,0) | 10 | (0.0, -1.0, 0) | (1, 1, 0) | 0.5 | 0.2 |
| `air_neutral` | `air_neutral_attack` | 0.9167 | sí | no | (0,0,0) | 5 (x4) | ver abajo | ver abajo | 0.5 | 0.2 |
| `air_down` | `air_down_attack` | 0.5 | sí | no | (0,0,0) | 20 | (0.1, -1.1, 0) | (0.25, -1.0, 0) | 0.5 | 0.2 |
| `air_up` | `air_up_attack` | 0.5833 | sí | no | (0,0,0) | 5 | (0.15, 0.8, 0) | (0.5, 1.25, 0) | 0.5 | 0.2 |
| `air_forward` | `air_forward_attack` | 0.6667 | sí | no | (0,0,0) | 10 | (0.75, 0.0, 0) | (1.2, 1, 0) | 0.5 | 0.2 |
| `air_back` | `air_back_attack` | 0.5833 | sí | no | (0,0,0) | 10 | (-0.7, 0.0, 0) | (-1.0, 1, 0) | 0.5 | 0.2 |

Excepciones de `hitbox_size`: `forward` (0.5, 0.5, 1.0), `heavy_down` (0.5, 0.5, 2.0), `air_up`
(0.5, 0.5, 0.8), `air_forward` (0.5, 0.5, 0.9).

`air_neutral` lanza 4 hitboxes a la vez (ids 9 a 12, uno por esquina, cada uno empuja hacia su
lado): posiciones/direcciones `(0.9,-0.9)/(1,-1)`, `(-0.9,-0.9)/(-1,-1)`, `(0.9,0.5)/(1,1)`,
`(-0.9,0.5)/(-1,1)`.

Los `id` de hitbox **solo importan dentro de un mismo ataque** (por eso hay ids repetidos entre
ataques, ej. los 3 neutrales usan `id` 1): `_spawned_hitbox_ids` se limpia al arrancar cada ataque.

Las duraciones "raras" (0.4583, 0.5833, 0.6667, 0.7083, 0.8333, 0.9167) no son arbitrarias: son
fracciones de segundo que cuadran con animaciones a 24 fps (11, 14, 16, 17, 20 y 22 frames). La
duración del ataque se afinó para calzar con el clip real de animación; las redondas (0.5, 0.625)
equivalen a 12 y 15 frames.

## PowerFighter: cómo extiende esto

`PowerFighter` sobrescribe `_process_attack()` para llamar primero a `_init_attack_by_move()` y luego a
`_init_power_attack_by_move()` (si `_power_attack` está activo, este último pisa el ataque normal).
Sus ataques viven en `_power_attacks` (`PowerAttacks`): `standard`, `down`, `up`, `air_standard`,
`air_down`, `air_up`. Son los que usan `jump_power` (`up`, `air_up`) y hitboxes con `use_gravity` /
`bounce` (`standard`, `air_standard`, proyectiles).

## Ver también

- `docs/combate/hitbox.md` — construcción y ciclo de vida del `Hitbox` en sí.
- `docs/arquitectura/arquitectura-personajes.md` — jerarquía `Person` → `Fighter` → `PowerFighter`.
- `docs/arte/asset-personaje.md` — lista de nombres de animación de ataque (fuente de verdad para nombres).
- `docs/combate/normal-and-power-attacks-moves.md` — ataques normales y power.
