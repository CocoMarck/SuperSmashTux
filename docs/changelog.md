# Changelog

## `2026-08-19`
> Apenas me di cuenta, pero gdscirpt no tiene para variables privadas. Pero weno, igual es bueno marcarlas como `_var_private`, ya que indica que eso no se toco fuera de la clase dueña. Es una forma de documentar.

### Hitobox refactor **LISTO**
- `AreaGravity3D` **LISTO**: Area3D con física simple.
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
- `knocked_out_anim` **LISTO**: Puede ser placeholder. Solo es una anim no se creo func, no se necesitaba.
- `grabbed anim` **LISTO**: Puede ser placeholder.

### Fighter
- `Shield` **LISTO**: 
    - `shield blockstun` **LISTO**: Nomas un datallito con el escudo, que todavía no pongo. Cuando se pone el escudo, y se recibe un golpe con el escudo, debe quedarse puesto el escudo por  "x" cantidad de tiempo, input totalmente bloqueado por esa "x" cantidad  de tiempo. Así se castiga el spamear usar escudo. Creo que 1 segundo de castigo debe ser suficiente. 
    - `shield pushback` **LISTO**: Tambien mover el personaje, en la dirección opuesta del ataque recibido.
- `Mientras se rueda no regenerar escudo` **LISTO**.
- `Fight move margen de error` **LISTO**: Input buffer temporal. Los flancos (`_left_pressed`, `_right_pressed`, etc.) duran 1 frame, lo que hace heavy attacks dificiles. Solución: timer `_direction_input_timer` (0.1s, en `GameBalance.INPUT_BUFFER_WINDOW`) en `person.gd`. Cada dirección presionada reinicia el timer. `_fight_move` usa el timer en vez de flancos puros. ~10 frames de ventana como Smash Bros. Si bien esto es para `Fighter` y hijos, esto se hara en `Person`.
- `Grab` como movimiento de ataque **LISTO**: Requiere de refactor hitbox system. No puede hacer grab cuando el personaje esta en el suelo (Esto no fue planeado asi, por por como esta hecho el aventar a `Person`, sucedió asi, y creo que esta bien.). 
- `spawn hitboxes damages` **LISTO**: Varios hitbox damage por move. Jala bien.
- `grabbing_anim` **LISTO**: Puede ser placeholder.

### Constantes
- Poner contestes de juego en `GameBalance` **LISTO**: Duración de stun, duración de efectos, duración de movimientos compartidos, margenes de perdon/error. Eso si, recordar usar namespace completo; `GameBalence.CONST_NAME`.

## `2026-08-28`
- **LISTO**: En `Person` y `Fighter`, existen muchas funcs que depender de `bool` y `time`. Jala, pero se puede optimizar para el lector de code. Que simplemente se cambie ese bool, por una func que diga si time es mayor que cero. Ejemplo `func knocked_out(): knockout_time > 0`

> Aveces ando en modo automático, y pongo cosas redundantes

### GravityBody
- **LISTO**: Normalizar a obtener width y height valor completo, con shape, y serán funciones publicas. Escalar si se requiere, pero con multiplicador. Ejemplo `get_width()*0.5`.
    - Funciones publicas **LISTO**: `get_width, get_height`. Y ya esta.
    - Eliminar la func legacy `_get_body_half_height() ` **LISTO**: Simplemente seria un `get_height()*0.5`.

### Fighter
- Ataques con salto **LISTO**: 
    - Ahora los movimientos de ataques pueden incluir un salto. Solo se puede hacer un salto en el aire y en el piso. No dos saltos. 
    - Si se hace el ataque de salto, ya no se puede hacer saltar normal, hasta caer al piso. 
    - Un golpe reinicia el conteo de saltos de ataque, por lo que si haces el salto con movimiento de ataque, y en el aire te dan un trancazo, ahora puedes hacer otro salto de ataque.
- Tres ataques neutrales en el piso **LISTO**: Contador de ataques. Reiniciar contador si no se hace en el mismo combo.
- El `heavy_hitstun` vuelve a permitir hacer ataques con salto. **LISTO**
- **LISTO**: Reiniciar contador de ataques con salto, cuando se agarre a ledge de orilla. 
- Arreglar Bug **FALTA**: hacer ataque con salto mientras `_holding_onto_the_ledge()`, sucede bug visual, porque se eleva first frame del ataque con salto y luego cancela. 
- Mecánica: **LISTO**: Cuando se hace ataque en el aire, cancelar heavy hitsun.
    - **LISTO** Solo poder atacar cuando pase "x" tiempo en el aire. 
- Animación de shield, para poder usarlo **LISTO**: Es necesario, que evita hacer que el jugador se salga de combo, por spamear escudo.. Es placeholder la anim, testear, puede que se me escapase algo. 

### PowerFighter
- `Tercer salto` **LISTO**: Tendrá anim para saltar en el aire, y para saltar en el piso. En el piso se tarda mas en saltar. Usar este salto, ya no permite hacer saltos hasta llegar al piso. Esto lo hace fighter.

### Person
- Optimizar, hacer mas modular, es `physics_process` de `Person` **LISTO**: 
    - El `Fighter`, remplaza el physics process, pero es muy parecido al de Person, por lo cual se puede optimizar Person para que sea modular, para que Fighter, no remplace todo, eso no es fácil de mantener.

    - Se realizo el `2026-09-04`: Asegurarse que jale bien. Primeras impresiones: De diez.
- Animación de caída en el piso, pequeño cooldown **FALTA**: 
    - Cuando se cae first frame en el piso, y dependiendo del `velocity.y` anterior, hacer la anim mas lenta, mas rápida, o a velocidad normal. Solo cuando no se esta recibiendo daño.
    - Si esta recibiendo daño se cancela la animación. 
    - Se sobrepone sobre move states. Los pone en false todos, para que no se pueda hacer nada mientras se hace la anim de caída en el piso.
    - Es una anim muy corta, poner constante en game balance, duración de anim como de 0.2 segundos.

- `process_sound` **FALTA**: modulo que obtiene señales, para reproducir sonidos, sonido de pasos, de daño recibido, y etc.
    - Contar tiempo al moverse en el piso o en el aire. (Solo cuando no se recibe daño)
    - Obtener señal frame uno al recibir daño.
    - Obtener señal frame uno al caer en el piso.
    - Obtener señal frame uno al saltar en el piso o en el aire.
    - Obtener señal frame uno al caer en cealing/techo o en wall.

- Mejoras en `knockback/hitstun` **LISTO**:
    - Ahora el no poder moverse, dura mas que el knockback. El duración de; knockback se queda fija. La duración de hitstun varia según el porcentaje de daño, y el daño recibido, y tiene un limite máximo.
    - `BASE_HITSTUN_DURATION` 0.3. Duración base del hitstun.
    - `MAX_HITSTUN_DURATION` 0.7. Duración máxima de hitstun.
    - `KNOCKBACK_DECAY_TIME` 0.3. Duración de movimiento de knockback. Fija.

- Bug **TESTEAR**: Por alguna extraña razón el `heavy_hitstun`, queda fijado de forma rara. Aun no identifico que lo deja siempre activo. hasta parece random. Ya lo cambie, párese jalar. El pedo era el flag/bool de wait heavy hitstun get up.

- Aceleración horizontal **TESTEAR**: al tener poca, si se mueve rapido, pero queda raro cuando se mueve en el aire aveces, ya que al ser poca, aveces se mueve muy rapido en el aire.
