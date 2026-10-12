class_name GravityBody3D
extends CharacterBody3D

'''
Gravedad 2D, para `CharacterBody3d`. Sencillon.
Colisiones con otros character body
'''

# Propiedades publicas
@export_group("Gravity")
@export var fall_acceleration: int = 24

# Prpiedades privadas | Gravedad | Fuerza vertical | Movimiento
var _target_velocity: Vector3 = Vector3.ZERO
var _air_count: float = 0.0

# Propiedades privadas | Shape
var _collision_shape: CollisionShape3D

# Propiedades privadas | Colisiones
var _immunity_to_body_collide :bool = false

# Funciones | Medidas del cuerpo
func _get_feet_position() -> Vector3:
	'''
	Posicion global de los pies del character. Igualita que _get_feet_y pero en Vector3,
	pa poder preguntarle a las plataformas inclinadas si andamos encima de su cara.
	'''
	return _collision_shape.global_position - Vector3(0.0, get_height()*0.5, 0.0)


# Funciones publicas | Size de collider
func get_width() -> float:
	return (
		(_collision_shape.shape.radius*2) * _collision_shape.global_basis.get_scale().x
	)

func get_height() -> float:
	return (
		_collision_shape.shape.height * _collision_shape.global_basis.get_scale().y
	)
	
# Colision con personas
func is_immunity_to_body_collide() -> bool:
	return _immunity_to_body_collide

func _toggle_body_collisions(delta: float, on_floor: bool) -> void:
	for body in get_tree().get_nodes_in_group("gravity_bodies"):
		if body == self:
			continue
		var remove: bool = true
		remove = on_floor and not (body.is_immunity_to_body_collide())
		if remove:
			remove_collision_exception_with(body)
		else:
			add_collision_exception_with(body)

# Aplicar gravedad a solidos
func _vertical_force(
	delta: float, multiplier: float = 1
) -> VerticalForceSignals:
	'''
	Fuerza vertical. Imitación de gravedad. Estilo 2D.
	Colisiones.
	'''
	var on_floor := is_on_floor()
	var on_ceiling := is_on_ceiling()
	var on_wall := is_on_wall()
	
	# Colision con gravty bodys
	_toggle_body_collisions(delta, on_floor)

	# Volver a obtener data
	on_floor = is_on_floor()
	on_ceiling = is_on_ceiling()
	on_wall = is_on_wall()
	
	# Lo que pasa cuando se colisiona.
	if on_floor:
		# Contadores a cero, para que no se acumule fuerza vertcal.
		_target_velocity.y = 0
		_air_count = 0
	else:
		# Acumular fuerza vertical, y contar tiempo en el aire.
		_target_velocity.y -= (fall_acceleration * multiplier) * delta
		_air_count += delta
	if on_ceiling:
		# Evitar saltar al techo, y segir con llendo hacia arriba. Nembe no, eso ta muy mal oshe.
		_target_velocity.y = -(fall_acceleration * multiplier) * delta
	if on_wall:
		_target_velocity.x = 0
	
	return VerticalForceSignals.new(
		on_floor, 
		on_ceiling,
		on_wall,
		_air_count, 
		_target_velocity.y # Force
	)

# Se usa para plataformas locas.
func _get_head_y() -> float:
	'''
	Altura global de la cabeza del character, calculada desde el CollisionShape3D.
	Es la contraparte de _get_feet_y, pero pa arriba, nos sirve pa saber si alcanzamos una orilla.
	'''
	return _collision_shape.global_position.y + get_height()*0.5

# Ready y physics process
func _ready() -> void:
	# El shape que se necesita si o si.
	_collision_shape = get_node("CollisionShape3D")
	add_to_group("gravity_bodies")

func _physics_process(delta: float) -> void:
	'''
	Procesamiento de fisica.
	Esto en realidad se debera remplazar. Pero sirve de ejemplo y de default process.
	'''
	_vertical_force(delta)
	
	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
