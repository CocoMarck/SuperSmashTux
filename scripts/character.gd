extends CharacterBody3D
class_name Character

# Constantes del script.
const MAX_JUMPS := 2

# Propiedades publicas | Gravidad y velocidad.
@export var speed := 14
@export var fall_acceleration := 48
@export var jump_impulse := 25
@export var init_looking_at_right : bool = false


# Propiedades publicas | Materiales y malla
@export var material : Material = null
@export var mesh : Mesh = null

# Propiedades privadas | Movimientos
var _move_left: bool = false
var _move_right: bool = false
var _move_up: bool = false
var _move_down: bool = false
var _jump: bool = false
var _attack: bool = false
var _power_attack: bool = false

# Propiedades privadas | Velocidad y salto
var _direction = Vector3(0.0, 0.0, 0.0)
var _target_velocity = Vector3.ZERO
var _jump_count = 0
var _was_jumping = false
var _air_count = 0
var _fall_acceleration_multiplier = 1

# Clase interna, para movimientos de pelea
class FightMove extends RefCounted:
	var name: StringName
	var duration: float
	var damage: int
	var stop_horizontal_move: bool
	var stop_vertical_move: bool
	var speed: Vector3
	var air_attack : bool
	
	func _init(
		p_name: StringName, p_duration: float, p_damage: int, 
		p_stop_horizontal_move: bool, p_stop_vertical_move: bool, p_speed: Vector3, p_air_attack
	):
		name = p_name
		duration = p_duration
		damage = p_damage
		stop_horizontal_move = p_stop_horizontal_move
		stop_vertical_move = p_stop_vertical_move
		speed = p_speed
		air_attack = p_air_attack

# Clase interna de atackes disponibles
class Attacks extends RefCounted:
	# name, duration, damage, stop x move, stop y move, speed 3d, air_attack
	var neutral := FightMove.new(
		"neutral", 0.1, 5, true, false, Vector3(0,0,0), false
	)
	var dash := FightMove.new(
		"dash", 0.3, 10, true, false, Vector3(20,0,0), false
	)
	var crouch := FightMove.new(
		"crouch", 0.2, 5, true, false, Vector3(0,0,0), false
	)
	
	var neutral_air := FightMove.new(
		"neutral_air", 0.4, 5, false, false, Vector3(0,0,0), true
	)
	var air_move := FightMove.new(
		"air_move", 0.3, 10, false, false, Vector3(0,0,0), true
	)
	var air_down := FightMove.new(
		"air_down", 0.3, 10, false, false, Vector3(0,0,0), true
	)

# Propiedades privadas ataques	
var _attack_count = 0
var _current_attack = null
var _attacks = Attacks.new()

# Funciones
func _get_initial_facing() -> Vector3:
	if init_looking_at_right:
		return Vector3.RIGHT
	else:
		return Vector3.LEFT

func _set_material( m: Material ) -> void:
	'''
	Establecer material al jugador.
	Aunque preferiblemente sea nomas color. 
	Pero por ahroa, asi ta bien.
	'''
	if material != null:
		$Pivot/Mesh.material_override = m

func _set_mesh( m: Mesh ) -> void:
	'''
	Establecer malla nueva
	'''
	if m != null:
		$Pivot/Mesh.mesh = m

func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Cambiar el color del character
	_set_mesh(mesh)
	_set_material(material)
	
	# Establecer direccion de vista inicial.
	$Pivot.basis = Basis.looking_at( _get_initial_facing() )

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
	
func _vertical_force(delta: float, multiplier: float = 1) -> Dictionary:
	'''
	Fuerza vertical. Imitación de gravidad. Estilo 2d.
	'''
	var on_floor := is_on_floor()
	if on_floor:
		# Contadores a cero, para que no se acumule fuerza vertcal.
		_target_velocity.y = 0
		_air_count = 0
	else:
		# Acumular fuerza vertical, y contar tiempo en el aire.
		_target_velocity.y -= (fall_acceleration * multiplier) * delta
		_air_count += 1
	return {
		"air_count": _air_count,
		"on_floor": on_floor,
		"force": _target_velocity.y
	}
	

