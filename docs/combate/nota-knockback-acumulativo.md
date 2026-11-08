# Nota: Knockback acumulativo

> **FALTA**: hoy `Person` reinicia el knockback por cada golpe. En partidas FFA de 4 esto se nota:
> cuando un peleador ya va volando, otro le pega algo débil y lo "salva" del vuelo. La idea es que
> el knockback se acumule: si recibe un golpe de `x` y luego uno de `y`, el impulso solo aumenta,
> nunca se reinicia ni se reduce.
>
> Verificado el 2026-11-07. Rutas: `scripts/characters/person.gd`,
> `scripts/characters/gravity_body_3d.gd`, `scripts/combat/hitbox_damage.gd`,
> `scripts/helpers/game_balance.gd`.

## Resumen

El knockback actual funciona **por golpe**, no como un estado acumulado:

- Cada golpe sobrescribe la dirección, el hitstun y la ventana de decaimiento.
- Si el personaje está en el aire, el golpe pone `_target_velocity.y = 0`, cancelando el impulso
  vertical que ya traía.
- Un golpe débil también limpia el heavy hitstun existente.

En 1v1 casi no se nota porque rara vez te pegan dos veces a mitad del vuelo. En FFA de 4 es común,
y el segundo golpe (aunque sea `neutral1`) corta el vuelo del primero.

## Estado actual

### Flujo de un golpe

1. `HitboxDamage._on_hitbox_body_entered()` detecta un `Person` y llama
   (`scripts/combat/hitbox_damage.gd:29-30`):

   ```gdscript
   body.set_damage_percentage( _damage )
   body.set_damage_move( _damage, _direction )
   ```

2. `Person.set_damage_move()` (`scripts/characters/person.gd:728-753`):
   - `_knockback_direction = direction`: **sobrescribe** la dirección.
   - `_hitstun_time = _get_hitstun_time(damage)`: **sobrescribe** el hitstun; uno débil puede
     acortar el que ya estaba activo.
   - `_knockback_decay_time = 0.0`: **reinicia** la ventana de knockback.
   - `_clean_heavy_hitstun_state()`: **limpia** el heavy hitstun existente.
   - Si está en el aire, `_target_velocity.y = 0`: **cancela** el impulso vertical acumulado.

3. `Person._apply_hitstun()` (`scripts/characters/person.gd:779-795`) aplica la aceleración
   mientras `_knockback_decay_time < GameBalance.KNOCKBACK_DECAY_TIME`:

   ```gdscript
   var accel := _normal_damage_power * damage_percentage
   _target_velocity.x += _knockback_direction.x * accel * delta
   _target_velocity.y += _knockback_direction.y * (accel * 10) * delta
   ```

   Al terminar el hitstun, `_knockback_decay_time` vuelve a `0.0`.

4. `Person._move()` (`scripts/characters/person.gd:522-532`) frena la velocidad horizontal durante
   el hitstun usando `_knockback_friction`:

   ```gdscript
   if _hitstun_active():
       accel = _knockback_friction
   _target_velocity.x = move_toward(_target_velocity.x, target_speed, accel * delta)
   ```

5. `GravityBody3D._vertical_force()` (`scripts/characters/gravity_body_3d.gd:79-86`) acumula la
   gravedad en `_target_velocity.y`.

6. `Person._commit_frame()` aplica `velocity = _target_velocity` y hace `move_and_slide()`
   (`scripts/characters/person.gd:1066-1067`).

### Por qué se siente reiniciado

- **Dirección sobrescrita**: un golpe débil con dirección distinta (o contraria) redirige el vuelo.
- **Hitstun sobrescrito**: un golpe débil puede dejar al personaje con menos stun del que tenía.
- **Ventana de knockback reiniciada**: la aceleración del golpe nuevo arranca desde cero y con su
  propia dirección.
- **Heavy hitstun limpiado**: un golpe débil cancela el tumbo que ya estaba activo.
- **Impulso vertical cancelado**: `_target_velocity.y = 0` borra el vuelo hacia arriba. Este es el
  "salvavidas" más notorio.

Ojo: el impulso **horizontal** ya acumulado en `_target_velocity.x` no se borra de golpe, pero sí
se le cambia la dirección y se le reinicia la ventana; además `_knockback_friction` lo va frenando.
El vertical sí se borra por completo.

### Valores actuales

