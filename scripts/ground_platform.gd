class_name GroundPlatform
extends StaticBody3D

# Plataforma de suelo normal, con orillas agarrables (debe tener un collision shape de caja 3D).

# Constantes del script.
const GROUP_NAME := &"ground_platforms"

# Propiedades privadas | Forma de la plataforma.
@onready var _collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Meterse al grupo de plataformas de suelo, pa que los characters nos encuentren facil y barato.
	'''
	add_to_group(GROUP_NAME)

# Funciones propias.
func has_ledges() -> bool:
	'''
	Saber si esta plataforma tiene orillas agarrables (agarrame esta). Solo si su primer CollisionShape3D
	lleva un BoxShape3D, si no, ni caso tiene buscarle la tercera pierna al vato.
	'''
	return _collision_shape != null and _collision_shape.shape is BoxShape3D

func get_top_y() -> float:
	'''
	Altura global de la cara de arriba de la plataforma.
	Si no hay caja de donde sacarla, se regresa la posicion global de la plataforma nomas, de fallback.
	'''
	if not has_ledges():
		return global_position.y
	var box := _collision_shape.shape as BoxShape3D
	var half_height := box.size.y * 0.5 * _collision_shape.global_basis.get_scale().y
	return _collision_shape.global_position.y + half_height

func get_ledge_x(right_side: bool) -> float:
	'''
	Posicion x global de una de las orillas de la plataforma.
	Con right_side en true da la orilla derecha, en false la izquierda.
	'''
	if not has_ledges():
		return global_position.x
	var box := _collision_shape.shape as BoxShape3D
	var half_width := box.size.x * 0.5 * _collision_shape.global_basis.get_scale().x
	return _collision_shape.global_position.x + (half_width if right_side else -half_width)
