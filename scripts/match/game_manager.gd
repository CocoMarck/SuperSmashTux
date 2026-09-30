class_name GameManager
extends Node

'''
No valida nada, esta bien que de crash si el mapa no esta bien construido.

- Agrega la camara de juego. CameraFollow.
- Detecta cuando se mueren los peleadores.
- Tiene las coordenadas de spawneo.
- Determina y gestiona las vidas de los peleadores.
- Spawnea los peleadores.
- Le da igual los Player, solo le importan los PowerFighter.
- Nada de manejo de cámaras o algo asi, eso si no. Eso es trabajo de la cámara.

Tiene de dependencias, esto:
- PlayArea: Area3D, con hijo CollisionShape3D, BoxShape3D

GameManager es dependencia de Camera.
'''

# Constantes | Materiales fijos para los luchadores
const SLOT_1_MATERIAL: Material = preload("res://materials/mat_red.tres")
const SLOT_2_MATERIAL: Material = preload("res://materials/mat_blue.tres")
const SLOT_3_MATERIAL: Material = preload("res://materials/mat_yellow.tres")
const SLOT_4_MATERIAL: Material = preload("res://materials/mat_green.tres")

# Propiedades publicas | Configuración de partida.
@export_group("Match Settings")
@export_range(1, 99, 1) var lives_per_character: int = 3
@export_range(0.0, 5.0, 0.05) var respawn_delay: float = 1.0   # segundos de espera antes de reaparecer

# Propiedades privadas | Estado por personaje.
# Aca probablemente mejor usar una clase, en vez de varios diccionarios.
var _spawn_point_of_power_fighter: Dictionary[PowerFighter, SpawnPoint] = {}
var _lives_of_power_fighter: Dictionary[PowerFighter, int] = {}
var _death_position_of_power_fighter: Dictionary[PowerFighter, Vector3] = {} # El death position, se usara para hacer efectos gráficos. Por ahora esta sin uso.

# Propiedades privadas | Dependencias, lo que tiene que tener el mapa.
var _play_area: Area3D
var _play_area_collision_shape : CollisionShape3D
var _play_area_box : BoxShape3D
var _play_area_bounds: AABB = AABB()
var _spawn_point1: SpawnPoint
var _spawn_point2: SpawnPoint
var _spawn_point3: SpawnPoint
var _spawn_point4: SpawnPoint

# Propiedades privadas, relacionadas con la camera.
var _camera_follow: CameraFollow

# Funciones
func _get_spawn_points() -> Array[SpawnPoint]:
	return [_spawn_point1, _spawn_point2, _spawn_point3, _spawn_point4]

func _get_all_materials() -> Array[Material]:
	return [SLOT_1_MATERIAL, SLOT_2_MATERIAL, SLOT_3_MATERIAL, SLOT_4_MATERIAL]

func _spawn_all_power_fighters() -> void:
	'''
	Spawnear a todos los personajes de la partida, sacando el numero de.
	'''
	var spawn_points = _get_spawn_points()
	for i in range(0, spawn_points.size()):
		# Instanciar, establecer posición, y meter script. (Esto lo debe hacer spawn point)
		var spawn_point = spawn_points[i]
		var power_fighter : PowerFighter
		if i == 0 or i == 1:
			power_fighter = spawn_point.spawn( GlobalUtils.CharacterType.PLAYER, i )
		else:
			power_fighter = spawn_point.spawn( GlobalUtils.CharacterType.NPC, i )
		power_fighter.material = _get_all_materials()[i]
		# Establecer spawn fijo.
		_spawn_point_of_power_fighter[power_fighter] = spawn_point
		_lives_of_power_fighter[power_fighter] = lives_per_character
		# Agregar al mapa
		add_child(power_fighter)

func _get_area_bounds() -> AABB:
	'''
	AABB en coordenadas del mundo de la caja de un area, sacada de su BoxShape3D.
	'''
	var half := _play_area_box.size * 0.5 * _play_area_collision_shape.global_basis.get_scale()
	return AABB(_play_area_collision_shape.global_position - half, half * 2.0)

