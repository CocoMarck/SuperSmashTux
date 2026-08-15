# Hitbox — Diseño

> Documento de diseño del sistema de hitboxes. Sustituye a la vieja `nota-hitbox.md`.
> Estado: el `Hitbox` actual (`scripts/hitbox.gd`) ya existe como script puro con debug visual.
> Planeado: convertirlo en **papa** y derivar hijos por tipo de efecto (`HitboxDamage`, `HitboxGrab`).

## Misión

Un hitbox es una caja de detección que acompaña a un movimiento. Tiene dos caras:

- **Física**: un `Area3D` con `CollisionShape3D` que detecta con quién chocó (`body_entered`).
- **Visual (debug)**: un `MeshInstance3D` translúcido del mismo tamaño que la caja, para verla
  en el editor o al depurar. Puede cambiar de color/alpha por código.

El hitbox **no decide qué movimiento lo lanzó**: eso lo sabe el `Fighter`. El hitbox
**decide qué pasa cuando pega** (según su tipo), y conoce a su `_parent` para no dañarlo.

## Arquitectura: papa + hijos

```
Area3D
  └── Hitbox          (papa: física + debug + lifetime, comportamiento genérico)
        ├── HitboxDamage   (daño + knockback, el comportamiento actual)
        └── HitboxGrab     (detecta y avisa al padre que agarre; no daña)
```

### `Hitbox` (papa) — `scripts/hitbox.gd`

Clase base que **todo** hitbox comparte. Extiende `Area3D`.

Responsabilidades:

- Construye el `CollisionShape3D` + `BoxShape3D` (la caja real, tamaño `p_size`).
- Construye el `MeshInstance3D` + `BoxMesh` (el debug visible, mismo `p_size`).
- Guarda `_parent` (quién lo lanzó) para ignorarlo en colisiones.
- Expone helpers de debug: `set_color(r, g, b, a)` y `set_alpha(alpha)`.
- **Lifetime**: se auto-destruye tras un tiempo con `queue_free()` (ver abajo).
- Deja que los hijos sobreescriban `_on_hitbox_body_entered(body)` para su efecto.

Firma sugerida del `_init` del papa (evoluciona la actual):

```gdscript
func _init(
    p_position: Vector3,
    p_size: Vector3,
    p_parent: Node3D,
    p_lifetime: float = 0.0,   # 0 = infinito, lo limpia el que lo lanzó
) -> void
```

### `HitboxDamage` — el golpe

Es el comportamiento **actual** de `hitbox.gd`: hace daño y empuja.

- En `_on_hitbox_body_entered` ignora a `_parent` y, si pega a un `Person`,
  aplica `set_damage_percentage()` y `set_damage_move()`.
- Parámetros de daño (`_damage`, `_direction`) los sigue pasando el `Fighter`
  desde el `FightMove`, igual que hoy.

### `HitboxGrab` — el agarre

Detecta al oponente para iniciar un agarre. **No hace daño.**

- En `_on_hitbox_body_entered` no aplica daño: avisa a `_parent` (el `Fighter`)
  para que arranque el estado de grab, o emite una señal `grabbed(body)`.
- Se lanzará desde un `FightMove` con `grab_attack = true` (ya existe esa bandera en
  `scripts/helpers/fight_move.gd:32`), pero con su propio tamaño/duración.

## Lifetime: el hitbox se sabe morir

Hoy el `Fighter` controla todo el ciclo de vida con `_hitbox_time` y `_clear_hitbox()`
(`scripts/fighter.gd`). El diseño planeado reparte el trabajo:

| Quién | Qué hace |
|---|---|
| **Hitbox** | Cuenta su `lifetime` en `_process()` y llama `queue_free()` al acabarse. Nunca queda huérfano, aunque al `Fighter` se le olvide. |
| **Fighter** | Sigue pudiendo matarlo **antes** con `_clear_hitbox()` (cancelar ataque a la mitad: te agarraron, te pegaron, respawn, soltaste el golpe). |

- `lifetime = 0.0` significa "no me destruyo solo": el `Fighter` decide cuándo.
- El `Fighter` ya calcula la duración exacta con `get_hitbox_time_ratio()`
  (`scripts/helpers/fight_move.gd:91`), así que basta pasarla como `lifetime`.

Ganancia: robustez (auto-cleanup) sin perder el control fino del `Fighter`.

## Uso desde `scripts/fighter.gd`

- `_spawn_hitbox(...)`: hace el **swap de ejes** (`Vector3(p.z, p.y, p.x)`), crea el hitbox
  hijo del `_pivot` y pasa el `lifetime` calculado desde el `FightMove`.
- `_clear_hitbox()`: `queue_free()` al hitbox activo y lo pone en `null`.
- Con grab: se lanzaría un `HitboxGrab` igual, solo que su efecto es avisar al agarre.

## Pendientes / a decidir

- Migrar `hitbox.gd` actual → `Hitbox` papa y crear `hitbox_damage.gd` y `hitbox_grab.gd`.
- Decidir si `HitboxGrab` notifica al `_parent` por método o por señal.
- Definir si el grab usa `FightMove` con `grab_attack = true` o un flujo propio.
- `HitboxGrab` aún no existe en código; solo está diseñado.
