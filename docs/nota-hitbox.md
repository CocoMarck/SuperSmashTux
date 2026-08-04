# Nota: Hitbox

> Hitbox de daño de un ataque. Actualmente es un **script puro** (`scripts/hitbox.gd`), ya no se usa el prefab `hitbox.tscn`.

## Misión

- Es el **hitbox de daño** de un movimiento de ataque: el "cuadradito" visible que sale con el golpe.
- Su trabajo es **detectar a quién golpea** (métodos de colisión propios). El `Character` no se los pasa.
- Contiene la propiedad **`_parent`** para saber a quién pertenece y **no hacerle daño a su propio player** (ni a aliados).

## `scripts/hitbox.gd`

- `class_name Hitbox extends Area3D`.
- En `_init(p_position, p_size, p_parent)` se construye todo en código:
  - `CollisionShape3D` + `BoxShape3D` (el daño real, del tamaño `p_size`).
  - `MeshInstance3D` + `BoxMesh` (el cuadradito visible, mismo `p_size`).
  - Se conecta `body_entered` y se guarda `_parent`.
- `_on_hitbox_body_entered(body)`: ignora a `_parent`, y si golpea a un `Character` hace su efecto (hoy solo imprime el golpe; el daño/knockback viene después).

## Uso desde `scripts/character.gd`

- `_spawn_hitbox(p_position)`:
  - Llama `_clear_hitbox()` para no dejar huérfanos.
  - **Swap de ejes**: el "adelante" (x) del `FightMove` cae en `z` del `Pivot`, y `z` en `x` invertido (`Vector3(p.z, p.y, p.x * -1)`), porque el adelante del `Pivot` es `-z`.
  - `Hitbox.new(fixed_position, Vector3(0.5, 0.5, 0.5), self)` y se agrega hijo de `$Pivot` (hereda la rotación de mirar al enemigo).
- `_clear_hitbox()`: `queue_free()` al hitbox activo.

## Timer / lifetime

- Hoy el **Character** controla la vida del hitbox (`_hitbox_count` / `_hitbox_duration`).
- **Posible futuro**: que el propio hitbox lleve su **timer** (auto-destrucción tras su `lifetime`). Aún por decidir.
