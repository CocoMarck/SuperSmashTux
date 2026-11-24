# Nota: Escalabilidad de personajes

> Qué tan fácil es sumar personajes con la arquitectura actual: qué funciona, qué estorba y una propuesta (**parcialmente implementada** al 2026-11-16). La jerarquía de clases vive en [arquitectura-personajes.md](arquitectura-personajes.md); el sistema de ataques en [nota-ataques.md](../combate/nota-ataques.md); el hitbox en [hitbox.md](../combate/hitbox.md); los nombres de animación en [asset-personaje.md](../arte/asset-personaje.md).
>
> Rutas cortas: `scripts/characters/` (`person.gd`, `fighter.gd`, `power_fighter.gd`), `scripts/controllers/` (`player_controller.gd`, `npc_controller.gd`), `scripts/match/spawn_point.gd`, `scripts/helpers/combat/` (`attacks.gd`, `power_attacks.gd`, `fight_move.gd`, `hitbox_move.gd`), `scripts/combat/hitbox_damage.gd`. Líneas verificadas el 2026-11-07; rol migrado a controllers el 2026-11-16.

## Resumen

**Calificación: 6.5/10.** Sólido para un prototipo con un personaje. Incómodo para escalar a un roster: cada personaje con moveset propio exige copiar cientos de líneas, y combinar un moveset propio con el rol de jugador o NPC obliga a duplicar clases.

## Lo que funciona

- **Ataques como datos.** Cada ataque es un diccionario que `FightMove` y `HitboxMove` mezclan sobre sus valores por defecto (`fight_move.gd`, `hitbox_move.gd`). *Por qué:* para balancear (daño, duración, tamaño de hitbox) se cambian números, no la lógica de `fighter.gd:511` (`_fight_move()`).
- **Capas con hooks vacíos.** `Person` define `_process_action` (`person.gd:1173`), `_cancel_action` (`person.gd:1179`) y `_process_visual` (`person.gd:1185`) como `pass`. `Fighter` sobrescribe `_process_action` (`fighter.gd:881`) y `_cancel_action` (`fighter.gd:944`). *Por qué:* cada capa agrega lo suyo sin tocar la física base. (Los hooks de input `_collect_input`/`_process_ai` se borraron con el refactor a controllers.)
- **Cerebro separado de habilidades.** Quién decide la acción está aparte de lo que el personaje puede hacer: `PlayerController` lee teclado y `NpcController` usa IA (nodos hijos). Ambos escriben los mismos bools (`_move_left`, `_attack`...) que el combate consume, hoy vía su `MoveInput`.
- **Un solo tipo de hitbox.** `HitboxDamage` sirve para golpe pegado al cuerpo (hijo del `Pivot`, `fighter.gd:350-352`) y para proyectil (`use_gravity`, nodo libre de la escena, `fighter.gd:353-358`). *Por qué:* la diferencia es un flag; no hay dos clases que mantener.

## Problemas

### 1. Moveset dentro del script

- `fighter.gd:48` define 15 `FightMove` (líneas 48-292) y `power_fighter.gd:8` define 6 (líneas 8-131). No hay movesets en `.tres`: el proyecto solo tiene `.tres` de entorno y materiales.
- Hay duplicación en `power_fighter.gd`: `down`/`air_down`, `standard`/`air_standard` y `up`/`air_up` tienen los mismos hitboxes y solo difieren en `name` y en flags de aire (`air_attack`, `override_horizontal_move`).
- *Efecto:* un personaje nuevo con moveset propio son unas 370 líneas que copiar y ajustar. *Por qué pesa:* un ajuste de balance hay que replicarlo a mano en cada par.

### 2. Slots fijos

- `Attacks` tiene 15 campos y su `_init` pide los 15 en orden (`attacks.gd:23`). `PowerAttacks` tiene 6 claves fijas (`power_attacks.gd:15-21`, lectura en `power_attacks.gd:30-35`).
- *Efecto:* un personaje con 3 ataques, o con un especial extra, exige tocar la clase base. `PowerAttacks` ignora en silencio las claves que no conoce: un `"special"` no da error, simplemente no se usa.
- *Por qué existen así:* `_init_attack_by_move()` (`fighter.gd:400`) elige el ataque por nombre de slot (`attacks.heavy_side`, etc.). Cambiar el conjunto de slots obliga a cambiar también ese selector.

### 3. Doble salto y poderes atados a `PowerFighter`

- `power_fighter.gd:161` (`_max_jumps = 2`, dentro de `_init()`) y el catálogo `power_attacks` viven en la misma clase. Mezclan dos cosas distintas: "puede lanzar poderes" y "tiene doble salto". Un personaje con poderes y salto simple (o al revés) no puede tomar solo una de las dos sin heredar la otra.
- *Verificado (2026-11-07, ya no aplica):* `set_script()` ejecutaba el `_init()` del script nuevo (probado en Godot 4.7.2 con un proyecto de prueba aislado, nodo plano + `set_script`), por eso el `_max_jumps = 2` aplicaba a `Player`/`NPC` aunque el prefab no tuviera script. Hoy ya no hay `set_script`: el prefab trae `script = power_fighter.gd` y `_max_jumps = 2` corre en su `_init()`.

### 4. `Player`/`NPC` al final de la herencia (problema principal) — **RESUELTO (2026-11-16)**

