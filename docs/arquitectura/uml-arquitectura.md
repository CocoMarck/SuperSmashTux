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
	GameManager o-- LivesManager
	LivesManager ..> PowerFighter : track / respawn
	GameManager o-- PowerFighterSlots
	PowerFighterSlots *-- PowerFighterData
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
- `GameManager` es el **nodo raíz del mapa**: cada mapa lo trae junto con `PlayArea`, `SpawnPoint1..4` y el nodo `LivesManager`. Las vidas las maneja `LivesManager`; el manager reemite sus señales.
- `GameManager` tiene un `PowerFighterSlots` en memoria con un `PowerFighterData` por slot. `CharacterMenu` lo llena antes de cambiar de escena; no hay respaldo si está vacío. Ver `docs/arquitectura/nota-power-fighter-configurer.md`.
- El tiempo límite todavía no existe. La propuesta `MatchTime` vive en `docs/arquitectura/nota-match-time.md`.
- A futuro el `GameManager` debería operar sobre `Person` (el papá) en vez de `PowerFighter`, para soportar más modos de juego.
- Señales-objeto: `VerticalForceSignals`, `MoveSignals`, `MoveStates` (RefCounted en `scripts/helpers/frame`).
