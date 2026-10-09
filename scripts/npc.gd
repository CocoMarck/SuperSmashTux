class_name NPC
extends PowerFighter

'''
No player controller

# Recovery
- Cuando el NPC detecta esta en el aire y detecta una plataforma cercana, intentara llegar a ella.

- Objetos. Detectar posiciones, primeramente el x y z base, Pero tambien el de la otra punta, el x y z, mas las dimensiones del objeto. Así se contempla de mejor manera la realidad de las posiciones disponibles.
'''

# NPC Enums
enum NPCIntention { # Intención de NPC
	IDLE, RUN, WALK, CROUCH, TURBO_JUMP, SINGLE_JUMP, DOUBLE_JUMP
}

# NPC
var _try_recovery = false
var _npc_horizontal_move = true
var _pin_left = true
var _pin_right = false
var _pin_down = false
var _pin_walk = false

# Rango de vista del NPC.
var _detection_area : Area3D
var _detection_counter : float = 0
var _detection_interval: float = 0.1

# Detección de objetos
var _detected_platforms : Array[Platform] = []

# Timer cambio de dirección horizontal aleatoria.
var _invert_horizontal_direction_intervals : Array[float] = [5.0, 3.0, 1.0]
var _count_invert_horizontal_direction : float = 0.0

# Timer cambio de velocidad aleatoria.
var _change_speed_intervals: Array[float] = [5.0, 4.0, 3.0]
var _count_change_speed : float = 0.0
var _speeds : Array[NPCIntention] = [
	NPCIntention.IDLE, NPCIntention.RUN, NPCIntention.WALK, NPCIntention.CROUCH]

# Timer saltos aleatoreos
var _jump_intervals : Array[float] = [8.0, 5.5, 4.2]

# Saltos interminables
var _turbo_jump: bool = false
var _count_jump_frames: int = 0

# Funciones | Apariencia.
func _get_default_material() -> Material:
	'''
	Material propio de los NPC.
	'''
	return GlobalUtils.NPC_MATERIAL

# Funciones | Detección de objetos
func check_nearby_objects(delta: float) -> void:
	# Solo checar si esta en el intervalo
	_detection_counter += delta
	if _detection_counter < _detection_interval:
		return
	_detection_counter = 0
	
	# Obtener bodies
	var bodies := _detection_area.get_overlapping_bodies()

	# Agregar lo que se detecte
	_detected_platforms.clear()
	for body in bodies:
		#print("Detectado: ", body.name)
		if (
			is_instance_valid(body) and (body is Platform) ):
			_detected_platforms.append(body)

# Funciones | Normalizar datos
func get_nodes_positions(nodes: Array[Node3D]) -> Array[Vector3]:
	var positions :Array[Vector3] = []
	for obj in nodes:
		positions.append(obj.global_position)
	return positions

func get_position_average_difference(position1: Vector3, position2: Vector3) -> float:
	'''Obtener diferencia entre dos posiciones'''
	# Saber cual es la pos max, y cual es la min
	var max_position :Vector3 = Vector3(
		max(position1.x, position2.x), max(position1.y, position2.y), max(position1.z, position2.z) )
	var min_position :Vector3 = Vector3(
		min(position1.x, position2.x), min(position1.y, position2.y), min(position1.z, position2.z) )
	
	# Obtener diferencia promedio. Si no hay diferencia, retornar cero, para no dividir cero.
	var x_difference :float = max_position.x - min_position.x
	var y_difference :float = max_position.y - min_position.y
	var z_difference :float = max_position.z - min_position.z
	var addition :float = (x_difference + y_difference + z_difference)
	if addition <= 0.0:
		return 0.0
	return (addition) / 3

func get_nearest_position(positions: Array[Vector3]) -> Vector3:
	'''
	Determina con el global position, la diferencia promedio entre varias posiciones. Y retorna la posición mas cercana.
	'''
	# Obtener diferencias
	var average_differences :Array[float] = []
	for position in positions:
		var difference :float = get_position_average_difference(global_position, position)
		average_differences.append(difference)
	
	var index_nearest_position: int = 0
	var min_difference :float = average_differences.min()
	for index in range(0, average_differences.size()):
		if average_differences[index] == min_difference:
			index_nearest_position = index
			break
	
	# Retornar la plataforma mas cercana
	return positions[index_nearest_position]

# Funciones | Detección por tipo de objeto
func get_nearest_platform_position() -> Vector3:
	'''
	Obtener la posición de la plataforma mas cercana con respecto al NPC.
	'''
	# Obtrener posiciones de plataformas
	var nodes : Array[Node3D] = []
	for node in _detected_platforms:
		nodes.append( node as Node3D )
	var positions :Array[Vector3] = get_nodes_positions(nodes)
	
	# Obtener diferencias
	return get_nearest_position(positions)

func directional_orientation_relative_to_oneself(target_position: Vector3) -> Vector3:
	var direction :Vector3 = Vector3.ZERO
	if global_position.x > target_position.x:
		direction.x = -1.0
	elif global_position.x < target_position.x:
		direction.x = 1.0
	if global_position.y > target_position.y:
		direction.y = -1.0
	elif global_position.y < target_position.y:
		direction.y = 1.0
	return direction

# Funciones | Cambios aleatoreos, para que no sea predecible
func _get_random_directional_interval() -> float:
	return _invert_horizontal_direction_intervals[
		randi() %_invert_horizontal_direction_intervals.size() ]

func _get_random_speed_interval() -> float:
	return _change_speed_intervals[ randi() %_change_speed_intervals.size() ]

func _get_random_speed_state() -> NPCIntention:
	return _speeds[ randi() %_speeds.size() ]

