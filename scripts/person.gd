class_name Person
extends GravityBody3D

'''
Person
Objeto de persona. Tiene lo necesario para tener fisicas 2D en un mundo 3D.
- Puede correr, caminar, ir agachado, y saltar. 
- Tiene compatibilidad con mas de un salto.
- Puede agarrarse de plataformas.
- Recibe daño y tiene hp.
- Tiene flancos de input de movimiento para poder hacer acciones especiales. O limitar acciones.
'''

# Constantes | Agarre de orillas.
const LEDGE_HANG_OFFSET := 0.3     # que tan separado de la orilla se queda colgado
const LEDGE_RELEASE_TIME := 0.3    # cooldown tras soltarse, pa no re-agarrarse solo

# Propiedades publicas
@export_group("Horizontal Movement")
@export var walking_speed: int = 3
@export var running_speed: int = 8
@export var init_looking_at_right: bool = false

@export_group("Vertical Movement")
@export var jump_impulse: int = 13

@export_group("Movement Tuning")
@export var ground_acceleration: float = 40.0
@export var ground_friction: float = 100.0
@export var knockback_friction: float = 10.0

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

# `_target_velocity`, pertenece a `GravityBody3D`.

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
var _allow_jump: bool = true

# Propiedades privadas | Daño
var _normal_damage_power :float = 50
var _knockback_active :bool = false
var _knockback_direction :Vector3 = Vector3.ZERO
var _knockback_time :float = 0.0
var _knockback_duration :float = 0.35
var _damage_degrees :float = 0.0

# Propiedades privadas | Inputs
var _walk: bool = false

var _move_left: bool = false
var _move_right: bool = false
var _move_up: bool = false
var _move_down: bool = false

var _jump: bool = false

# Propiedades privadas | Flancos de inputs
# Los flancos de input perminten ataques al same time de dos teclas.
var _was_jumping: bool = false
var _was_move_down: bool = false
var _down_pressed: bool = false
var _was_move_up: bool = false
var _up_pressed: bool = false


# Propiedades privadas | Agarre de orillas.
var _hanging_ledge: GroundPlatform = null
var _hanging_right_side: bool = false
var _hang_position: Vector3 = Vector3.ZERO
var _ledge_release_count: float = 0.0

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


# Funciones | Respawn
func respawn(at_position: Vector3) -> void:
	'''
	Reaparecer limpio: posicion, velocidad, daño, saltos, ataque/hitbox en curso, agarre de
	orilla y orientacion inicial, todo se resetea.
	'''
	global_position = at_position
	_target_velocity = Vector3.ZERO
	damage_percentage = 0.0
	_jump_count = 0
	_air_count = 0
	# Si el personaje se murio a medio ataque, poner _current_attack a null no libera el hitbox
	# ya lanzado (_spawned_hitbox, un Area3D hijo de $Pivot). Sin esta linea quedaria vivo y
	# podria dañar a quien este parado en el spawn apenas reaparece.
	_release_hanging_ledge()
	_drop_through_count = 0.0
	_set_x_not_zero_value( _get_initial_facing() )


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
		# Flancos Salto
		want_jump = (_jump or _move_up) # <--- El move up se usara para ataques hacia arriba.
		can_jump = (want_jump and _allow_jump) and not _was_jumping

		# Flancos Down
		_down_pressed = _move_down and not _was_move_down

		# Flancos up
		_up_pressed = _move_up and not _was_move_up
	_was_jumping = want_jump
	_was_move_down = _move_down
	_was_move_up = _move_up

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
	if _walk:
		speed = walking_speed
	else:
		speed = running_speed
	if signals.on_floor and _move_down:
		speed = walking_speed
		speed_multiplier = 0.8

	# Velocidad horizontal
	var target_speed := _direction.x * (speed*speed_multiplier)
	var accel := ground_friction if _direction.x == 0.0 else ground_acceleration
	# Si se invierte el sentido del movimiento, frenar rapido (friction) en vez de acelerar despacio como si arrancara de cero, para evitar el "patinaje" al voltear.
	if target_speed != 0.0 and sign(_target_velocity.x) != 0.0 and sign(_target_velocity.x) != sign(target_speed):
		accel = ground_friction
	if _knockback_active:
		accel = knockback_friction
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
		neutral_up = not moving and _move_up and not _move_down
		neutral_crouch = not moving and _move_down and not _move_up
		crouch_move = moving and _move_down and not _move_up
		walking = _walk and moving
		running = moving and not walking and not crouch_move
	
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
		_animation_player.play("look_up")
	elif states.neutral_crouch:
		_animation_player.play("crouch")
	elif states.crouch_move:
		_animation_player.play("crouch_walk")
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

