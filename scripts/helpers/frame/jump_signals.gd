class_name JumpSignals
extends RefCounted

# Datos de salto del peleador, para que los controladores (NPC) decidan sin ver el Person.
var count: int
var max: int
var impulse: int
var fall_acceleration: int

func _init(
	p_count: int=0, p_max:int=1, p_impulse:int=0, 
	p_fall_acceleration:int=0):
	count = p_count
	max = p_max
	impulse = p_impulse
	fall_acceleration = p_fall_acceleration
