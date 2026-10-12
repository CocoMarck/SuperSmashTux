# UML — Arquitectura de código

> Mapa de clases del proyecto. Para la explicación de personajes ver `docs/arquitectura/arquitectura-personajes.md`.

## Personajes

```
CharacterBody3D → GravityBody3D → Person → Fighter → PowerFighter → Player / NPC
```

## Diagrama

```mermaid
classDiagram
	direction TB

	CharacterBody3D <|-- GravityBody3D
	GravityBody3D <|-- Person
	Person <|-- Fighter
	Fighter <|-- PowerFighter
	PowerFighter <|-- Player
	PowerFighter <|-- NPC

	Platform <|-- GroundPlatform
	Platform <|-- OneWayPlatform

	Person ..> GroundPlatform : se agarra
	Fighter ..> Attacks : usa
	Attacks *-- FightMove
	Fighter ..> Hitbox : crea
	PowerFighter ..> PowerAttacks : usa
	PowerAttacks *-- FightMove
	NPC ..> Platform : detecta
	NPC ..> Person : detecta
	Person ..> Hitbox : recibe daño
	Player ..> PlayerInputMap : usa
	GlobalUtils o-- PlayerInputMap
	SpawnPoint ..> PowerFighter : instancia
	GameManager ..> SpawnPoint : usa
	GameManager ..> PowerFighter : respawnea
	GameManager ..> CameraFollow : crea y configura
	GameManager o-- CameraFollow
```

## Notas

- `GravityBody3D`: gravedad 2D + colisiones (normales y entre cuerpos) + medidas del cuerpo.
- `Person`: moverse, saltar, ledge grab, plataformas one-way (drop-through y coyote time), daño, `respawn()`.
- `Fighter`: ataques (15 `FightMove`), grab (con `HitboxGrab` y lanzamiento), shield (con defensa y roll).
- `PowerFighter`: doble salto y ataques de poder (`PowerAttacks`); el "tercer salto" es el ataque de poder hacia arriba (`jump_power`).
- `NPC`: IA propia vía `_process_ai(delta, frame)` (hook definido en `Person`).
- `GameManager` es **modular**: un concern por módulo en `scripts/match/`, sin que un módulo le pregunte a otro. Ver `docs/arquitectura/nota-game-manager-modular.md`.
- Señales-objeto: `VerticalForceSignals`, `MoveSignals`, `MoveStates` (RefCounted en `scripts/helpers/frame`).