func _move(delta: float, vertical_force_signals: Dictionary) -> Dictionary:
	'''
	Movimientos. 
	Si esta atacando, ya no se puede saltar ni mover. El ataque sobreescribe ello.
	Retorna señales de movimientos.
	'''
	# No mover si esta atacando en piso.
	var attacking = _current_attack != null
	var horizontal_move := true
	if (attacking):
		horizontal_move = _current_attack.stop_horizontal_move == false
	
	# Variables necesarias
	var on_floor = vertical_force_signals["on_floor"]
	var is_jumping := (_jump or _move_up)
	var jump_pressed := is_jumping and not _was_jumping
	_was_jumping = is_jumping
	
	if horizontal_move:
		_direction = _get_move_direction()
	
	# Gravedad desender mas rapido
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
	
	# Normal move
	var moving = direction.x != 0.0
	var jumping = tv.y > 0
	var falling = not jumping and not on_floor
	
	# On floor fight
	var neutral = (on_floor and not moving) and (not _move_up and not _move_down)
	var running = on_floor and moving
	var neutral_crouch = (on_floor and not moving) and _move_down
	
	# On air fight
	var neutral_air = (not on_floor and not moving) and (not _move_up and not _move_down)
	var air_move = not on_floor and moving
	var air_down = not on_floor and _move_down
	
	return {
		# Normal move
		"moving": moving,
		"jumping": jumping,
		"falling": falling,
		
		# On floor fight
		"neutral": neutral,
		"running": running,
		"neutral_crouch": neutral_crouch,
		
		# On air fight
		"neutral_air": neutral_air,
		"air_move": air_move,
		"air_down": air_down,
	}

func _fight(delta: float, states: Dictionary):
	'''
	Este evento sobrepaza el move. 
	Si es necesario deja inoovil al player (para terminar ataque correctamente). Tambien sobrescribe estados.
	Se puede hacer modificando `_target_velocity.x` a cero. Y states a false o true segun el caso.
	'''
	if _attack and _current_attack == null:
		# On floor attack
		var init_attack = true
		if states["neutral"]:
			_current_attack = _attacks.neutral
		elif states["running"]:
			_current_attack = _attacks.dash
		elif states["neutral_crouch"]:
			_current_attack = _attacks.crouch
		
		# On air attack
		elif states["neutral_air"]:
			_current_attack = _attacks.neutral_air
		elif states["air_down"]:
			_current_attack = _attacks.air_down
		elif states["air_move"]:
			_current_attack = _attacks.air_move
		else:
			init_attack = false
		
		if init_attack:
			_attack_count = 0
		
	# Hacer ataque, esperando lo que dure, y haciendo que no se mueva el player si es necesario.
	if _current_attack != null:
		print(_current_attack.name)
		
		# Movimiento a al tacar atacar
		if _current_attack.stop_horizontal_move:
			states["running"] = false
			_target_velocity.x = _current_attack.speed.x * _direction.x
		if _current_attack.stop_vertical_move:
			_target_velocity.y = _current_attack.speed.y * _direction.y
			
		if _attack_count >= _current_attack.duration:
			_current_attack = null
		else:
			_attack_count += delta

func _anim(delta: float, states: Dictionary, direction: Vector3) -> void:
	'''
	Animaciones.
	Si son de movimeinto pos chido, pero si son de atacke sobrepesar las de movimiento.
	'''
	# Movimientos de pelea
	if _current_attack != null:
		$AnimationPlayer.stop()
		if _current_attack.name == "neutral":
			$Pivot/Mesh.rotation_degrees.x = -20
		elif _current_attack.name == "dash":
			$Pivot/Mesh.rotation_degrees.x = 60
			$Pivot/Mesh.position.y = -0.3
		elif _current_attack.name == "crouch":
			$Pivot/Mesh.rotation_degrees.x = 85
			$Pivot/Mesh.position.y = -0.5
		elif _current_attack.name == "neutral_air":
			$Pivot/Mesh.rotation_degrees.x = 45
		elif _current_attack.name == "air_move":
			$Pivot/Mesh.rotation_degrees.x = 90
		elif _current_attack.name == "air_down":
			$Pivot/Mesh.rotation_degrees.x = 0
	
	else:
		# Animacion | Movimiento en el piso
		if states["neutral"]:
			$Pivot/Mesh.rotation.x = 0
		if states["running"]:
			if not $AnimationPlayer.is_playing():
				$AnimationPlayer.play("run")
		else:
			$AnimationPlayer.stop()

		# Animacion | Salto
		if states["jumping"]:
			$Pivot/Mesh.rotation.x = -50
		elif states["falling"]:
			$Pivot/Mesh.rotation.x = 50
		
	# Animación | Mover direccion visual del player.
	if states["moving"]:
		$Pivot.basis = Basis.looking_at(direction)

func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas.
	'''
	_collect_input()
	var gravity_signals = _vertical_force(delta, _fall_acceleration_multiplier)
	var move_signals = _move(delta, gravity_signals)
	var move_states = _get_move_states(move_signals)
	_fight(delta, move_states)
	_anim(delta, move_states, move_signals["direction"])
	
	# Procesar todo
	velocity = _target_velocity
	move_and_slide()
	
	# Debug
	'''
	var move_states_text = ""
	for key in move_states.keys():
		move_states_text += "- {key}: {value}\n".format(
			{"key":key, "value": move_states[key]}
		)
	print(
		"Instance ID: {id}\n".format({"id": get_instance_id()}) , move_states_text
	)
	'''
