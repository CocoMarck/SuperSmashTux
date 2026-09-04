# Changelog

## `2026-08-19`
> Apenas me di cuenta, pero gdscirpt no tiene para variables privadas. Pero weno, igual es bueno marcarlas como `_var_private`, ya que indica que eso no se toco fuera de la clase dueña. Es una forma de documentar.

### Hitobox refactor **LISTO**
- `Hitbox` **LISTO**: (Hijo de Area3D. Papa: física + debug + lifetime, comportamiento genérico). Contiene `id`, para identificarlo.
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
    - **LISTO** Movimiento al recibir daño fuerte (15% o mas). Pero no permite moverse en piso, solo en el aire de forma horizontal; sin poder atacar, y salto en el aire anula stun.
    - **LISTO** En el piso estas tumbado, pero cualquier input te levanta. Si no recibe input en el piso se quedara x segundos en el piso, y se levantara solo. Mientras te levantas, eres inmune al daño. 
    - **LISTO** Mientras te lavantas, pues no puedes hacer ningún input. Tienes que esperarte. 
    - **LISTO** El conteo del stun sucede en el piso, levantarse, y inmunidad al levantarse.
- `Apply knocked out` **LISTO**: Completamente noqueado, en "x" segundos se habilita el poder moverse. Con un golpe, se te quita el estado de noqueado. El knockout, solo se habilita con poderes, o castigos, por ejemplo, habilidad mágica para dormir o romper escudo. 
- `_knocked_out_anim` **FALTA**: Puede ser placeholder.
- `_grabbed_anim` **FALTA**: Puede ser placeholder.
- Al recibir daño en el aire, ya no poder saltar en el aire **LISTO**.

### Fighter
- `Shield` **LISTO**: 
    - `shield blockstun` **LISTO**: Nomas un datallito con el escudo, que todavía no pongo. Cuando se pone el escudo, y se recibe un golpe con el escudo, debe quedarse puesto el escudo por  "x" cantidad de tiempo, input totalmente bloqueado por esa "x" cantidad  de tiempo. Así se castiga el spamear usar escudo. Creo que 1 segundo de castigo debe ser suficiente. 
    - `shield pushback` **LISTO**: Tambien mover el personaje, en la dirección opuesta del ataque recibido.
- `Mientras se rueda no regenerar escudo` **LISTO**.
- `Fight move margen de error` **LISTO**: Input buffer temporal. Los flancos (`_left_pressed`, `_right_pressed`, etc.) duran 1 frame, lo que hace heavy attacks dificiles. Solución: timer `_direction_input_timer` (0.1s, en `GameBalance.INPUT_BUFFER_WINDOW`) en `person.gd`. Cada dirección presionada reinicia el timer. `_fight_move` usa el timer en vez de flancos puros. ~10 frames de ventana como Smash Bros. Si bien esto es para `Fighter` y hijos, esto se hara en `Person`.
- `Grab` como movimiento de ataque **LISTO**: Requiere de refactor hitbox system. No puede hacer grab cuando el personaje esta en el suelo (Esto no fue planeado asi, por por como esta hecho el aventar a `Person`, sucedió asi, y creo que esta bien.). 
- `grabbing_anim` **FALTA**: Puede ser placeholder.
- `spawn hitboxes damages` **LISTO***: Varios hitbox damage por move. Aun no jala tan bien pero jala.

### Constantes
- Poner contestes de juego en `GameBalance` **LISTO**: Duración de stun, duración de efectos, duración de movimientos compartidos, margenes de perdon/error. Eso si, recordar usar namespace completo; `GameBalence.CONST_NAME`.

## `2026-08-28`
- **LISTO**: En `Person` y `Fighter`, existen muchas funcs que depender de `bool` y `time`. Jala, pero se puede optimizar para el lector de code. Que simplemente se cambie ese bool, por una func que diga si time es mayor que cero. Ejemplo `func knocked_out(): knockout_time > 0`

> Aveces ando en modo automático, y pongo cosas redundantes

### GravityBody
- **LISTO**: Normalizar a obtener width y hegiht valor completo, con shape, y serán funciones publicas. Escalar si se requiere, pero con multiplicador. Ejemplo `get_width()*0.5`.
    - Funciones publicas **LISTO**: `get_width, get_height`. Y ya esta.
    - Eliminar la func legacy `_get_body_half_height() ` **FALTA**: Simplemente seria un `get_height()*0.5`.

### Fighter
- Ataques con salto **LISTO**: 
    - Ahora los movimientos de ataques pueden incluir un salto. Solo se puede hacer un salto en el aire y en el piso. No dos saltos. 
    - Si se hace el ataque de salto, ya no se puede hacer saltar normal, hasta caer al piso. 
    - Un golpe reinicia el conteo de saltos de ataque, por lo que si haces el salto con movimiento de ataque, y en el aire te dan un trancazo, ahora puedes hacer otro salto de ataque.
- Tres ataques neutrales en el piso **LISTO**: Contador de ataques. Reiniciar contador si no se hace en el mismo combo.
- El `heavy_hitstun` vuelve a permitir hacer ataques con salto. **LISTO**

### PowerFighter
- `Tercer salto` **LISTO**: Tendrá anim para saltar en el aire, y para saltar en el piso. En el piso se tarda mas en saltar. Usar este salto, ya no permite hacer saltos hasta llegar al piso. Esto lo hace fighter.

### Person
- Optimizar, hacer mas modular, es `physics_process` de `Person` **FALTA**: El `Fighter`, remplaza el physics process, pero es muy parecido al de Person, por lo cual se puede optimizar Person para que sea modular, para que Fighter, no remplace todo, eso no es fácil de mantener.