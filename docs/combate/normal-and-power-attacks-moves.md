# Normal and power attacks moves

Los nombres son los de la sección del `.cfg` y, por lo tanto, el clip de animación que reproduce `Fighter`. Ya se usa el sufijo `attack` en el contrato real; el texto viejo que decía lo contrario quedó obsoleto.

En `PowerAttacks`, las propiedades internas `standard` y `air_standard` se llenan desde las secciones `power_attack` y `air_power_attack`.

## Fighter

Estos ataques los contiene `Attacks`; cada propiedad es un `FightMove`.

### En el piso
- `neutral_attack1`, `neutral_attack2`, `neutral_attack3`: cuando no se mueve y está parado.
- `down_attack`: agachado y sin moverse.
- `dash_attack`: corriendo y atacar.
- `forward_attack`: caminando y atacar.
- `up_attack`: sin moverse y presionar ataque arriba.
- `heavy_side_attack`: presionar al mismo tiempo ataque y der/izq.
- `heavy_up_attack`: presionar al mismo tiempo ataque y arriba.
- `heavy_down_attack`: presionar al mismo tiempo ataque y abajo.

### En el aire
- `air_neutral_attack`: en el aire, sin moverse y atacar.
- `air_back_attack`: en el aire, moviéndose de espaldas y atacar.
- `air_forward_attack`: en el aire, moviéndose a un lado y atacar.
- `air_down_attack`: en el aire y atacar presionando abajo, moviéndose o no.
- `air_up_attack`: en el aire y atacar presionando arriba, moviéndose o no.

## PowerFighter

Estos ataques los contiene `PowerAttacks`; cada propiedad es un `FightMove`.

### En el piso
- `power_attack`: proyectil, ráfaga de energía o carga de ataque.
- `down_power_attack`: poder hacia abajo, puede ser ataque o no.
- `up_power_attack`: poder hacia arriba que da propulsión. Puede hacer daño o no.

### En el aire
- `air_power_attack`: igual que `power_attack`, con animación en el aire.
- `air_down_power_attack`: igual que `down_power_attack`, con animación en el aire.
- `air_up_power_attack`: igual que `up_power_attack`, con animación en el aire.
