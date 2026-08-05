# Nota: Sistema de ataques

> Cómo se elige, ejecuta y termina un ataque (`FightMove`) desde `Character._fight()`. Para el hitbox en sí (construcción, swap de ejes, ciclo de vida) ver `docs/nota-hitbox.md`.

## Piezas

- **`FightMove`** (`scripts/helpers/fight_move.gd`): describe UN movimiento — duración, daño, si frena el movimiento normal, velocidad propia, si es aéreo, posición del hitbox, animación o rotación de malla.
- **`Attacks`** (`scripts/helpers/attacks.gd`): catálogo fijo con los 6 `FightMove` del juego (3 en piso, 3 en aire). `Character` declara `var _attacks: Attacks = Attacks.new()`, así que el catálogo se crea al instanciarse el personaje, no en `_ready()`.
- **`Character._fight(delta, states)`**: la máquina que decide cuándo arranca un ataque, lo sostiene mientras dura, y dispara/cierra el hitbox.

## Cómo se elige el ataque

`_fight()` arranca un ataque por **flanco** del input, no mientras esté sostenido, pero ese flanco ya viene resuelto desde antes: `player.gd` lee el botón de ataque con `Input.is_action_just_pressed(input_map.attack)`, que solo devuelve `true` en el frame exacto en que se aprieta el botón. Así, `_attack` dura un único frame por pulsación y `_fight()` no necesita calcular nada extra — le alcanza con preguntar `if _attack and _current_attack == null`.

Esto existe porque antes se leía `_attack` con `Input.is_action_pressed` (estado sostenido, `true` mientras el botón siga apretado): al terminar un ataque (`_current_attack = null`), si el jugador seguía con el botón apretado, la condición volvía a cumplirse sola en el frame siguiente y arrancaba otro ataque — es decir, mantener presionado el botón permitía spamear ataques sin soltar. Con `is_action_just_pressed`, cada pulsación dispara como mucho un ataque: hay que soltar y volver a apretar para atacar de nuevo.

Por contraste, `_jump` y los `_move_*` siguen leyéndose en `player.gd` con `Input.is_action_pressed` (estado sostenido) — ahí sí hace falta sostener el botón para seguir moviéndose o cayendo con salto cortado, por ejemplo. Para el salto, que sí necesita detectar el flanco (que solo salte una vez por pulsación), es `Character._move()` quien lo hace a mano con `_was_jumping`. `_attack` es hoy la única de estas variables que viaja como flanco puro desde el input en vez de como estado sostenido.

Un ataque solo arranca además si `_current_attack == null` (no hay uno en curso ya). Con eso resuelto, mira los `states` que ya calculó `_get_move_states()` a partir del movimiento de ese frame:

| Estado | Ataque | Contexto |
|---|---|---|
| `neutral` | `neutral` | piso, quieto |
| `running` | `dash` | piso, corriendo |
| `neutral_crouch` | `crouch` | piso, agachado |
| `neutral_air` | `neutral_air` | aire, quieto |
| `air_down` | `air_down` | aire, agachado (cayendo rápido) |
| `air_move` | `air_move` | aire, moviéndose |

Si ninguno matchea (`init_attack = false`), no pasa nada. Si sí, se resetea `_attack_count = 0` para empezar a contar la duración del golpe recién elegido.

**Limitación conocida: no hay buffer de input.** Si el jugador aprieta el botón de ataque mientras `_current_attack != null`, esa pulsación se pierde — `_attack` fue `true` en ese frame pero la condición `_current_attack == null` lo bloquea, y no queda registrado en ningún lado para encolarse. No hay forma de "encadenar" un segundo golpe apenas termine el primero; hay que esperar a que el ataque en curso termine y recién ahí volver a pulsar.

## El ataque manda sobre el movimiento

`_fight()` corre **después** de `_move()` en el pipeline de `_physics_process` (`_move()` → `_get_move_states()` → `_fight()` → `_anim()`). Esto es a propósito: `_move()` ya calculó velocidad e input normales, y `_fight()` tiene la última palabra para pisarlos si hay un ataque activo:

- `stop_horizontal_move` → si es `true`, `_target_velocity.x` deja de salir del input y pasa a ser `_current_attack.speed.x * _direction.x` (la velocidad la fija el `FightMove`, no el jugador). También apaga el estado `running` a mano, para que la animación no lo pise.
- `stop_vertical_move` → mismo trato pero con `_target_velocity.y` y `speed.y`.

Todos los ataques actuales usan `_direction` (la dirección hacia la que mira el personaje) como signo de la velocidad impuesta, así que un `dash` empuja hacia adelante en vez de mandar al personaje quieto.

Cuando `_attack_count` llega a `_current_attack.duration`, el ataque termina (`_current_attack = null`) y el movimiento vuelve a manos del input normal el frame siguiente.

## `hitbox_time_ratio` e `inversed_hitbox_ratio`

Es el mecanismo menos obvio del sistema. `get_hitbox_time_ratio()` devuelve `duration * hitbox_time_ratio` — un instante de tiempo dentro de la duración del ataque. Qué significa ese instante depende de `inversed_hitbox_ratio` (default `true` en `FightMove._init`, y ningún ataque del catálogo lo cambia hoy):

