class_name PowerFighter
extends Fighter

# Propiedades privadas | Input
var _power_attack: bool = false

# Propiedades privadas | Power attacks
var _power_attacks: PowerAttacks = PowerAttacks.new({
	"up" : FightMove.new({
		"name": &"up_power_attack", # Nombre de animación
		"duration": 0.625,
		"speed": Vector3(8,0,0),
		"direction": Vector3(0,0,0),
		"jump_power": 10.0,
		"air_attack": false,
		"grab_attack": false,
		"override_horizontal_move": true,
		"override_vertical_move": false,
		"immortal": false,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1,
				"damage": 10,
				"size": Vector3(0.5,0.5,0.5),
				"position": Vector3(0.3,0.9,0),
				"direction": Vector3(0.75,0.75,0),
				"init_time_ratio": 0.5,
				"duration": 0.2
			})
		]
	}),
	"air_up" : FightMove.new({
		"name": &"air_up_power_attack", # Nombre de animación
		"duration": 0.625,
		"speed": Vector3(8,0,0),
		"direction": Vector3(0,0,0),
		"jump_power": 10.0,
		"air_attack": true,
		"grab_attack": false,
		"override_horizontal_move": true,
		"override_vertical_move": false,
		"immortal": false,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1,
				"damage": 10,
				"size": Vector3(0.5,0.5,0.5),
				"position": Vector3(0.3,0.9,0),
				"direction": Vector3(0.75,0.75,0),
				"init_time_ratio": 0.5,
				"duration": 0.2
			})
		]
	})
})

func _init_power_attack_by_move(direction_buffered: bool, states: MoveStates):
	if not _power_attack:
		return
	# En el piso
	if states.neutral_up:
		_current_attack = _power_attacks.up
	elif states.air_up:
		_current_attack = _power_attacks.air_up

# Remplazando funciones.
func _process_attack(direction_buffered: bool, states: MoveStates) -> void:
	_init_attack_by_move(direction_buffered, states)
	_init_power_attack_by_move(direction_buffered, states)

# Init
func _init() -> void:
	_max_jumps = 2
