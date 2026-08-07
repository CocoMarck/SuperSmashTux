class_name GroundPlatform
extends Platform

# Plataforma de suelo normal, con orillas agarrables 
# (debe tener un collision shape de caja 3D y no tener inclinación).

# Funciones propias.
func has_ledges() -> bool:
	'''
	Solo una caja define esquinas claras en X; sin BoxShape3D no hay orilla real que agarrar.
	'''
	return _get_box() != null

func get_ledge_x(right_side: bool) -> float:
	'''
	Posicion X global de la orilla derecha o izquierda segun right_side.
	Si la plataforma no tiene orillas, cae a global_position.x sin tronar.
	'''
	var box := _get_box()
	if box == null:
		return global_position.x
	var half_width := box.size.x * 0.5 * _collision_shape.global_basis.get_scale().x
	return _collision_shape.global_position.x + (half_width if right_side else -half_width)
