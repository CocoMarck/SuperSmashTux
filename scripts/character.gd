class_name Character
extends GravityBody3D

# Constantes del script.
const MAX_JUMPS := 2

# Constantes | Plataformas de un solo sentido.
const DROP_THROUGH_TIME := 0.25    # segundos que se ignora la plataforma tras el tap de abajo
const ONE_WAY_MARGIN := 0.1        # franja por debajo de la cara superior de la plataforma, pa no quedarse atorado
const ONE_WAY_COYOTE_TIME := 0.3   # tiempo de perdon al salirse de la orilla y querer regresar

# Constantes | Agarre de orillas.
const LEDGE_GRAB_REACH := 1.2      # que tan lejos por fuera de la orilla se puede agarrar
const LEDGE_GRAB_DEPTH := 2.5      # que tan abajo de la cara superior se agarra
const LEDGE_HANG_OFFSET := 0.5     # que tan separado de la orilla se queda colgado
const LEDGE_RELEASE_TIME := 0.35   # cooldown tras soltarse, pa no re-agarrarse solo

# Propiedades publicas | Gravedad y velocidad.
@export_group("Movement")
@export var speed: int = 18
@export var jump_impulse: int = 25
@export var init_looking_at_right: bool = false

# Propiedades publicas | Apariencia.
@export_group("Appearance")
@export var material: Material = null
@export var mesh: Mesh = null

# Propiedades publicas | HP y porcentaje de daño.
@export_group("Health")
var hp :int = 100
var damage_percentage :float = 0

# Propiedades privadas | Deteccion de inputs.
var _move_left: bool = false
var _move_right: bool = false
var _move_up: bool = false
var _move_down: bool = false
var _jump: bool = false
var _attack: bool = false
var _power_attack: bool = false
var _up_pressed: bool = false
var _down_pressed: bool = false
var _was_move_up: bool = false
var _was_move_down: bool = false

# Propiedades privadas | Velocidad y salto.
var _direction: Vector3 = Vector3.ZERO
var _x_not_zero_value :float = 0.0
var _jump_count: int = 0
var _was_jumping: bool = false
var _fall_acceleration_multiplier: float = 1.0

# Propiedades privadas | Hitbox de daño a los enemigos locos.
var _hitbox_count: float = 0.0
var _hitbox_duration: float = 0.0
var _spawned_hitbox: Area3D = null

# Propiedades privadas | Ataques.
var _attack_count: float = 0.0
var _current_attack: FightMove = null
var _attacks: Attacks = Attacks.new(
	# name: StringName="", duration: float, p_damage: int, stop_horizontal_move: bool, stop_vertical_move: bool,
	# speed: Vector3, air_attack: bool, hitbox_position: Vector3, animation_name: StringName, mesh_rotation_x: float, 
	# hitbox_time_ratio: float, inversed_hitbox_ratio: bool, power_direction: Vector3
	FightMove.new(
		"neutral", 0.2, 5, true, false, Vector3(0,0,0), false, Vector3(0.3, 0.1, 0), &"neutral_attack", 0.0,
		0.5, true, Vector3(1,1,0)
	),
	FightMove.new(
		"dash", 0.3, 10, true, false, Vector3(22,0,0), false, Vector3(0.5, -0.5, 0), &"dash_attack", 0.0,
		0.5, true, Vector3(1.5,1,0)
	),
	FightMove.new(
		"crouch", 0.2, 5, true, false, Vector3(0,0,0), false, Vector3(0.6, -0.5, 0), &"crouch_attack",
		0.0, 0.5, true, Vector3(1,1,0)
	),
	FightMove.new(
		"neutral_air", 0.4, 5, false, false, Vector3(0,0,0), true, Vector3(0.5, -0.6, 0), &"", 45.0,
		0.5, true, Vector3(1,1,0)
	),
	FightMove.new(
		"air_move", 0.3, 10, false, false, Vector3(0,0,0), true, Vector3(0.6, 0, 0), &"", 90.0,
		0.5, true, Vector3(1.5,1,0)
	),
	FightMove.new(
		"air_down", 0.3, 10, false, false, Vector3(0,0,0), true, Vector3(0.1, -0.7, 0), &"", 0.0,
		0.5, true, Vector3(1,1.5,0)
	)
)
var _attack_direction : Vector3 = Vector3(0.0, 0.0, 0.0)

