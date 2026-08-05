class_name MoveSignals
extends RefCounted

var direction: Vector3
var velocity: Vector3
var on_floor: bool

func _init(p_direction, p_velocity, p_on_floor):
	direction = p_direction
	velocity = p_velocity
	on_floor = p_on_floor