- **`inversed_hitbox_ratio = true` (caso actual, todos los ataques)**: el hitbox aparece **tarde**. `_fight()` compara `_attack_count - delta` contra `get_hitbox_time_ratio()`; recién cuando el contador pasa ese punto se spawnea el hitbox, y dura lo que queda de ataque (`duration - get_hitbox_time_ratio()`). Con el default `hitbox_time_ratio = 0.5`, el golpe conecta a partir de la mitad del ataque y se mantiene hasta el final — pensado para que el "cargue" de la animación no tenga hitbox y el impacto salga en el remate.
- **`inversed_hitbox_ratio = false`**: el hitbox aparece **temprano**, desde el primer frame del ataque (`first_attack_frame`), y dura exactamente `get_hitbox_time_ratio()` segundos. Sirve para golpes donde el daño está al inicio del gesto, no al final.

Ningún `FightMove` del catálogo usa hoy `inversed_hitbox_ratio = false` ni cambia `hitbox_time_ratio` del default `0.5` — pero la clase ya soporta ambos casos si algún ataque futuro lo necesita.

## Ataques aéreos y aterrizaje

`air_attack` marca cuáles de los 6 movimientos son aéreos (los tres del bloque "en el aire" del catálogo). `_move()` revisa esto cada frame: si el personaje toca piso (`on_floor`) mientras hay un ataque en curso y ese ataque tiene `air_attack == true`, se cancela (`_current_attack = null`) sin esperar a que termine su `duration`. Es para que un aterrizaje corte el ataque en vez de dejarlo "pegado" al personaje ya en piso.

## Colgado de una orilla no se pelea

En el pipeline de `_physics_process`, `_ledge_grab()` corre **antes** que `_fight()`. Por eso `_fight()` arranca con un guard: si `_hanging_ledge != null`, corta cualquier ataque en curso (`_current_attack = null`), limpia el hitbox con `_clear_hitbox()` y hace `return` sin evaluar nada más. Mientras el personaje está colgado, manda `_ledge_grab`, no el sistema de ataques.

El `_clear_hitbox()` se llama a mano acá porque no se puede delegar a `_ledge_grab`: ese método solo limpia el hitbox cuando `_current_attack != null`, así que un hitbox que sobreviviera al final de su ataque quedaría pegado al personaje colgado (el `return` de este guard salta el bloque de limpieza normal al final de `_fight()`). Llamar `_clear_hitbox()` es seguro aunque no haya hitbox activo.

Sin este guard, además, había un bug real: `_ledge_grab` cancelaba el ataque en curso y, acto seguido, `_fight` veía `_current_attack == null` con el botón sostenido y arrancaba uno nuevo cada frame — invisible porque la animación estaba bloqueada, pero spameaba la consola y creaba/cancelaba `FightMove` sin parar. `_anim()` tiene un guard equivalente (`if _hanging_ledge != null: return`), así que tampoco hay animación de ataque estando colgado.

## Animación o rotación de malla

En `_anim()`, si `_current_attack != null`:

- Si `animation_name` **no** está vacío (`&""`), se reproduce esa animación (`neutral_attack`, `dash_attack`, `crouch_attack` — los 3 ataques de piso).
- Si está vacío, se **detiene** el `AnimationPlayer` y en su lugar se rota la malla en X con `mesh_rotation_x` (los 3 ataques aéreos: `neutral_air`, `air_move`, `air_down`). Es el apaño actual mientras esos golpes no tienen animación propia — una rotación fija simula el gesto en vez de un clip animado.

## Pendiente conocido: el daño no se aplica

Cada `FightMove` define `damage`, pero hoy **no se usa en ningún lado**. El `Hitbox` (ver `docs/nota-hitbox.md`) detecta a quién golpea y solo lo imprime por consola; no resta vida ni aplica knockback. El dato ya está modelado y listo para cuando se implemente el daño real.

## Los 6 ataques (`scripts/helpers/attacks.gd`)

| Ataque | Contexto | `duration` | `damage` | frena mov. (H/V) | `speed` | `air_attack` | `hitbox_position` | `animation_name` / rotación |
|---|---|---|---|---|---|---|---|---|
| `neutral` | piso, quieto | 0.2 | 5 | H sí / V no | (0, 0, 0) | no | (0.3, 0.1, 0) | `neutral_attack` |
| `dash` | piso, corriendo | 0.3 | 10 | H sí / V no | (22, 0, 0) | no | (0.5, -0.5, 0) | `dash_attack` |
| `crouch` | piso, agachado | 0.2 | 5 | H sí / V no | (0, 0, 0) | no | (0.6, -0.5, 0) | `crouch_attack` |
| `neutral_air` | aire, quieto | 0.4 | 5 | no / no | (0, 0, 0) | sí | (0.5, -0.6, 0) | sin animación, rota malla 45° en X |
| `air_move` | aire, moviéndose | 0.3 | 10 | no / no | (0, 0, 0) | sí | (0.6, 0, 0) | sin animación, rota malla 90° en X |
| `air_down` | aire, agachado | 0.3 | 10 | no / no | (0, 0, 0) | sí | (0.1, -0.7, 0) | sin animación, sin rotación (0°) |

Todos usan `hitbox_time_ratio = 0.5` e `inversed_hitbox_ratio = true` (valores default de `FightMove`, ninguno los sobrescribe).
