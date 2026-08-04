extends RefCounted
class_name PlayerInputMap

# Nombres de las acciones del Input Map para un jugador.
var move_left: StringName
var move_right: StringName
var move_up: StringName
var move_down: StringName
var jump: StringName
var attack: StringName

func _init(
	p_move_left: StringName, p_move_right: StringName, p_move_up: StringName,
	p_move_down: StringName, p_jump: StringName, p_attack: StringName
):
	move_left = p_move_left
	move_right = p_move_right
	move_up = p_move_up
	move_down = p_move_down
	jump = p_jump
	attack = p_attack
