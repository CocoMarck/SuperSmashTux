# UML — Arquitectura de código

> Mapa de clases del proyecto. Para la explicación de personajes ver `docs/arquitectura-personajes.md`.

## Personajes

```
CharacterBody3D → GravityBody3D → Person → Fighter → PowerFighter → Player / TestPlayer / NPC
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
	PowerFighter <|-- TestPlayer
	PowerFighter <|-- NPC

	Platform <|-- GroundPlatform
	Platform <|-- OneWayPlatform

	Person ..> GroundPlatform : se agarra
	Fighter ..> Attacks : usa
	Attacks *-- FightMove
	Fighter ..> Hitbox : crea
	Person ..> Hitbox : recibe daño
	Player ..> PlayerInputMap : usa
	GlobalUtils o-- PlayerInputMap
	SpawnPoint ..> PowerFighter : instancia
	GameManager ..> SpawnPoint : usa
	GameManager ..> PowerFighter : respawnea
```

## Notas

- `GravityBody3D`: gravedad 2D + colisiones (normales y one-way).
- `Person`: moverse, saltar, ledge grab, daño, `respawn()`.
- `Fighter`: ataques (13 `FightMove`), grab y shield (temporizadores).
- `PowerFighter`: doble salto; poderes pendientes.
- `Character` y `OldFightMove` son legacy, fuera de la cadena.
- Señales-objeto: `VerticalForceSignals`, `MoveSignals`, `MoveStates` (RefCounted en `scripts/helpers`).
