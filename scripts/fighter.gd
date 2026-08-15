class_name Fighter
extends Person

# Propiedades privadas | Input
var _attack: bool = false
var _grab: bool = false
var _shield: bool = false

# Propiedades privadas | Grab
var _grab_time: float = 0.0
var _grab_duration: float = 0.3

# Propiedades privadas | Shield
var _shield_time: float = 0.0
var _shield_duration: float = 5.0
## Tambien poner de regeneracion, pero por ahora no.
var _shield_mesh_instance := MeshInstance3D.new()
var _shield_sphere : SphereMesh
var _init_shield_radius : float
var _init_shield_height : float

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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.8,0,0),
			"direction": Vector3(1,0.5,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(1.0,-1.0,0),
			"direction": Vector3(0.25,0.75,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.3,0.9,0),
			"direction": Vector3(0.25,1.0,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.5,-1.0,0),
			"direction": Vector3(1.0,0.5,0.0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,1.0),
			"hitbox_position": Vector3(1.0,-0.2,0),
			"direction": Vector3(1.0,0.5,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.8,0.1,0),
			"direction": Vector3(1.25,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.1,0.8,0),
			"direction": Vector3(0.25,1.5,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,2.0),
			"hitbox_position": Vector3(0.0,-1.0,0),
			"direction": Vector3(0.25,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.9, -0.9, 0),
			"direction": Vector3(1,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.1, -1.1, 0),
			"direction": Vector3(1,-1.0,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.0, 0.8, 0),
			"direction": Vector3(0.5,1.25,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(1.2, 0.0, 0),
			"direction": Vector3(1.5,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
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
			"inmortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(-0.7, 0.0, 0),
			"direction": Vector3(1.0,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
		}
	),
)

# Propiedades privadas | Hitbox
var _hitbox_time: float = 0.0
var _spawned_hitbox: Area3D = null


# Funciones | hitbox de ataque.
func _spawn_hitbox(p_size: Vector3, p_position: Vector3, p_damage: int, p_direction: Vector3) -> void:
	'''
	Spawn de hitbox por movimiento de ataque.
	Swap de ejes: el "adelante" (x) del FightMove cae en z del Pivot, y z en x invertido.
	Se indica posision y tamaño de hitbox.
	'''
	var fixed_position := Vector3(p_position.z, p_position.y, p_position.x)
	_spawned_hitbox = Hitbox.new(fixed_position, p_size, self, p_damage, p_direction)
	_pivot.add_child(_spawned_hitbox)

func _clear_hitbox() -> void:
	'''
	Eliminar el hitbox activo, si existe.
	'''
	if _spawned_hitbox != null:
		_spawned_hitbox.queue_free()
		_spawned_hitbox = null

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
		var init_attack = true
		if states.neutral:
			_current_attack = _attacks.ground_neutral
		elif states.moving and (_left_pressed or _right_pressed):
			_current_attack = _attacks.heavy_side
		elif states.walking:
			_current_attack = _attacks.forward
		elif states.running:
			_current_attack = _attacks.dash
		elif states.neutral_crouch and _down_pressed:
			_current_attack = _attacks.heavy_down
		elif states.neutral_crouch:
			_current_attack = _attacks.down
		elif states.neutral_up and _up_pressed:
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
			_clear_hitbox()
		
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
	if _current_attack != null and _spawned_hitbox == null:
		# Basado en la duracion del ataque, es lo que dura el hitbox de damage.
		if (_current_attack.inversed_hitbox_ratio):
			if _attack_count-delta >= _current_attack.get_hitbox_time_ratio():
				_spawn_hitbox(
					_current_attack.hitbox_size, _current_attack.hitbox_position, _current_attack.hitbox_damage, _attack_direction
				)
				_hitbox_time = _current_attack.duration - _current_attack.get_hitbox_time_ratio()
		else:
			if first_attack_frame:
				_spawn_hitbox(
					_current_attack.hitbox_size, _current_attack.hitbox_position, _current_attack.hitbox_damage, _attack_direction
				)
				_hitbox_time = _current_attack.get_hitbox_time_ratio()
	if _spawned_hitbox != null:
		if _hitbox_time <= 0:
			_clear_hitbox()
		_hitbox_time -= delta

func _attack_anim(delta:float) -> void:
	if _current_attack.name != &"":
		_animation_player.play(_current_attack.name)
	else:
		_animation_player.stop()
		#_mesh_instance.rotation_degrees.x = _current_attack.mesh_rotation_x

func _attacking() -> bool:
	return _current_attack != null

# Funciones | Agarre
func _grabbing() -> bool:
	return _grab_time > 0

func _grab_move(delta: float, signals: VerticalForceSignals) -> void:
	if signals.on_floor:
		if _grab:
			if _grab_time <= 0.0:
				_grab_time = _grab_duration
	
	if _grab_time > 0.0:
		_grab_time -= delta

# Funciones | Shield
func _shield_move(delta: float, signals: VerticalForceSignals) -> void:
	if signals.on_floor:
		if _shield:
			if _shield_time <= 0.0:
				_shield_time = _shield_duration
	
	if _shield_time > 0.0:
		_shield_time -= delta
		if _shield == false:
			_shield_time = 0.0
	
	# Daño por exceso de uso de escudo
	if _shield == true and _shield_time <= 0.0:
		if signals.on_floor:
			_target_velocity.y = jump_impulse

func _get_shield_porcent() -> float:
	if _shield_time > 0:
		return _shield_time / _shield_duration
	return 0.0

func _with_shield() -> bool:
	return _shield_time > 0

# Funciones | Init
func _ready() -> void:
	super()
	_shield_mesh_instance = $Visual/ShieldMeshInstance3D
	_shield_mesh_instance.visible = false
	_shield_sphere = _shield_mesh_instance.mesh
	_init_shield_radius = _shield_sphere.radius
	_init_shield_height = _shield_sphere.height
	_pivot.add_child(_shield_mesh_instance)

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
	if not _knockback_active:
		_ledge_grab(delta, gravity_signals, move_signals)
	_set_x_not_zero_value(move_signals.direction)
	
	# Cancelar salto por ataque heavy arriba.
	if _up_pressed and _attack and move_signals.on_floor:
		_target_velocity.y = 0
	
	# Ledge grab
	if _holding_onto_the_ledge() and _knockback_active:
		_release_hanging_ledge()
	
	# Fight and Defence moves
	if ( not (_shield and _grab) ) and not _attacking(): 
		# No permitir grab y shield a la vez. No permitir hacer agarre o escudo cuando se ataca.
		_grab_move(delta, gravity_signals)
		_shield_move(delta, gravity_signals)
	var grabbing = _grabbing()
	var with_shield = _with_shield()
	var grab_or_shield = grabbing or with_shield
	if grab_or_shield:
		# Anular ataque si se hace grab o escudo.
		_current_attack = null
	else:
		# Solo permitir atacar cuando no se hace grab o se pone escudo
		_fight_move(delta, gravity_signals, move_states)
	
	# Defensa | Recivir ataques en escudo.
	## Esto hacerlo func tipo `_shield_defence`
	if with_shield:
		if _knockback_active:
			_knockback_active = false
			_ignore_last_damage()
			_shield_time -= (_shield_duration*_last_damage_porcentage)
	
	# Bloqueo de direccion por movimiento de inputs.
	_horizontal_move = true
	_allow_jump = true
	if _attacking():
		_allow_jump = false
		# Si este en el piso y da trancazos, no permitir inputs de movimiento horizontal.
		if _current_attack.air_attack == false:
			_horizontal_move = false
	elif _grabbing() or _with_shield():
		_horizontal_move = false
		_allow_jump = false

	# Damage
	if _knockback_active:
		_damage_move(delta)
	
	# Anular ataque, grab, y shield
	if  _knockback_active or _holding_onto_the_ledge():
		_current_attack = null
		_grab_time = 0.0
		_shield_time = 0.0
		_clear_hitbox()
		
	# Visual | Escudo
	## Esto hacerlo func tipo `_visual_shield`
	with_shield = _with_shield()
	_shield_mesh_instance.visible = with_shield
	if with_shield:
		var porcent :float = _get_shield_porcent()
		_shield_sphere.radius = _init_shield_radius * porcent
		_shield_sphere.height = _init_shield_height * porcent
	
	# Anim
	_reset_visual_values()
	if _knockback_active:
		_damage_anim(delta, gravity_signals)
	elif _holding_onto_the_ledge():
		_ledge_grab_anim(delta)
	elif _attacking():
		_attack_anim(delta)
	elif grabbing:
		_animation_player.play("grab")
	elif with_shield: 
		_animation_player.play("guard")
	else:
		_move_anim(delta, move_states)
	_set_pivot_direction(move_signals)

	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
