# Nota: Sistema de ataques

> Cómo se elige, ejecuta y termina un ataque (`FightMove`). Para el hitbox en sí (construcción, ciclo
> de vida) ver `docs/nota-hitbox.md`. Para dónde encaja esto en la jerarquía de clases ver
> `docs/arquitectura-personajes.md`.

## Dos implementaciones paralelas — una viva, una legacy

Hoy existen **dos** dueños del sistema de ataques, cada uno con su propio catálogo `Attacks` declarado
por separado:

- **`scripts/character.gd`** (clase `Character`) — según `docs/arquitectura-personajes.md`, **ya nadie
  la extiende**. Es legacy, se deja documentada porque el archivo sigue en el repo y sigue teniendo
  hitbox real (`Hitbox` la reconoce con `body is Character`), pero no es donde se desarrolla gameplay
  nuevo.
- **`scripts/fighter.gd`** (clase `Fighter`, hija de `Person`) — la implementación viva. Es la que
  extienden `PowerFighter` → `Player` / `TestPlayer` / `NPC`.

Los dos declaran **el mismo catálogo de 13 nombres de `FightMove`**, pero con valores distintos
(duración, algunas posiciones de hitbox) y con lógica de selección/cancelación ligeramente distinta.
Este documento marca explícitamente cuándo algo aplica a uno, al otro, o a ambos.

## Piezas

- **`FightMove`** (`scripts/helpers/fight_move.gd`): describe UN movimiento. Se construye con un
  `Dictionary` de config que se mergea sobre `_defaults` (así que cualquier propiedad no especificada
  cae en su default). Propiedades reales: `name`, `duration`, `speed`, `direction`, `air_attack`,
  `grab_attack`, `override_horizontal_move`, `override_vertical_move`, `inmortal`, `hitbox_damage`,
  `hitbox_size`, `hitbox_position`, `hitbox_time_ratio`, `hitbox_rotation`, `inversed_hitbox_ratio`.
  No existen `stop_horizontal_move`/`stop_vertical_move` ni "rotación de malla" como propiedades — esos
  nombres son de una versión vieja de este doc, ya no existen en el código.
- **`Attacks`** (`scripts/helpers/attacks.gd`): catálogo fijo de **13 `FightMove`** — 8 en piso
  (`ground_neutral`, `down`, `up`, `dash`, `forward`, `heavy_side`, `heavy_up`, `heavy_down`) y 5 en
  aire (`air_neutral`, `air_down`, `air_up`, `air_forward`, `air_back`). Tanto `Character` como
  `Fighter` declaran `var _attacks: Attacks = Attacks.new(...)` como propiedad de instancia (se crea al
  instanciarse el personaje, no en `_ready()`).
- **`Character._fight(delta, states)`** / **`Fighter._fight_move(delta, signals, states)`**: la máquina
  que decide cuándo arranca un ataque, lo sostiene mientras dura, y dispara/cierra el hitbox. Mismo
  algoritmo en esencia, ver diferencias abajo.

## Cómo se elige el ataque

En ambas clases, un ataque arranca por **flanco** de `_attack` (`_attack and _current_attack == null`)
y solo si `_current_attack == null`. Pero de los **13 `FightMove` declarados, solo 8 son alcanzables
hoy desde el juego** — ninguna de las dos implementaciones tiene un `elif` que dispare `forward`,
`heavy_side`, `heavy_up`, `heavy_down` ni `air_back`. Estos 5 quedan declarados en el catálogo (con su
`FightMove`, su animación listada en `docs/asset-personaje.md`, sus valores de hitbox) pero **nadie los
selecciona**: son movimientos "listos para conectar" a un input que combine ataque + dirección
simultánea (`heavy_*`) o a un estado de caminar-vs-correr distinto (`forward`) o de mirar hacia atrás en
el aire (`air_back`), que hoy no existe en `_get_move_states()`.

Tabla de estados que sí disparan ataque (idéntica en `Character._fight()` y `Fighter._fight_move()`):

