class_name MoveInput
extends RefCounted

# Person
var move_left: bool = false
var move_right: bool = false
var move_up: bool = false
var move_down: bool = false
var jump: bool = false
var walk: bool = false

# Fighter
var attack: bool = false
var grab: bool = false
var shield: bool = false

# PowerFighter
var power_attack: bool = false

func _init() -> void:
	pass