func _set_pivot_direction(signals: MoveSignals) -> void:
	if signals.on_floor or _holding_onto_the_ledge():
		_pivot.basis = Basis.looking_at(
			Vector3(_x_not_zero_value, signals.direction.y, signals.direction.z)
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
	if signals.air_count < 0.1:
		_damage_degrees = 0
		_animation_player.play("hurt_ground")
	elif signals.on_floor:
		_damage_degrees = 0
		_animation_player.play("hurt_ground")
	else:
		_animation_player.play("hurt_air")
		_damage_degrees += ((_normal_damage_power*damage_percentage)*8 )*delta
	_pivot.rotation_degrees.x = _damage_degrees


# Funciones | Agarre de orillas
func _release_hanging_ledge() -> void:
	'''
	Soltar la cornisa que traiamos agarrada y avisarle a la plataforma pa que quede libre pa otro.
	Aguanta que la plataforma ya no exista, asi que se puede llamar sin miedo.
	'''
	if _hanging_ledge != null and is_instance_valid(_hanging_ledge):
		_hanging_ledge.release_ledge(_hanging_right_side, self)
	_hanging_ledge = null

func _ledge_grab(
	delta: float, vertical_force_signals: VerticalForceSignals, move_signals: MoveSignals
) -> void:
	'''
	Agarre de orillas estilo Smash Bros. Deteccion puramente espacial: cada GroundPlatform expone
	una zona de agarre a cada lado (matematica de rangos, is_character_in_ledge_zone), aqui solo se
	pregunta "¿ando en esa zona?" + "¿vengo cayendo?". Sin heuristicas de historial.
	Colgado, arriba te subes con impulso y abajo te sueltas y caes.
	Corre despues de _move, asi que pisa lo que calculo sin pedirle permiso. _fight y _anim corren despues
	pero se salen temprano si andamos colgados, por eso no nos pisan de vuelta.
	
	Remplaza direccion horizontal.
	'''
	# Cooldown pa no re-agarrarnos solitos justo despues de soltarnos.
	if _ledge_release_count > 0.0:
		_ledge_release_count = max(_ledge_release_count - delta, 0.0)

	# Si ya andamos colgados, decidir que hacer.
	if _hanging_ledge != null:
		# Si la plataforma se esfumo, soltarse de volada.
		if not is_instance_valid(_hanging_ledge):
			_release_hanging_ledge()
			return

		# Determinar a donde se debe mirar mientras uno se cuelga pa irse a conocer a diosito.
		var inward := -1.0 if _hanging_right_side else 1.0

		if _up_pressed:
			# Subirse de vuelta a la plataforma, puro impulso hacia arriba; si se mete o no ya es bronca del jugador.
			_target_velocity.y = jump_impulse
			_release_hanging_ledge()
			_ledge_release_count = LEDGE_RELEASE_TIME
			return

		if _down_pressed:
			# Soltarse a proposito y empezar a caer.
			_target_velocity = Vector3.ZERO
			_target_velocity.y = -1.0
			_release_hanging_ledge()
			_ledge_release_count = LEDGE_RELEASE_TIME
			return

		# Nadamas quedarse ahi colgado, bien quietecito.
		_target_velocity = Vector3.ZERO
		global_position = _hang_position
		_air_count = 0
		_jump_count = 0
		# Voltearlo de cara a la orilla. _anim corre despues pero se sale temprano si andamos colgados, asi no lo voltea.
		move_signals.direction.x = inward
		return

	# No estamos colgados: checar si toca agarrarnos. Zona de agarre + venir cayendo, nada mas.
	if _ledge_release_count > 0.0:
		return
	if vertical_force_signals.on_floor:
		return
	if _target_velocity.y >= 0.0:
		return

	for platform in get_tree().get_nodes_in_group(Platform.GROUP_NAME):
		var ground := platform as GroundPlatform
		if ground == null or not is_instance_valid(ground):
			continue
		if not ground.has_ledges():
			continue

		for right_side in [true, false]:
			if not ground.is_character_in_ledge_zone(right_side, global_position):
				continue
			# Una cornisa, un personaje. Si ya hay alguien colgado de este lado, seguir buscando otra.
			if not ground.take_ledge(right_side, self):
				continue

			_hanging_ledge = ground
			_hanging_right_side = right_side
			var top_y := ground.get_top_y()
			var ledge_x := ground.get_ledge_x(right_side)
			var anchor_x := (ledge_x + LEDGE_HANG_OFFSET) if right_side else (ledge_x - LEDGE_HANG_OFFSET)
			var anchor_y := global_position.y - (_get_head_y() - top_y)
			_hang_position = Vector3(anchor_x, anchor_y, global_position.z)
			_target_velocity = Vector3.ZERO
			return

func _holding_onto_the_ledge() -> bool:
	return _hanging_ledge != null

func _ledge_grab_anim(delta) -> void:
	_animation_player.play("idle")

# Funciones | Inicializar
func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Fall
	fall_acceleration = 30
	
	# Essentail nodes
	_visual = $Visual
	# El hijo de Visual es la raiz del .glb importado; su nombre depende del
	# archivo fuente (ej. "standard_character_a_pose"), asi que se toma
	# dinamico en vez de hardcodearlo, y se navega desde ahi.
	var model_root: Node3D = _visual.get_child(0)
	_pivot = model_root.get_node("Pivot")
	_mesh_instance = model_root.get_node("Pivot/Skeleton3D/MeshInstance3D")
	_animation_player = model_root.get_node("AnimationPlayer")
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
	var gravity_signals = _vertical_force(delta, _down_pressed, _fall_acceleration_multiplier)
	var move_signals = _move(delta, gravity_signals)
	var move_states = _get_move_states(move_signals)
	_ledge_grab(delta, gravity_signals, move_signals)
	_set_x_not_zero_value(move_signals.direction)
	
	# Ledge grab
	if _holding_onto_the_ledge() and _knockback_active:
		_release_hanging_ledge()

	# Damage
	if _knockback_active:
		_damage_move(delta)

	# Anim
	if _knockback_active:
		_damage_anim(delta, gravity_signals)
	elif _holding_onto_the_ledge():
		_ledge_grab_anim(delta)
	else:
		_move_anim(delta, move_states)
	_set_pivot_direction(move_signals)

	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
