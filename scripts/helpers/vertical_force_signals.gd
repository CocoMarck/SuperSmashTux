class_name VerticalForceSignals
extends RefCounted

var on_floor :bool
var air_count :float
var force :float

func _init(p_on_floor:bool, p_air_count:float, p_force:float):
	on_floor = p_on_floor
	air_count = p_air_count
	force = p_force
