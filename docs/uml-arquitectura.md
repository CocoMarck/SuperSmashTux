# UML — Arquitectura de Character

## Diagrama de clases

```mermaid
classDiagram
    direction LR

    Character <|-- Player
    Character <|-- Npc

    class Character {
        <<prefab>>
        +speed: float
        +jump_velocity: float
        +input_actions: Dictionary
        +_physics_process(delta)
        +_handle_movement(direction: Vector3)
        +move_and_slide()
    }

    class Player {
        <<scene>>
        +input_actions: "player1"
        +spawn_position: Vector3
    }

    class Npc {
        <<scene>>
        +input_actions: "npc" / AI
        +ai_state: enum
        +_think()
    }
```

## Notas

- **Character** (`prefabs/character.tscn`) — Escena base reutilizable. Todo personaje (player o npc) hereda de aquí: física, gravedad, salto, colisión y esqueleto de input.
- **Player** — Hereda de Character. Usa acciones de input del `Input Map` (p. ej. `player1_left`, `player1_jump`). Puede haber varios players, cada uno con su propio set de acciones.
- **Npc** — Hereda de Character. **NO debe hardcodear el input del jugador**: debe estar listo para recibir inputs alternativos (otro gamepad, otro teclado, o IA). El sistema de input de Character debe ser configurable vía `@export input_actions`.
- El input del Character se resuelve por **nombre de acción configurable**, no hardcodeado, para que Player y Npc compartan la misma lógica de movimiento.
