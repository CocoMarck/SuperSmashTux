# Nota: GameManager modular

> **Regla de arquitectura.** El `GameManager` **no debe ser un monolito**. Cada concern de la partida
> vive en su propio módulo, dentro de `scripts/match/`. Este documento define qué módulos existen,
> cuáles faltan, y cómo se hablan entre ellos.

Reemplaza la idea vieja de "un manager que hace todo": ver `nota-game-manager-inyectable.legacy.md`.

## El problema que resuelve

El `GameManager` original (`scripts/legacy/old_game_manager.gd`) mezclaba en un solo archivo:

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
| Encuadre | `CameraFollow` | sigue a los peleadores, zoom, temblor (el temblor debería salir de aquí) | **LISTO** |
| Colocación | `SpawnPoint` | instancia peleadores configurados | **LISTO** |

`GameManager` crea la `CameraFollow` por código (`CameraFollow.new()`), le inyecta el `PlayArea`
como `camera_area`, y la cuelga de sí mismo. La cámara **ya no tiene** referencia al manager, y el
mapa quedó sin nodos de cámara: sus únicas dependencias son `PlayArea` y 4 spawn points.

## Módulos que faltan

### `CameraManager` — pendiente

Hoy el `CameraFollow` mezcla dos cosas que deberían estar separadas:

- **Encuadre** (seguir peleadores, calcular rect y distancia). Esto ya es un módulo aparte.
- **Efectos de cámara** (el temblor). Hoy es un método público que el manager **llama directo**
  (`_camera_follow.shake(500)`), no una señal. Es la costura que queda por cortar.

Lo que debería pasar: el `GameManager` emite una señal cuando alguien muere, y un
`CameraManager` la escucha y decide el temblor, el tiempo, y la intensidad. Así el manager
deja de saber qué es un temblor, y agregar un efecto nuevo (flash, zoom dramatico al último KO)
no toca el manager.

También falta recuperar lo que se perdió al simplificar: **encuadrar el punto de muerte** mientras
el peleador espera su respawn (`get_pending_respawn_positions()` del manager viejo).

### `TalkerManager` — pendiente (el comentarista)

El comentarista es el consumidor más claro del principio, porque **no toca las reglas**: solo
observa y comenta. Debería ser un módulo que escucha eventos de la partida y decide qué decir.

Eventos que le sirven, y que la partida ya puede emitir:

- muerte de alguien (y a quién le quedan cuántas vidas)
- último KO de la partida
- alguien con daño alto
- combos largos
- inicio y fin de partida

Nada de esto debe requerir que el `GameManager` sepa que existe un comentarista. El manager
emite `death_occurred(...)`; el `TalkerManager` decide si habla.

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
- Las carpetas de módulos van en `scripts/match/`. Lo que ya no se usa, a `scripts/legacy/`
  con prefijo `Old*` en el `class_name` (`OldGameManager`, `OldCameraFollow`, `OldSpawnPoint`),
  para que los nombres sigan documentando de qué implementación son.
- Cuando un módulo se vuelve legacy, su nota en `docs/` se renombra a `.legacy.md` y se le
  pone un banner al inicio. Así el doc sigue legible pero nadie lo toma por vigente.
- El diagrama de clases de `docs/uml-arquitectura.md` es la fuente de verdad de qué módulos
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
