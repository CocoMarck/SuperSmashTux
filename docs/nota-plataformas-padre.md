# Nota: Papá común para plataformas

> `OneWayPlatform` y `GroundPlatform` repiten código: el registro en grupo y el cálculo de la cara superior (`get_top_y`). Se propone un papá común `Platform`. **Aún no aplicado; es propuesta.**

## Qué repiten hoy

- **Registro en grupo**: ambas tienen `const GROUP_NAME` + un `_ready()` que hace `add_to_group(GROUP_NAME)` — mismo patrón, distinta constante.
- **`get_top_y()`**: calcular el medio-alto del primer `CollisionShape3D` según su shape y escala global, y sumarlo a su posición global. `OneWayPlatform` ya lo tiene generalizado (Box / Cylinder / Capsule); `GroundPlatform` solo soporta Box y repite la misma idea con menos casos.
- **Fallback**: si no hay shape útil, ambas regresan `global_position.y`.

## Propuesta: `Platform extends StaticBody3D`

Un papá común (`class_name Platform`) con lo genérico:

- `get_top_y()` **generalizado** (la versión de `OneWayPlatform`, que soporta Box/Cylinder/Capsule).
- Un helper `_get_first_collision_shape()` que busque el primer `CollisionShape3D` hijo.
- **Grupo**: para no repetir el `_ready()`, el papá registra `_get_group_name()` — virtual que cada hijo sobreescribe con su grupo.

## Qué queda en cada hijo

- **`GroundPlatform`**: `has_ledges()` (verificar que el primer CollisionShape3D sea un `BoxShape3D`) y `get_ledge_x(right_side)` (las dos orillas). Ambos son suyos, no se repiten.
- **`OneWayPlatform`**: hoy no tendría nada extra, solo su grupo.

## Estado

- **No aplicado.** Decisión pendiente: se crea el papá y se cambia el `extends` de ambos scripts, o se dejan como están.
