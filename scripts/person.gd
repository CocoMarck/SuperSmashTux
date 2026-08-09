class_name Person
extends GravityBody3D

# Propiedades publicas
@export_group("Horizontal Movement")
@export var walking_speed: int = 4
@export var running_speed: int = 10
@export var init_looking_at_right: bool = false

@export_group("Vertical Movement")
@export var jump_impulse: int = 13

@export_group("Appearence")
@export var material: Material = null
@export var mesh: Mesh = null

@export_group("Health")
@export var hp :int = 100
@export var damage_percentage :float = 0

# Essential character nodes
var _visual: Node3D
var _pivot: Node3D
var _mesh_instance: MeshInstance3D
var _animation_player: AnimationPlayer
var _collision_shape: CollisionShape3D

# `_target_velocity`, pertenece a `GravityBody3D`.

# Propiedades privadas | Aceleracion horizontal
var _ground_acceleration: float = 40.0
var _air_acceleration: float = 20.0
var _ground_friction: float = 60.0
var _knockback_friction: float = 12.0

# Propiedades privadas | Multiples saltos
var _max_jumps = 1
var _jump_count = 0

# Propiedadas privadas | Estados posición
var _direction: Vector3 = Vector3.ZERO
var _x_not_zero_value: float = 0.0
var _last_x_direction: float = 0.0

# Propiedades privadas | Multiplicadores.
var _fall_acceleration_multiplier: float = 1.0

# Propiedades privadas | Bloquear movimiento
var _horizontal_move: bool = true
var _can_jump: bool = true

# Propiedades privadas | Daño
var _normal_damage_power :float = 50
var _knockback_active :bool = false
var _knockback_direction :Vector3 = Vector3.ZERO
var _knockback_time :float = 0.0
var _knockback_duration :float = 0.35
var _damage_degrees :float = 0.0

# Propiedades privadas | Inputs
var _walking: bool = false

var _move_left: bool = false
var _move_right: bool = false
var _move_up: bool = false
var _move_down: bool = false

var _jump: bool = false

# Propiedades privadas | Flancos de inputs de arriba/abajo.
var _was_jumping: bool = false

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
	var axis := 0.0
	if _horizontal_move == true:
		axis = ( float(int(_move_right) -int(_move_left)) )
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
		_mesh_instance.material_override = p_meterial

func _set_mesh( p_mesh: Mesh ) -> void:
	'''
	Establecer malla nueva
	'''
	if p_mesh != null:
		_mesh_instance.mesh = p_mesh

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
	# Variables | Salto y moverse horizontalmente
	var want_jump := false
	var can_jump := false
	if _knockback_active:
		_move_left = false
		_move_right = false
		_move_down = false
		_move_up = false
	else:
		# Salto
		want_jump = (_jump or _move_up) # <--- El move up se usara para ataques hacia arriba.
		can_jump = (want_jump and _can_jump) and not _was_jumping
	_was_jumping = want_jump

	# Variables | Direccion de movimiento horizontal
	# Solo actualizar direccion en el piso.
	_direction = _get_move_direction()

	# En caida | Descender o no mas rapido.
	if signals.on_floor:
		_fall_acceleration_multiplier = 1
	else:
		if _move_down:
			_fall_acceleration_multiplier = 2
		if can_jump:
			_fall_acceleration_multiplier = 1
	
	# En el piso
	if signals.on_floor:
		#  No aceptar saltos infinitos.
		_jump_count = 0
	else:
		if _max_jumps == 1.0:
			_jump_count = _max_jumps

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
			speed_multiplier = 0.8
	else:
		if _last_x_direction == _direction.x:
			speed_multiplier = 1
		else:
			speed_multiplier = 0.8
	
	# Velocidad horizontal
	var target_speed := _direction.x * (speed*speed_multiplier)
	var accel := _air_acceleration
	if _knockback_active:
		accel = _knockback_friction
	elif signals.on_floor:
		if _direction.x == 0.0:
			accel = _ground_friction
		else:
			accel = _ground_acceleration
		
	_target_velocity.x = move_toward(_target_velocity.x, target_speed, accel*delta)

	# Salto | Aplicar salto normal o doble salto segun sea el caso.
	if can_jump and _jump_count < _max_jumps:
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
	var neutral_up := false
	var neutral_crouch := false
	var crouch_move := false

	var neutral_air := false
	var air_move := false
	var air_up := false
	var air_down := false

	if signals.on_floor:
		# En el piso
		neutral = not moving and (not _move_up and not _move_down)
		running = moving and not _walking
		neutral_up = not moving and _move_up and not _move_down
		neutral_crouch = not moving and _move_down and not _move_up
		crouch_move = moving and _move_down and not _move_up
		walking = _walking and moving
	
	else:
		# En el aire
		neutral_air = not moving and (not _move_up and not _move_down)
		air_move = moving
		air_up = _move_up and not _move_down
		air_down = _move_down and not _move_up

	return MoveStates.new(
		walking,
		moving,
		jumping,
		falling,
		
		neutral,
		running,
		neutral_up,
		neutral_crouch,
		crouch_move,

		neutral_air,
		air_move,
		air_up,
		air_down,
	)

