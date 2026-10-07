class_name NPC
extends PowerFighter

'''
No player controller

# Recovery
- Cuando el NPC detecta esta en el aire y detecta una plataforma cercana, intentara llegar a ella.
'''

# NPC
var _try_recovery = false
var _invert_pin = false
var _npc_horizontal_move = true
var _pin_left = true
var _pin_right = false

# Rango de vista del NPC.
var _detection_area : Area3D
var _detection_counter : float = 0
var _detection_interval: float = 0.1

# Detección de objetos
var _detected_platforms : Array[Platform] = []

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

# Funciones | Apariencia.
func _get_default_material() -> Material:
	'''
	Material propio de los NPC.
	'''
	return GlobalUtils.NPC_MATERIAL

# Funciones | Procesar AI
func _process_ai(delta: float, frame: FrameMotionSignals):
	'''
	Recomendado hacer esto modular, por ahora puede ser súper monolítico.
	'''
	# Detectar objetos mas que entraron al area y trabajar con ello.
	check_nearby_objects(delta)
	if _detected_platforms.size() > 0:
		var nearest_platform_position = get_nearest_platform_position()
		print("Posición de plataforma mas cercana: ", nearest_platform_position)

	# Todavia no tiene movimiento horizontal, solo salta en su lugar.
	_move_left = false
	_move_right = false
	_move_up = false
	_move_down = false
	_attack = false
	_jump = false
	_move_down = false

	# Validar que existan datos para el NPC
	if frame == null:
		return
	
	# Mover NPC
	_invert_pin = false
	if not frame.vertical_force_signals.on_floor and not _try_recovery:
		_invert_pin = true
		_try_recovery = true
		_jump = true
	if _try_recovery and frame.vertical_force_signals.on_floor:
		_try_recovery = false
		_attack = true
		

	if _npc_horizontal_move:
		# Invertir dirección
		if _invert_pin:
			if _pin_left:
				_pin_right = true
				_pin_left = false
			elif _pin_right:
				_pin_left = true
				_pin_right = false
		# Mover, ya sea izq o der. No ambos.
		if not (_pin_left and _pin_right):
			_move_left = _pin_left
			_move_right = _pin_right
			
	if frame.vertical_force_signals.on_floor:
		_jump = false
		
# Funciones | Probablemente no se use
func _collect_input() -> void:
	pass

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
	material.albedo_color = Color(0.0, 1.0, 0.0, 0.075)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mesh_instance.material_override = material
