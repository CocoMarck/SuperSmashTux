class_name OldFightMove
extends RefCounted

# Propiedades publicas | Configuracion.
var name: StringName
var duration: float
var damage: int
var power_direction: Vector3

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
var mesh_rotation_x: float # <-- Esto es legacy. Se borrara cuando se usen full animaciones. Como debe ser.

func _init(
	p_name: StringName="", p_duration: float=0.0, p_damage: int=0.0,
	p_stop_horizontal_move: bool=false, p_stop_vertical_move: bool=false, p_speed: Vector3=Vector3.ZERO, 
	p_air_attack: bool=false, p_hitbox_position: Vector3=Vector3.ZERO,
	p_animation_name: StringName = &"", p_mesh_rotation_x: float = 0.0, p_hitbox_time_ratio: float = 0.5, p_inversed_hitbox_ratio: bool = true, 
	p_power_direction: Vector3 = Vector3(1,1,1)
):
	# Asignar los parametros de construccion a las propiedades de la clase.
	name = p_name
	duration = p_duration
	damage = p_damage
	power_direction = p_power_direction
	
	stop_horizontal_move = p_stop_horizontal_move
	stop_vertical_move = p_stop_vertical_move
	speed = p_speed
	air_attack = p_air_attack
	
	hitbox_position = p_hitbox_position
	
	# Animation
	animation_name = p_animation_name
	mesh_rotation_x = p_mesh_rotation_x # <-- Esto es legacy. Se borrara cuando se usen full animaciones. Como debe ser.
	
	# Tiempo de hitbox
	hitbox_time_ratio = p_hitbox_time_ratio
	inversed_hitbox_ratio = p_inversed_hitbox_ratio

func get_hitbox_time_ratio() -> float:
	return (duration * hitbox_time_ratio)
