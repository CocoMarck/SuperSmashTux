# Nota: Detección generalista con AABB para NPC

## Objetivo

Mejorar la detección de objetos del NPC para considerar sus bordes reales (AABB) en lugar de solo el centro. Esto debe hacerse de forma **generalista** (sin acoplarlo a `Platform`), siguiendo la filosofía actual de `get_nodes_positions()` para poder extenderlo a otros objetos (Fighters, hitboxes, etc.) en el futuro.

## Estado actual

- `scripts/npc.gd` guarda solo plataformas en `_detected_platforms: Array[Platform]`.
- Utiliza `get_nodes_positions()` + `get_nearest_platform_position()` para obtener la plataforma más cercana por su centro.
- Durante el recovery, el NPC apunta al centro de la plataforma.
- `scripts/platform.gd` ya cuenta con `get_aabb_global()` (líneas 79-88), que devuelve un `AABB` en coordenadas globales respetando rotación y escala.

## Problema

Usar únicamente `global_position` (centro) pierde información sobre los bordes del objeto. Para tomar decisiones de aterrizaje más precisas durante el recovery, conviene conocer los extremos del área caminable.

## Propuesta

### 1. Helpers generalistas para obtener AABBs

En `npc.gd` se añadirán funciones que detecten nodos con `has_method("get_aabb_global")`, evitando acoplarse a una clase específica:

```gdscript
# Obtener AABBs de nodos que implementen get_aabb_global()
func get_nodes_aabbs(nodes: Array[Node3D]) -> Array[AABB]:
    var aabbs: Array[AABB] = []
    for obj in nodes:
        if not is_instance_valid(obj): continue
        if obj.has_method("get_aabb_global"):
            aabbs.append(obj.get_aabb_global())
    return aabbs

# Obtener AABB más cercano (por distancia 2D horizontal al centro)
func get_nearest_aabb(nodes: Array[Node3D]) -> AABB:
    if nodes.is_empty(): return AABB()
    var best_aabb: AABB = AABB()
    var best_dist: float = INF
    for obj in nodes:
        if not is_instance_valid(obj) or not obj.has_method("get_aabb_global"): continue
        var aabb = obj.get_aabb_global()
        var center = aabb.get_center()
        var dist = Vector2(global_position.x, global_position.y).distance_squared_to(Vector2(center.x, center.y))
        if dist < best_dist:
            best_dist = dist
            best_aabb = aabb
    return best_aabb
```

### 2. Elegir borde accesible según dirección

Durante el recovery, en lugar de apuntar al centro, se apunta al borde más accesible en función de la dirección actual del NPC:

```gdscript
var aabb = get_nearest_aabb(_detected_platforms)
var target_x: float
if _pin_right:
    target_x = aabb.position.x  # borde izquierdo (más accesible yendo a la derecha)
elif _pin_left:
    target_x = aabb.get_end().x  # borde derecho (más accesible yendo a la izquierda)
else:
    target_x = aabb.get_center().x  # fallback
var target_pos = Vector3(target_x, aabb.get_end().y, global_position.z)  # usar Z seguro
```

### 3. Integración con recovery actual

- Reemplazar `get_nearest_platform_position()` por lógica basada en AABB.
- Mantener `_detected_platforms` como `Array[Node3D]`/`Array[Platform]`. Sigue siendo generalista porque solo se comprueba `has_method("get_aabb_global")`.
- No modificar `Platform`. Esto prepara la detección para almacenar Fighters, hitboxes u otros objetos cuando corresponda.
- Ajustar `directional_orientation_relative_to_oneself()` o calcular la dirección directamente a partir de `target_pos` si es necesario.

## Notas técnicas

- `get_aabb_global()` ya calcula correctamente AABB axis-aligned en coordenadas globales, respetando rotación y escala. Esto es suficiente incluso para plataformas inclinadas (`Roof`).
- Se utiliza distancia 2D (`x,y`) para evitar sesgos por Z.
- Mantiene el principio "generalista" solicitado: no hay acoplamiento a `Platform`, solo detección por método.

## Ventajas

- **Más realista**: considera todo el ancho caminable, no solo el centro.
- **Menos correcciones bruscas**: al acercarse al borde accesible reduce el overshooting.
- **Reutilizable**: cualquier nodo con `get_aabb_global()` será detectado automáticamente.
- **Mejora el recovery**: el NPC aterriza con mayor probabilidad en la zona útil de la plataforma.

## Veredicto

Cambio fácil, localizado en `npc.gd`, que mejora el comportamiento del recovery sin romper la lógica actual. Además deja la base preparada para extender la detección a otros tipos de objetos.