| Estado | Ataque (`Attacks.xxx`) | Contexto |
|---|---|---|
| `neutral` | `ground_neutral` | piso, quieto |
| `running` | `dash` | piso, corriendo |
| `neutral_crouch` | `down` | piso, agachado |
| `neutral_up` | `up` | piso, quieto, mirando arriba |
| `neutral_air` | `air_neutral` | aire, quieto |
| `air_move` | `air_forward` | aire, moviéndose |
| `air_down` | `air_down` | aire, agachado (cayendo rápido) |
| `air_up` | `air_up` | aire, mirando arriba |

Si ninguno matchea (`init_attack = false`), no pasa nada. Si sí, se resetea `_attack_count = 0`.

**Limitación conocida: no hay buffer de input.** Si el jugador aprieta el botón de ataque mientras
`_current_attack != null`, esa pulsación se pierde — no hay forma de encadenar un segundo golpe apenas
termine el primero.

## El ataque manda sobre el movimiento

- `override_horizontal_move` → si es `true`, la velocidad horizontal deja de salir del input y pasa a
  ser la que fija el `FightMove` (`speed.x` combinado con la dirección de encare). En `Character` además
  apaga a mano el estado `running` para que la animación no lo pise.
- `override_vertical_move` → mismo trato con la velocidad vertical. Hoy **ningún** `FightMove` del
  catálogo lo pone en `true` (todos usan el default `false`), así que en la práctica solo el eje
  horizontal se llega a sobrescribir.

Cuando `_attack_count` llega a `_current_attack.duration`, el ataque termina (`_current_attack = null`)
y el movimiento vuelve a manos del input normal el frame siguiente.

## `hitbox_time_ratio` e `inversed_hitbox_ratio` — sigue igual

Mecanismo sin cambios respecto a antes. `get_hitbox_time_ratio()` devuelve `duration *
hitbox_time_ratio`. Con `inversed_hitbox_ratio = true` (default de `FightMove`, y **todos** los 13
ataques de **ambos** catálogos lo dejan así) el hitbox aparece **tarde**: `_fight()`/`_fight_move()`
comparan `_attack_count - delta` contra `get_hitbox_time_ratio()`, y recién ahí spawnean el hitbox, que
dura lo que resta de ataque (`duration - get_hitbox_time_ratio()`). Con el default `hitbox_time_ratio =
0.5` (también sin excepciones en el catálogo actual), el golpe conecta a partir de la mitad del ataque.
La rama `inversed_hitbox_ratio = false` (hitbox desde el primer frame) sigue existiendo en el código
pero, igual que antes, ningún `FightMove` la usa hoy.

## Ataques aéreos y aterrizaje — la lógica de cancelación DIFIERE entre las dos clases

- **`Character._move()`**: si el personaje toca piso mientras hay un ataque en curso con `air_attack ==
  true`, lo cancela (`_current_attack = null`). Solo cancela en un sentido (aéreo que aterriza); no hay
  chequeo equivalente para un ataque de piso que se quede en el aire.
- **`Fighter._fight_move()`**: cancela en **ambos sentidos** — si está en piso y el ataque es aéreo, o si
  está en el aire y el ataque **no** es aéreo, se anula (`_current_attack = null` y `_clear_hitbox()`).
  Si el contexto sí matchea (piso+terrestre o aire+aéreo), en cambio pone `_direction.x = 0` mientras
  dura el ataque. Es una guarda más estricta que la de `Character`.

## Colgado de una orilla no se pelea — mecanismo distinto en cada clase

- **`Character._fight()`** usa un **guard de entrada**: si `_hanging_ledge != null`, corta cualquier
  ataque (`_current_attack = null`), limpia el hitbox con `_clear_hitbox()` y hace `return` antes de
  evaluar nada más. `_anim()` tiene el guard espejo (`if _hanging_ledge != null: return`).