func _forget_power_fighter(power_fighter: PowerFighter) -> void:
	'''
	Olvidar por completo los datos relacionados con un power fighter que ya no existe.
	'''
	_spawn_point_of_power_fighter.erase(power_fighter)
	_lives_of_power_fighter.erase(power_fighter)
	_death_position_of_power_fighter.erase(power_fighter)

func _handle_power_fighter_death(power_fighter: PowerFighter) -> void:
	'''
	Un personaje se salio del area jugable. Si le quedan vidas, se sace del arbol de inmediato. See quita de la scene. Se queda la instncia. Delay al morir, despes respawn. Si no le quedan vidas, se purga de la scene.
	'''
	_camera_follow.shake( 500 )
	_lives_of_power_fighter[power_fighter] -= 1
	# Debug
	print("%s: morido por la patria vidas; %d" % [_get_power_fighter_label(power_fighter), _lives_of_power_fighter[power_fighter]])
	# Si se ya no tiene vidas, adios.
	if _lives_of_power_fighter[power_fighter] == 0:
		power_fighter.queue_free()
		_forget_power_fighter(power_fighter)
		return
	# Obtener posición de muerte, y quetarlo de la vista del scene.
	var parent := power_fighter.get_parent()
	if parent != null:
		_death_position_of_power_fighter[power_fighter] = power_fighter.global_position
		parent.remove_child(power_fighter)
	# Inicalizar spawn con delay
	if respawn_delay > 0.0:
		await get_tree().create_timer(respawn_delay).timeout
	# Respawn a la scene, solo si existe la instancia del power fighter
	if not is_instance_valid(power_fighter):
		return
	add_child(power_fighter)
	power_fighter.respawn( _spawn_point_of_power_fighter[power_fighter].global_position )
	_death_position_of_power_fighter.erase(power_fighter)

func _get_power_fighter_label(power_fighter: PowerFighter) -> String:
	if power_fighter is Player:
		var player_id: int = (power_fighter as Player).player_id
		return power_fighter.name + str(GlobalUtils.PlayerId.keys()[player_id])
	return power_fighter.name

# Funciones | Gestionar vidas
func _ready() -> void:
	# Establecer propiedades dependencia
	_play_area = $PlayArea
	_play_area_collision_shape = $PlayArea/CollisionShape3D
	_play_area_box = _play_area_collision_shape.shape as BoxShape3D
	_play_area_bounds = _get_area_bounds()
	_spawn_point1 = $SpawnPoint1
	_spawn_point2 = $SpawnPoint2
	_spawn_point3 = $SpawnPoint3
	_spawn_point4 = $SpawnPoint4
	# Camera
	_camera_follow = CameraFollow.new(_play_area, null)
	_camera_follow.camera_area = _play_area
	add_child(_camera_follow)
	# Debug
	if _play_area_bounds.size == Vector3.ZERO:
		# Play_area sin configurar; no se detectaran muertes
		push_warning("GameManager: fail open no fail-closed. No detect play area bounds")
	# Spawneo
	_spawn_all_power_fighters()

func _physics_process(delta: float) -> void:
	'''
	Es un physics process, para no perder data de físicas. Como salir de una área 3d. Pero también funcionaria con un simple process.
	'''
	for power_fighter in _lives_of_power_fighter.keys():
		# Si no es instancia valida, forzar olvidar todos sus datos. El handle death, ya lo olvida. Este es verificador.
		if not is_instance_valid(power_fighter):
			_forget_power_fighter(power_fighter)
			continue
		# Si esta recien spawneado, o recien muerto (esperando su respawn_delay, fuera del arbol. Se salte este frame nomas, sigue registrando y se revisa en cuanto vuelva al arbol
		if not power_fighter.is_inside_tree():
			continue
		# Detactar que este fuera del area de juego.
		if not _play_area_bounds.has_point(power_fighter.global_position):
			_handle_power_fighter_death(power_fighter)
		
