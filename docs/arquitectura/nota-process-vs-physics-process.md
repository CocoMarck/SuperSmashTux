# Nota: `_process` vs `_physics_process`

> Nota de arquitectura. Aclara cuándo usar cada callback y por qué.

## La regla de oro

- **Si mueve un nodo o depende de colisiones** → `_physics_process`.
- **Si es cosmético / visual o un temporizador de backend sin físicas** → `_process`.

## Diferencias

| | `_process` | `_physics_process` |
|---|---|---|
| Cada cuándo | Cada frame de render (depende del monitor: 60/120/144fps) | Paso de física **fijo** (60Hz, simulación determinista) |
| Para qué | Lo **visual**: animaciones, tweens, UI, texto, interpolación de cámara, partículas | Lo **físico**: movimiento, gravedad, colisiones, `move_and_slide()`, solapamientos |
| El `delta` | Varía según el fps | Siempre ~0.0166s a 60Hz |

## Ejemplos en el proyecto

**`_process` (correcto):**
- `hitbox.gd:` — el contador de lifetime del visor (visual, no altera colisión).
- `hitbox_grab.gd:` — el temporizador de `_grabbing_lifetime`.
- `match_time.gd` — el reloj de la partida. No depende de colisiones ni necesita `delta` fijo.
- `match_countdown.gd` — el 3-2-1 previo a la pelea. Mismo caso: solo cuenta tiempo.

**`_physics_process` (correcto):**
- `gravity_body_3d.gd` — la gravedad y el `move_and_slide()`.
- `area_gravity_3d.gd` — hitboxes con gravedad: mover el Area fuera de la física.
- `lives_manager.gd` — revisa cada frame si alguien salió del `PlayArea`; depende de posiciones físicas.

## Dato extra
`Area3D` también usa `_physics_process` sin problema. Es un `Node` normal; no hay limitación de Godot ahí.