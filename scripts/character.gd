extends CharacterBody3D
class_name Character

# Constantes del script.
const MAX_JUMPS := 2
const HITBOX_SCENE := preload("res://prefabs/hitbox.tscn")
const HITBOX_LIFETIME := 0.1

# Propiedades publicas | Gravedad y velocidad.
@export_group("Movimiento")
@export var speed: int = 18
@export var fall_acceleration: int = 48
@export var jump_impulse: int = 25
@export var init_looking_at_right: bool = false

# Propiedades publicas | Apariencia
@export_group("Apariencia")
@export var material: Material = null
@export var mesh: Mesh = null

# Propiedades privadas | Movimientos
var _move_left: bool = false
var _move_right: bool = false
var _move_up: bool = false
var _move_down: bool = false
var _jump: bool = false
var _attack: bool = false
var _power_attack: bool = false

# Propiedades privadas | Velocidad y salto
var _direction: Vector3 = Vector3.ZERO
var _target_velocity: Vector3 = Vector3.ZERO
var _jump_count: int = 0
var _was_jumping: bool = false
var _air_count: int = 0
var _fall_acceleration_multiplier: float = 1.0

# Propiedades privadas | Hitbox daño a los enemigos locos.
var _hitbox_count: float = 0.0
var _spawned_hitbox: Area3D = null

# Propiedades privadas | Ataques
var _attack_count: float = 0.0
var _current_attack: FightMove = null
var _attacks: Attacks = Attacks.new()

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Cambiar el color del character
	_set_mesh(mesh)
	_set_material(material)

	# Establecer direccion de vista inicial.
	$Pivot.basis = Basis.looking_at(_get_initial_facing())

# Funciones | Procesamiento de físicas.
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

# Funciones de apariencia
func _get_initial_facing() -> Vector3:
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
	if material != null:
		$Pivot/Mesh.material_override = m

func _set_mesh( m: Mesh ) -> void:
	'''
	Establecer malla nueva
	'''
	if m != null:
		$Pivot/Mesh.mesh = m

# Funciones hitbox de ataque.
func _spawn_hitbox(position: Vector3) -> void:
	_spawned_hitbox = HITBOX_SCENE.instantiate()
	var fixed_position := Vector3(position.z, position.y, position.x*-1)
	_spawned_hitbox.position = fixed_position
	$Pivot.add_child(_spawned_hitbox)
	_spawned_hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node3D):
	# Esto lo debe hacer el hitbox. Fucnion del hitbox prefab
	if body is Character and body != self:
		print(body.name, " recibio trancazo")

func _clear_hitbox() -> void:
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
	
func _vertical_force(delta: float, multiplier: float = 1) -> Dictionary:
	'''
	Fuerza vertical. Imitación de gravedad. Estilo 2d.
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
	
	# Gravedad descender mas rapido
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

func _fight(delta: float, states: Dictionary) -> void:
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
			_clear_hitbox()
			_spawn_hitbox(_current_attack.hitbox_position)
			_current_attack = null
		else:
			_attack_count += delta
			_hitbox_count = 0
	if _spawned_hitbox != null:
		_hitbox_count += delta
		if _hitbox_count >= HITBOX_LIFETIME:
			_clear_hitbox()

func _anim(delta: float, states: Dictionary, direction: Vector3) -> void:
	'''
	Animaciones.
	Si son de movimeinto pos chido, pero si son de atacke sobrepesar las de movimiento.
	'''
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
