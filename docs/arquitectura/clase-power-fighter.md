# Clase: `PowerFighter`

> `PowerFighter` es la capa de combate con poder sobre `Fighter`: doble salto y 6 `FightMove` de `PowerAttacks`. Verificado contra el working tree el 2026-11-26. Rutas: `scripts/characters/power_fighter.gd`, `scripts/characters/fighter.gd`, `scripts/characters/person.gd`, `scripts/helpers/combat/power_attacks.gd`, `scripts/helpers/frame/move_input.gd`, `scripts/match/power_fighter_configurer.gd`, `data/characters/tux.power_fighter.cfg`, `prefabs/standard_power_fighter.tscn`.
## Resumen

Extensión deliberadamente pequeña de `Fighter` (`power_fighter.gd:1-2`): solo añade el flag de poder, el catálogo `power_attacks` y el segundo salto. El rol jugador/NPC NO vive aquí: vive en el nodo hijo `PersonController3D` (`PlayerController` / `NpcController`), según [arquitectura-personajes.md](arquitectura-personajes.md).

## Superficie pública

| Símbolo | Línea | Nota |
|---|---|---|
| `_power_attack: bool` | `power_fighter.gd:5` | Flag privado; solo se lee en el hook de power. |
| `power_attacks: PowerAttacks` | `power_fighter.gd:8` | Catálogo público de 6 movimientos; el configurer lo puede reemplazar. |
| `input.power_attack` → `_power_attack` | `power_fighter.gd:164` | Único flag que esta clase agrega al copiado de `MoveInput` (`move_input.gd:18`). |

## Hooks y pipeline

Sobrescribe `_collect_controller_input` (`power_fighter.gd:155`) para copiar ese flag; `Person._collect_controller_input` (`person.gd:1248`) se queda con la colección base. Sobrescribe `_false_inputs` (`power_fighter.gd:133`) para sumar `_power_attack = false` a la cadena `Person` (`person.gd:450`) → `Fighter` (`fighter.gd:329`). Implementa `_init_power_attack_by_move` (`power_fighter.gd:138`), hook vacío en `Fighter` (`fighter.gd:455`). `_init()` (`power_fighter.gd:169`) pone `_max_jumps = 2` sobre el default de `Person` (`person.gd:76`).

Cadena real, en orden dentro del mismo frame: `Fighter._process_attack()` (`fighter.gd:459`) → `_init_attack_by_move()` (`fighter.gd:465`) → `_init_power_attack_by_move()` (`fighter.gd:466`). No son llamadas anidadas: el power corre **después** y puede pisar el `_current_attack` normal antes de que `_set_attack()` inicialice contadores (`fighter.gd:472-485`). Detalle del pipeline en [nota-ataques.md](../combate/nota-ataques.md).

NO sobrescribe `_physics_process` (`person.gd:1262`), `_process_action` (`fighter.gd:920`), `_process_stun` (`person.gd:1066`), `_ready` (`fighter.gd:893`) ni la cancelación de ataques (`fighter.gd:488`). El power se cuelga de hooks, no de funciones sensibles.

## Estado interno y game feel

Los defaults de `PowerAttacks` están hardcodeados en el propio script (`power_fighter.gd:8-131`): 6 moves (`standard`, `down`, `up`, `air_standard`, `air_down`, `air_up`; nombres de animación en [normal-and-power-attacks-moves.md](../combate/normal-and-power-attacks-moves.md)). `up` y `air_up` traen `jump_power: 12.0` (`power_fighter.gd:59`, `power_fighter.gd:120`). Eso dispara el castigo de ataque saltarín de `Fighter`: `_fight_move()` cuenta el intento, lo corta al pasar de 1 y devuelve los saltos al máximo (`fighter.gd:409-410`, `fighter.gd:564-578`), con reinicio al tocar piso (`fighter.gd:544-545`). Es el "tercer salto" documentado en [arquitectura-personajes.md](arquitectura-personajes.md), no un salto extra del contador.

Tux reemplaza esos 6 defaults desde `data/characters/tux.power_fighter.cfg` (`power_fighter_configurer.gd:109-113`); `standard` conserva los defaults de prefab/code (`prefabs/standard_power_fighter.tscn:19-21`). No migrarlos "por higiene": la decisión está en [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md).

## Invariantes

- Un solo `_power_attack` por frame: `MoveInput` trae un bool (`move_input.gd:18`), el controller lo resetea (`person_controller_3d.gd:28`) y `_collect_controller_input` lo copia una vez (`power_fighter.gd:164`). No hay cola ni buffer; `_false_inputs` lo baja con input bloqueado (`person.gd:479-480`).
- Cakeo por hook: el poder se inyecta en `_init_power_attack_by_move` sin tocar `_physics_process`, `_process_action`, `_process_stun`, `_ready` ni `_cancel_attack`.
- `standard` sin cfg: poder y saltos salen de code/prefab; los `.power_fighter.cfg` son para ids no-standard.

## Deudas / puntos de refactor

- `_max_jumps = 2` (`power_fighter.gd:170`) convive con el default base `_max_jumps = 1` (`person.gd:76`) y con un prefab que no lo exporta (`prefabs/standard_power_fighter.tscn:19-21`): la política de saltos está partida entre código y plantilla.
- Defaults de `PowerAttacks` hardcodeados en `power_fighter.gd:8-131` junto al cfg de Tux: dos fuentes de verdad para el mismo conjunto de 6 moves.
- `PowerAttacks._init()` (`power_attacks.gd:24-35`) solo mergea el `Dictionary`; no hay validación profunda de slots ni de `FightMove`, igual que en el configurer.

## Ver también

- [clase-fighter.md](clase-fighter.md) — ficha de la base (`Fighter`).
- [arquitectura-personajes.md](arquitectura-personajes.md) — jerarquía `Person` → `Fighter` → `PowerFighter` y controllers.
- [nota-ataques.md](../combate/nota-ataques.md) — selección de ataque, `jump_power` y cancelación.
- [normal-and-power-attacks-moves.md](../combate/normal-and-power-attacks-moves.md) — nombres de los 15 normales y los 6 power.
- [nota-power-fighter-configurer.md](nota-power-fighter-configurer.md) — cfg por personaje vs defaults de `standard`.
