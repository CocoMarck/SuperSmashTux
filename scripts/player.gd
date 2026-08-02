extends Character
'''
El player, pos espera input.
'''

@export var actions = {
	"move_left": "",
	"move_right": "",
	"move_up": "",
	"move_down": "",
	"jump": "",
	"attack": ""
}

func _collect_input() -> void:
	'''
	Obtener data de input del user.
	Si esta limpio el dicionario ignorar acciones.
	'''
	for value in actions.values():
		if value == "":
			return
	_move_left = Input.is_action_pressed(actions["move_left"])
	_move_right = Input.is_action_pressed(actions["move_right"])
	_move_up = Input.is_action_pressed(actions["move_up"])
	_move_down = Input.is_action_pressed(actions["move_down"])
	_jump = Input.is_action_pressed(actions["jump"])
	_attack = Input.is_action_pressed(actions["attack"])
