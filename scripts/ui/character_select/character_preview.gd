class_name CharacterPreview
extends SubViewportContainer

'''
Preview 3D de un personaje girando sobre una plataforma giratoria (Turntable).
Dentro de su propio mundo 3D con fondo transparente; encuadra la cámara con el tamaño del modelo.
'''

# Constantes
const SECONDS_PER_TURN := 6.0
const IDLE_ANIMATION := &"idle"
const TUX_MESH_OFFSET_Y := -1.2 # Mismo ajuste que PowerFighterConfigurer._build_tux_instance.
const FILL_RATIO := 0.7 # Parte del alto de la imagen que ocupa el personaje.
const FEET_RATIO := 0.12 # Espacio bajo los pies, como fracción del alto visible.
const SLOT_MATERIALS: Array[Material] = [
	preload("res://materials/mat_red.tres"),
	preload("res://materials/mat_blue.tres"),
	preload("res://materials/mat_yellow.tres"),
	preload("res://materials/mat_green.tres"),
]

# Propiedades públicas
@export_group("Cámara")
@export var camera_distance: float = 0.0 ## 0 = se calcula con el tamaño del modelo.
@export var camera_height: float = 0.0 ## 0 = se calcula con el tamaño del modelo.

# Propiedades privadas
var _model: Node3D = null

# Propiedades privadas | Nodos
@onready var _camera: Camera3D = %Camera3D
@onready var _turntable: Node3D = %Turntable

# Funciones | Callbacks
func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	_turntable.rotation.y = wrapf(_turntable.rotation.y + TAU / SECONDS_PER_TURN * delta, 0.0, TAU)

# Funciones
func show_character(entry: CharacterCatalog.Entry, slot: int) -> void:
	'''
	Muestra el modelo del personaje (con el color del slot en B.O.B). Aleatorio no tiene modelo: limpia.
	'''
	clear()
	if entry == null or entry.model == null:
		return
	_model = entry.model.instantiate() as Node3D
	_turntable.add_child(_model)
	_turntable.rotation.y = 0.0

	# La estructura del glb es Raíz/Pivot/Skeleton3D/Mesh y Raíz/AnimationPlayer.
	var mesh := _find_mesh(_model)
	if mesh != null:
		if entry.config == GlobalUtils.PowerFighterConfig.TUX:
			mesh.position.y = TUX_MESH_OFFSET_Y
		else:
			mesh.material_override = SLOT_MATERIALS[clampi(slot, 0, 3)]
		_frame_camera(mesh)

	var animation_player := _model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation(IDLE_ANIMATION):
		animation_player.get_animation(IDLE_ANIMATION).loop_mode = Animation.LOOP_LINEAR
		animation_player.play(IDLE_ANIMATION)
	set_process(true)

func clear() -> void:
	'''
	Quita el modelo y detiene el giro.
	'''
	set_process(false)
	if _model != null:
		_turntable.remove_child(_model)
		_model.queue_free()
		_model = null

func _find_mesh(root: Node) -> MeshInstance3D:
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	return meshes[0] as MeshInstance3D if not meshes.is_empty() else null

func _frame_camera(mesh: MeshInstance3D) -> void:
	'''
	Pone la cámara de frente al modelo: ocupa FILL_RATIO del alto y los pies quedan cerca del fondo.
	'''
	var aabb: AABB = mesh.transform * mesh.get_aabb()
	var visible_height: float = aabb.size.y / FILL_RATIO
	var half_fov: float = deg_to_rad(_camera.fov) / 2.0
	var distance: float = camera_distance if camera_distance > 0.0 else visible_height / (2.0 * tan(half_fov))
	var height: float = camera_height if camera_height > 0.0 else aabb.position.y + visible_height * (0.5 - FEET_RATIO)
	_camera.position = Vector3(0.0, height, distance)
	_camera.rotation = Vector3.ZERO