- **`Fighter._physics_process()`** no tiene guard de entrada en `_fight_move()`: la llama igual mientras
  cuelga (salvo que esté en shield+grab o ya atacando). En cambio, **después** de correr `_fight_move`,
  hace limpieza: `if _knockback_active or _holding_onto_the_ledge(): _current_attack = null; _grab_time
  = 0.0; _shield_time = 0.0`. Y en el bloque de animación, el `elif _holding_onto_the_ledge():
  _ledge_grab_anim(delta)` corre antes que `elif _attacking(): _attack_anim(delta)`, así que la anim de
  colgado siempre gana. El efecto final (no se pelea colgado) es el mismo, pero el mecanismo es "corre
  y luego se anula" en `Fighter` contra "ni siquiera corre" en `Character`.

## Swap de ejes del hitbox — diferencia sutil entre las dos clases

Ambas clases spawnean el hitbox como hijo del `Pivot`, intercambiando ejes porque el "adelante" (x) del
`FightMove` cae en `z` del `Pivot`:

- `Character._spawn_hitbox`: `Vector3(p_position.z, p_position.y, p_position.x * -1)` — invierte el eje
  `x` original al mapearlo a `z`.
- `Fighter._spawn_hitbox`: `Vector3(p_position.z, p_position.y, p_position.x)` — **sin** invertir.

No se pudo confirmar leyendo solo estos scripts si esto es un ajuste intencional (por diferencias en la
orientación del `Pivot` entre los dos assets) o un descuido; se deja documentado como diferencia real de
código, no como explicación de causa.

## Animación de ataque — ya no hay "rotación de malla" como fallback

Los 13 `FightMove` de ambos catálogos tienen `name` no vacío (los 13 nombres listados en
`docs/asset-personaje.md`), así que la rama vieja de "sin animación, rota malla en X" ya no aplica en la
práctica:

- `Character._anim()`: si `_current_attack.name != &""` reproduce esa animación; si estuviera vacío
  detendría el `AnimationPlayer`. Con el catálogo actual esa segunda rama nunca se toma.
- `Fighter._attack_anim()`: mismo patrón (`if _current_attack.name != &"": ... else: _animation_player.stop()`),
  pero además tiene una línea de rotación de malla **comentada**
  (`#_mesh_instance.rotation_degrees.x = _current_attack.mesh_rotation_x`) — código muerto que confirma
  que el mecanismo de rotación-como-animación-placeholder fue abandonado, no que siga vigente.

## Daño: ya SE aplica (esto cambió respecto a la versión vieja de este doc)

`scripts/hitbox.gd`, en `_on_hitbox_body_entered`, hoy llama de verdad:

```gdscript
body.set_damage_percentage( _damage )
body.set_damage_move( _damage, _direction )
```

para cualquier `body` que sea `Character` o `Person` (por lo tanto también `Fighter` y sus hijos). Ya no
es un "pendiente conocido" — el dato `hitbox_damage` del `FightMove` sí viaja hasta el personaje
golpeado y sí produce empuje:

- **`Character.set_damage_move`**: guarda dirección y activa `_taking_damage = true`; `_damage_move()`
  (que se llama en vez de `_fight()` mientras `_taking_damage` esté activo) empuja
  `_target_velocity` una sola vez, proporcional a `_normal_damage_move_power * damage_percentage`, y
  además suelta al personaje si estaba colgado de una orilla.
- **`Person.set_damage_move`** (usado por `Fighter`): activa un **knockback por tiempo**
  (`_knockback_active`, `_knockback_time = _knockback_duration` = 0.35s) en vez de un empuje instantáneo.
  Mientras dura, `_damage_move(delta)` acelera la velocidad cada frame (con fricción propia,
  `_knockback_friction`) y `_damage_anim` gira el `Pivot` en X (efecto "tumble") según cuánto
  `damage_percentage` acumulado tenga. Es un sistema más elaborado que el de `Character`, coherente con
  que `Fighter` es la implementación viva.

Lo que **sigue sin existir** en ninguna de las dos clases: morir o quedar fuera de combate al llegar a
cierto `damage_percentage`/`hp`. `docs/arquitectura-personajes.md` ya lo marca como pendiente
(`Person`, muerte por `hp == 0`).

