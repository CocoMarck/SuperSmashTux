# Changelog

## `2026-08-19`
### Person
- `Running` **LISTO**
- `Walking` **LISTO**
- `Crouch Walking` **LISTO**
- `Jumping` **LISTO**
- `Air jumping` **LISTO**: Posibilidad de saltar en el aire, por defecto no salta en el aire.
- `Damage move` **LISTO**: Movimiento de al recibir daño. Tiene stun pero corto.
- `Stun move` **FALTA**: Movimiento al recibir daño. Pero no permite moverse en piso solo en el aire. En el piso quedas en el piso, cualquier input te levanta. Si no recibe input en el piso se quedara x segundos en el piso, y se levantara solo. Mientras te levantas, eres inmune al daño, y colisiones.
- `Knocked out` **FALTA**: Completamente noqueado, en "x" segundos se habilita el poder moverse. Con un golpe, se te quita este estado de noqueado.

### Fighter
- `Shield stun` **LISTO**: Nomas un datallito con el escudo, que todavía no pongo. Cuando se pone el escudo, y se recibe un golpe con el escudo, debe quedarse puesto el escudo por  "x" cantidad de tiempo, input totalmente bloqueado por esa "x" cantidad  de tiempo. Así se castiga el spamear usar escudo. Creo que 1 segundo de castigo debe ser suficiente.
- `Mientras se rueda no regenerar escudo` **LISTO**.
- `Fight move margen de error` **LISTO**: Input buffer temporal. Los flancos (`_left_pressed`, `_right_pressed`, etc.) duran 1 frame, lo que hace heavy attacks dificiles. Solución: timer `_direction_input_timer` (0.1s, en `GameBalance.INPUT_BUFFER_WINDOW`) en `person.gd`. Cada dirección presionada reinicia el timer. `_fight_move` usa el timer en vez de flancos puros. ~10 frames de ventana como Smash Bros. Si bien esto es para `Fighter` y hijos, esto se hara en `Person`.

### Constantes
- Poner contestes de juego en `GameBalance` **FALTA**: Duración de stun, duración de efectos, duración de movimientos compartidos, margenes de perdon/error. Eso si, recordar usar namespace complketo. `GameBalence.CONST_NAME`.