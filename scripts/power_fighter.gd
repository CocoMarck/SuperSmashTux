class_name PowerFighter
extends Fighter

# Propiedades privadas | Input
var _power_attack: bool = false

# Propiedades privadas | Power attacks
var _power_attacks: PowerAttacks = PowerAttacks.new({
	"standard" : FightMove.new({
		"name": &"power_attack", "duration": 0.5833, "speed": Vector3(0,0,0),
		"air_attack": false, "override_horizontal_move": true,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1, "damage": 10, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(0.25,0.3,0),
				"init_time_ratio": 0.5, "duration": 2.0, 
				"use_gravity": true, "speed": 20, "bounce": true, "bounce_impulse": 8.0, "fall_acceleration": 20, 
			})
		]
	}),
	"down": FightMove.new({
		"name": &"down_power_attack", "duration": 0.8333, "speed": Vector3(0,0,0),
		"air_attack": false, "override_horizontal_move": true,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(-1,0.25,0),
				"init_time_ratio": 0.15, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 2, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(-0.8,0.3,0), "direction": Vector3(1,0.25,0),
				"init_time_ratio": 0.15, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 3, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(-1,0.25,0),
				"init_time_ratio": 0.35, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 4, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(-0.8,0.3,0), "direction": Vector3(1,0.25,0),
				"init_time_ratio": 0.35, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 5, "damage": 15, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(0,0.75,0),
				"init_time_ratio": 0.4, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 6, "damage": 15, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(-0.8,0.3,0), "direction": Vector3(0,0.75,0),
				"init_time_ratio": 0.4, "duration": 0.1
			}),
		]
	}),
	"up" : FightMove.new({
		"name": &"up_power_attack", "duration": 0.625, "speed": Vector3(5,0,0),
		"jump_power": 12.0, "air_attack": false,
		"grab_attack": false, "override_horizontal_move": true,
		"override_vertical_move": false, "immortal": false,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1, "damage": 10, "size": Vector3(0.5,0.5,0.5),
				"position": Vector3(0.3,0.9,0), "direction": Vector3(0.75,0.75,0),
				"init_time_ratio": 0.5, "duration": 0.2
			})
		]
	}),
	"air_standard" : FightMove.new({
		"name": &"air_power_attack", "duration": 0.5833, "speed": Vector3(0,0,0),
		"air_attack": true, "override_horizontal_move": false,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1, "damage": 10, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(0.25,0.3,0),
				"init_time_ratio": 0.5, "duration": 2.0, 
				"use_gravity": true, "speed": 20, "bounce": true, "bounce_impulse": 8.0, "fall_acceleration": 20, 
			})
		]
	}),
	"air_down": FightMove.new({
		"name": &"air_down_power_attack", "duration": 0.8333, "speed": Vector3(0,0,0),
		"air_attack": true, "override_horizontal_move": false,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(-1,0.25,0),
				"init_time_ratio": 0.15, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 2, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(-0.8,0.3,0), "direction": Vector3(1,0.25,0),
				"init_time_ratio": 0.15, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 3, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(-1,0.25,0),
				"init_time_ratio": 0.35, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 4, "damage": 5, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(-0.8,0.3,0), "direction": Vector3(1,0.25,0),
				"init_time_ratio": 0.35, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 5, "damage": 15, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(0.8,0.3,0), "direction": Vector3(0,0.75,0),
				"init_time_ratio": 0.4, "duration": 0.1
			}),
			HitboxMove.new({
				"id": 6, "damage": 15, "size": Vector3(0.5,0.5,0.5), 
				"position": Vector3(-0.8,0.3,0), "direction": Vector3(0,0.75,0),
				"init_time_ratio": 0.4, "duration": 0.1
			}),
		]
	}),
	"air_up" : FightMove.new({
		"name": &"air_up_power_attack", "duration": 0.625, "speed": Vector3(5,0,0),
		"jump_power": 12.0, "air_attack": true,
		"grab_attack": false, "override_horizontal_move": true,
		"override_vertical_move": false, "immortal": false,
		"hitboxes_moves": [
			HitboxMove.new({
				"id": 1, "damage": 10, "size": Vector3(0.5,0.5,0.5),
				"position": Vector3(0.3,0.9,0), "direction": Vector3(0.75,0.75,0),
				"init_time_ratio": 0.5, "duration": 0.2
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
	elif states.neutral_crouch:
		_current_attack = _power_attacks.down
	elif states.neutral or states.walking or states.running or states.crouch_move:
		_current_attack = _power_attacks.standard
	elif states.air_up:
		_current_attack = _power_attacks.air_up
	elif states.air_down:
		_current_attack = _power_attacks.air_down
	elif states.rising or states.falling or states.jumping:
		_current_attack = _power_attacks.air_standard

# Remplazando funciones.
func _process_attack(direction_buffered: bool, states: MoveStates) -> void:
	_init_attack_by_move(direction_buffered, states)
	_init_power_attack_by_move(direction_buffered, states)

# Init
func _init() -> void:
	_max_jumps = 2