## Los 13 ataques — valores reales, `Character` vs `Fighter`

`hitbox_size` es `(0.5, 0.5, 0.5)` y `hitbox_time_ratio`/`inversed_hitbox_ratio` son `0.5`/`true` en las
13 entradas de ambos catálogos, sin excepciones — se omiten de la tabla porque no varían.
⚠ = no alcanzable hoy por ningún estado de `_fight()`/`_fight_move()` (ver sección "Cómo se elige el
ataque").

| Ataque | `duration` Character | `duration` Fighter | `hitbox_damage` | `override_horizontal_move` | `speed` | `air_attack` | `hitbox_position` (igual en ambos salvo nota) | animación |
|---|---|---|---|---|---|---|---|---|
| `ground_neutral` | 0.2 | **0.875** | 5 | sí | (0,0,0) | no | (0.8, 0, 0) | `ground_neutral_attack` |
| `down` | 0.2 | **0.5** | 5 | sí | (0,0,0) | no | (1.0, -1.0, 0) | `down_attack` |
| `up` | 0.5 | **0.5833** | 5 | sí | (0,0,0) | no | (0.1, 0.8, 0) | `up_attack` |
| `dash` | 0.3 | **0.8333** | 5 | sí | (7,0,0) | no | Character (1.0,-1.0,0) / Fighter **(0.5,-1.0,0)** | `dash_attack` |
| `forward` ⚠ | 0.3 | 0.3 | 10 | sí | (10,0,0) | no | (0.5, -0.5, 0) | `forward_attack` |
| `heavy_side` ⚠ | 0.5 | 0.5 | 5 | sí | (0,0,0) | no | (1.0, -1.0, 0) | `heavy_side_attack` |
| `heavy_up` ⚠ | 0.5 | 0.5 | 5 | sí | (0,0,0) | no | (1.0, -1.0, 0) | `heavy_up_attack` |
| `heavy_down` ⚠ | 0.5 | 0.5 | 5 | sí | (0,0,0) | no | (1.0, -1.0, 0) | `heavy_down_attack` |
| `air_neutral` | 1.0 | **0.9167** | 5 | no | (0,0,0) | sí | (0.9, -0.9, 0) | `air_neutral_attack` |
| `air_down` | 0.5 | 0.5 | 10 | no | (0,0,0) | sí | (0.1, -1.1, 0) | `air_down_attack` |
| `air_up` | 0.5 | **0.5833** | 5 | no | (0,0,0) | sí | (0.0, 0.8, 0) | `air_up_attack` |
| `air_forward` | 0.6667 | 0.6667 | 10 | no | (0,0,0) | sí | (1.2, 0.0, 0) | `air_forward_attack` |
| `air_back` ⚠ | 0.5 | 0.5 | 10 | no | (0,0,0) | sí | (1.2, 0.0, 0) | `air_back_attack` |

Todos usan `override_vertical_move = false` (ningún ataque sobrescribe la velocidad vertical).

Las duraciones de `Fighter` con decimales "raros" (0.875, 0.5833, 0.8333, 0.9167) no son arbitrarias
como las de `Character` (0.2, 0.3, 0.5, 1.0): son fracciones de segundo consistentes con animaciones a
24fps (21, 14, 20, 22 frames respectivamente) — indicio de que en `Fighter` la duración del ataque se
afinó para calzar con el clip de animación real, mientras que `Character` (legacy, y con la rama de
"rotación de malla" nunca conectada del todo) se quedó con números redondos de placeholder.

## Ver también

- `docs/nota-hitbox.md` — construcción y ciclo de vida del `Hitbox` en sí.
- `docs/arquitectura-personajes.md` — por qué `Character` es legacy y `Fighter` es la clase viva.
- `docs/asset-personaje.md` — lista completa y ya actualizada de los 13 nombres de animación de ataque
  (fuente de verdad para nombres; este doc no los repite salvo en la tabla de valores).
