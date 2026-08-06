class_name Person
extends GravityBody3D

# Propiedades publicas
@export_group("Horizontal Movement")
@export var walking_speed: int = 8
@export var running_speed: int = 18
@export var init_looking_at_right: bool = false

@export_group("Vertical Movement")
@export var jump_impulse: int = 25

@export_group("Appearence")
@export var material: Material = null
@export var mesh: Mesh = null

@export_group("Health")
@export var hp :int = 100
@export var damage_percentage :float = 0

# `_target_velocity`, pertenece a `GravityBody3D`.

# Propiedades privadas | Multiples saltos
var _max_jumps = 1
var _jump_count = 0

# Propiedadas privadas | Estados posición
var _direction: Vector3 = Vector3.ZERO
var _x_not_zero_value: float = 0.0

# Propiedades privadas | Multiplicadores.
var _fall_acceleration_multiplier: float = 1.0

# Propiedades privadas | Daño
var _taking_damage :bool = false
var _normal_damage_power : float = 200
var _current_damage_direction: Vector3 = Vector3.ZERO

# Propiedades privadas | Inputs
var _walking: bool = false

var _move_left: bool = false
var _move_right: bool = false
var _move_up: bool = false
var _move_down: bool = false

var _jump: bool = false

# Propiedades privadas | Flancos de inputs de arriba/abajo.
var _was_jumping: bool = false
var _was_move_down: bool = false

# Fuciones | Direccion
func _get_initial_facing() -> Vector3:
	'''
	Determinar hacia donde mira el character al iniciar, segun configuracion del editor.
	'''
	if init_looking_at_right:
		return Vector3.RIGHT
	else:
		return Vector3.LEFT

func _get_move_direction() -> Vector3:
	'''
	Obtener direccion de movimiento. Tambien sirve para voltear el character.
	'''
	var axis = ( float(int(_move_right) -int(_move_left)) )
	return Vector3(axis, 0.0, 0.0)

func _set_x_not_zero_value(p_direction: Vector3) -> void:
	'''
	Para saber en donde esta mirando el player.
	'''
	if p_direction.x != 0.0:
		_x_not_zero_value = p_direction.x
	elif _x_not_zero_value == 0.0:
		if init_looking_at_right:
			_x_not_zero_value = 1.0
		else:
			_x_not_zero_value = -1.0

# Funciones | Apariencia
func _set_material( p_meterial: Material ) -> void:
	'''
	Establecer material al jugador.
	Aunque preferiblemente sea nomas color.
	Pero por ahora, asi está bien.
	'''
	if p_meterial != null:
		$Pivot/Mesh.material_override = p_meterial

func _set_mesh( p_mesh: Mesh ) -> void:
	'''
	Establecer malla nueva
	'''
	if p_mesh != null:
		$Pivot/Mesh.mesh = p_mesh

func _get_default_material() -> Material:
	'''
	Material por defecto segun el tipo de personaje. Los scripts hijos lo sobrescriben.
	'''
	return null

# Funciones | Input
func _collect_input() -> void:
	'''
	Funcion para obtener acciones sobrescritas por otro script hijo de character.
	'''
	pass


# Funciones | Mover
func _move(delta: float, signals: VerticalForceSignals) -> MoveSignals:
	'''
	Movimientos.
	Retorna señales de movimientos.
	'''
	# Variables | Salto
	var want_jump := (_jump or _move_up)
	var can_jump := want_jump and not _was_jumping
	_was_jumping = want_jump

	# Variables | Direccion de movimiento horizontal
	# Solo actualizar direccion en el piso.
	if can_jump:
		_direction = Vector3(_x_not_zero_value, 0, 0)
	else:
		_direction = _get_move_direction()

	# En caida | Descender o no mas rapido.
	if not signals.on_floor:
		if _move_down:
			_fall_acceleration_multiplier = 2
		if want_jump:
			_fall_acceleration_multiplier = 1
	else:
		_fall_acceleration_multiplier = 1
	
	# En el piso
	if signals.on_floor:
		#  No aceptar saltos infinitos.
		_jump_count = 0

	# Cambiador de velocidad segun sea el caso.
	var speed : int
	var speed_multiplier := 1.0
	if _walking:
		speed = walking_speed
	else:
		speed = running_speed
	if signals.on_floor:
		if signals.on_floor and _move_down:
			speed = walking_speed
			speed_multiplier = 0.75
	else:
		if can_jump:
			speed_multiplier = 0.5
	
	# Velocidad horizontal
	_target_velocity.x = _direction.x * (speed*speed_multiplier)

	# Salto | Aplicar salto normal o doble salto segun sea el caso.
	if want_jump and _jump_count < _max_jumps:
		_target_velocity.y = jump_impulse
		if signals.air_count > 0:
			_jump_count = _max_jumps
		else:
			_jump_count += 1
	
	# Retornar
	return MoveSignals.new(
		_direction, 
		_target_velocity, 
		signals.on_floor
	)

