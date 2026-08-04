class_name OneWayPlatform
extends StaticBody3D

# Plataforma que se atraviesa desde abajo, pero en la que te posas al caer encima.

# Constantes del script.
const GROUP_NAME := &"one_way_platforms"

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Meterse al grupo de plataformas de un solo sentido, pa que los characters nos encuentren facil y barato.
	'''
	add_to_group(GROUP_NAME)

# Funciones propias.
func get_top_y() -> float:
	'''
	Altura global de la cara de arriba de la plataforma. Se calcula desde el primer CollisionShape3D hijo.
	Si no hay shape soportado, se regresa la posicion global de la plataforma nomas, de fallback.
	'''
	var collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null or collision_shape.shape == null:
		return global_position.y

	var half_height := 0.0
	var shape := collision_shape.shape
	if shape is BoxShape3D:
		half_height = (shape as BoxShape3D).size.y * 0.5
	elif shape is CylinderShape3D:
		half_height = (shape as CylinderShape3D).height * 0.5
	elif shape is CapsuleShape3D:
		half_height = (shape as CapsuleShape3D).height * 0.5
	else:
		return global_position.y

	var scale_y := collision_shape.global_basis.get_scale().y
	return collision_shape.global_position.y + (half_height * scale_y)
