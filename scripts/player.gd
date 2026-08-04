class_name Player
extends Character

# Propiedades publicas | Identificacion y mapeo de controles del jugador.
@export var player_id: GlobalUtils.PlayerId
var input_map: PlayerInputMap = null

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Resolver el mapa de inputs del jugador a partir de su ID.
	'''
	super() # Primero ejecutar el método ready de la clase papá
	input_map = GlobalUtils.PLAYER_INPUT_MAPS.get(player_id)

# Funciones | Apariencia.
func _get_default_material() -> Material:
	'''
	Material del jugador segun su ID.
	'''
	return GlobalUtils.PLAYER_MATERIALS.get(player_id)

# Funciones | Input del jugador.
func _collect_input() -> void:
	'''
	Obtener data de input del user.
	Si no hay input_map asignado (nadie lo configuro todavia) ignorar acciones.
	'''
	if input_map == null:
		return

	# Leer los inputs configurados para el jugador.
	# Los que no son just precced son para señal no continua.
	_move_left = Input.is_action_pressed(input_map.move_left)
	_move_right = Input.is_action_pressed(input_map.move_right)
	_move_up = Input.is_action_pressed(input_map.move_up)
	_move_down = Input.is_action_pressed(input_map.move_down)
	_jump = Input.is_action_pressed(input_map.jump)
	_attack = Input.is_action_just_pressed(input_map.attack)
