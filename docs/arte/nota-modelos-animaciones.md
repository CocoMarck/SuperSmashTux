# Nota: Modelos y Animaciones

> Convenciones para meter mallas (modelos) y animaciones al proyecto. Pensadas para que las entienda alguien que no es pro en 3D. Idea central: **1 unidad = 1 metro**, y que el espacio del Pivot quede siempre en metros para que los golpes salgan parejos. Algunas partes son decisión ya tomada, otras están pendientes de aplicar (se marcan).

## La idea de fondo: 1 unidad = 1 metro

En Godot y Blender no existe un "centímetro" por defecto: los números son unidades. Aquí decidimos que **1 unidad = 1 metro**.

- Un humanoide normal mide ~1.5 unidades → mide 1 metro y medio.
- Un personaje chiquito de 1.2 unidades → mide 1.2 metros. "1.2 de 1, pos es un metro dos".
- Un personaje gigante de 3 unidades → 3 metros.

Esto quiere decir que **en Blender se modela a tamaño real** (un humanoide de 1.5m se modela de 1.5 unidades). No hay que hacer nada raro con escalas.

### El tamaño final se decide en Godot, no en Blender

El modelo se autor en metros, pero **la altura final de cada personaje se decide en Godot** escalando al personaje (por script o en la escena). Si quieres un ejército de Tux de 1m, los escalas a 1.0; si quieres uno de 1.2, a 1.2. Modelar a 1 unidad como base está bien porque después escalas — por eso todos en 1m no es mala idea, jaja.

## La regla de oro: el Pivot siempre en metros

El **Pivot** es el `Node3D` que guarda la malla, y de él cuelgan también los **hitboxes** de los golpes (posiciones del `FightMove.hitbox_position`). Todo lo que se le pone al Pivot en espacio local es "en metros".

El problema: si el personaje está escalado (ej. raíz en 3), 1 unidad del Pivot no es 1 metro en el mundo. Por eso hay que **normalizar el Pivot**: que 1 unidad de su espacio = 1 metro de mundo, **sin importar el tamaño final del personaje**.

Cómo se logra (pendiente de aplicar en `Person`):
- `$Pivot.scale = Vector3.ONE / escala_del_cuerpo` (si el cuerpo escala 3 → `1/3`).
- Compensar la malla para que no se encoja: `$Pivot/Mesh.scale = Vector3(escala_del_cuerpo, ...)`.

Con esto, el **mismo `hitbox_position` significa los mismos metros para todos los personajes**, aunque uno mida 1m y otro 3m. Es la forma de que los golpes se sientan iguales y no haya que re-tunear cada personaje por separado.

### Detalle técnico importante

El `CollisionShape3D` (la caja invisible con la que el personaje choca contra el piso) es **hijo de la raíz, no del Pivot**. O sea: escalar el Pivot no cambia la colisión. Eso es bueno — la colisión la controla la raíz/el shape, y el Pivot es solo el "cuerpo visual + hitboxes".

## Origen de la malla en medio

Regla: **el origen de la malla va en el centro de esta**, y el origen del Pivot también coincide con el centro de la malla. El Pivot queda "encajado" en el medio del cuerpo.

Por qué importa:
- Al girar el cuerpo (ej. el giro de knockback cuando te lanzan), gira alrededor de su centro y se ve natural.
- El código que calcula pies/cabeza (`_get_feet_y`/`_get_head_y`) no depende de la malla: saca las medidas del `CollisionShape3D`. Así que tener el origen en medio no rompe nada.

Si modelas en Blender con el origen fuera del centro, el personaje "flota" o se ve desplazado al animarlo/girarlo.

## Dirección: a dónde mira el personaje

Esta es de las que "se batallan" si no se decide desde el principio. La convención:

- En Godot, el "frente" de un modelo es **-Z**.
- En Blender, el personaje se modela mirando **+Y**, y se exporta con los ajustes **Forward: -Z / Up: Y** (los default de glTF). Así llega a Godot mirando -Z, o sea, al frente.

Si todos los modelos respetan esto, no hay que estar rotando cosas a mano por cada personaje. En el script, la dirección visual se fija con `Basis.looking_at(...)` (como ya hace `_set_pivot_direction` en `person.gd`).

## Animaciones con Blender

Blender y Godot se llevan muy bien vía **glTF (.glb)**: exportas el modelo con sus animaciones y Godot las importa listas.

- La vía es: modelar y animar en Blender → exportar `.glb` → usarlo en Godot con un `AnimationPlayer` (como ya se usa hoy).
- **Los nombres de las animaciones deben coincidir con los que el código busca** (`neutral_attack`, `dash_attack`, `crouch`, `walk`, `run`, `jump`, `fall`, `idle`, etc.). Si el nombre no coincide, el código toca "idle" o se queda mudo.
- Hoy las animaciones son *value tracks* hechas a mano para la cápsula placeholder; con modelos reales llegan como animaciones esqueléticas. En Godot se consumen igual con `AnimationPlayer`.

## Materiales

Regla simple: **a toda malla se le asigna un material base, aunque sea un placeholder**. Sin material, el mesh no tiene "slot" donde Godot le pueda poner color — y no se puede reemplazar/agregar material cómodamente.

- En Blender: asígnale un material al modelo (un gris cualquiera sirve) y se exporta con ese slot.
- En Godot: se reemplaza con `material_override` (lo que ya hace `_set_material` en `person.gd`) o con `surface_set_material(i, material)` si se quiere por superficie.

## Qué se hace por script y qué no

- **Por script** (una sola vez en `_ready()`, en un `_setup_mesh()`): la escala final del personaje, la posición del Pivot/malla, y si es una primitiva (caja, cápsula) su `size`. Todo con `@export` para ajustar sin tocar código.
- **No por script**: el tamaño real del modelo (eso se autor en Blender). El script solo *corrige* desviaciones, no es la fuente de la verdad.

Ojo: el `size` solo existe en las primitivas procedurales (`BoxMesh.size`, `CapsuleMesh.height`). En modelos importados no hay "size": se usa `scale`.

## Estado / pendientes

- [ ] Normalizar el Pivot a metros en `Person` (`$Pivot.scale = 1/escala` + compensar `$Pivot/Mesh`).
- [ ] Decidir/escalar el cuerpo a su tamaño final (hoy la raíz está en 3 y el cuerpo mide ~4.35m).
- [ ] Re-tunear los `hitbox_position` de los `FightMove` al espacio en metros.
- [ ] Documentar la lista de nombres de animaciones esperados por el código (cuando se integre el primer modelo real).
