@abstract
class_name Platform
extends StaticBody3D

# Clase abstracta papa de las plataformas del juego.
# Centraliza el registro en grupo y el calculo de la cara superior via collision shape.

# Propiedades privadas | Forma de la plataforma.
@onready var _collision_shape: CollisionShape3D = _get_first_collision_shape()

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Registrar la plataforma en su grupo. El nombre del grupo lo define cada hijo
	sobrescribiendo _get_group_name().
	'''
	add_to_group(_get_group_name())

# Funciones propias.
func _get_first_collision_shape() -> CollisionShape3D:
	'''
	Buscar el primer CollisionShape3D hijo directo de la plataforma.
	'''
	for child in get_children():
		if child is CollisionShape3D:
			return child
	return null

func get_top_y() -> float:
	'''
	Altura (Y global) de la cara superior de la plataforma, segun su collision shape.
	Soporta BoxShape3D, CylinderShape3D y CapsuleShape3D. Sin shape util, cae a global_position.y.
	'''
	if _collision_shape == null or _collision_shape.shape == null:
		return global_position.y

	var half_height := 0.0
	var shape := _collision_shape.shape
	if shape is BoxShape3D:
		half_height = (shape as BoxShape3D).size.y * 0.5
	elif shape is CylinderShape3D:
		half_height = (shape as CylinderShape3D).height * 0.5
	elif shape is CapsuleShape3D:
		half_height = (shape as CapsuleShape3D).height * 0.5
	else:
		return global_position.y

	var scale_y := _collision_shape.global_basis.get_scale().y
	return _collision_shape.global_position.y + (half_height * scale_y)

# Funciones para sobrescribir en los hijos.
@abstract
func _get_group_name() -> StringName
