class_name AreaGravity3D
extends Area3D

'''
Area3D con gravedad simple, y movimiento simple.
'''

# Constantes | Deteccion de piso
const FLOOR_MARGIN: float = 0.

# Privadas
var _target_velocity: Vector3 = Vector3.ZERO
var _fall_acceleration: float = 0.0
var _air_count: float = 0.0

# Visibles en GUI
@export var bounce : bool = false
@export var bounce_impulse: float = 0.0
@export var speed: float = 0 # Horizontal speed

# Direccion de spawneo. Para movimiento solo usa x.
var _direction: Vector3 = Vector3.ZERO
var _x_not_zero_value: float = 0.0

# Flags
var use_gravity: bool = false

func _allow_bounce() -> bool:
	return bounce and bounce_impulse > 0

func _allow_vertical_force() -> bool:
	return use_gravity and _fall_acceleration > 0

func _set_x_not_zero_value(p_direction: Vector3) -> void:
	'''
	Para saber en donde esta mirando el player.
	'''
	if p_direction.x != 0.0:
		_x_not_zero_value = p_direction.x
	elif _x_not_zero_value == 0.0:
		_x_not_zero_value = 1.0

func _detect_collisions() -> VerticalForceSignals:
	'''
	Detectar si el area aterrizo sobre una plataforma. Solo importa cuando esta cayendo.
	'''
	# on_ceiling, on_wall, on_floor, _air_count, _target_velocity.y
	var signals = VerticalForceSignals.new(
		false, false, false, _air_count, _target_velocity.y
	)
	if _target_velocity.y >= 0.0:
		return signals
	
	for body in get_overlapping_bodies():
		if not (body is Platform):
			continue
		var platform : Platform = (body as Platform)
		var box : AABB = platform.get_aabb_global()
		var point : Vector3 = global_position
		# Colisiono en la parte de  arriba. 
		if _target_velocity.y < 0.0 and point.y >= box.end.y - FLOOR_MARGIN:
			signals.on_floor = true
		# Colisiono en la parte de abajo.
		elif _target_velocity.y > 0.0 and point.y <= box.position.y + FLOOR_MARGIN:
			signals.on_ceiling = true
		# Colisiono en un lado.
		elif (
			point.y > box.position.y - FLOOR_MARGIN and
			point.y < box.end.y + FLOOR_MARGIN and
			point.x < box.position.x or point.x > box.end.x
		):
			signals.on_wall = true
	return signals

func _vertical_force(delta:float) -> VerticalForceSignals:
	if not _allow_vertical_force():
		return

	# Fuerza vertical
	_target_velocity.y -= _fall_acceleration * delta
	
	# Colisión
	var signals : VerticalForceSignals = _detect_collisions()
	if signals.on_floor:
		_target_velocity.y = 0.0
	elif signals.on_ceiling:
		_target_velocity.y = 0.0
	if _target_velocity.y != 0:
		_air_count += delta
	
	return signals

func _allow_speed():
	return speed > 0

func move(delta: float, signals: VerticalForceSignals) -> void:
	# Movimiento horizontal
	if _allow_speed():
		_target_velocity.x = (speed * _x_not_zero_value)
	
	if _allow_bounce():
		if signals.on_floor:
			_target_velocity.y = bounce_impulse 
		elif signals.on_wall:
			_x_not_zero_value *= -1.0 # Invertir dirección
			_target_velocity.x *= -1.0 # Invertir dirección frame 1.

func _commit(delta: float) -> void:
	'''Commit physics'''
	global_position += _target_velocity * delta

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_x_not_zero_value(_direction)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var vertical_force_signals :VerticalForceSignals = _vertical_force(delta)
	move(delta, vertical_force_signals)
	_commit(delta)