func _move_anim(delta:float, states: MoveStates) -> void:
	'''
	Animaciones
	'''
	# En el piso
	if states.neutral_up:
		_animation_player.play("looking_up")
	elif states.neutral_crouch:
		_animation_player.play("crouch")
	elif states.crouch_move:
		_animation_player.play("crouch_move")
	elif states.neutral:
		_animation_player.play("idle")
	elif states.walking:
		_animation_player.play("walk")
	elif states.running:
		_animation_player.play("run")
	# En el aire
	elif states.jumping:
		_animation_player.play("jump")
	elif states.falling:
		_animation_player.play("fall")
	else:
		_animation_player.play("idle")

func _set_pivot_direction(signals: MoveSignals, direction: Vector3) -> void:
	if signals.on_floor:
		_pivot.basis = Basis.looking_at(
			Vector3(_x_not_zero_value, direction.y, direction.z)
		)
		_last_x_direction = _x_not_zero_value
		_pivot.rotate_x( 0 )

# Funciones | Damage recibido
func set_damage(damage:int):
	hp -= damage

func set_damage_percentage(damage:int) -> void:
	damage_percentage += damage*0.01

func set_damage_move(damage:float, direction:Vector3) -> void:
	'''
	Recibir un trancazo
	'''
	_knockback_direction = direction
	_knockback_active = true
	_knockback_time = _knockback_duration

func _damage_move(delta: float) -> void:
	_knockback_time -= delta
	var accel := _normal_damage_power * damage_percentage
	_target_velocity.x += (
		_knockback_direction.x * accel * delta
	)
	_target_velocity.y += (
		_knockback_direction.y * (accel*10) * delta
	)
	if _knockback_time <= 0.0:
		_knockback_active = false
		_pivot.rotation_degrees.x = 0
	
func _damage_anim(delta: float, signals: VerticalForceSignals) -> void:
	_animation_player.stop()
	if signals.on_floor:
		_damage_degrees = 0
	else:
		_damage_degrees += ((_normal_damage_power*damage_percentage)*8 )*delta
	_pivot.rotation_degrees.x = _damage_degrees
		

# Funciones | Inicializar
func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Essentail nodes
	_visual = $Visual
	_pivot = $Visual/Pivot
	_mesh_instance = $Visual/Pivot/Skeleton3D/MeshInstance3D
	_animation_player = $Visual/Pivot/AnimationPlayer
	_collision_shape = $CollisionShape3D
	
	# Apariencia
	_set_mesh(mesh)
	if material == null:
		material = _get_default_material()
	_set_material(material)

	# Direccion
	_pivot.basis = Basis.looking_at(_get_initial_facing())

# Funciones | Procesar
func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas.
    Este puede ser remplazado segun se necesite.
	'''
	_collect_input()
	
	# Move
	var gravity_signals = _vertical_force(delta, _fall_acceleration_multiplier)
	var move_signals = _move(delta, gravity_signals)
	_set_x_not_zero_value(move_signals.direction)
	var move_states = _get_move_states(move_signals)

	# Damage
	if _knockback_active:
		_damage_move(delta)

	# Anim
	if _knockback_active:
		_damage_anim(delta, gravity_signals)
	else:
		_move_anim(delta, move_states)
	_set_pivot_direction(move_signals, move_signals.direction)

	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
