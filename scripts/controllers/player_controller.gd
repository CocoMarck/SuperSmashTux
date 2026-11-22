class_name PlayerController
extends PersonController3D

# Propiedades publicas | Identificacion y mapeo de controles del jugador.
@export var player_id: GlobalUtils.PlayerId
var player_input_map: PlayerInputMap = null

# Funciones remplazadas
func get_input(delta: float, frame: FrameMotionSignals) -> MoveInput:
	_input.move_left = Input.is_action_pressed(player_input_map.move_left)
	_input.move_right = Input.is_action_pressed(player_input_map.move_right)
	_input.move_up = Input.is_action_pressed(player_input_map.move_up)
	_input.move_down = Input.is_action_pressed(player_input_map.move_down)
	_input.jump = Input.is_action_pressed(player_input_map.jump)
	_input.attack = Input.is_action_just_pressed(player_input_map.attack)
	_input.walk = Input.is_action_pressed(player_input_map.walk)
	_input.grab = Input.is_action_just_pressed(player_input_map.grab)
	_input.shield = Input.is_action_pressed(player_input_map.shield)
	_input.power_attack = Input.is_action_just_pressed(player_input_map.power_attack)

	return _input

# Funciones Necesarias
func _ready() -> void:
	'''
	Resolver el mapa de inputs del jugador a partir de su ID.
	'''
	super() # Primero ejecutar el método ready de la clase papá
	player_input_map = GlobalUtils.PLAYER_INPUT_MAPS.get(player_id)