# Funciones movimiento AI
func _invert_horizontal_move():
	if _pin_left:
		_pin_right = true
		_pin_left = false
	elif _pin_right:
		_pin_left = true
		_pin_right = false

func _random_horizontal_move(delta: float):
	# Movimiento horizontal aleatoreo
	if _count_invert_horizontal_direction >= _get_random_directional_interval():
		_count_invert_horizontal_direction = 0.0
		_invert_horizontal_move()
	_count_invert_horizontal_direction += delta

func _random_speed_move(delta: float):
	if _count_change_speed >= _get_random_speed_interval():
		_count_change_speed = 0.0
		var state :NPCIntention = _get_random_speed_state()
		_npc_horizontal_move = true
		_pin_down = false
		_pin_walk = false
		match state:
			NPCIntention.IDLE:
				_npc_horizontal_move = false
			NPCIntention.RUN:
				_pin_walk = false
			NPCIntention.WALK:
				_pin_walk = true
			NPCIntention.CROUCH:
				_pin_down = true
	_count_change_speed += delta

func _collect_input() -> void:
	# Esto sucede primero que el `_process_ai()` en person.
	_move_left = false
	_move_right = false
	_move_up = false
	_move_down = false
	_jump = false
	_walk = false
	_power_attack = false
	_attack = false

func _calcule_max_jump_height_frames(fall_acceleration: float, impulse: float) -> int:
	'''
	> Basado en funcionamiento de GravityBody3D

	Cada que esta en el aire, se acumula el fall aceleración, imitando la gravedad. Si no esta en el aire no se acumula. 

	Por lo que se debe determinar hasta cuando se alcanza la altura maxima de un salto dependiendo de la fuerza de gravedad, y el impulso.

	Es un aproximado de, porque no recive delta, ya que delta depende de que el calculo, se haga en tiempo de juego, y así no sirve.
	
	Se espera que el fall acceleration, no sea mayor que impulse, o si no no jala. Se espera algo asi de paremetros: 0.4, 10.

	De hecho es hasta realista, porque ni el jugador sabe el tiempo exacto para saltar.
	'''
	var frames :int = 0
	var vertical_force: float = -impulse
	var is_zero :bool = vertical_force < fall_acceleration
	while is_zero:
		vertical_force += fall_acceleration
		is_zero = vertical_force < fall_acceleration
		frames += 1
	return frames

# Funciones | Procesar AI
func _process_ai(delta: float, frame: FrameMotionSignals):
	'''
	Recomendado hacer esto modular, por ahora puede ser súper monolítico.
	'''
	# En person sucede primero el `_collect_input()`

	# Detectar objetos mas que entraron al area y trabajar con ello.
	check_nearby_objects(delta)

	# Validar que existan datos para el NPC
	if frame == null:
		return
	
	# Mover NPC
	if not frame.vertical_force_signals.on_floor and not _try_recovery:
		_try_recovery = true
	if _try_recovery and frame.vertical_force_signals.on_floor:
		_try_recovery = false
	
	if _try_recovery and _detected_platforms.size() > 0:
		var nearest_platform_position :Vector3 = get_nearest_platform_position()
		var direction :Vector3 = directional_orientation_relative_to_oneself(
			nearest_platform_position)
		_turbo_jump = false
		if direction.x == 1.0:
			_pin_left = false
			_pin_right = true
		elif direction.x == -1.0:
			_pin_left = true
			_pin_right = false
		if direction.y == 1.0:
			_turbo_jump = true
		#print("Posición de plataforma mas cercana: ", nearest_platform_position)
	
	# Cambio de direccion y velocidad aleatorio.
	if not _try_recovery:
		_random_horizontal_move(delta)
		_random_speed_move(delta)
	
	# Commit movimiento horizonal
	if _npc_horizontal_move or _try_recovery:
		# Mover, ya sea izq o der. No ambos.
		if not (_pin_left and _pin_right):
			_move_left = _pin_left
			_move_right = _pin_right

	# Commit movimiento vertical
	if _turbo_jump and _try_recovery:
		# Salto en el piso.
		if frame.vertical_force_signals.on_floor:#and _jump_count == 0:
			_jump = true
			_count_jump_frames = 0
		# Los demas saltos
		var reached_max_jumps :bool = _jump_count >= _max_jumps
		if _jump == false or reached_max_jumps:
			var frames :int = _calcule_max_jump_height_frames(fall_acceleration*delta, jump_impulse)
			#var short_time_in_the_air :bool = frame.vertical_force_signals.air_count <= delta
			#print(frames)
			if (_count_jump_frames >= frames):
				if reached_max_jumps:
					_move_up = true
					_power_attack = true
					_count_jump_frames = 0
				else:
					_jump = true
					_count_jump_frames = 0
		# Contar frames de salto.
		_count_jump_frames += 1
	if _pin_down and not _turbo_jump: # Pioridad a salto
		_move_down = true

	# Commit velocidad
	if not _try_recovery:
		if _pin_walk:
			_walk = true
		
# Inicializar area de detección/vista de NPC
func _ready():
	super()

	# Instancear Detection area
	_detection_area = Area3D.new()
	_detection_area.name = "DetectionArea"
	add_child(_detection_area)

	# Detection area | collision shape
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16.0, 9.0, 0.5)

	collision.shape = box
	_detection_area.add_child(collision)

	# Detection area | Lo visible
	var mesh_instance := MeshInstance3D.new()

	var mesh := BoxMesh.new()
	mesh.size = box.size

	mesh_instance.mesh = mesh
	_detection_area.add_child(mesh_instance)

	# Detection area | Material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 1.0, 0.5, 0.05)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mesh_instance.material_override = material
