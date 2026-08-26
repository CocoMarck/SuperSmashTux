class_name Fighter
extends Person

# Constantes Shield en `GameBalance`

# Propiedades privadas | Input
var _attack: bool = false
var _grab: bool = false
var _shield: bool = false

# Propiedades privadas | Grab
var _grab_move_time: float = 0.0
var _grab_move_duration: float = 0.3

# Propiedades privadas | Shield
var _shield_time: float = 0.0
var _shield_regeneration_time :float = 0.0
var _shield_regeneration_value :float = 0.5
var _allow_shield: bool = true

# Propiedades privadas | Shield rodar
var _roll: bool = false
var _roll_forward: bool = false
var _roll_backward: bool = false
var _roll_time: float = 0.0
var _roll_duration: float = 0.625
var _roll_speed: float = 3.0

var _shield_mesh_instance : MeshInstance3D
var _shield_sphere : SphereMesh
var _init_shield_radius : float
var _init_shield_height : float

# Propiedades privadas | shields stun
var _shield_blockstun : bool = false
var _shield_blockstun_time : float = 0.0


# Propiedades privadas | Ataque
var _attack_count: float = 0.0
var _current_attack: FightMove = null
var _attack_direction : Vector3 = Vector3(0.0, 0.0, 0.0)

var _attacks: Attacks = Attacks.new(
	# En el piso
	FightMove.new(
		{
			"name": &"ground_neutral_attack",
			"duration": 0.875,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.8,0,0),
			"direction": Vector3(1,0.5,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"down_attack",
			"duration": 0.5,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 8,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(1.0,-1.0,0),
			"direction": Vector3(0.25,0.75,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"up_attack",
			"duration": 0.4583,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 7,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.3,0.9,0),
			"direction": Vector3(0.25,1.0,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"dash_attack",
			"duration": 0.8333,
			"speed": Vector3(7,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.5,-1.0,0),
			"direction": Vector3(0.5,0.8,0.0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"forward_attack",
			"duration": 0.4583,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 6,
			"hitbox_size": Vector3(0.5,0.5,1.0),
			"hitbox_position": Vector3(1.0,-0.2,0),
			"direction": Vector3(1.0,0.5,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"heavy_side_attack",
			"duration": 0.7083,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 20,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.8,0.1,0),
			"direction": Vector3(1,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"heavy_up_attack",
			"duration": 0.5833,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 20,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.1,0.8,0),
			"direction": Vector3(0.25,1.0,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"heavy_down_attack",
			"duration": 0.625,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,2.0),
			"hitbox_position": Vector3(0.0,-1.0,0),
			"direction": Vector3(0.25,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	
	# En el aire
	FightMove.new(
		{
			"name": &"air_neutral_attack",
			"duration": 0.9167,
			"speed": Vector3(0,0,0),
			"air_attack": true,
			"grab_attack": false,
			"override_horizontal_move": false,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.9, -0.9, 0),
			"direction": Vector3(1,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"air_down_attack",
			"duration": 0.5,
			"speed": Vector3(0,0,0),
			"air_attack": true,
			"grab_attack": false,
			"override_horizontal_move": false,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 20,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.1, -1.1, 0),
			"direction": Vector3(0.25,-1.0,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"air_up_attack",
			"duration": 0.5833,
			"speed": Vector3(0,0,0),
			"air_attack": true,
			"grab_attack": false,
			"override_horizontal_move": false,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.8),
			"hitbox_position": Vector3(0.15, 0.8, 0),
			"direction": Vector3(0.5,1.25,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"air_forward_attack",
			"duration": 0.6667,
			"speed": Vector3(0,0,0),
			"air_attack": true,
			"grab_attack": false,
			"override_horizontal_move": false,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.9),
			"hitbox_position": Vector3(0.75, 0.0, 0),
			"direction": Vector3(1.2,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"air_back_attack",
			"duration": 0.5833,
			"speed": Vector3(0,0,0),
			"air_attack": true,
			"grab_attack": false,
			"override_horizontal_move": false,
			"override_vertical_move": false,
			"immortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(-0.7, 0.0, 0),
			"direction": Vector3(1.0,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inverted_hitbox_ratio": true
		}
	),
)

# Propiedades privadas | Hitbox
var _spawned_hitbox_damage: Area3D = null


# Funciones | hitbox de ataque.
func _spawn_hitbox_damage(p_size: Vector3, p_position: Vector3, p_damage: int, p_direction: Vector3, p_lifetime: float) -> void:
	'''
	Spawn de hitbox por movimiento de ataque.
	Swap de ejes: el "adelante" (x) del FightMove cae en z del Pivot, y z en x invertido.
	Se indica posision y tamaño de hitbox.
	'''
	var fixed_position := Vector3(p_position.z, p_position.y, p_position.x)
	_spawned_hitbox_damage = HitboxDamage.new(
		{
			"position": fixed_position, 
			"size": p_size, 
			"parent": self, 
			"damage": p_damage,
			"direction": p_direction,
			"lifetime": p_lifetime,
			"color": Color(1.0, 0.0, 1.0, 0.3)
		}
	)
	_pivot.add_child(_spawned_hitbox_damage)

func _clear_hitbox_damage() -> void:
	'''
	Eliminar el hitbox activo, si existe.
	'''
	if _spawned_hitbox_damage != null:
		_spawned_hitbox_damage.queue_free()
		_spawned_hitbox_damage = null

# Funciones | Pelear
func _fight_move(delta: float, signals: VerticalForceSignals, states: MoveStates) -> void:
	'''
	Este evento sobrepasa el move. 
	'''
	if _attack and _current_attack == null:
		_attack_direction.x = 0.0
		_attack_direction.y = 0.0
		_attack_direction.z = 0.0
		
		# Ataque en piso
		var direction_buffered = _is_direction_buffer() # Margen de error de precion de direccion.
		var init_attack = true
		if states.neutral:
			_current_attack = _attacks.ground_neutral
		elif states.moving and direction_buffered:
			_current_attack = _attacks.heavy_side
		elif states.walking:
			_current_attack = _attacks.forward
		elif states.running:
			_current_attack = _attacks.dash
		elif states.neutral_crouch and direction_buffered:
			_current_attack = _attacks.heavy_down
		elif states.neutral_crouch or states.crouch_move:
			_current_attack = _attacks.down
		elif states.neutral_up and direction_buffered:
			_current_attack = _attacks.heavy_up
		elif states.neutral_up:
			_current_attack = _attacks.up

		# Ataque en aire
		elif states.neutral_air:
			_current_attack = _attacks.air_neutral
		elif states.air_down:
			_current_attack = _attacks.air_down
		elif states.air_up:
			_current_attack = _attacks.air_up
		elif states.air_forward:
			_current_attack = _attacks.air_forward
		elif states.air_back:
			_current_attack = _attacks.air_back
		else:
			init_attack = false
		
		if init_attack:
			_attack_count = 0
			_attack_direction.x = _current_attack.direction.x * _x_not_zero_value
			_attack_direction.y = _current_attack.direction.y * 0.1
			#_attack_direction.z = _attack_direction.z * _current_attack.direction.y
	
	# Cancelar ataque aerio si no esta en aire.
	# Cancelar ataque en piso si esta en el aire
	if _current_attack != null:
		if signals.on_floor and _current_attack.air_attack:
			_current_attack = null
		elif not signals.on_floor and not _current_attack.air_attack:
			_current_attack = null
		else:
			_direction.x = 0
		if _current_attack == null:
			_clear_hitbox_damage()
		
	# Hacer ataque, esperando lo que dure, y haciendo que no se mueva el player si es necesario.
	var first_attack_frame = false
	if _current_attack != null:
		first_attack_frame = _attack_count == 0
		if first_attack_frame:
			print(_current_attack.name)
		
		# Movimiento a al atacar
		if _current_attack.override_horizontal_move:
			_target_velocity.x = _current_attack.speed.x * _x_not_zero_value
		if _current_attack.override_vertical_move:
			_target_velocity.y = _current_attack.speed.y
			
		# Finalizar ataque.
		if _attack_count >= _current_attack.duration:
			_current_attack = null
		else:
			_attack_count += delta
	
	# Hitbox. Asegurarsee de solo spawnear uno.
	if _current_attack != null and _spawned_hitbox_damage == null:
		# Basado en la duracion del ataque, es lo que dura el hitbox de damage.
		if (_current_attack.inverted_hitbox_ratio):
			if _attack_count-delta >= _current_attack.get_hitbox_time_ratio():
				_spawn_hitbox_damage(
					_current_attack.hitbox_size, 
					_current_attack.hitbox_position, 
					_current_attack.hitbox_damage, 
					_attack_direction, 
					_current_attack.duration -_current_attack.get_hitbox_time_ratio()
				)
		else:
			if first_attack_frame:
				_spawn_hitbox_damage(
					_current_attack.hitbox_size,
					_current_attack.hitbox_position, 
					_current_attack.hitbox_damage, 
					_attack_direction,
					_current_attack.duration -_current_attack.get_hitbox_time_ratio()
				)

func _attack_anim(delta:float) -> void:
	if _current_attack.name != &"":
		_animation_player.play(_current_attack.name)
	else:
		_animation_player.stop()
		#_mesh_instance.rotation_degrees.x = _current_attack.mesh_rotation_x

func _attacking() -> bool:
	return _current_attack != null

# Funciones | Agarre
func _waiting_grab_move() -> bool:
	return _grab_move_time > 0

func _grab_move(delta: float, signals: VerticalForceSignals) -> void:
	if signals.on_floor:
		if _grab:
			if _grab_move_time <= 0.0:
				_grab_move_time = _grab_move_duration
				var hitbox = HitboxGrab.new({
					"parent": self, 
					"position": Vector3(0,0,1.0),
					"size": Vector3(0.5,0.5,1.0),
					"color": Color(0.5, 0.0, 1.0, 0.4),
					"lifetime": 0.1,
					"direction": Vector3.ZERO,
				})
				_pivot.add_child(hitbox)
	
	if _grab_move_time > 0.0:
		_grab_move_time -= delta

# Funciones | Shield
func _shield_regeneration(delta: float, signals: VerticalForceSignals) -> void:
	if signals.on_floor:
		if _shield_regeneration_time <= 0.0:
			_shield_time += _shield_regeneration_value
			
		if _shield_regeneration_time <= 0:
			_shield_regeneration_time = GameBalance.SHIELD_REGENERATION_DURATION
			
		_shield_regeneration_time -= delta
	if _shield_time >= GameBalance.SHIELD_DURATION:
		_shield_time = GameBalance.SHIELD_DURATION

func _shield_move(delta: float, signals: VerticalForceSignals) -> void:
	# Tiene que estar en el piso
	if signals.on_floor:
		if _shield_time > 0.0:
			_shield_time -= delta
			# Blockstun time
			if _shield_blockstun_time <= 0:
				_shield_blockstun = false
			if _shield_blockstun:
				_shield_blockstun_time -= delta
		if _shield_time <= 0.0:
			# Daño por exceso de uso de escudo
			_target_velocity.y = jump_impulse
			_shield_blockstun = false
			_shield_time = 0.0
		else:
			# Rodar
			_roll = _left_pressed or _right_pressed

func _shield_defence() -> void:
	'''
	Defensa de ataques locos. Anular daño.
	'''
	if _knockback_active:
		_knockback_active = false
		_heavy_hitstun_active = false
		_ignore_last_damage()
		_shield_time -= (GameBalance.SHIELD_DURATION*_last_damage_percentage)
		_shield_blockstun = true
		_shield_blockstun_time = GameBalance.SHIELD_STUN_DURATION

func _get_shield_porcent() -> float:
	if _shield_time > 0:
		return _shield_time / GameBalance.SHIELD_DURATION
	return 0.0

func _with_shield(signals: VerticalForceSignals) -> bool:
	return (_shield_time > 0) and ((_shield or _shield_blockstun) and _allow_shield and signals.on_floor) and (not _attacking())

# Funciones | Shield rodar
func _rolling() -> bool:
	return _roll_backward or _roll_forward

func _roll_move(delta: float, signals: VerticalForceSignals) -> void:
	if _roll and (_allow_shield) and (not _shield_blockstun):
		if _roll_time <= 0:
			if _left_pressed and _last_x_direction == 1:
				_roll_backward = true
				_roll_forward = false
			elif _right_pressed and _last_x_direction == -1:
				_roll_backward = true
				_roll_forward = false
			elif _left_pressed or _right_pressed:
				_roll_backward = false
				_roll_forward = true
			_roll_time = _roll_duration
			_shield_time -= GameBalance.SHIELD_DURATION * GameBalance.ROLL_SHIELD_COST_RATIO # Consto de usar rodada
	if signals.on_floor == false:
		_roll_time = 0
	if _rolling():
		_immunity_to_damage = true
		_immunity_to_body_collide = true
		if _roll_backward:
			_target_velocity.x = _roll_speed * (_last_x_direction*-1)
		elif _roll_forward:
			_target_velocity.x = _roll_speed * _last_x_direction
		if _roll_time <= 0:
			_roll = false
			_roll_forward = false
			_roll_backward = false
			_immunity_to_damage = false
			_immunity_to_body_collide = false
		_roll_time -= delta

func _roll_anim() -> void:
	if _roll_backward:
		_animation_player.play("roll_backward")
	elif _roll_forward:
		_animation_player.play("roll_forward")

func grabbing_person(p_person: Person):
	'''
	Señal de agarre por `HitboxGrab` spawneado.
	- Bloquear inputs de victima.
	'''
	print("Grabbing: ", p_person.name)

# Funciones | Init
func _ready() -> void:
	super()
	_shield_mesh_instance = $Visual/ShieldMeshInstance3D
	_shield_mesh_instance.visible = false
	_shield_sphere = _shield_mesh_instance.mesh
	_init_shield_radius = _shield_sphere.radius
	_init_shield_height = _shield_sphere.height
	_shield_time = GameBalance.SHIELD_DURATION

# Funciones | Procesar
func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas.
    Este puede ser remplazado segun se necesite.
	'''
	_collect_input()
	
	# Move
	var gravity_signals = _vertical_force(
		delta, (_down_pressed and _heavy_hitstun_active == false), _fall_acceleration_multiplier
	)
	var move_signals = _move(delta, gravity_signals)
	var move_states = _get_move_states(move_signals)
	if _heavy_hitstun_active or _knockback_active:
		_release_hanging_ledge()
		_ledge_release_count = 1.0
	_ledge_grab(delta, gravity_signals, move_signals)
	_set_x_not_zero_value(move_signals.direction)
	
	# Cancelar salto por ataque heavy arriba.
	if _is_direction_buffer() and _attack and move_signals.on_floor:
		_target_velocity.y = 0
	
	# Fight and Defence moves
	## No permitir grab y shield.
	if _shield or _with_shield(gravity_signals):
		_grab = false
	if _grab or _waiting_grab_move():
		_shield = false
	## No permitir hacer agarre o escudo cuando se ataca.
	if not _attacking(): 	
		_grab_move(delta, gravity_signals)
		if (_shield or _shield_blockstun)  and _allow_shield:
			_shield_move(delta, gravity_signals)
		else:
			if not _rolling():
				_shield_regeneration(delta, gravity_signals)
	var waiting_grab_move = _waiting_grab_move()
	var with_shield = _with_shield(gravity_signals)
	var grab_or_shield = waiting_grab_move or with_shield
	if grab_or_shield or _rolling():
		# Anular ataque si se hace grab, escudo, o rueda.
		_current_attack = null
		_clear_hitbox_damage()
	else:
		# Solo permitir atacar cuando no se hace grab o se pone escudo
		_fight_move(delta, gravity_signals, move_states)
	
	# Bloqueo de direccion por movimiento de inputs.
	# Mejor bloquiar la direccion en un solo lado.
	_horizontal_move = true
	_allow_jump = true
	if _attacking():
		_allow_jump = false
		# Si este en el piso y da trancazos, no permitir inputs de movimiento horizontal.
		if _current_attack.air_attack == false:
			_horizontal_move = false
	elif _waiting_grab_move() or with_shield or _rolling():
		_horizontal_move = false
		_allow_jump = false
		
	# Defensa | Recibir ataques en escudo. Rodar.
	if with_shield:
		_shield_defence()
	_roll_move(delta, gravity_signals)

	# Damage
	if _knockback_active:
		_apply_hitstun(delta)
	elif _heavy_hitstun_active:
		_apply_heavy_hitstun(delta, gravity_signals)
	
	# Anular ataque, grab, y shield
	_allow_shield = true
	if  _knockback_active or _heavy_hitstun_active or _holding_onto_the_ledge() or _rolling():
		_current_attack = null
		_grab_move_time = 0.0
		_allow_shield = false
		_clear_hitbox_damage()
		
	# Visual | Escudo
	## Esto hacerlo func tipo `_visual_shield`
	with_shield = _with_shield(gravity_signals)
	_shield_mesh_instance.visible = with_shield
	if with_shield:
		var porcent :float = _get_shield_porcent()
		_shield_sphere.radius = _init_shield_radius * porcent
		_shield_sphere.height = _init_shield_height * porcent
	
	# Anim
	_reset_visual_values()
	if _knockback_active:
		_hitstun_anim(delta, gravity_signals)
	elif _heavy_hitstun_active:
		_heavy_hitstun_anim(delta, gravity_signals)
	elif _holding_onto_the_ledge():
		_ledge_grab_anim(delta)
	elif _attacking():
		_attack_anim(delta)
	elif _rolling():
		_roll_anim()
	elif waiting_grab_move:
		_animation_player.play("grab")
	elif with_shield: 
		_animation_player.play("guard")
	else:
		_move_anim(delta, move_states)
	if not (_heavy_hitstun_active or _knockback_active):
		_set_pivot_direction(move_signals)

	# Effects
	immunity_effect(delta)

	# Procesar todo
	_push_bodies_apart(delta, move_states)
	velocity = _target_velocity
	move_and_slide()
