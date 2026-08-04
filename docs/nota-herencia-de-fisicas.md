# Nota: Herencia de física

> Nota de arquitectura. Documenta la decisión actual de herencia para la física.

## GravityBody3D

- El `Character` (fighter) es **hijo** de `GravityBody3D` (`scripts/gravity_body_3d.gd`).
- `GravityBody3D` extiende `CharacterBody3D` y contiene solo la **gravedad / fuerza vertical** (`_vertical_force`), junto con `fall_acceleration`, `_target_velocity` y `_air_count`.
- Lo de **velocidad, salto y `move_and_slide`** es asunto de `Character`, no del papá.

```
CharacterBody3D → GravityBody3D → Character
```

## ObjectWithPhysics

- `ObjectWithPhysics` queda reservado para **items y objetos** (rama separada, no es papá de `Character`).
- No se crea aún; solo contemplado.

## Posibilidad

- Es **posible** que `GravityBody3D` a su vez sea hijo de otro objeto (cadena de herencia mayor).
- Solo contemplarlo como posibilidad; no es decisión tomada.
