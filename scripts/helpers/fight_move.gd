extends RefCounted
class_name FightMove

# Propiedades publicas | Configuracion.
var name: StringName
var duration: float
var damage: int

# Propiedades publicas | Movimiento.
var stop_horizontal_move: bool
var stop_vertical_move: bool
var speed: Vector3

# Propiedades publicas | Ataque.
var air_attack: bool
var hitbox_position: Vector3
var hitbox_time_ratio: float
var inversed_hitbox_ratio: bool

# Propiedades publicas | Animacion.
var animation_name: StringName
var mesh_rotation_x: float

func _init(
	p_name: StringName, p_duration: float, p_damage: int,
	p_stop_horizontal_move: bool, p_stop_vertical_move: bool, p_speed: Vector3, 
	p_air_attack: bool, p_hitbox_position: Vector3,
	p_animation_name: StringName = &"", p_mesh_rotation_x: float = 0.0, p_hitbox_time_ratio: float = 0.5, p_inversed_hitbox_ratio: bool = true
):
	# Asignar los parametros de construccion a las propiedades de la clase.
	name = p_name
	duration = p_duration
	damage = p_damage
	stop_horizontal_move = p_stop_horizontal_move
	stop_vertical_move = p_stop_vertical_move
	speed = p_speed
	air_attack = p_air_attack
	hitbox_position = p_hitbox_position
	animation_name = p_animation_name
	mesh_rotation_x = p_mesh_rotation_x
	hitbox_time_ratio = p_hitbox_time_ratio
	inversed_hitbox_ratio = p_inversed_hitbox_ratio

func get_hitbox_time_ratio() -> float:
	return (duration * hitbox_time_ratio)
