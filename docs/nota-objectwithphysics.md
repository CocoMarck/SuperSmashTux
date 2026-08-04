# Nota: Futura herencia de física

> Nota de arquitectura a futuro. Solo contemplación, no código.

## ObjectWithPhysics

- El `Character` (fighter) debe ser **hijo** de un objeto `ObjectWithPhysics` (o equivalente).
- `ObjectWithPhysics` contendrá las funciones de **gravedad / fuerza vertical** y **colisiones**, que hoy viven en `scripts/character.gd` (`_vertical_force`, `move_and_slide`, etc.).

## Posibilidad

- Es **posible** que `ObjectWithPhysics` a su vez sea hijo de otro objeto (cadena de herencia mayor).
- Solo contemplarlo como posibilidad; no es decisión tomada.
