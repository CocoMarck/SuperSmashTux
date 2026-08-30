class_name PowerFighter
extends Fighter

# Propiedades privadas | Input
var _power_attack: bool = false

# Propiedades privadas | Power attacks
var _power_attacks: PowerAttacks = null

func _init() -> void:
	_max_jumps = 2
