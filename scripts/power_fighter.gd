class_name PowerFighter
extends Fighter

# Propiedades privadas | Input
var _power_attack: bool = false

# Propiedades privadas | Power attacks
var _power_attacks: PowerAttacks = PowerAttacks.new({
	"up" : FightMove.new({
		"name": &"up_attack", # Nombre de animación
		"duration": 0.4583,
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
		"name": &"up_attack", # Nombre de animación
		"duration": 0.4583,
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

func _set_attack(states: MoveStates) -> void:
	'''
	Obtener ataques normales o power attacks, segun sea el caso.
	'''
	if _current_attack == null:
		_attack_direction.x = 0.0
		_attack_direction.y = 0.0
		_attack_direction.z = 0.0
		
		var direction_buffered = _is_direction_buffer() # Margen de error de presión de direccion.
		if _attack:
			# En el piso
			if states.neutral:
				_current_attack = _attacks.ground_neutral
			elif (states.moving and not states.crouch_move) and direction_buffered:
				_current_attack = _attacks.heavy_side
			elif states.walking:
				_current_attack = _attacks.forward
			elif states.running:
				_current_attack = _attacks.dash
			elif states.neutral_crouch and direction_buffered:
				_current_attack = _attacks.heavy_down
			elif states.neutral_crouch or states.crouch_move:
				_current_attack = _attacks.down
			elif states.neutral_up and direction_buffered:
				_current_attack = _attacks.heavy_up
			elif states.neutral_up:
				_current_attack = _attacks.up

			# En aire
			elif states.neutral_air:
				_current_attack = _attacks.air_neutral
			elif states.air_down:
				_current_attack = _attacks.air_down
			elif states.air_up:
				_current_attack = _attacks.air_up
			elif states.air_forward:
				_current_attack = _attacks.air_forward
			elif states.air_back:
				_current_attack = _attacks.air_back
		
		if _power_attack:
			# En el piso
			if states.neutral_up:
				_current_attack = _power_attacks.up
			elif states.air_up:
				_current_attack = _power_attacks.air_up
		
		#  Inicializar data de ataque.
		if _current_attack != null:
			_attack_count = 0
			_attack_direction.x = _current_attack.direction.x * _x_not_zero_value
			_attack_direction.y = _current_attack.direction.y * 0.1

# Init
func _init() -> void:
	_max_jumps = 2
