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
- `Fight move margen de error` **FALTA**: Para los ataques heavy, de direccion mas ataque al mismo tiempo, establecer un margen de error. Margen de error de 0.1 m o menos, por cada flanco de movimiento. O si hace falta, crear flancos nuevos de movimiento, de margen de error.