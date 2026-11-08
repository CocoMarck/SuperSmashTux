class_name OffscreenCam
extends PanelContainer

# Mini cámara que muestra a un peleador que salió del encuadre.
# Comparte el World3D del juego y solo renderiza mientras está activa.

# Propiedades publicas | Configuración de la mini cámara.
@export_group("Camera")
@export var camera_offset := Vector3(0.0, 0.3, 3.2) # Origen del peleador = centro de su cápsula de 1.8.
@export var look_height: float = 0.1 # Altura sobre el origen del peleador a la que apunta la cámara.

# Propiedades privadas
var _target: Node3D = null
var _active: bool = false

# Propiedades privadas | Nodos
@onready var _tag_label: Label = %TagLabel
@onready var _viewport: SubViewport = %Viewport
@onready var _camera: Camera3D = %Camera

# Funciones | Callbacks
func _ready() -> void:
	'''
	Arranca oculta en el juego; el editor sí la muestra para poder diseñarla. La prende set_active().
	'''
	visible = false

func _process(_delta: float) -> void:
	'''
	Sigue al peleador solo si está activa; salta el frame si el peleador ya no es válido o salió del árbol (p. ej. esperando respawn).
	'''
	if not _active or _target == null or not is_instance_valid(_target) or not _target.is_inside_tree():
		return
	var target_pos := _target.global_position
	_camera.global_position = target_pos + camera_offset
	_camera.look_at(target_pos + Vector3(0.0, look_height, 0.0))

# Funciones
func setup(label: String, color: Color, target: Node3D) -> void:
	'''
	Configura el tag del jugador (P1, P2, CPU), su color y el peleador a seguir.
	Llamar con la escena ya dentro del árbol.
	'''
	_target = target
	_tag_label.text = label
	_tag_label.add_theme_color_override("font_color", color)
	# Mismo mundo 3D que el juego; si no, el SubViewport dibujaría un mundo vacío.
	_viewport.world_3d = get_viewport().world_3d
	set_active(false)

func set_active(active: bool) -> void:
	'''
	Muestra u oculta la mini cámara. El SubViewport solo dibuja la escena mientras se ve.
	'''
	_active = active
	visible = active
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	)
