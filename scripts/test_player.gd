class_name TestPlayer
extends PowerFighter

# Funciones | Input del jugador.
func _collect_input() -> void:
	'''
	Obtener data de input del user.
	'''
	# Leer los inputs configurados para el jugador.
	# Los que no son just precced son para señal no continua.
	_move_left = Input.is_action_pressed("player1_move_left")
	_move_right = Input.is_action_pressed("player1_move_right")
	_move_up = Input.is_action_pressed("player1_move_up")
	_move_down = Input.is_action_pressed("player1_move_down")
	_jump = Input.is_action_pressed("player1_jump")
	_attack = Input.is_action_just_pressed("player1_attack")
	_walking = Input.is_action_pressed("player1_walk")
	_grab = Input.is_action_just_pressed("player1_grab")
	_shield = Input.is_action_pressed("player1_shield")