- `_normal_damage_power = 35` (`scripts/characters/person.gd:82`).
- `BASE_HITSTUN_DURATION = 0.3` (`scripts/helpers/game_balance.gd:25`).
- `MAX_HITSTUN_DURATION = 0.7` (`scripts/helpers/game_balance.gd:26`).
- `KNOCKBACK_DECAY_TIME = 0.3` (`scripts/helpers/game_balance.gd:27`).

El daño acumulado sí escala el knockback (`accel` es proporcional a `damage_percentage`), pero el
reset de dirección, ventana y velocidad vertical pesa más en el caso que nos interesa.

## Qué debería pasar

Regla propuesta: **el knockback es un estado acumulativo**.

- Un golpe nuevo **suma** impulso al vuelo existente; nunca lo reinicia ni lo reduce.
- El hitstun no se acorta: `_hitstun_time = max(_hitstun_time, nuevo)`.
- No se cancela `_target_velocity.y` si el personaje ya viene en vuelo.
- La ventana de decaimiento no se reinicia desde cero; solo se extiende si el golpe nuevo aporta
  más knockback.
- Un golpe débil puede aportar poco, pero no debe cambiar radicalmente la dirección del vuelo.
- Debe existir un tope para evitar acumulación infinita en FFA.

## Opciones de diseño

### A. Cambio mínimo en `set_damage_move()`

- Si ya hay hitstun activo y la ventana de knockback sigue viva:
  - no sobrescribir `_knockback_direction` sin más; sumar o combinar.
  - no reiniciar `_knockback_decay_time`.
  - no poner `_target_velocity.y = 0`.
  - usar `max()` para el hitstun.
- Pros: pocas líneas y ataca directamente el "salvavidas".
- Contras: hay que definir cómo se combinan direcciones y cómo se pone el tope.

### B. Estado separado `_knockback_velocity: Vector3`

- Guardar el impulso de knockback aparte del movimiento normal.
- Cada golpe suma un vector de impulso; el estado decae con el tiempo.
- `_target_velocity` se compone de movimiento + knockback.
- Pros: modela bien el vuelo, es fácil de capar y no se mezcla con la fricción normal.
- Contras: toca `set_damage_move()`, `_apply_hitstun()`, `_move()` y `_commit_frame()`.

### C. Dirección dominante y suma de magnitudes

- Conservar la dirección del golpe más fuerte y sumar la magnitud de los golpes nuevos.
- Pros: evita que un golpe débil cambie la dirección.
- Contras: se siente menos físico y es más difícil de balancear.

## Preguntas abiertas

- ¿La dirección se suma, se promedia o gana la del golpe más fuerte?
- ¿Cuál es el tope de velocidad de knockback?
- ¿El hitstun se extiende con cualquier golpe o solo con los que superan cierto daño?
- ¿Aplica también a `set_thrown_move()` (agarres)?
- ¿Qué pasa si el golpe nuevo empuja hacia abajo mientras el personaje sube?
- ¿El daño porcentual sigue escalando el knockback igual que hoy?

## Cómo probarlo

1. En FFA de 4, lanzar a alguien con `heavy_side` y, a mitad del vuelo, pegarle con `neutral1` de
   otro jugador. El vuelo debe continuar y sumar, no cortarse.
2. Repetir con golpes en direcciones opuestas.
3. Repetir pegando en el pico del salto, para confirmar que no se cancela `_target_velocity.y`.
4. Medir distancia recorrida y tiempo de hitstun con y sin acumulación.
5. Comparar 1v1 contra FFA para confirmar que el cambio no rompe el caso simple.

## Archivos involucrados

| Archivo | Rol |
|---|---|
| `scripts/combat/hitbox_damage.gd` | Detecta el golpe y llama `set_damage_percentage()` + `set_damage_move()` |
| `scripts/characters/person.gd` | `set_damage_move()`, `_apply_hitstun()`, `_move()` |
| `scripts/characters/gravity_body_3d.gd` | Acumula gravedad en `_target_velocity.y` |
| `scripts/helpers/game_balance.gd` | Constantes de hitstun y knockback |

## Ver también

- [nota-ataques.md](nota-ataques.md) — cómo se elige el ataque y cómo se aplica el daño hoy.
- [hitbox.md](hitbox.md) — construcción y ciclo de vida del `Hitbox`.
- [game_balance.gd](../../scripts/helpers/game_balance.gd) — valores de hitstun y knockback.
