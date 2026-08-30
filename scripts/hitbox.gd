class_name Hitbox
extends Area3D

'''
Hitbox. 
Hace daño a cualquier cosa.
'''

# Propiedades privadas
var id : int
var _parent : Node3D = null

var _shape := CollisionShape3D.new()
var _box_shape := BoxShape3D.new()

var _mesh := MeshInstance3D.new()
var _box_mesh := BoxMesh.new()
var _material := StandardMaterial3D.new()

var _direction: Vector3 # <--- Direccion de spawneo

var _lifetime :float = 0.0
var _init_lifetime: float

var _defaults: Dictionary = {
	"parent": Node3D.new(),
	"id": 1,
	"position": Vector3.ZERO,
	"size": Vector3(1,1,1),
	"color": Color(1.0, 1.0, 1.0, 0.4),
	"lifetime": 1.0,
	"direction": Vector3.ZERO,
}

func _init(
	p_config: Dictionary
):
	# Config fixeado con defaults
	var config := _defaults.duplicate()
	config.merge(p_config, true)  # true = p_config gana

	id = config["id"]
	position = config["position"]
	_parent = config["parent"]
	_lifetime = config["lifetime"]
	_init_lifetime = config["lifetime"]
	
	# Shape daño real
	_box_shape.size = config["size"]
	_shape.shape = _box_shape
	
	# Cuadradito visible
	_box_mesh.size = config["size"]
	_mesh.mesh = _box_mesh
	
	_direction = config["direction"]

	# Material
	_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	_mesh.material_override = _material
	set_color( config["color"] )
	
	# Inicializar collider y mesh
	add_child(_shape)
	add_child(_mesh)

func set_color( p_color: Color ) -> void:
	_material.albedo_color = p_color

func set_alpha(p_alpha: float) -> void:
	_material.albedo_color.a = clampf(p_alpha, 0.0, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _good_lifetime() -> bool:
	return _init_lifetime > 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _good_lifetime():
		if _lifetime <= 0:
			self.queue_free()
		_lifetime -= delta
