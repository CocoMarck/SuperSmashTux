class_name GroundPlatform
extends Platform

# Plataforma de suelo normal, con orillas agarrables (debe tener un collision shape de caja 3D).

# Constantes del script.
const GROUP_NAME := &"ground_platforms"

# Funciones | Grupo (usado por el _ready() del papa Platform).
func _get_group_name() -> StringName:
	return GROUP_NAME

# Funciones propias.
func has_ledges() -> bool:
	'''
	Solo un BoxShape3D define esquinas claras en X; un cilindro o capsula
	no tienen una orilla real que agarrar.
	'''
	return _collision_shape != null and _collision_shape.shape is BoxShape3D

func get_ledge_x(right_side: bool) -> float:
	'''
	Posicion X global de la orilla derecha o izquierda segun right_side.
	Si la plataforma no tiene orillas, cae a global_position.x sin tronar.
	'''
	if not has_ledges():
		return global_position.x
	var box := _collision_shape.shape as BoxShape3D
	var half_width := box.size.x * 0.5 * _collision_shape.global_basis.get_scale().x
	return _collision_shape.global_position.x + (half_width if right_side else -half_width)
