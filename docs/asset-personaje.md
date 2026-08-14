# Asset de Personaje (contrato visual)

> Estructura esperada para los assets de personaje y cómo se instancian dentro de un `CharacterBody3D`. **Aplicar esta convención al crear assets nuevos.**

## Estructura del asset (escena instanciable)

```
Node3D               # Raíz del asset = el "contrato" del modelo
    Pivot            # Node3D: aquí viven volteos y spin del personaje
        Skeleton3D
            MeshInstance3D
    AnimationPlayer
```

## Uso dentro de un personaje

```
CharacterBody3D      # script Person/Fighter
    CollisionShape3D
    Visual           
        (Instancia del asset)
```

## Reglas

- **Nombres fijos, pero solo dentro del modelo.** `Pivot`, `Skeleton3D`/`MeshInstance3D` y `AnimationPlayer` deben llamarse igual en todos los assets — eso es lo que exportas de Blender y no cambia. El nodo que Godot pone automáticamente al instanciar el `.glb` (el hijo directo de `Visual`, con el nombre del archivo del modelo, ej. `standard_character_a_pose`) **no** se puede renombrar ni reparentar (ni arrastrando en el editor con "Editable Children", ni por script — Godot no lo permite). Por eso `person.gd` no asume ese nombre: en `_ready()` toma `_visual.get_child(0)` (lo que sea que haya ahí) y desde ese nodo navega por ruta fija hacia `Pivot`, `Pivot/Skeleton3D/MeshInstance3D` y `AnimationPlayer`. Así cualquier modelo nuevo funciona sin tocar código, sin importar cómo se llame su archivo `.glb`.
- **`MeshInstance3D` siempre con material.** La malla debe traer material asignado (por defecto o propio). Sin material se ve invisible/blanco de más.
- **`Skeleton3D` sí va en el asset, pero solo lo tocan las animaciones.** Las animaciones animan los huesos; **no se usa desde código** (ningún script accede a `Skeleton3D`).
- **El `Pivot` vive dentro del asset** para que volteos, rotación de daño (spin) y animaciones viajen juntos con el modelo.
- **El `.glb` se instancia, nunca se embebe.** Dentro de `Visual` va una instancia del `.glb` (arrastrado desde el panel de archivos), no una copia pegada a mano del mesh/skin/animaciones. Embeber duplica esos datos binarios como texto dentro del `.tscn` del prefab lo que afecta el tamaño del archivo y el rendimiento.

---

## Cómo agregar un personaje nuevo

1. **En Blender**: modelar y armar el rig con el nodo raíz llamado `Pivot`, con la malla/esqueleto colgando de ahí (ver reglas de escala y orientación en `docs/nota-modelos-animaciones.md`). Animar con los nombres exactos que usa el código — ver la sección [Animaciones](#animaciones) más abajo para la lista completa por contexto (piso/aire, Person/Fighter/PowerFighter).
2. **Exportar a `.glb`** y copiarlo a `assets/`.
3. **Crear el prefab** (`.tscn` nuevo en `prefabs/`) con esta estructura:
   ```
   CharacterBody3D      # raíz, sin script propio (se asigna en runtime desde spawn_point.gd)
       CollisionShape3D
       Visual            # Node3D, con el transform de corrección de escala/orientación del modelo
           <instancia del .glb>   # arrastrar el .glb desde el panel de archivos hasta Visual
   ```
   Al arrastrar el `.glb` sobre `Visual`, Godot genera el `ext_resource`/`instance=` solo — no hay que escribir nada a mano ni renombrar el nodo instanciado.
4. **No hace falta tocar `person.gd`, `fighter.gd` ni `power_fighter.gd`.** Son genéricos: mientras el modelo respete los nombres fijos de la regla anterior, el personaje nuevo funciona sin cambios de código.

---

## Animaciones
Nombres de animaciones. Estos no se cambian y se espera que se tengan todas las anims, o no si, posiblemente sucedera crash.

### En el piso

#### Person
- `idle`: Parado sin moverse
- `run`: Correr.
- `walk`: Caminar.
- `look_up`: Mirar arriba.
- `crouch`: Agacharse sin moverse.
- `crouch_walk`: Movimiento agachado.
- `hurt_ground`: Recibiendo daño en el piso.
- `knockdown`: Tumbado en el piso. Lleva a estado al person.
- `inpact_front`: Colision de frente en cualquier lado.
- `impact_back`: Colision de espaldas en cualquier lado.
- `turn`: Dar vuelta. (Saltando no puede dar vuelta).
- `hold_platform`: Agarrarse de plataforma.

#### Fighter
- `ground_neutral_attack`: Cendo no se mueve y esta parado.
- `down_attack`: Cuando esta agachado y sin moverse.
- `dash_attack`: Corriendo y atacar.
- `forward_attack`: Caminando y attack.
- `up_attack`: Sin moverse, y precionar ataque arriba.
- `heavy_side_attack`: Cuando se preciona al mismo tiempo ataque y der o izq.
- `heavy_up_attack`: Sin moverse, y precionar al mismo tiempo ataque y arriba.
- `heavy_down_attack`: Sin moverse, y precionar al mismo tiempo ataque y abajo.
- `pickup`: Agarrar item.
- `grab`: Agarrar a la gente.
- `guard`: Animación de defensa. Protección.
- `roll_forward`: Vuelta estilo parkur.
- `roll_backward`: Vuelta estilo parkur.

#### PowerFighter
- `power_neutral`: Proyectil, rafaga de energia, o carga de ataque.
- `power_side`: Poder hacia un lado.
- `power_up`: Poder hacia arriba que da propulicón. Puede hacer daño o no.
- `power_down`: Poder hacia abajo, puede ser ataque o no.

### En el aire
#### Person
- `jump`: Saltando.
- `fall`: Cayendo.
- `hurt_air`: Daño recibido en el aire.

#### Fighter
- `air_neutral_attack`: En el aire, sin moverse y atacar.
- `air_back_attack`: En el aire moviendose a de espaldas y atacar.
- `air_forward_attack`: En el aire moviendose a un lado y atacar.
- `air_down_attack`: En el aire y atacar precionando abajo. Ya sea moviendose o no.
- `air_up_attack`: En el aire y atacar precionando arriba. Ya sea moviendose o no.

#### PowerFighter
- `air_jump`: Salto en el aire.
- `power_air_up`: Lo mismo que power up. Pero animacion en el aire.
- `power_air_down`: Lo mismo que power down. Pero animacion en el aire.
- `power_air_side`: Lo mismo que power side. Pero animacion en el aire.