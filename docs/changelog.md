# Changelog

## `2026-08-19`
### Person
- `Running` **LISTO**
- `Walking` **LISTO**
- `Crouch Walking` **LISTO**
- `Jumping` **LISTO**
- `Air jumping` **LISTO**: Posibilidad de saltar en el aire, por defecto no salta en el aire.
- `Damage move` **LISTO**: Movimiento al recibir daño. Tiene stun pero corto, no deja "secuelas". Lo causan golpes no heavys. Se considera heavy, por cantidad de porcentaje de daño.
- `Stun move` **LISTO**: Movimiento al recibir daño. Pero no permite moverse en piso solo en el aire y solo de forma horozontal y sin poder atacar. En el piso estas tumbado, pero cualquier input te levanta. Si no recibe input en el piso se quedara x segundos en el piso, y se levantara solo. Mientras te levantas, eres inmune al daño. Mientras te lavantas, pues no puedes hacer ningun input. Tienes que esperarte. No se puede hacer ningun salto en el stun move. Solo el tercer salto, pero eso esta en `PowerFighter`. El conteo del stun sucede en el piso.
- `Knocked out` **FALTA**: Completamente noqueado, en "x" segundos se habilita el poder moverse. Con un golpe, se te quita el estado de noqueado. El knockout, solo se habilita con poderes, o castigos, por ejemplo, habilidad magica para dormir o romper escudo. 

### Fighter
- `Shield stun` **LISTO**: Nomas un datallito con el escudo, que todavía no pongo. Cuando se pone el escudo, y se recibe un golpe con el escudo, debe quedarse puesto el escudo por  "x" cantidad de tiempo, input totalmente bloqueado por esa "x" cantidad  de tiempo. Así se castiga el spamear usar escudo. Creo que 1 segundo de castigo debe ser suficiente. **FALTA**. Tambien mover el personaje, por la direccion del ataque recibido.
- `Mientras se rueda no regenerar escudo` **LISTO**.
- `Fight move margen de error` **LISTO**: Input buffer temporal. Los flancos (`_left_pressed`, `_right_pressed`, etc.) duran 1 frame, lo que hace heavy attacks dificiles. Solución: timer `_direction_input_timer` (0.1s, en `GameBalance.INPUT_BUFFER_WINDOW`) en `person.gd`. Cada dirección presionada reinicia el timer. `_fight_move` usa el timer en vez de flancos puros. ~10 frames de ventana como Smash Bros. Si bien esto es para `Fighter` y hijos, esto se hara en `Person`.

### Constantes
- Poner contestes de juego en `GameBalance` **LISTO**: Duración de stun, duración de efectos, duración de movimientos compartidos, margenes de perdon/error. Eso si, recordar usar namespace completo; `GameBalence.CONST_NAME`.