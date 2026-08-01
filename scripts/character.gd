extends CharacterBody3D
class_name Character

# Constantes del script.
const MAX_JUMPS := 2

# Propiedades publicas | Gravidad y velocidad.
@export var speed := 14
@export var fall_acceleration := 48
@export var jump_impulse := 25
@export var init_looking_at_right : bool = false


# Propiedades publicas | Materiales y malla
@export var material : Material = null
@export var mesh : Mesh = null

# Propiedades privadas | Movimientos
var _move_left: bool = false
var _move_right: bool = false
var _move_up: bool = false
var _move_down: bool = false
var _jump: bool = false

# Propiedades privadas | Velocidad y salto
var _target_velocity = Vector3.ZERO
var _jump_count = 0
var _was_jumping = false
var _air_count = 0

# Funciones
func _get_initial_facing() -> Vector3:
	if init_looking_at_right:
		return Vector3.RIGHT
	else:
		return Vector3.LEFT

func _set_material( m: Material ) -> void:
	'''
	Establecer material al jugador.
	Aunque preferiblemente sea nomas color. 
	Pero por ahroa, asi ta bien.
	'''
	if material != null:
		$Pivot/Mesh.material_override = m

func _set_mesh( m: Mesh ) -> void:
	'''
	Establecer malla nueva
	'''
	if m != null:
		$Pivot/Mesh.mesh = m

func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Cambiar el color del character
	_set_mesh(mesh)
	_set_material(material)
	
	# Establecer direccion de vista inicial.
	$Pivot.basis = Basis.looking_at( _get_initial_facing() )

func _get_move_direction() -> Vector3:
	'''
	Obtener direccion de movimiento. Tambien sirve para voltear el character.
	'''
	var axis = ( float(int(_move_right) -int(_move_left)) )
	return Vector3(axis, 0.0, 0.0)

func _collect_input() -> void:
	'''
	Funcion para obtener acciones sobrescritas por otro script hijo de character.
	'''
	pass
	
func _vertical_force(delta: float) -> Dictionary:
	'''
	Fuerza vertical. Imitación de gravidad. Estilo 2d.
	'''
	var on_floor := is_on_floor()
	if on_floor:
		# Contadores a cero, para que no se acumule fuerza vertcal.
		_target_velocity.y = 0
		_air_count = 0
	else:
		# Acumular fuerza vertical, y contar tiempo en el aire.
		_target_velocity.y -= fall_acceleration * delta
		_air_count += 1
	return {
		"air_count": _air_count,
		"on_floor": on_floor,
		"force": _target_velocity.y
	}
	

func _move(delta: float, vertical_force_signals: Dictionary) -> Dictionary:
	'''
	Movimientos. 
	Retorna señales de movimientos.
	'''
	# Variables necesarias
	var on_floor = vertical_force_signals["on_floor"]
	var direction := _get_move_direction()
	var is_jumping := _jump or _move_up
	var jump_pressed := is_jumping and not _was_jumping
	_was_jumping = is_jumping
	
	# Gravedad | Fuerza vertical. 
	# Contadores a cero, para que no se acumule fuerza vertcal.
	if on_floor:
		_jump_count = 0
	
	# Velocidad horizontal
	_target_velocity.x = direction.x * speed
		
	# Salto | Aplicar salto normal o doble segun el caso.
	if jump_pressed and _jump_count < MAX_JUMPS:
		_target_velocity.y = jump_impulse
		if _air_count > 0:
			_jump_count = MAX_JUMPS
		else:
			_jump_count += 1
	
	return {
		"direction": direction,
		"target_velocity": _target_velocity,
		"on_floor": on_floor,
	}

func _get_move_states(signals: Dictionary) -> Dictionary:
	'''
	Obtener estados de movimiento, basado en las señales de movimiento.
	'''
	var on_floor = signals["on_floor"]
	var direction = signals["direction"]
	var tv = signals["target_velocity"]
	
	var moving = direction.x != 0.0
	var jumping = tv.y > 0
	var falling = not jumping and not on_floor
	var neutral = on_floor and not moving
	var running = on_floor and moving
	var neutral_air = not on_floor and not moving
	var air_move = not on_floor and moving
	
	return {
		"moving": moving,
		"jumping": jumping,
		"falling": falling,
		"neutral": neutral,
		"running": running,
		"nuetral_air": neutral_air,
		"air_move": air_move
	}

func _anim(delta: float, states: Dictionary, direction: Vector3) -> void:
	'''
	Animaciones
	'''
	# Animacion | Movimiento en el piso
	if states["neutral"]:
		$Pivot/Mesh.rotation.x = 0
	if states["running"]:
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play("run")
	else:
		$AnimationPlayer.stop()
	
	# Animacion | Salto
	if states["jumping"]:
		$Pivot/Mesh.rotation.x = -50
	elif states["falling"]:
		$Pivot/Mesh.rotation.x = 50
		
	# Animación | Mover direccion visual del player.
	if states["moving"]:
		$Pivot.basis = Basis.looking_at(direction)

func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas.
	'''
	_collect_input()
	var gravity_signals = _vertical_force(delta)
	var move_signals = _move(delta, gravity_signals)
	var move_states = _get_move_states(move_signals)
	_anim(delta, move_states, move_signals["direction"])
	
	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
	
	# Debug
	'''
	var move_states_text = ""
	for key in move_states.keys():
		move_states_text += "- {key}: {value}\n".format(
			{"key":key, "value": move_states[key]}
		)
	print(
		"Instance ID: {id}\n".format({"id": get_instance_id()}) , move_states_text
	)
	'''
