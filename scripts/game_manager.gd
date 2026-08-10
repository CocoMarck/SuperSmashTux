class_name GameManager
extends Node

# Encargado de armar la partida: cuantos personajes salen, de que tipo, cuantas vidas trae cada quien,
# y de vigilar que nadie se salga del area jugable pa respawnearlo o eliminarlo.

# Constantes | Materiales fijos pa los numeros 3 y 4 de la partida.
const SLOT_3_MATERIAL: Material = preload("res://materials/mat_yellow.tres")
const SLOT_4_MATERIAL: Material = preload("res://materials/mat_green.tres")

# Propiedades publicas | Configuracion de partida.
@export_group("Match Settings")
@export var character_types: Array[GlobalUtils.CharacterType] = [
	GlobalUtils.CharacterType.PLAYER, GlobalUtils.CharacterType.PLAYER,
]
@export_range(1, 99, 1) var lives_per_character: int = 3

# Propiedades publicas | Referencias de escena.
@export_group("Scene References")
@export var spawn_points: Array[SpawnPoint] = []
@export var play_area: Area3D

# Propiedades privadas | Estado por personaje.
var _spawn_point_of_character: Dictionary[Character, SpawnPoint] = {}
var _lives_of_character: Dictionary[Character, int] = {}
var _death_count_of_character: Dictionary[Character, int] = {}
var _npc_id_of_character: Dictionary[Character, GlobalUtils.NPCId] = {}
var _play_area_bounds: AABB = AABB()

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Calcular los limites del area jugable y spawnear a todo mundo.
	'''
	_play_area_bounds = _get_area_bounds(play_area)
	if _play_area_bounds.size == Vector3.ZERO:
		# Fail-open y no fail-closed: si el area quedo mal enlazada nomas se avisa y no se
		# detectan muertes, no se anda eliminando gente por un error de configuracion.
		push_warning("GameManager: play_area sin configurar; no se detectaran muertes.")
	_spawn_all_characters()

# Funciones | Procesamiento de fisicas.
func _physics_process(delta: float) -> void:
	'''
	Vigilar a cada personaje vivo y ver si se salio del area jugable.
	Se compara la posicion contra el AABB por polling, igualito que camera_follow.gd hace pa
	dejar de contar a alguien pal encuadre, asi los dos sistemas nunca se desincronizan.
	'''
	if _play_area_bounds.size == Vector3.ZERO:
		return
	for character in _lives_of_character.keys():
		# .keys() saca una copia del array de llaves, asi que borrar del diccionario aqui
		# adentro (via _forget_character o _handle_character_death) es seguro.
		if not is_instance_valid(character):
			_forget_character(character)
			continue
		if not character.is_inside_tree():
			# Recien spawneado, su add_child todavia esta diferido. Se salta este frame nomas,
			# sigue registrado y se revisa normal en cuanto entre al arbol.
			continue
		if not _play_area_bounds.has_point(character.global_position):
			_handle_character_death(character)

# Funciones propias.
func _get_used_player_numbers(requested_player_slots: int) -> Array[int]:
	'''
	Simular, sin spawnear nada, que numeros de PlayerId va a terminar usando la partida.
	Necesario pa saber que numeros los NPC no pueden repetirse, sin importar en que orden
	del arreglo character_types venga cada quien.
	'''
	var numbers: Array[int] = []
	for candidate_id in range(requested_player_slots):
		if GlobalUtils.PLAYER_INPUT_MAPS.has(candidate_id):
			numbers.append(candidate_id + 1)
	return numbers

func _spawn_all_characters() -> void:
	'''
	Spawnear a todos los personajes de la partida, sacando el numero de character_types.size()
	(sin limite forzado; si faltan SpawnPoint pa cubrirlos, esos slots se saltan), repartiendo
	los SpawnPoint en orden y asignando PlayerId consecutivos a los jugadores.
	'''
	var requested_player_slots := character_types.count(GlobalUtils.CharacterType.PLAYER)
	var forbidden_npc_numbers := _get_used_player_numbers(requested_player_slots)
	var next_player_id := 0
	var next_npc_id := 0
	var count := character_types.size()
	for i in range(count):
		if i >= spawn_points.size():
			push_warning("GameManager: falta SpawnPoint para el slot %d" % i)
			continue
		var spawn_point := spawn_points[i]
		var resolved_type := character_types[i]
		var resolved_player_id: GlobalUtils.PlayerId = GlobalUtils.PlayerId.PLAYER_1

		if resolved_type == GlobalUtils.CharacterType.PLAYER:
			var candidate_id: GlobalUtils.PlayerId = next_player_id
			next_player_id += 1
			if GlobalUtils.PLAYER_INPUT_MAPS.has(candidate_id):
				resolved_player_id = candidate_id
			else:
				# Si ya no hay mapa de input pa mas jugadores; este slot se cae a NPC.
				resolved_type = GlobalUtils.CharacterType.NPC

		var resolved_npc_id: GlobalUtils.NPCId = GlobalUtils.NPCId.NPC_1
		var has_npc_id := false
		if resolved_type == GlobalUtils.CharacterType.NPC:
			while forbidden_npc_numbers.has(next_npc_id + 1):
				next_npc_id += 1
			if next_npc_id < GlobalUtils.NPCId.keys().size():
				resolved_npc_id = next_npc_id
				has_npc_id = true
			else:
				push_warning("GameManager: se acabaron los NPCId disponibles pal slot %d" % i)
			next_npc_id += 1

		var character := spawn_point.spawn(resolved_type, resolved_player_id, spawn_point.init_looking_at_right)

		# Numero compartido de esta partida: 1/2 pa jugadores, o el npc_id+1 si le toco uno.
		# Al numero 3 y 4 les toca color fijo, sin importar si termino siendo Player o NPC.
		var slot_number := -1
		if resolved_type == GlobalUtils.CharacterType.PLAYER:
			slot_number = resolved_player_id + 1
		elif has_npc_id:
			slot_number = resolved_npc_id + 1
		if slot_number == 3:
			character.material = SLOT_3_MATERIAL
		elif slot_number == 4:
			character.material = SLOT_4_MATERIAL

		if has_npc_id:
			_npc_id_of_character[character] = resolved_npc_id
		_spawn_point_of_character[character] = spawn_point
		_lives_of_character[character] = lives_per_character

func _handle_character_death(character: Character) -> void:
	'''
	Un personaje se salio del area jugable. Si le quedan vidas, respawnea en su punto
	original; si no, se olvida de el y se elimina del arbol.
	'''
	var death_count: int = _death_count_of_character.get(character, 0) + 1
	_death_count_of_character[character] = death_count
	print("%s: morido por la patria x%d" % [_get_character_label(character), death_count])
	var lives_left := _lives_of_character[character] - 1
	if lives_left <= 0:
		_forget_character(character)
		character.queue_free()
	else:
		_lives_of_character[character] = lives_left
		character.respawn(_spawn_point_of_character[character].global_position)

func _forget_character(character: Character) -> void:
	'''
	Sacar a un personaje de los diccionarios de estado.
	'''
	_spawn_point_of_character.erase(character)
	_lives_of_character.erase(character)
	_death_count_of_character.erase(character)
	_npc_id_of_character.erase(character)

func _get_character_label(character: Character) -> String:
	'''
	Etiqueta pa mostrar en consola: PLAYER_1/PLAYER_2 pal jugador (sacado del propio enum,
	pa que si algun dia cambia el nombre del enum el mensaje se actualice solo), o NPC llano
	pal resto.
	'''
	if character is Player:
		var player_id: int = (character as Player).player_id
		return GlobalUtils.PlayerId.keys()[player_id]
	if _npc_id_of_character.has(character):
		return GlobalUtils.NPCId.keys()[_npc_id_of_character[character]]
	return "NPC"

func _get_area_bounds(area: Area3D) -> AABB:
	'''
	AABB en coordenadas del mundo de la caja de un area, sacada de su BoxShape3D.
	Copia local a proposito de la misma logica que ya existe en camera_follow.gd: ese script
	ya esta estabilizado y queda fuera de alcance, asi que aqui no se comparte ni se
	refactoriza, nomas se duplica.
	'''
	if area == null:
		return AABB()
	var collision_shape: CollisionShape3D = null
	for child in area.get_children():
		collision_shape = child as CollisionShape3D
		if collision_shape != null:
			break
	if collision_shape == null:
		return AABB()
	var box := collision_shape.shape as BoxShape3D
	if box == null:
		return AABB()
	var half := box.size * 0.5 * collision_shape.global_basis.get_scale()
	return AABB(collision_shape.global_position - half, half * 2.0)
