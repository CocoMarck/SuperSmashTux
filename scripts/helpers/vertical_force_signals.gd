class_name VerticalForceSignals
extends RefCounted

var on_floor :bool
var on_ceiling :bool
var on_wall :bool
var air_count :float
var force :float

func _init(p_on_floor:bool, p_on_ceiling:bool, p_on_wall:bool, p_air_count:float, p_force:float):
	on_floor = p_on_floor
	on_ceiling = p_on_ceiling
	on_wall = p_on_wall
	air_count = p_air_count
	force = p_force
