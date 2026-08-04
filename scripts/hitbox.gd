class_name Hitbox
extends Area3D

'''

'''

# Propiedades privadas
var _parent : Node3D = null

var _shape := CollisionShape3D.new()
var _box_shape := BoxShape3D.new()

var _mesh := MeshInstance3D.new()
var _box_mesh := BoxMesh.new()

func _init(p_position: Vector3, p_size: Vector3, p_parent: Node3D):
	position = p_position
	_parent = p_parent
	
	# Shape daño real
	_box_shape.size = p_size
	_shape.shape = _box_shape
	
	# Cuadradito visible
	_box_mesh.size = p_size
	_mesh.mesh = _box_mesh
	
	# Inicializar todo
	add_child(_shape)
	add_child(_mesh)
	body_entered.connect(_on_hitbox_body_entered)
	

func _on_hitbox_body_entered(body: Node3D) -> void:
	'''
	Golpe a cuerpo. Ya sea character, item, lo que sea.
	'''
	if body == _parent:
		return
	if body is Character:
		print(body.name, " recibio trancazo")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
