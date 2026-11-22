@tool
class_name StagePlan
extends Control

'''
Plano 2D (vista XY) de un escenario, dibujado leyendo la escena real: cajas de los StaticBody3D como
polígonos. La escena se instancia sin meterla al árbol, se lee y se libera.
Es @tool para que el editor muestre el plano. Las clases del juego no se usan para detectar nodos porque
en el editor los scripts que no son @tool son placeholders.
'''

# Constantes
const PLATFORM_COLOR := Color("#C9D1DB")
const MARGIN := 10.0

# Propiedades públicas
@export_file("*.tscn") var scene_path: String = "":
	set(value):
		scene_path = value
		_load_geometry()
		queue_redraw()

# Propiedades privadas
# Cajas ya leídas por ruta.
static var _cache: Dictionary[String, Array] = {}
var _boxes: Array[PackedVector2Array] = []

# Funciones | Callbacks
func _ready() -> void:
	_load_geometry()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var bounds: Rect2 = _bounds()
	if bounds.size.x <= 0.0 and bounds.size.y <= 0.0:
		return
	var available: Vector2 = size - Vector2.ONE * MARGIN * 2.0
	if available.x <= 0.0 or available.y <= 0.0:
		return
	var plan_scale: float = minf(available.x / maxf(bounds.size.x, 0.001), available.y / maxf(bounds.size.y, 0.001))
	var offset: Vector2 = size / 2.0 - bounds.get_center() * Vector2(plan_scale, -plan_scale) # Y invertida: arriba es +Y.
	for box: PackedVector2Array in _boxes:
		draw_colored_polygon(_to_screen(box, plan_scale, offset), PLATFORM_COLOR)

# Funciones
func _load_geometry() -> void:
	'''
	Lee la geometría de scene_path (con caché por ruta fuera del editor, donde la escena puede estar cambiando).
	'''
	_boxes = []
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	if not Engine.is_editor_hint() and _cache.has(scene_path):
		_boxes.assign(_cache[scene_path])
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return
	var root: Node = packed.instantiate()
	var boxes: Array[PackedVector2Array] = []
	_collect(root, Transform3D.IDENTITY, boxes)
	root.free()
	if not Engine.is_editor_hint():
		_cache[scene_path] = boxes
	_boxes = boxes

func _collect(node: Node, parent_transform: Transform3D, boxes: Array[PackedVector2Array]) -> void:
	'''
	Recorre el árbol componiendo a mano las transformadas (fuera del árbol no hay global_transform).
	'''
	var node_3d := node as Node3D
	var current: Transform3D = parent_transform * node_3d.transform if node_3d != null else parent_transform
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh is BoxMesh and mesh_instance.get_parent() is StaticBody3D:
		var half: Vector3 = (mesh_instance.mesh as BoxMesh).size / 2.0
		var corners := PackedVector2Array()
		for sign_xy: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var point: Vector3 = current * Vector3(half.x * sign_xy.x, half.y * sign_xy.y, 0.0)
			corners.append(Vector2(point.x, point.y))
		boxes.append(corners)
	for child: Node in node.get_children():
		_collect(child, current, boxes)

func _bounds() -> Rect2:
	var points := PackedVector2Array()
	for box: PackedVector2Array in _boxes:
		points.append_array(box)
	if points.is_empty():
		return Rect2()
	var rect := Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		rect = rect.expand(point)
	return rect

func _to_screen_point(point: Vector2, plan_scale: float, offset: Vector2) -> Vector2:
	return point * Vector2(plan_scale, -plan_scale) + offset

func _to_screen(points: PackedVector2Array, plan_scale: float, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(_to_screen_point(point, plan_scale, offset))
	return result
