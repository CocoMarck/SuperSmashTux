class_name MoveSignals
extends RefCounted

var direction: Vector3
var velocity: Vector3
var on_floor: bool

func _init(p_direction=Vector3.ZERO, p_velocity=Vector3.ZERO, p_on_floor=false):
	direction = p_direction
	velocity = p_velocity
	on_floor = p_on_floor
