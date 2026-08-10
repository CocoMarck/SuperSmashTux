# Normal and power attacks moves
No se usa prefijo attack en ningun lado porque las clases ya tienen contextalmente que son `Attacks`.

## Fighter
Estos ataques los contendra una clase `Attacks`. Que simplemente de propiedades tendra `FightMove` con estos nombres.

### En el piso
- `ground_neutral`: Cuando no se mueve y esta parado.
- `down`: Cuando esta agachado y sin moverse.
- `dash`: Corriendo y atacar.
- `forward`: Caminando y attack.
- `up`: Sin moverse, y precionar ataque arriba.
- `heavy_side`: Cuando se preciona al mismo tiempo ataque y der o izq.
- `heavy_up`: Sin moverse, y precionar al mismo tiempo ataque y arriba.
- `heavy_down`: Sin moverse, y precionar al mismo tiempo ataque y abajo.

### En el aire
- `air_neutral`: En el aire, sin moverse y atacar.
- `air_back`: En el aire moviendose a de espaldas y atacar.
- `air_forward`: En el aire moviendose a un lado y atacar.
- `air_down`: En el aire y atacar precionando abajo. Ya sea moviendose o no.
- `air_up`: En el aire y atacar precionando arriba. Ya sea moviendose o no.

---
## PowerFighter
Estos ataques los contendra una clase `PowerAttacks`. Que simplemente de propiedades tendra `FightMove` con estos nombres.

### En el piso
- `power_neutral`: Proyectil, rafaga de energia, o carga de ataque.
- `power_side`: Poder hacia un lado.
- `power_up`: Poder hacia arriba que da propulicón. Puede hacer daño o no.
- `power_down`: Poder hacia abajo, puede ser ataque o no.

### En el aire
- `air_jump`: Salto en el aire.
- `power_air_up`: Lo mismo que power up. Pero animacion en el aire.
- `power_air_down`: Lo mismo que power down. Pero animacion en el aire.
- `power_air_side`: Lo mismo que power side. Pero animacion en el aire.