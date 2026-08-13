class_name GroundPlatform
extends Platform

# Plataforma de suelo normal, con orillas agarrables 
# (debe tener un collision shape de caja 3D y no tener inclinación).

# Propiedades publicas | Zona de agarre.
@export var ledge_zone_width: float = 1.0   # que tan ancha hacia afuera es la zona de agarre de cada orilla
@export var ledge_zone_depth: float = 0.5   # que tanto se expande hacia abajo la zona de agarre, desde la cara superior

# Propiedades privadas | Quien anda colgao de cada cornisa.
var _ledge_holders: Dictionary = {}

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

func is_ledge_free(right_side: bool, who: Node = null) -> bool:
	'''
	Saber si la cornisa de ese lado esta libre. Si la trae el mismo que pregunta, tambien cuenta como libre.
	De pasada limpia al ocupante si ya se murio, pa que la cornisa no se quede apartada por un fantasma.
	'''
	var holder = _ledge_holders.get(right_side)
	if holder == null or not is_instance_valid(holder):
		_ledge_holders.erase(right_side)
		return true
	return holder == who

func take_ledge(right_side: bool, who: Node) -> bool:
	'''
	Apartar la cornisa de ese lado. Devuelve false si ya la trae alguien mas.
	'''
	if not is_ledge_free(right_side, who):
		return false
	_ledge_holders[right_side] = who
	return true

func release_ledge(right_side: bool, who: Node) -> void:
	'''
	Soltar la cornisa. Nomas suelta si de verdad la traia quien lo pide, pa que nadie desaloje a otro.
	'''
	if _ledge_holders.get(right_side) == who:
		_ledge_holders.erase(right_side)

func is_character_in_ledge_zone(right_side: bool, position: Vector3) -> bool:
	'''
	Si una posicion global cae dentro de la cajita de agarre de ese lado: una franja horizontal de
	ledge_zone_width medida hacia afuera del borde, y ledge_zone_depth hacia abajo desde la cara
	superior. Pura comparacion de rangos, nada de fisica ni nodos.
	'''
	if not has_ledges():
		return false
	var ledge_x := get_ledge_x(right_side)
	var in_x := (position.x >= ledge_x and position.x <= ledge_x + ledge_zone_width) if right_side \
		else (position.x <= ledge_x and position.x >= ledge_x - ledge_zone_width)
	if not in_x:
		return false
	var top_y := get_top_y()
	return position.y <= top_y and position.y >= top_y - ledge_zone_depth
