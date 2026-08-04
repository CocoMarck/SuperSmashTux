# Nota: Hitbox prefab scene

> Nota de arquitectura. El hitbox es un objeto a explorar; esto es lo que sabemos hasta ahora.

## Rol

- `prefabs/hitbox.tscn` es el **hitbox de daño** de un ataque (el cuadrito visible).
- Es el objeto que debe contener los **métodos de colisión** (quién recibe el golpe, cuánto daño, etc.).
- El `Character` **no debe pasárselos**: solo lo spawn-ea, lo posiciona y lo libera.

## Propiedad `parent`

- El hitbox debe tener una propiedad **`parent`** para saber a quién pertenece.
- Sirve para **no hacerle daño a su propio player** (evitar auto-golpes), y en general para no dañar a aliados.

## Responsabilidades (futuras)

- Métodos de colisión propios: detectar el cuerpo golpeado, aplicar daño, knockback, etc.
- `Character` solo: spawn (`_spawn_hitbox`), posición (`hitbox_position` del `FightMove`) y limpieza.
- Auto-destrucción por `lifetime` (aún por definir si vive en el hitbox o en el character).
