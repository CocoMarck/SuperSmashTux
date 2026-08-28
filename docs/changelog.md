# Changelog

## `2026-08-19`
> Apenas me di cuenta, pero gdscirpt no tiene para variables privadas. Pero weno, igual es bueno marcarlas como `_var_private`, ya que indica que eso no se toco fuera de la clase dueña. Es una forma de documentar.

### Hitobox refactor **LISTO**
- `Hitbox` **LISTO**: (Hijo de Area3D. Papa: física + debug + lifetime, comportamiento genérico)
- `HitboxDamage` **LISTO**: (daño + knockback, el comportamiento actual)
- `HitboxGrab` **LISTO**: (detecta y avisa al padre que agarre; no daña)

### Person
- `Running` **LISTO**
- `Walking` **LISTO**
- `Crouch Walking` **LISTO**
- `Jumping` **LISTO**
- `Air jumping` **LISTO**: Posibilidad de saltar en el aire, por defecto no salta en el aire.
- `Apply hitstun` **LISTO**: Movimiento al recibir daño. Tiene stun pero corto, no deja "secuelas". Lo causan golpes no heavys. Se considera heavy, por cantidad de porcentaje de daño.
- `Apply heavy hitstun` **LISTO**: 
    - **LISTO** Movimiento al recibir daño fuerte (15% o mas). Pero no permite moverse en piso, solo en el aire de forma horozontal; sin poder atacar, y salto en el aire anula stun.
    - **LISTO** En el piso estas tumbado, pero cualquier input te levanta. Si no recibe input en el piso se quedara x segundos en el piso, y se levantara solo. Mientras te levantas, eres inmune al daño. 
    - **LISTO** Mientras te lavantas, pues no puedes hacer ningún input. Tienes que esperarte. 
    - **LISTO** El conteo del stun sucede en el piso, levantarse, y inmunidad al levantarse.
- `Apply knocked out` **FALTA**: Completamente noqueado, en "x" segundos se habilita el poder moverse. Con un golpe, se te quita el estado de noqueado. El knockout, solo se habilita con poderes, o castigos, por ejemplo, habilidad mágica para dormir o romper escudo. 

### Fighter
- `Shield` **FALTA**: 
    - `shield blockstun` **LISTO**: Nomas un datallito con el escudo, que todavía no pongo. Cuando se pone el escudo, y se recibe un golpe con el escudo, debe quedarse puesto el escudo por  "x" cantidad de tiempo, input totalmente bloqueado por esa "x" cantidad  de tiempo. Así se castiga el spamear usar escudo. Creo que 1 segundo de castigo debe ser suficiente. 
    - `shield pushback` **FALTA**: Tambien mover el personaje, en la dirección opuesta del ataque recibido.
- `Mientras se rueda no regenerar escudo` **LISTO**.
- `Fight move margen de error` **LISTO**: Input buffer temporal. Los flancos (`_left_pressed`, `_right_pressed`, etc.) duran 1 frame, lo que hace heavy attacks dificiles. Solución: timer `_direction_input_timer` (0.1s, en `GameBalance.INPUT_BUFFER_WINDOW`) en `person.gd`. Cada dirección presionada reinicia el timer. `_fight_move` usa el timer en vez de flancos puros. ~10 frames de ventana como Smash Bros. Si bien esto es para `Fighter` y hijos, esto se hara en `Person`.
- `Grab` como movimiento de ataque **LISTO**: Requiere de refactor hitbox system.

### Constantes
- Poner contestes de juego en `GameBalance` **LISTO**: Duración de stun, duración de efectos, duración de movimientos compartidos, margenes de perdon/error. Eso si, recordar usar namespace completo; `GameBalence.CONST_NAME`.