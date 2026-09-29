class_name NewGameManager
extends Node

'''
No valida nada, esta bien que de crash si el mapa no esta bien construido.

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

# Constantes | Para spawnear
const POWER_FIGHTER_PREFAB = preload("res://prefabs/standard_power_fighter.tscn")
const POWER_FIGHTER_SCRIPT = preload("res://scripts/power_fighter.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const NPC_SCRIPT = preload("res://scripts/npc.gd")

# Propiedades publicas | Configuración de partida.
@export_group("Match Settings")
@export_range(1, 99, 1) var lives_per_character: int = 3
@export_range(0.0, 5.0, 0.05) var respawn_delay: float = 0.3   # segundos de espera antes de reaparecer

# Propiedades privadas | Estado por personaje.
var _spawn_point_of_character: Dictionary[PowerFighter, SpawnPoint] = {}
var _lifes_of_power_fighter: Dictionary[PowerFighter, int] = {}

# Propiedades privadas | Dependencias, lo que tiene que tener el mapa.
var _play_area: Area3D
var _play_area_collision_shape : CollisionShape3D
var _play_area_box : BoxShape3D
var _play_area_bounds: AABB = AABB()
var _spawn_point1: SpawnPoint
var _spawn_point2: SpawnPoint
var _spawn_point3: SpawnPoint
var _spawn_point4: SpawnPoint

# Funciones
func _get_spawn_points() -> Array[SpawnPoint]:
	return [_spawn_point1, _spawn_point2, _spawn_point3, _spawn_point4]

func _get_all_materials() -> Array[Material]:
	return [SLOT_1_MATERIAL, SLOT_2_MATERIAL, SLOT_3_MATERIAL, SLOT_4_MATERIAL]

func _spawn_all_characters() -> void:
	'''
	Spawnear a todos los personajes de la partida, sacando el numero de.
	'''
	var spawn_points = _get_spawn_points()
	for i in range(0, spawn_points.size()):
		# Instanciar, establecer posición, y meter script. (Esto lo debe hacer spawn point)
		var spawn_point = spawn_points[i]
		var power_fighter = POWER_FIGHTER_PREFAB.instantiate()
		if i == 0 or i == 1:
			# Forzar poner players en primeros dos spawn points.
			power_fighter.set_script(PLAYER_SCRIPT)
			power_fighter.player_id = i
		else:
			#power_fighter.set_script(POWER_FIGHTER_SCRIPT)
			power_fighter.set_script(NPC_SCRIPT)
		power_fighter.material = _get_all_materials()[i]
		power_fighter.position = spawn_point.global_position
		power_fighter.init_looking_at_right = spawn_point.init_looking_at_right
		# Establecer spawn fijo.
		_spawn_point_of_character.assign({power_fighter: spawn_point})
		_spawn_point_of_character.assign({power_fighter: lives_per_character})
		# Agregar al mapa
		add_child(power_fighter)

func _get_area_bounds() -> AABB:
	'''
	AABB en coordenadas del mundo de la caja de un area, sacada de su BoxShape3D.
	'''
	var half := _play_area_box.size * 0.5 * _play_area_collision_shape.global_basis.get_scale()
	return AABB(_play_area_collision_shape.global_position - half, half * 2.0)

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
	# Debug
	if _play_area_bounds.size == Vector3.ZERO:
		# Play_area sin configurar; no se detectaran muertes
		push_warning("GameManager: fail open no fail-closed. No detect play area bounds")
	# Spawneo
	_spawn_all_characters()

# Funciones | Gestionar vidas
func _physics_process(delta: float) -> void:
	'''
	Es un physics process, para no perder data de físicas. Como salir de una área 3d. Pero también funcionaria con un simple process.
	'''
	for power_fighter in _lifes_of_power_fighter.keys():
		continue
