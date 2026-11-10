# Nota: GameManager modular

> **Regla de arquitectura.** El `GameManager` **no debe ser un monolito**. Cada concern de la partida
> vive en su propio módulo, dentro de `scripts/match/`. Este documento define qué módulos existen,
> cuáles faltan, y cómo se hablan entre ellos.

Reemplaza la idea vieja de "un manager que hace todo" (su nota se eliminó; queda en el historial de git).

## `GameManager` es el mapa

`GameManager` es el script del **nodo raíz de cada mapa** (`Main` en `map1.tscn`), no un autoload ni un manager global. Cada mapa lo trae y debe incluir: `PlayArea` (`Area3D` con caja), `SpawnPoint1..4` y un nodo `LivesManager`. Los módulos de partida cuelgan de él.

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
| Reglas de partida | `GameManager` | lineup, cuenta regresiva, cronómetro, fin y cámara | **LISTO** |
| Datos de lineup | `PowerFighterSlots` | datos por slot: control, config, vidas y `player_id` | **LISTO** |
| Vidas | `LivesManager` | vidas, muerte por salir del `PlayArea`, respawn y eliminación | **LISTO** |
| Encuadre | `CameraFollow` | sigue a los peleadores, zoom, temblor al morir alguien (escucha `lives_changed`) | **LISTO** |
| Colocación | `SpawnPoint` | instancia peleadores configurados | **LISTO** |

`GameManager` también spawnea a los peleadores. El lineup sale de `power_fighter_slots`
(`PowerFighterSlots`), que llena `CharacterMenu` antes de cambiar de escena. **No hay respaldo**: si
un slot no existe, no se spawnea. Abrir `map1.tscn` directo desde el editor deja la partida sin
peleadores.

> Resto temporal: `scripts/helpers/match_setup_legacy.gd` (`MatchSetupLegacy`) sigue en el repo, pero
> no lo referencia nadie. No forma parte del flujo y se puede borrar.

`GameManager` instancia la `CameraFollow` desde el prefab `prefabs/camera_follow.tscn` (igual que
`SpawnPoint` hace con los peleadores), le asigna el `PlayArea` como `camera_area` antes del `add_child`,
y la cuelga de sí mismo. El fov y la distancia inicial se ajustan en la `Camera3D` hija del prefab. La cámara **ya no tiene** referencia al manager, y el
mapa quedó sin nodos de cámara: sus únicas dependencias son `PlayArea` y 4 spawn points.

## `LivesManager` — vidas, respawn y eliminación

Vive en `scripts/match/lives_manager.gd` y es un **nodo hijo del mapa** (`LivesManager` en
`map1.tscn`). El `GameManager` lo toma con `$LivesManager`.

- **Configuración fija**: solo `respawn_delay` (`@export` del nodo).
- **Datos por partida**: el `GameManager` los inyecta. `setup(fighter_parent, play_area_bounds)` le pasa el padre y el área; `track(power_fighter, max_lives, respawn_position)` registra a cada peleador recién spawneado. Las vidas salen de `PowerFighterData.lives`; el `GameManager` llama `track(power_fighter, slot.lives, ...)`. Ya no existe `lives_per_character`.
- **Ciclo**: `start()` empieza a revisar salidas del `PlayArea`; `stop()` lo detiene al terminar la partida.
- **Señales**: `lives_changed`, `eliminated` (antes del `queue_free`), `respawned` y `deaths_resolved(remaining)`.

El `GameManager` **reemite** `lives_changed` y `power_fighter_eliminated` para conservar el contrato del HUD, y con `deaths_resolved` decide el fin de la partida. Los peleadores siguen siendo **hijos directos del `GameManager`** porque la cámara y el HUD los descubren como hermanos; `LivesManager` solo los saca del árbol y los vuelve a meter durante el respawn.

## `PowerFighterSlots` — lineup por slot

`PowerFighterData` (`scripts/helpers/power_fighter_data.gd`) es un `RefCounted` con los datos de un
slot: `control`, `config`, `lives` y `player_id`.

`PowerFighterSlots` (`scripts/match/power_fighter_slots.gd`) es un `Node` que guarda un
`Dictionary[int, PowerFighterData]`. El `GameManager` lo instancia con `PowerFighterSlots.new()` como
propiedad (`power_fighter_slots`); **no** se cuelga del árbol.

- `set_slot(id, data)`: valida que sea `PowerFighterData` y que `config` esté en
  `GlobalUtils.CONFIG_OPTIONS`.
- `get_slot(id)`: devuelve los datos; si el slot no existe, falla a propósito.
- `has_slot(id)`: dice si ese slot está ocupado.
- `get_slots()`: devuelve el diccionario completo. A diferencia de una lista compactada, conserva el
  id de cada slot.

`CharacterMenu` escribe con `set_slot(i, data)` y `GameManager._spawn_all_power_fighters()` lee con
`has_slot(i)` + `get_slot(i)`. Deuda conocida: `FightHud` todavía usa `get_slots().values()` y luego
indexa por slot; eso solo es correcto si los slots son contiguos. Pendiente usar `has_slot/get_slot`.

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
el peleador espera su respawn (`get_pending_respawn_positions()` del manager viejo, eliminado). Hoy `LivesManager` guarda `_death_position` (posición donde cayó cada peleador), pero todavía no lo usa nadie; es el dato que necesita el efecto de cámara.

### `TalkerManager` — pendiente (el comentarista)

El comentarista es el consumidor más claro del principio, porque **no toca las reglas**: solo
observa y comenta. Debería ser un módulo que escucha eventos de la partida y decide qué decir.

Eventos que le sirven (el `GameManager` ya emite señales y reemite las de `LivesManager`; el comentarista solo tendría que escucharlas):

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

- **`MatchTime`**: cuenta regresiva y tiempo límite de la partida. Hoy el cronómetro vive en el
  `GameManager` y `TIME_OPTIONS` todavía no se pasa a la partida. Idea y API propuesta en
  [nota-match-time.md](nota-match-time.md). El nombre `MatchClock` de notas anteriores queda
  descartado.
- **`MatchCountdown`**: cuenta regresiva y letrero de ¡PELEA! antes de arrancar.
- **`MatchHUD`**: puente entre las reglas y el `FightHud`, para sacar del manager el contrato de señales.
- **`GameSpeed`**: cámara lenta o freeze al dar un golpe killer.
- **`PersonName`**: helper estático enfocado a `Person` para obtener el nombre visible (sirve para `PowerFighter` y futuros hijos). Usa `Node.name`; no se debe declarar `var name` en `Person` porque choca con `Node.name`.
- **`ScoreManager`** o similar: quién va ganando, para el HUD.
- **`AudioManager`**: sonidos de golpe, muerte, KO. Mismo patrón que el comentarista.

### Deuda de diseño: `GameManager` debe tratar `Person`

El `GameManager` hoy trabaja con `PowerFighter` porque el único modo es pelea. Para crecer a otros modos (equipos, objetivos, `Person` que no pelea), conviene que opere sobre **`Person`**, el papá común de `Player`, `NPC`, `PowerFighter` y futuros personajes. Así el manager no arrastra ataques, saltos ni poderes que no todos los modos necesitan.

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