- `player.gd:2` y `npc.gd:2` heredaban de `PowerFighter`. GDScript tiene herencia única: un personaje con script propio (`extends PowerFighter`, por ejemplo) no puede además ser `Player` ni `NPC`.
- `SpawnPoint.spawn()` (`spawn_point.gd:12`) instanciaba un prefab genérico (`standard_power_fighter.tscn`, raíz `CharacterBody3D` sin script) y le ponía el script con `set_script` (`spawn_point.gd:23` y `spawn_point.gd:28`).
- *Lo que se ganaba:* un solo prefab sirve para jugador y NPC.
- *Lo que costaba:* para un personaje con script propio habría que crear `PlayerX extends X` y `NPCX extends X`, copiando la lógica de `player.gd` y `npc.gd`. Con N personajes son 2N clases de rol. Además, el `match` de `spawn()` solo cubre `PLAYER` y `NPC` (`scripts/helpers/global_utils.gd:5`), así que cualquier otro rol no recibe script.

> **Resuelto:** el rol dejó de ser herencia. `Player`/`NPC` (y `player.gd`/`npc.gd`) se borraron y viven como nodos hijos `PlayerController`/`NpcController` (`PersonController3D`). El prefab lleva `script = power_fighter.gd` y el configurer asigna `controller` en vez de `set_script`. Ver [nota-power-fighter-controller.md](nota-power-fighter-controller.md).

### 5. Los datos solo cubren golpes

- Hoy los datos cubren golpes, saltos de ataque (`jump_power`, usado por `up` y `air_up` de `PowerFighter`) y proyectiles con gravedad y rebote (`use_gravity`, `bounce`, `fighter.gd:350-358`).
- Mecánicas como teletransporte, contraataque o carga no tienen campo en el dato: requieren código nuevo en `Fighter` o en una subclase.

### 6. Animaciones atadas por nombre

- `_attack_anim()` (`fighter.gd:595-599`) reproduce `_current_attack.name` en el `AnimationPlayer`. El nombre del `FightMove` **es** el nombre de la animación; ahora tiene setter porque el loader de `.fighter.cfg` lo asigna desde cfg, así que el cfg debe respetar esos nombres exactos.
- Un modelo nuevo debe traer esos nombres exactos (lista en [asset-personaje.md](../arte/asset-personaje.md), sección Animaciones). Si falta uno, ese doc advierte que puede romperse.
- *Efecto:* es una ventaja para variantes (cambiar de modelo no toca código) y un límite para personajes con animaciones distintas.

### 7. `GameManager` acoplado a `PowerFighter`

- El lineup, las vidas y el fin de partida del `GameManager` asumen `PowerFighter`. Para modos futuros (equipos, objetivos, `Person` que no pelea) conviene que opere sobre **`Person`**, el papá común, en vez de la capa de combate.
- *Por qué pesa:* un modo nuevo que no sea pelea tendría que fingir ser `PowerFighter` o duplicar la lógica del manager.

## Dificultad hoy

| Caso | Dificultad | Por qué |
|---|---|---|
| Variante: mismo rig, otro modelo y/o números | Fácil/medio | Con el mismo moveset basta el modelo con los nombres exactos. Con números propios hace falta una subclase, y ahí choca el problema 4: hoy todos comparten el catálogo de la clase base |
| Personaje realmente distinto (moveset, poderes, mecánicas) | Medio/difícil | Copiar o reescribir ~370 líneas, slots fijos, `PlayerX`/`NPCX`, mecánicas nuevas en `Fighter` |

## Propuesta (NO implementada)

> Idea para discutir. Nada de esto existe en el código.

1. **Moveset como `Resource` (`.tres`)**: un recurso con un diccionario de ataques (`nombre → config de FightMove`). *Por qué:* el catálogo sale del código y cada personaje tiene el suyo. La selección de `_init_attack_by_move()` pediría claves en vez de campos fijos, lo que resuelve el problema 2.
2. **Player/NPC como controladores por composición** — **IMPLEMENTADO (2026-11-16)**: un nodo hijo que lee teclado o IA y manda órdenes al personaje (`move_left`, `attack`...). *Por qué:* el personaje queda como una sola clase y el rol deja de ser herencia. Elimina `PlayerX`/`NPCX` (problema 4). Ver [nota-power-fighter-controller.md](nota-power-fighter-controller.md).
3. **Stats en el mismo recurso**: saltos máximos, velocidades, etc. *Por qué:* `_max_jumps` deja de depender de `PowerFighter` (problema 3).

**Resultado esperado:** personaje nuevo = un `.tres` + modelo con animaciones.

```mermaid
flowchart LR
    R[("Recurso .tres<br/>moveset + stats")] -. datos .-> P["Personaje<br/>(Person / Fighter)<br/>física y combate"]
    C1["Controlador Player<br/>lee teclado"] -->|órdenes| P
    C2["Controlador NPC<br/>lee IA"] -->|órdenes| P
```

**Preguntas abiertas** (decisión del equipo antes de avanzar):
- ~~¿El controlador es un nodo hijo, como se propone aquí, o se queda como script de rol?~~ **Decidido (2026-11-16): nodo hijo.**
- ¿Los stats van en el mismo `.tres` que el moveset o en otro recurso?
- ¿Las mecánicas especiales (teletransporte, contraataque) se modelan como datos o como subclases de `Fighter`?

## Ver también

- [arquitectura-personajes.md](arquitectura-personajes.md): jerarquía `Person` → `Fighter` → `PowerFighter`.
- [nota-ataques.md](../combate/nota-ataques.md): cómo se elige y ejecuta un ataque.
- [hitbox.md](../combate/hitbox.md): construcción y ciclo de vida del hitbox.
- [asset-personaje.md](../arte/asset-personaje.md): nombres de animación fijos.