# Propiedades privadas damage
var _normal_damage_move_power :float = 200
var _current_damage_directon: Vector3 = Vector3.ZERO 
var _taking_damage :bool = false

# Propiedades privadas | Plataformas de un solo sentido.
var _drop_through_count: float = 0.0
var _one_way_ignored: Dictionary = {}
var _last_floor_one_way: OneWayPlatform = null
var _one_way_coyote_count: float = 0.0

# Propiedades privadas | Agarre de orillas.
var _hanging_ledge: GroundPlatform = null
var _hanging_right_side: bool = false
var _hang_position: Vector3 = Vector3.ZERO
var _ledge_release_count: float = 0.0

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Cambiar el color del character. Si no se puso material a mano en el editor, usar el del tipo de personaje.
	_set_mesh(mesh)
	if material == null:
		material = _get_default_material()
	_set_material(material)

	# Establecer direccion de vista inicial.
	$Pivot.basis = Basis.looking_at(_get_initial_facing())

# Funciones | Procesamiento de físicas.
func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas.
	'''
	
	# Detectar inputs, señales y otros estados del personaje
	_collect_input()
	# Flancos de arriba/abajo. Se calculan aqui, una sola vez, pa que todos los sistemas lean el mismo tap.
	_up_pressed = _move_up and not _was_move_up
	_down_pressed = _move_down and not _was_move_down
	_was_move_up = _move_up
	_was_move_down = _move_down
	var gravity_signals = _vertical_force(delta, _fall_acceleration_multiplier)
	var vertical_force_signals = {
		"on_floor": gravity_signals.on_floor, "air_count": gravity_signals.air_count, "force": gravity_signals.force
	}
	var move_signals = _move(delta, vertical_force_signals)
	_set_x_not_zero_value()
	var move_states = _get_move_states(move_signals)
	_one_way_platforms(delta, vertical_force_signals["on_floor"])
	_ledge_grab(delta)
	if not _taking_damage:
		_fight(delta, move_states)
	else:
		_damage_move()
	_anim(delta, move_states, move_signals["direction"])

	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
	
# Funciones damage recivido
func set_damage(damage:int):
	hp -= damage

func set_damage_percentage(damage:int) -> void:
	damage_percentage += damage*0.01

func set_damage_move(damage:float, direction:Vector3) -> void:
	'''
	Recibir un trancazo. Si nos agarran colgados de una orilla, soltarse pa que el knockback si nos avente
	y no nos regrese el snap de _ledge_grab al frame siguiente.
	'''
	if _hanging_ledge != null:
		_hanging_ledge = null
		_ledge_release_count = LEDGE_RELEASE_TIME
	_current_damage_directon = direction
	_taking_damage = true

func _damage_move() -> void:
	_target_velocity.x += (_normal_damage_move_power*_current_damage_directon.x) * damage_percentage
	_target_velocity.y += (_normal_damage_move_power*_current_damage_directon.y) * damage_percentage
	_taking_damage = false

func _set_x_not_zero_value() -> void:
	'''
	Para saber en donde esta mirando el player.
	'''
	if _direction.x != 0.0:
		_x_not_zero_value = _direction.x
	elif _x_not_zero_value == 0.0:
		if init_looking_at_right:
			_x_not_zero_value = 1.0
		else:
			_x_not_zero_value = -1.0

# Funciones de apariencia
func _get_initial_facing() -> Vector3:
	'''
	Determinar hacia donde mira el character al iniciar, segun configuracion del editor.
	'''
	if init_looking_at_right:
		return Vector3.RIGHT
	else:
		return Vector3.LEFT

func _set_material( m: Material ) -> void:
	'''
	Establecer material al jugador.
	Aunque preferiblemente sea nomas color.
	Pero por ahora, asi está bien.
	'''
	if m != null:
		$Pivot/Mesh.material_override = m

func _set_mesh( m: Mesh ) -> void:
	'''
	Establecer malla nueva
	'''
	if m != null:
		$Pivot/Mesh.mesh = m

func _get_default_material() -> Material:
	'''
	Material por defecto segun el tipo de personaje. Los scripts hijos lo sobrescriben.
	'''
	return null

# Funciones hitbox de ataque.
func _spawn_hitbox(p_position: Vector3, p_damage: int, p_direction: Vector3) -> void:
	'''
	Spawn de hitbox por movimiento de ataque.
	Swap de ejes: el "adelante" (x) del FightMove cae en z del Pivot, y z en x invertido.
	Se indica posision y tamaño de hitbox.
	'''
	var fixed_position := Vector3(p_position.z, p_position.y, p_position.x*-1)
	_spawned_hitbox = Hitbox.new(fixed_position, Vector3(0.5, 0.5, 0.5), self, p_damage, p_direction)
	$Pivot.add_child(_spawned_hitbox)

func _clear_hitbox() -> void:
	'''
	Eliminar el hitbox activo, si existe.
	'''
	if _spawned_hitbox != null:
		_spawned_hitbox.queue_free()
		_spawned_hitbox = null

# Funciones movimiento
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

func _move(delta: float, vertical_force_signals: Dictionary) -> Dictionary:
	'''
	Movimientos. 
	Si esta atacando, ya no se puede saltar ni mover. El ataque sobreescribe ello.
	Retorna señales de movimientos.
	'''
	# No mover si esta atacando en piso.
	var attacking = _current_attack != null
	var horizontal_move := true
	var can_jump = true
	if (attacking):
		horizontal_move = _current_attack.stop_horizontal_move == false
		can_jump = false
	
	# Variables necesarias
	var on_floor = vertical_force_signals["on_floor"]
	var is_jumping := (_jump or _move_up) and can_jump
	var jump_pressed := is_jumping and not _was_jumping
	_was_jumping = is_jumping
	
	if horizontal_move:
		_direction = _get_move_direction()
	
	# Gravedad descender mas rapido | Caida rapida: abajo en el aire cae al doble, saltar restaura la normal.
	if not on_floor:
		if _move_down:
			_fall_acceleration_multiplier = 2
		if is_jumping:
			_fall_acceleration_multiplier = 1
	else:
		_fall_acceleration_multiplier = 1
	
	# Gravedad | Fuerza vertical. 
	# Contadores a cero, para que no se acumule fuerza vertcal.
	if on_floor:
		_jump_count = 0
		
		# Si esta atacando en el aire, y cai al piso, hacer nulo el ataque.
		if attacking:
			if _current_attack.air_attack:
				_current_attack = null
	
	# Velocidad horizontal
	_target_velocity.x = _direction.x * speed
		
	# Salto | Aplicar salto normal o doble segun el caso.
	if jump_pressed and _jump_count < MAX_JUMPS:
		_target_velocity.y = jump_impulse
		# Si ya estaba en el aire sin saltar (se cayo), este salto consume todos para no regalar saltos extra.
		if _air_count > 0:
			_jump_count = MAX_JUMPS
		else:
			_jump_count += 1
	
	return {
		"direction": _direction,
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
	
	# Movimiento normal
	var moving = direction.x != 0.0
	var jumping = tv.y > 0
	var falling = not jumping and not on_floor

	# Estado en piso
	var neutral = (on_floor and not moving) and (not _move_up and not _move_down)
	var running = on_floor and moving
	var neutral_crouch = (on_floor and not moving) and _move_down

	# Estado en aire
	var neutral_air = (not on_floor and not moving) and (not _move_up and not _move_down)
	var air_move = not on_floor and moving
	var air_down = not on_floor and _move_down

	return {
		# Movimiento normal
		"moving": moving,
		"jumping": jumping,
		"falling": falling,

		# Estado en piso
		"neutral": neutral,
		"running": running,
		"neutral_crouch": neutral_crouch,

		# Estado en aire
		"neutral_air": neutral_air,
		"air_move": air_move,
		"air_down": air_down,
	}

func _fight(delta: float, states: Dictionary) -> void:
	'''
	Este evento sobrepasa el move. 
	Si es necesario deja inmovil al player (para terminar ataque correctamente). Tambien sobrescribe estados.
	Se puede hacer modificando `_target_velocity.x` a cero. Y states a false o true segun el caso.
	Un ataque por pulsacion: player.gd lee el boton con is_action_just_pressed, asi que _attack ya viene siendo el puro flanco.
	'''
	# Colgados de una orilla no se pelea, ahi manda _ledge_grab. Cortar cualquier ataque y su hitbox.
	if _hanging_ledge != null:
		_current_attack = null
		_clear_hitbox()
		return

	if _attack and _current_attack == null:
		_attack_direction.x = 0.0
		_attack_direction.y = 0.0
		_attack_direction.z = 0.0
		
		# Ataque en piso
		var init_attack = true
		if states["neutral"]:
			_current_attack = _attacks.neutral
			_attack_direction.x = _x_not_zero_value 
		elif states["running"]:
			_current_attack = _attacks.dash
			_attack_direction.x = _x_not_zero_value
		elif states["neutral_crouch"]:
			_current_attack = _attacks.crouch
			_attack_direction.x = _x_not_zero_value*0.5
			_attack_direction.y = 1.0

		# Ataque en aire
		elif states["neutral_air"]:
			_current_attack = _attacks.neutral_air
			_attack_direction.x = _x_not_zero_value
			_attack_direction.y = -1.0
		elif states["air_move"]:
			_current_attack = _attacks.air_move
			_attack_direction.x = _x_not_zero_value
		elif states["air_down"]:
			_current_attack = _attacks.air_down
			_attack_direction.y = -1.0
		else:
			init_attack = false
		
		if init_attack:
			_attack_count = 0
			_attack_direction.x = _attack_direction.x * _current_attack.power_direction.x
			_attack_direction.y = (_attack_direction.y*0.1) * _current_attack.power_direction.y
			_attack_direction.z = _attack_direction.z * _current_attack.power_direction.y
		
	# Hacer ataque, esperando lo que dure, y haciendo que no se mueva el player si es necesario.
	var first_attack_frame = false
	if _current_attack != null:
		first_attack_frame = _attack_count == 0
		if first_attack_frame:
			print(_current_attack.name)
		
		# Movimiento a al tacar atacar
		if _current_attack.stop_horizontal_move:
			states["running"] = false
			_target_velocity.x = _current_attack.speed.x * _direction.x
		if _current_attack.stop_vertical_move:
			_target_velocity.y = _current_attack.speed.y * _direction.y
			
		# Finalizar ataque.
		if _attack_count >= _current_attack.duration:
			_current_attack = null
		else:
			_attack_count += delta
	
	# Hitbox. Asegurarsee de solo spawnear uno.
	if _current_attack != null and _spawned_hitbox == null:
		# Basado en la duracion del ataque, es lo que dura el hitbox de damage.
		if (_current_attack.inversed_hitbox_ratio):
			if _attack_count-delta >= _current_attack.get_hitbox_time_ratio():
				_spawn_hitbox(
					_current_attack.hitbox_position, _current_attack.damage, _attack_direction
				)
				_hitbox_duration = _current_attack.duration - _current_attack.get_hitbox_time_ratio()
				_hitbox_count = 0
		else:
			if first_attack_frame:
				_spawn_hitbox(
					_current_attack.hitbox_position, _current_attack.damage, _attack_direction
				)
				_hitbox_duration = _current_attack.get_hitbox_time_ratio()
				_hitbox_count = 0
	if _spawned_hitbox != null:
		if _hitbox_count >= _hitbox_duration:
			_clear_hitbox()
		_hitbox_count += delta


func _anim(delta: float, states: Dictionary, direction: Vector3) -> void:
	'''
	Animaciones.
	Si son de movimeinto pos chido, pero si son de ataque sobrepesar las de movimiento.
	'''
	# Si andamos colgados de una orilla, _ledge_grab ya fijo la animacion y hacia donde miramos. No pisarselo.
	if _hanging_ledge != null:
		return
	# Movimientos de pelea
	if _current_attack != null:
		if _current_attack.animation_name != &"":
			$AnimationPlayer.play(_current_attack.animation_name)
		else:
			$AnimationPlayer.stop()
			$Pivot/Mesh.rotation_degrees.x = _current_attack.mesh_rotation_x

	else:
		# Animacion | Movimiento en el piso
		if states["neutral"]:
			$AnimationPlayer.play("idle")
		elif states["running"]:
			$AnimationPlayer.play("run")
		# Animacion | Salto
		elif states["jumping"]:
			$AnimationPlayer.play("jump")
		elif states["falling"]:
			$AnimationPlayer.play("fall")
		else:
			$AnimationPlayer.play("idle")
		
	# Animación | Mover direccion visual del player.
	if states["moving"]:
		$Pivot.basis = Basis.looking_at(direction)

# Funciones plataformas de un solo sentido.
func _one_way_platforms(delta: float, on_floor: bool) -> void:
	'''
	Maneja las plataformas de un solo sentido, estilo Smash Bros: se atraviesan de abajo pa arriba,
	pero solidas al caer encima. Con tap de abajo estando parado en una, te dejas caer a proposito.
	'''
	# Plataforma de un solo sentido en la que estamos parados ahorita, si hay.
	var floor_one_way := _get_floor_one_way() if on_floor else null

	# Arrancar caida voluntaria si se hace tap de abajo estando parado sobre una plataforma de un solo sentido.
	if _down_pressed and floor_one_way != null:
		_drop_through_count = DROP_THROUGH_TIME
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
		_one_way_coyote_count = ONE_WAY_COYOTE_TIME
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
			or (not one_way.is_above_surface(feet_position, ONE_WAY_MARGIN) and not in_coyote)

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

func _get_feet_y() -> float:
	'''
	Altura global de los pies del character, calculada desde el CollisionShape3D.
	Ojo, la raiz esta escalada y el CollisionShape3D desplazado, por eso todo sale de global_position y global_basis.
	'''
	var collision_shape := $CollisionShape3D as CollisionShape3D
	if collision_shape == null or collision_shape.shape == null:
		return global_position.y
	return collision_shape.global_position.y - _get_body_half_height()

func _get_feet_position() -> Vector3:
	'''
	Posicion global de los pies del character. Igualita que _get_feet_y pero en Vector3,
	pa poder preguntarle a las plataformas inclinadas si andamos encima de su cara.
	'''
	var collision_shape := $CollisionShape3D as CollisionShape3D
	if collision_shape == null or collision_shape.shape == null:
		return global_position
	return collision_shape.global_position - Vector3(0.0, _get_body_half_height(), 0.0)

# Funciones agarre de orillas.
func _get_body_half_height() -> float:
	'''
	Medio-alto global del CollisionShape3D del character. Sirve tanto pa los pies como pa la cabeza.
	Soporta capsula, caja, cilindro y esfera, que son los shapes de collision mas comunes por aqui.
	'''
	var collision_shape := $CollisionShape3D as CollisionShape3D
	if collision_shape == null or collision_shape.shape == null:
		return 0.0

	var half_height := 0.0
	var shape := collision_shape.shape
	if shape is CapsuleShape3D:
		half_height = (shape as CapsuleShape3D).height * 0.5
	elif shape is BoxShape3D:
		half_height = (shape as BoxShape3D).size.y * 0.5
	elif shape is CylinderShape3D:
		half_height = (shape as CylinderShape3D).height * 0.5
	elif shape is SphereShape3D:
		half_height = (shape as SphereShape3D).radius
	else:
		return 0.0

	var scale_y := collision_shape.global_basis.get_scale().y
	return half_height * scale_y

func _get_head_y() -> float:
	'''
	Altura global de la cabeza del character, calculada desde el CollisionShape3D.
	Es la contraparte de _get_feet_y, pero pa arriba, nos sirve pa saber si alcanzamos una orilla.
	'''
	var collision_shape := $CollisionShape3D as CollisionShape3D
	if collision_shape == null or collision_shape.shape == null:
		return global_position.y
	return collision_shape.global_position.y + _get_body_half_height()

func _ledge_grab(delta: float) -> void:
	'''
	Agarre de orillas estilo Smash Bros. Si vas cayendo junto a la orilla de una GroundPlatform,
	te cuelgas de ella. Colgado, arriba te subes con impulso y abajo te sueltas y caes.
	Corre despues de _move, asi que pisa lo que calculo sin pedirle permiso. _fight y _anim corren despues
	pero se salen temprano si andamos colgados, por eso no nos pisan de vuelta.
	'''
	# Cooldown pa no re-agarrarnos solitos justo despues de soltarnos.
	if _ledge_release_count > 0.0:
		_ledge_release_count = max(_ledge_release_count - delta, 0.0)

	# Si ya andamos colgados, decidir que hacer.
	if _hanging_ledge != null:
		# Si la plataforma se esfumo, soltarse de volada.
		if not is_instance_valid(_hanging_ledge):
			_hanging_ledge = null
			return

		# Determinar a donde se debe mirar mientras uno se cuelga pa irse a conocer a diosito.
		var inward := -1.0 if _hanging_right_side else 1.0

		if _up_pressed:
			# Subirse de vuelta a la plataforma, puro impulso hacia arriba; si se mete o no ya es bronca del jugador.
			_target_velocity.y = jump_impulse
			_hanging_ledge = null
			_ledge_release_count = LEDGE_RELEASE_TIME
			return

		if _down_pressed:
			# Soltarse a proposito y empezar a caer.
			_target_velocity = Vector3.ZERO
			_target_velocity.y = -1.0
			_hanging_ledge = null
			_ledge_release_count = LEDGE_RELEASE_TIME
			return

		# Nadamas quedarse ahi colgado, bien quietecito.
		_target_velocity = Vector3.ZERO
		global_position = _hang_position
		_air_count = 0
		_jump_count = 0
		if _current_attack != null:
			_current_attack = null
			_clear_hitbox()
		$AnimationPlayer.play("idle")
		# Voltearlo de cara a la orilla. _anim corre despues pero se sale temprano si andamos colgados, asi no lo voltea.
		$Pivot.basis = Basis.looking_at(Vector3(inward, 0.0, 0.0))
		return

	# No estamos colgados, checar si toca agarrarnos de alguna orilla.
	if _ledge_release_count > 0.0:
		return
	if is_on_floor():
		return
	if _target_velocity.y >= 0.0:
		return

	for platform in get_tree().get_nodes_in_group(Platform.GROUP_NAME):
		var ground := platform as GroundPlatform
		if ground == null or not is_instance_valid(ground):
			continue
		if not ground.has_ledges():
			continue

		var top_y := ground.get_top_y()
		var head_y := _get_head_y()
		# Vertical: la cabeza debe andar por debajo del borde, pero sin pasarse de largo.
		if head_y > top_y or head_y < top_y - LEDGE_GRAB_DEPTH:
			continue

		# Obtener las 2 orillitas de la plataforma del suelo.
		var right_ledge_x := ground.get_ledge_x(true)
		var left_ledge_x := ground.get_ledge_x(false)

		# Horizontal: hay que venir por fuera de la plataforma, cerquita del alcance.
		var grabbed_right := global_position.x > right_ledge_x and global_position.x - right_ledge_x <= LEDGE_GRAB_REACH
		var grabbed_left := global_position.x < left_ledge_x and left_ledge_x - global_position.x <= LEDGE_GRAB_REACH

		if grabbed_right or grabbed_left:
			_hanging_ledge = ground
			_hanging_right_side = grabbed_right
			var ledge_x := right_ledge_x if grabbed_right else left_ledge_x
			var anchor_x := (ledge_x + LEDGE_HANG_OFFSET) if grabbed_right else (ledge_x - LEDGE_HANG_OFFSET)
			var anchor_y := global_position.y - (head_y - top_y)
			_hang_position = Vector3(anchor_x, anchor_y, global_position.z)
			_target_velocity = Vector3.ZERO
			break
