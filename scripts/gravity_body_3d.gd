class_name GravityBody3D
extends CharacterBody3D

'''
Gravedad 2D, para `CharacterBody3d`. Sencillon.
'''

# Propiedades publicas 
@export_group("Gravity")
@export var fall_acceleration: int = 48

# Prpiedades privadas | Gravedad | Fuerza vertical | Movimiento
var _target_velocity: Vector3 = Vector3.ZERO
var _air_count: int = 0

func _vertical_force(delta: float, multiplier: float = 1) -> Dictionary:
	'''
	Fuerza vertical. Imitación de gravedad. Estilo 2D.
	'''
	var on_floor := is_on_floor()
	var on_ceiling := is_on_ceiling()
	if on_floor:
		# Contadores a cero, para que no se acumule fuerza vertcal.
		_target_velocity.y = 0
		_air_count = 0
	else:
		# Acumular fuerza vertical, y contar tiempo en el aire.
		_target_velocity.y -= (fall_acceleration * multiplier) * delta
		_air_count += 1
	if on_ceiling:
		# Evitar saltar al techo, y segir con llendo hacia arriba. Nembe no, eso ta mal.
		_target_velocity.y = -(fall_acceleration * multiplier)*delta
	return {
		"air_count": _air_count,
		"on_floor": on_floor,
		"force": _target_velocity.y
	}

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	'''
	Procesamiento de fisica.
	Esto en realidad se debera remplazar. Pero sirve de ejemplo y de default process.
	'''
	_vertical_force(delta)
	
	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
