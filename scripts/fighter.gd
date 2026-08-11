class_name Fighter
extends Person

# Propiedades privadas | Input
var _attack: bool = false

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
			"direction": Vector3(1,0.25,0),
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
			"duration": 0.5833,
			"speed": Vector3(0,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"inmortal": false,
			
			"hitbox_damage": 5,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.1,0.8,0),
			"direction": Vector3(0.25,2,0),
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
			"hitbox_position": Vector3(1.0,-1.0,0),
			"direction": Vector3(1.0,0.5,0.0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"forward_attack",
			"duration": 0.3,
			"speed": Vector3(10,0,0),
			"air_attack": false,
			"grab_attack": false,
			"override_horizontal_move": true,
			"override_vertical_move": false,
			"inmortal": false,
			
			"hitbox_damage": 10,
			"hitbox_size": Vector3(0.5,0.5,0.5),
			"hitbox_position": Vector3(0.5,-0.5,0),
			"direction": Vector3(1.5,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"heavy_side_attack",
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
			"direction": Vector3(0.25,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"heavy_up_attack",
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
			"direction": Vector3(0.25,1,0),
			"hitbox_time_ratio": 0.5,
			"hitbox_rotation": 0.0,
			"inversed_hitbox_ratio": true
		}
	),
	FightMove.new(
		{
			"name": &"heavy_down_attack",
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
			"direction": Vector3(1,1.25,0),
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
			"duration": 0.5,
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
			_attack_direction.x = _x_not_zero_value 
		elif states.running:
			_current_attack = _attacks.dash
			_attack_direction.x = _x_not_zero_value
		elif states.neutral_crouch:
			_current_attack = _attacks.down
			_attack_direction.x = _x_not_zero_value*0.5
			_attack_direction.y = 1.0
		elif states.neutral_up:
			_current_attack = _attacks.up
			_attack_direction.y = 1.0

		# Ataque en aire
		elif states.neutral_air:
			_current_attack = _attacks.air_neutral
			_attack_direction.x = _x_not_zero_value
			_attack_direction.y = -1.0
		elif states.air_move:
			_current_attack = _attacks.air_forward
			_attack_direction.x = _x_not_zero_value
		elif states.air_down:
			_current_attack = _attacks.air_down
			_attack_direction.y = -1.0
		elif states.air_up:
			_current_attack = _attacks.air_up
			_attack_direction.y = 1.0
		else:
			init_attack = false
		
		if init_attack:
			_attack_count = 0
			_attack_direction.x = _attack_direction.x * _current_attack.direction.x
			_attack_direction.y = (_attack_direction.y*0.1) * _current_attack.direction.y
			_attack_direction.z = _attack_direction.z * _current_attack.direction.y
	
	# Cancelar ataque aerio si no esta en aire.
	# Cancelar ataque en piso si esta en el aire
	if _current_attack != null:
		if signals.on_floor and _current_attack.air_attack:
			_current_attack = null
		elif not signals.on_floor and not _current_attack.air_attack:
			_current_attack = null
		else:
			_direction.x = 0
		
	# Hacer ataque, esperando lo que dure, y haciendo que no se mueva el player si es necesario.
	var first_attack_frame = false
	if _current_attack != null:
		first_attack_frame = _attack_count == 0
		if first_attack_frame:
			print(_current_attack.name)
		
		# Movimiento a al tacar atacar
		if _current_attack.override_horizontal_move:
			_target_velocity.x = _current_attack.speed.x * _x_not_zero_value
		if _current_attack.override_vertical_move:
			_target_velocity.y = _current_attack.speed.y * _x_not_zero_value
			
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


# Funciones | Procesar
func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas.
    Este puede ser remplazado segun se necesite.
	'''
	_collect_input()
	
	# Move
	var gravity_signals = _vertical_force(delta, _move_down, _fall_acceleration_multiplier)
	var move_signals = _move(delta, gravity_signals)
	_set_x_not_zero_value(move_signals.direction)
	var move_states = _get_move_states(move_signals)
	
	# Fight moves
	_fight_move(delta, gravity_signals, move_states)
	
	# Bloqueo de direccion de movimiento por inputs.
	_horizontal_move = true
	_can_jump = true
	if _current_attack != null:
		_can_jump = false
		# Si este en el piso y da trancazos, no permitir inputs de movimiento horizontal.
		if _current_attack.air_attack == false:
			_horizontal_move = false

	# Damage
	if _knockback_active:
		_damage_move(delta)
		_current_attack = null
	
	# Anim
	if _knockback_active:
		_damage_anim(delta, gravity_signals)
	elif _current_attack != null:
		_attack_anim(delta)
	else:
		_move_anim(delta, move_states)
	_set_pivot_direction(move_signals, move_signals.direction)

	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
