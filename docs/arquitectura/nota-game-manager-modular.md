# Nota: GameManager modular

> **Regla de arquitectura.** El `GameManager` **no debe ser un monolito**. Cada concern de la partida
> vive en su propio módulo, dentro de `scripts/match/`. Este documento define qué módulos existen,
> cuáles faltan, y cómo se hablan entre ellos.

Reemplaza la idea vieja de "un manager que hace todo" (su nota se eliminó; queda en el historial de git).

## El problema que resuelve

El `GameManager` original (`OldGameManager`, ya eliminado del repo; se puede recuperar del historial de git) mezclaba en un solo archivo:

- las **reglas** de la partida (vidas, muertes, respawn, lineup)
- la **geometría del mapa** (dónde está el play area, dónde los spawn points)
- la **cámara** (le exponía `get_play_area_bounds()`, `get_pending_respawn_positions()` e
  `is_shake_active()` para que la cámara viniera a preguntarle)

Esa última parte es la que importa: la cámara **dependía** del manager, y el manager tenía que
mantener un estado artificial (`_shake_end_time_msec`, un diccionario de posiciones de muerte)
**solo para poder responderle**. Un efecto de cámara no es una regla de juego, pero el manager
tenía que saber de-effects para que la cámara pudiera preguntar.

## La regla

**Un módulo, un concern. Nadie consulta a nadie: se avisan con señales.**

- El manager **arma** los módulos y les inyecta lo que necesitan. No es dueño de su estado.
- Un módulo **nunca** consulta a otro módulo. Si necesita saber algo, pregunta con una señal.
- Lo que es **regla** vive en el manager. Lo que es **presentación** (cámara, sonido, comentarista)
  vive en su propio módulo y **escucha** eventos de la partida.

La prueba de que un módulo está bien separado: se le puede quitar y **las reglas de la partida no
cambian**. Nada de reglas depende de que la cámara exista.

## Módulos que existen (en `scripts/match/`)

| Módulo | `class_name` | Concern | Estado |
|---|---|---|---|
| Reglas de partida | `GameManager` | vidas, detección de muerte, respawn, lineup | **LISTO** |
| Encuadre | `CameraFollow` | sigue a los peleadores, zoom, temblor al morir alguien (escucha `lives_changed`) | **LISTO** |
| Colocación | `SpawnPoint` | instancia peleadores configurados | **LISTO** |

`GameManager` también spawnea a los 4 peleadores: los slots 1 y 2 como `PLAYER`, el 3 y 4 como `NPC`.

`GameManager` instancia la `CameraFollow` desde el prefab `prefabs/camera_follow.tscn` (igual que
`SpawnPoint` hace con los peleadores), le asigna el `PlayArea` como `camera_area` antes del `add_child`,
y la cuelga de sí mismo. El fov y la distancia inicial se ajustan en la `Camera3D` hija del prefab. La cámara **ya no tiene** referencia al manager, y el
mapa quedó sin nodos de cámara: sus únicas dependencias son `PlayArea` y 4 spawn points.

## Módulos que faltan

### `CameraManager` — pendiente

La costura del temblor ya se cortó: el `GameManager` ya no llama `shake()`. Al crear la cámara
conecta su señal `lives_changed` a `CameraFollow.on_power_fighter_died`, y la cámara decide el
efecto (hoy tiembla `shake_duration_ms`, export del prefab). El manager no sabe qué es un temblor.

Lo que queda: el `CameraFollow` todavía mezcla **encuadre** (seguir peleadores, rect, distancia) y
**efectos** (el temblor). Si los efectos crecen (flash, zoom dramático al último KO), conviene
sacarlos a un `CameraManager` que escuche las mismas señales, sin tocar el manager.

Otra dependencia implícita: la cámara encuentra a los peleadores porque es hija del `GameManager`
(busca entre los hijos de su padre). Cortarla implicaría pasarle los peleadores con
`power_fighter_spawned` / `power_fighter_eliminated`.

También falta recuperar lo que se perdió al simplificar: **encuadrar el punto de muerte** mientras
el peleador espera su respawn (`get_pending_respawn_positions()` del manager viejo, eliminado). El manager actual ya guarda `_death_position_of_power_fighter`, pero hoy no lo usa nadie.

### `TalkerManager` — pendiente (el comentarista)

El comentarista es el consumidor más claro del principio, porque **no toca las reglas**: solo
observa y comenta. Debería ser un módulo que escucha eventos de la partida y decide qué decir.

Eventos que le sirven (hoy el `GameManager` **no emite ninguna señal**, esto es lo que habría que agregar):

- muerte de alguien (y a quién le quedan cuántas vidas)
- último KO de la partida
- alguien con daño alto
- combos largos
- inicio y fin de partida

Nada de esto debe requerir que el `GameManager` sepa que existe un comentarista. El manager
emitiría una señal de muerte (por ejemplo `death_occurred(...)`, nombre ilustrativo, no existe aún); el `TalkerManager` decide si habla.

### `EffectsManager` — pendiente

Aplica el mismo criterio que el comentarista, pero a efectos visuales: ragdoll al morir, destellos
de golpe, partículas de impacto.

Y aquí hay una decisión de diseño que sigue abierta: **¿quién dispara el efecto?** Hay dos
posturas y el proyecto aún no ha elegido:

- **El manager dispara**: el manager sabe que alguien murió y pide el ragdoll. Simple, pero
  entonces el manager vuelve a saber de-effects.
- **El objeto vivo dispara**: el `PowerFighter` detecta su propia muerte y se reemplaza por un
  ragdoll. El manager solo lleva las vidas. Más fiel al principio, pero reparte la decisión.

Ojo: hoy nadie detecta su propia muerte. La muerte sigue siendo **salirse del `PlayArea`**, y la
muerte por `hp == 0` (que es la que dispararía el ragdoll) sigue pendiente.

### Otros que probablemente hagan falta

- **`MatchFlow`**: contar el final de la partida (cuándo se acabaron las vidas de todos), rondas.
- **`ScoreManager`** o similar: quién va ganando, para el HUD.
- **`AudioManager`**: sonidos de golpe, muerte, KO. Mismo patrón que el comentarista.

## Cómo se documenta la modularidad

- Un módulo por concern, un archivo, un `class_name` sin prefijo.
- Las carpetas de módulos van en `scripts/match/`. Lo que ya no se usa se **elimina del repo**
  (queda en el historial de git). Antes se archivaba en `scripts/legacy/` con prefijo `Old*`
  (`OldGameManager`, `OldCameraFollow`, `OldSpawnPoint`), pero esa carpeta ya no existe.
- Cuando un módulo se elimina, su nota en `docs/` se elimina también (queda en el historial de git).
- El diagrama de clases de `docs/arquitectura/uml-arquitectura.md` es la fuente de verdad de qué módulos
  existen hoy. La lista de "módulos que faltan" de esta nota es el backlog, no el estado.

## Lo que NO se debe hacer

- **Meter reglas de juego en un módulo de presentación.** Si el `CameraFollow` necesita saber
  cuántas vidas le quedan a alguien para hacer un efecto, es señal mal puesta: el evento
  debería llevar ese dato, no el módulo ir a buscarlo.
- **Que un módulo le guarde estado a otro** para que otro pueda preguntar (el patrón
  `_shake_end_time_msec` del manager viejo). Si un módulo necesita guardar algo, lo guarda
  para sí mismo, y avisa.
- **Un `GameManager` que crece.** Si le estás agregando una sección nueva, probablemente es un
  módulo nuevo.
