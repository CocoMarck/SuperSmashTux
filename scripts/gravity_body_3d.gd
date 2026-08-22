class_name GravityBody3D
extends CharacterBody3D

'''
Gravedad 2D, para `CharacterBody3d`. Sencillon.
Tiene funciones para colisiones con objetos de un solo sentido.
Colisiones con otros character body
'''

# Constantes | Plataformas de un solo sentido en `GameBalence`.

# Propiedades publicas 
@export_group("Gravity")
@export var fall_acceleration: int = 24

# Prpiedades privadas | Gravedad | Fuerza vertical | Movimiento
var _target_velocity: Vector3 = Vector3.ZERO
var _air_count: float = 0.0

# Propiedades privadas | Shape
var _collision_shape: CollisionShape3D

# Propiedades privadas | Plataformas de un solo sentido.
var _drop_through_count: float = 0.0
var _one_way_ignored: Dictionary = {}
var _last_floor_one_way: OneWayPlatform = null
var _one_way_coyote_count: float = 0.0

# Propiedades privadas | Colisiones
var _immunity_to_body_collide :bool = false

# Funciones | Deteccion de colisiones especiales.
# Funciones | Plataformas de un solo sentido.
func _get_floor_one_way() -> OneWayPlatform:
	'''
	Buscar en las colisiones del ultimo move_and_slide si topamos con alguna OneWayPlatform.
	Devuelve la primera que encuentre, o null si no hubo ninguna.
	'''
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is OneWayPlatform:
			return collider as OneWayPlatform
	return null
	
func _get_feet_position() -> Vector3:
	'''
	Posicion global de los pies del character. Igualita que _get_feet_y pero en Vector3,
	pa poder preguntarle a las plataformas inclinadas si andamos encima de su cara.
	'''
	return _collision_shape.global_position - Vector3(0.0, _get_body_half_height(), 0.0)
	
# Funciones agarre de orillas.
func _get_body_half_height() -> float:
	'''
	Medio-alto global del CollisionShape3D del character. Sirve tanto pa los pies como pa la cabeza.
	Soporta capsula, caja, cilindro y esfera, que son los shapes de collision mas comunes por aqui.
	'''
	var half_height := 0.0
	half_height = _collision_shape.shape.height * 0.5

	var scale_y := _collision_shape.global_basis.get_scale().y
	return half_height * scale_y

func _one_way_platforms(delta: float, ignore: bool, on_floor: bool) -> void:
	'''
	Maneja las plataformas de un solo sentido, estilo Smash Bros: se atraviesan de abajo pa arriba,
	pero solidas al caer encima. Con tap de abajo estando parado en una, te dejas caer a proposito.
	'''
	# Plataforma de un solo sentido en la que estamos parados ahorita, si hay.
	var floor_one_way := _get_floor_one_way() if on_floor else null

	# Arrancar caida voluntaria si se hace tap de abajo estando parado sobre una plataforma de un solo sentido.
	if ignore and floor_one_way != null:
		_drop_through_count = GameBalance.DROP_THROUGH_TIME
		# Empujoncito hacia abajo pa despegarse y que no se re-enganche por el snap del piso.
		_target_velocity.y = min(_target_velocity.y, -1.0)

	# Temporizador de la caida voluntaria.
	if _drop_through_count > 0.0:
		_drop_through_count = max(_drop_through_count - delta, 0.0)

	# Coyote time: si nos salimos de la orilla caminando, la plataforma sigue solida un ratito,
	# pa que si regresamos de volada no nos caigamos como si nada.
	if _drop_through_count > 0.0:
		# Si se esta cayendo a proposito, cancelar el coyote, si no la plataforma se queda solida y el tap no sirve.
		_one_way_coyote_count = 0.0
	elif floor_one_way != null:
		_last_floor_one_way = floor_one_way
		_one_way_coyote_count = GameBalance.ONE_WAY_COYOTE_TIME
	else:
		_one_way_coyote_count = max(_one_way_coyote_count - delta, 0.0)

	var feet_position := _get_feet_position()

	# Recorrer todas las plataformas de un solo sentido y decidir si atravesarlas o no.
	for platform in get_tree().get_nodes_in_group(Platform.GROUP_NAME):
		var one_way := platform as OneWayPlatform
		if one_way == null or not is_instance_valid(one_way):
			continue

		# En coyote time nomas pa la plataforma en la que estabamos parados, no pa todas.
		var in_coyote := one_way == _last_floor_one_way and _one_way_coyote_count > 0.0
		var should_ignore := _drop_through_count > 0.0 \
			or _target_velocity.y > 0.0 \
			or (not one_way.is_above_surface(feet_position, GameBalance.ONE_WAY_MARGIN) and not in_coyote)

		# Solo llamar add/remove cuando el estado cambia de verdad, pa no hacerlo de a gratis cada frame.
		if _one_way_ignored.get(one_way, false) != should_ignore:
			if should_ignore:
				add_collision_exception_with(one_way)
			else:
				remove_collision_exception_with(one_way)
			_one_way_ignored[one_way] = should_ignore

	# Limpiar del cache las plataformas que ya no sean validas.
	for cached_platform in _one_way_ignored.keys():
		if not is_instance_valid(cached_platform):
			_one_way_ignored.erase(cached_platform)

	# Limpiar tambien la referencia de la ultima plataforma pisada, si ya no es valida.
	if _last_floor_one_way != null and not is_instance_valid(_last_floor_one_way):
		_last_floor_one_way = null
		_one_way_coyote_count = 0.0

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
	delta: float, ignore_one_way_platforms: bool = false, multiplier: float = 1
) -> VerticalForceSignals:
	'''
	Fuerza vertical. Imitación de gravedad. Estilo 2D.
	Colisiones.
	'''
	var on_floor := is_on_floor()
	var on_ceiling := is_on_ceiling()
	var on_wall := is_on_wall()
	
	# Ignorar o no plataformas de un solo sentido
	_one_way_platforms(delta, ignore_one_way_platforms, on_floor)

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
	return _collision_shape.global_position.y + _get_body_half_height()

# Ready y physics process
func _ready() -> void:
	# El shape que se necesita si o si.
	_collision_shape = $CollisionShape3D
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