# Funciones | Estados de movimiento
func _get_move_states(signals: MoveSignals) -> MoveStates:
	'''
	Obtener estados de movimiento, basado en las señales de movimiento.
    Sirve para animar, o para otras cosas.
	'''
	# Movimiento normal
	var moving = signals.direction.x != 0.0
	var jumping = velocity.y > 0
	var falling = not jumping and not signals.on_floor

	# En el piso o en el aire
	var neutral := false
	var walking := false
	var running := false
	var neutral_crouch := false
	var crouch_move := false

	var neutral_air := false
	var air_move := false
	var air_down := false

	if signals.on_floor:
		# En el piso
		neutral = not moving and (not _move_up and not _move_down)
		running = moving
		neutral_crouch = not moving and _move_down
		crouch_move = moving and _move_down
		walking = _walking and moving
	
	else:
		# En el aire
		neutral_air = not moving and (not _move_up and not _move_down)
		air_move = moving
		air_down = moving and _move_down

	return MoveStates.new(
		walking,
		moving,
		jumping,
		falling,
		
		neutral,
		running,
		neutral_crouch,
		crouch_move,

		neutral_air,
		air_move,
		air_down,
	)

func _move_anim(delta:float, states: MoveStates) -> void:
	'''
	Animaciones
	'''
	# En el piso
	if states.neutral_crouch:
		$AnimationPlayer.play("crouch")
	elif states.crouch_move:
		$AnimationPlayer.play("crouch_move")
	elif states.neutral:
		$AnimationPlayer.play("idle")
	elif states.walking:
		$AnimationPlayer.play("walk")
	elif states.running:
		$AnimationPlayer.play("run")
	# En el aire
	elif states.jumping:
		$AnimationPlayer.play("jump")
	elif states.falling:
		$AnimationPlayer.play("fall")
	else:
		$AnimationPlayer.play("idle")

func _set_pivot_direction(direction: Vector3) -> void:
	$Pivot.basis = Basis.looking_at(
		Vector3(_x_not_zero_value, direction.y, direction.z)
	)

# Funciones | Damage recibido
func set_damage(damage:int):
	hp -= damage

func set_damage_percentage(damage:int) -> void:
	damage_percentage += damage*0.01

func set_damage_move(damage:float, direction:Vector3) -> void:
	'''
	Recibir un trancazo
	'''
	_current_damage_direction = direction
	_taking_damage = true

func _damage_move() -> void:
	_target_velocity.x += (
		(_normal_damage_power*_current_damage_direction.x) * damage_percentage
	)
	_target_velocity.y += (
		(_normal_damage_power*_current_damage_direction.y) * damage_percentage
	)
	_taking_damage = false

# Funciones | Inicializar
func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Apariencia
	_set_mesh(mesh)
	if material == null:
		material = _get_default_material()
	_set_material(material)

	# Direccion
	$Pivot.basis = Basis.looking_at(_get_initial_facing())

# Funciones | Procesar
func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas.
    Este puede ser remplazado segun se necesite.
	'''
	_collect_input()
	_was_move_down = _move_down
	# Move
	var gravity_signals = _vertical_force(delta, _fall_acceleration_multiplier)
	var move_signals = _move(delta, gravity_signals)
	_set_x_not_zero_value(move_signals.direction)
	var move_states = _get_move_states(move_signals)

	# Damage
	if _taking_damage:
		_damage_move()

	# Anim
	_move_anim(delta, move_states)
	_set_pivot_direction(move_signals.direction)

	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
