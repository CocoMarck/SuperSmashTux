# UML — Refactor de Character (Person / Fighter / PowerFighter)

> **Aplicado.** La división de `Character` en `Person` / `Fighter` / `PowerFighter` ya está en el código. Este doc quedó como registro histórico de lo que se planeó; el estado real vive en `docs/arquitectura-personajes.md` (explicación por capa) y `docs/uml-arquitectura.md` (diagrama completo).

## Qué quedó como se planeó

- `CharacterBody3D → GravityBody3D → Person → Fighter → PowerFighter` ✅
- `Person`: moverse, saltar (multi-salto, default 1), ledge grab, recibir daño con knockback, `respawn()`, `_collect_input()` virtual. ✅
- `Fighter`: salta 1 vez, `_attacks` (13 `FightMove` configurados con `Dictionary`), `_fight_move()`, hitbox, grab y shield. ✅
- `PowerFighter`: `_max_jumps = 2`. ✅
- `Player`, `TestPlayer` y `NPC` ahora cuelgan de `PowerFighter`. ✅
- Señales como objetos (`VerticalForceSignals`, `MoveSignals`, `MoveStates`) en `scripts/helpers`. ✅
- `Hitbox` checa víctima con `body is Person` (antes `body is Character`). ✅

## Qué cambió de camino vs. la propuesta original

- `Character` no se borró: quedó como clase legacy (`scripts/character.gd`) sin herederos activos.
- El grab/shield empezaron como temporizadores en `Fighter` (`_grab_time`, `_shield_time`), todavía sin grab box ni bloqueo de daño.
- `_ai_process` para NPCs se decidió más adelante y quedó documentado en `docs/nota-ai-npc.md`.
- La muerte por `hp == 0` (ragdoll + respawn) sigue pendiente; hoy respawnea el `GameManager` cuando alguien se sale del área jugable.

## Decisiones resueltas

1. Conteo de saltos: `Fighter` salta 1, `PowerFighter` 2 (via `_max_jumps`). ✅
2. Nombre del papá: se usó `Person` (reemplaza a `Character`). ✅
3. Víctima del hitbox: `body is Person`. ✅
4. Animaciones: `_move_anim` en `Person`; `Fighter` usa `_attack_anim`. ✅
5. PowerFighter: doble salto aplicado; golpes/salto de poder quedaron como placeholder. 🕓
6. Plataformas: one-way en `GravityBody3D`, ledge grab en `Person`. ✅
7. `GlobalUtils.CharacterType`: solo `PLAYER` y `NPC` (el `GameManager` decide el prefab `standard_power_fighter.tscn` y el script a asignar). ✅
