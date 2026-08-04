class_name Player
extends Character

# Propiedades publicas | Identificacion y mapeo de controles del jugador.
@export var player_id: GlobalUtils.PlayerId
var actions: PlayerInputMap = null

# Funciones | Input del jugador.
func _collect_input() -> void:
	'''
	Obtener data de input del user.
	Si no hay actions asignado (nadie lo configuro todavia) ignorar acciones.
	'''
	if actions == null:
		return

	# Leer los inputs configurados para el jugador.
	_move_left = Input.is_action_pressed(actions.move_left)
	_move_right = Input.is_action_pressed(actions.move_right)
	_move_up = Input.is_action_pressed(actions.move_up)
	_move_down = Input.is_action_pressed(actions.move_down)
	_jump = Input.is_action_pressed(actions.jump)
	_attack = Input.is_action_pressed(actions.attack)
