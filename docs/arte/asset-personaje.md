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
        (Instancia del asset) # Index 0
        ShieldMeshInstance3D  # Index 1
```
> Respetar los index.

## Reglas

- **Nombres fijos, pero solo dentro del modelo.** `Pivot`, `Skeleton3D`/`MeshInstance3D` y `AnimationPlayer` deben llamarse igual en todos los assets — eso es lo que exportas de Blender y no cambia. El nodo que Godot pone automáticamente al instanciar el `.glb` (el hijo directo de `Visual`, con el nombre del archivo del modelo, ej. `standard_character_a_pose`) **no** se puede renombrar ni reparentar (ni arrastrando en el editor con "Editable Children", ni por script — Godot no lo permite). Por eso `person.gd` no asume ese nombre: en `_ready()` toma `_visual.get_child(0)` (lo que sea que haya ahí) y desde ese nodo navega por ruta fija hacia `Pivot`, `Pivot/Skeleton3D/MeshInstance3D` y `AnimationPlayer`. Así cualquier modelo nuevo funciona sin tocar código, sin importar cómo se llame su archivo `.glb`.
- **`MeshInstance3D` siempre con material.** La malla debe traer material asignado (por defecto o propio). Sin material se ve invisible/blanco de más.
- **`Skeleton3D` sí va en el asset, pero solo lo tocan las animaciones.** Las animaciones animan los huesos; **no se usa desde código** (ningún script accede a `Skeleton3D`).
- **El `Pivot` vive dentro del asset** para que volteos, rotación de daño (spin) y animaciones viajen juntos con el modelo.
- **El `.glb` se instancia, nunca se embebe.** Dentro de `Visual` va una instancia del `.glb` (arrastrado desde el panel de archivos), no una copia pegada a mano del mesh/skin/animaciones. Embeber duplica esos datos binarios como texto dentro del `.tscn` del prefab lo que afecta el tamaño del archivo y el rendimiento.

---

## Cómo agregar un personaje nuevo

1. **En Blender**: modelar y armar el rig con el nodo raíz llamado `Pivot`, con la malla/esqueleto colgando de ahí (ver reglas de escala y orientación en `docs/arte/nota-modelos-animaciones.md`). Animar con los nombres exactos que usa el código — ver la sección [Animaciones](#animaciones) más abajo para la lista completa por contexto (piso/aire, Person/Fighter/PowerFighter).
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
- Nombres de animaciones. Estos no se cambian y se espera que se tengan todas las anims, o no si, posiblemente sucederá crash. 
- Las animaciones que no especifiquen que son cíclicas, no lo son.
- Las animaciones que no especifiquen frames, pueden tener frames libres.

#### Lógica de prefix
Todo nombre que no tenga prefijo `air_`, sucede en el piso. Ejemplo `rising`, conceptualmente se puede entender que sucede si o si en el aire, pero también puedes elevarte en el piso, por lo que poner `air_rising` tiene sentido.

### En el piso

#### Person
01. `idle`: Parado sin moverse. Animación cíclica.
02. `run`: Correr. Animación cíclica.
03. `walk`: Caminar. Animación cíclica.
04. `look_up`: Mirar arriba. Animación cíclica.
05. `crouch`: Agacharse sin moverse. Animación cíclica.
06. `crouch_walk`: Movimiento agachado. Animación cíclica.
07. `hurt`: Recibiendo daño en el piso.
08. `knockdown`: Tumbado en el piso. Lleva a estado al person. Animación cíclica.
09. `inpact_front`: Colisión de frente en cualquier lado.
10. `impact_back`: Colisión de espaldas en cualquier lado.
11. `turn`: Dar vuelta. (Saltando no puede dar vuelta).
12. `hold_platform`: Agarrarse de plataforma. Animación cíclica.
13. `knocked_out`: Noqueado. Animación cíclica.
14. `neutral_jump`: Sin moverse, solo saltar. Animación cíclica.
15. `moving_jump`: Moviéndose, y saltar. Animación cíclica.
16. `grabbed`: Siendo agarrado. Animación cíclica.

#### Fighter
17. `neutral_attack1`: Cuando no se mueve y esta parado. (Concepto empezando en idle, y terminando en idle.).
18. `neutral_attack2`: Lo mismo que `neutral_attack1`.
19. `neutral_attack3`: Lo mismo que `neutral_attack1`.
20. `down_attack`: Cuando esta agachado y sin moverse.
21. `dash_attack`: Corriendo y atacar.
22. `forward_attack`: Caminando y attack.
23. `up_attack`: Sin moverse, y presionar ataque arriba.
24. `heavy_side_attack`: Cuando se presiona al mismo tiempo ataque y der o izq.
25. `heavy_up_attack`: Sin moverse, y presionar al mismo tiempo ataque y arriba.
26. `heavy_down_attack`: Sin moverse, y presionar al mismo tiempo ataque y abajo.
27. `pickup`: Agarrar item.
28. `grab`: Intentar agarrar a alguien.
29. `grabbing`: Agarrando a alguien. Animación cíclica.
30. `guard`: Animación de defensa. Protección. Animación cíclica.
31. `roll_forward`: `guard`, y luego vuelta adelante estilo parkur. 15 frames.
32. `roll_backward`: `guard`, y luego vuelta atrás estilo parkur. 15 frames.
33. `throw_forward`: `grabbing` y luego arrojar victima al frente.
34. `throw_backward`: `grabbing` y luego arrojar victima hacia atrás.


#### PowerFighter
35. `power_attack`: Proyectil, ráfaga de energía, o carga de ataque.
36. `up_power_attack`: Poder hacia arriba que da propulsión. Puede hacer daño o no.
37. `down_power_attack`: Poder hacia abajo, puede ser ataque o no.

### En el aire
#### Person
38. `air_rising`: Elevándose en el aire sin saltar. Por un golpe, por un trampolín, etc. Animación cíclica.
39. `air_jump`: Salto en el aire neutral.
40. `air_back_jump`: Salto en el aire de espaldas.
41. `air_forward_jump`: Salto en el aire de frente.
42. `air_hurt`: Daño recibido en el aire.
43. `air_fall`: Cayendo normal, sin stun ni nada. Animación cíclica.

#### Fighter
43. `air_neutral_attack`: En el aire, sin moverse y atacar.
44. `air_back_attack`: En el aire moviéndose de espaldas y atacar.
45. `air_forward_attack`: En el aire moviéndose de frente y atacar.
46. `air_down_attack`: En el aire y atacar presionando abajo. Ya sea moviéndose o no.
47. `air_up_attack`: En el aire y atacar presionando arriba. Ya sea moviéndose o no.

#### PowerFighter
48. `air_up_power_attack`: Lo mismo que power up. Pero animación en el aire.
49. `air_down_power_attack`: Lo mismo que power down. Pero animación en el aire.
50. `air_power_attack`: Proyectil, ráfaga de energía, o carga de ataque.