class_name GameManager
extends Node

# Reglas de la partida: spawnea 4 peleadores (slots 1-2 Player, 3-4 NPC), gestiona vidas,
# muertes por salir del PlayArea y respawn, y lleva la cuenta regresiva, el cronómetro y el fin.
# Instancia la CameraFollow desde su prefab.
# Avisa al HUD mediante señales.
# Necesita en el mapa: PlayArea (Area3D con CollisionShape3D de caja) y SpawnPoint1..4.

# Señales | Avisos para el HUD (FightHud se conecta a ellas en su _ready).
signal power_fighter_spawned(power_fighter: PowerFighter, slot: int, is_player: bool, max_lives: int)
signal lives_changed(power_fighter: PowerFighter, lives: int)
signal power_fighter_eliminated(power_fighter: PowerFighter) # Se emite antes del queue_free.
signal match_time_changed(seconds: int) # Segundos enteros transcurridos de la partida. Solo se emite cuando cambia el segundo.
signal countdown_tick(seconds_left: int) # Cuenta regresiva previa a la pelea: 3, 2, 1.
signal fight_announced(duration: float) # Terminó la cuenta: el HUD muestra ¡PELEA! durante `duration` segundos. Los peleadores siguen congelados.
signal match_started() # Terminó el letrero de ¡PELEA! (o no hay), los peleadores ya pueden moverse y el cronómetro arranca.
signal match_ended(winner: PowerFighter) # Una sola vez por partida. winner == null es empate. Se emite después de power_fighter_eliminated.

# Constantes | Materiales fijos para los luchadores
const SLOT_1_MATERIAL: Material = preload("res://materials/mat_red.tres")
const SLOT_2_MATERIAL: Material = preload("res://materials/mat_blue.tres")
const SLOT_3_MATERIAL: Material = preload("res://materials/mat_yellow.tres")
const SLOT_4_MATERIAL: Material = preload("res://materials/mat_green.tres")

# Constantes | Prefabs
const CAMERA_FOLLOW_PREFAB: PackedScene = preload("res://prefabs/camera_follow.tscn")

# Propiedades publicas | Configuración de partida.
@export_group("Match Settings")
@export_range(1, 99, 1) var lives_per_character: int = 3
@export_range(0.0, 5.0, 0.05) var respawn_delay: float = 1.0   # segundos de espera antes de reaparecer
@export_range(0, 9, 1) var countdown_seconds: int = 3   # segundos de cuenta regresiva antes de pelear. Con 0 no hay cuenta.
@export_range(0.0, 5.0, 0.1) var fight_sign_seconds: float = 1.2   # segundos que dura el letrero ¡PELEA! con los peleadores congelados. Con 0 no hay letrero.

# Propiedades privadas | Estado por personaje.
# Aca probablemente mejor usar una clase, en vez de varios diccionarios.
var _spawn_point_of_power_fighter: Dictionary[PowerFighter, SpawnPoint] = {}
var _lives_of_power_fighter: Dictionary[PowerFighter, int] = {}
var _death_position_of_power_fighter: Dictionary[PowerFighter, Vector3] = {} # El death position, se usara para hacer efectos gráficos. Por ahora esta sin uso.

# Propiedades privadas | Estado de la partida (cronómetro y fin).
var _match_time: float = 0.0 # Segundos transcurridos desde que arrancó la partida (sin contar la cuenta regresiva).
var _last_emitted_second: int = 0
var _match_running: bool = false # false durante la cuenta regresiva y tras el fin; el cronómetro solo avanza en true.
var _match_over: bool = false # true una vez emitido match_ended. Ya no se restan vidas ni se vuelve a emitir.
var _elimination_pending_check: bool = false # Alguien se eliminó este frame; se revisa el fin al terminar el recorrido.

# Propiedades privadas | Dependencias, lo que tiene que tener el mapa.
var _play_area: Area3D
var _play_area_bounds: AABB = AABB()
var _spawn_point1: SpawnPoint
var _spawn_point2: SpawnPoint
var _spawn_point3: SpawnPoint
var _spawn_point4: SpawnPoint

# Propiedades privadas | Cámara
var _camera_follow: CameraFollow

# Funciones | Utilidades de spawn
func _get_spawn_points() -> Array[SpawnPoint]:
	return [_spawn_point1, _spawn_point2, _spawn_point3, _spawn_point4]

func _get_all_materials() -> Array[Material]:
	return [SLOT_1_MATERIAL, SLOT_2_MATERIAL, SLOT_3_MATERIAL, SLOT_4_MATERIAL]

# Funciones | Spawneo y vidas
func _spawn_all_power_fighters() -> void:
	'''
	Spawnea un peleador por cada SpawnPoint: los slots 1-2 son Player y los 3-4 NPC.
	'''
	var spawn_points = _get_spawn_points()
	for i in range(0, spawn_points.size()):
		# SpawnPoint.spawn se encarga de instanciar y posicionar al peleador.
		var spawn_point = spawn_points[i]
		var power_fighter : PowerFighter
		var is_player := i == 0 or i == 1
		if is_player:
			power_fighter = spawn_point.spawn( GlobalUtils.CharacterType.PLAYER, i )
		else:
			power_fighter = spawn_point.spawn( GlobalUtils.CharacterType.NPC, i )
		power_fighter.material = _get_all_materials()[i]
		# Establecer spawn fijo.
		_spawn_point_of_power_fighter[power_fighter] = spawn_point
		_lives_of_power_fighter[power_fighter] = lives_per_character
		# Agregar al mapa
		add_child(power_fighter)
		power_fighter_spawned.emit(power_fighter, i, is_player, lives_per_character)

func _forget_power_fighter(power_fighter: PowerFighter) -> void:
	'''
	Olvidar por completo los datos relacionados con un power fighter que ya no existe.
	'''
	_spawn_point_of_power_fighter.erase(power_fighter)
	_lives_of_power_fighter.erase(power_fighter)
	_death_position_of_power_fighter.erase(power_fighter)

func _handle_power_fighter_death(power_fighter: PowerFighter) -> void:
	'''
	Un personaje salió del área jugable y pierde una vida. Sin vidas se elimina (emite, queue_free y marca
	revisar el fin). Con vidas se saca del árbol sin liberar la instancia y reaparece tras respawn_delay.
	'''
	_lives_of_power_fighter[power_fighter] -= 1
	lives_changed.emit(power_fighter, _lives_of_power_fighter[power_fighter])
	# Debug
	print("%s: morido por la patria vidas; %d" % [_get_power_fighter_label(power_fighter), _lives_of_power_fighter[power_fighter]])
	# Si se ya no tiene vidas, adios.
	if _lives_of_power_fighter[power_fighter] == 0:
		power_fighter_eliminated.emit(power_fighter)
		power_fighter.queue_free()
		_forget_power_fighter(power_fighter)
		_elimination_pending_check = true
		return
	# Obtener posición de muerte, y quitarlo de la vista de la escena.
	var parent := power_fighter.get_parent()
	if parent != null:
		_death_position_of_power_fighter[power_fighter] = power_fighter.global_position
		parent.remove_child(power_fighter)
	# Inicializar spawn con delay
	if respawn_delay > 0.0:
		await get_tree().create_timer(respawn_delay).timeout
	# Respawn a la scene, solo si existe la instancia del power fighter
	if not is_instance_valid(power_fighter):
		return
	add_child(power_fighter)
	power_fighter.respawn( _spawn_point_of_power_fighter[power_fighter].global_position )
	_death_position_of_power_fighter.erase(power_fighter)

# Funciones | Flujo de partida (cuenta, fin y cronómetro)
func _set_power_fighters_frozen(frozen: bool) -> void:
	'''
	Congela o descongela a todos los peleadores (jugadores y NPC). Se apaga su process_mode en vez de usar
	Person.block_move, porque ese flag no lo lee nadie. Así tampoco corre su IA, física ni animación.
	'''
	var mode := Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	for power_fighter in _lives_of_power_fighter.keys():
		if is_instance_valid(power_fighter):
			power_fighter.process_mode = mode

func _run_countdown() -> void:
	'''
	Cuenta regresiva de inicio: congela, avisa 3-2-1 (1 s cada uno), deja el letrero de ¡PELEA! con todos
	congelados, y hasta que termina descongela y arranca la partida (y el cronómetro).
	'''
	var frozen := countdown_seconds > 0 or fight_sign_seconds > 0.0
	if frozen:
		_set_power_fighters_frozen(true)
	for seconds_left in range(countdown_seconds, 0, -1):
		countdown_tick.emit(seconds_left)
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return
	if fight_sign_seconds > 0.0:
		fight_announced.emit(fight_sign_seconds)
		await get_tree().create_timer(fight_sign_seconds).timeout
		if not is_inside_tree():
			return
	if frozen:
		_set_power_fighters_frozen(false)
	_match_running = true
	match_started.emit()

func _check_match_end() -> void:
	'''
	Revisa si la partida terminó. Se llama después de recorrer a todos los peleadores, así que si los
	últimos dos caen en el mismo frame quedan 0 con vidas y es empate (en vez de ganar el segundo de la lista).
	_forget_power_fighter ya sacó a los eliminados, por eso basta contar lo que queda.
	'''
	_elimination_pending_check = false
	if _match_over:
		return
	var remaining := _lives_of_power_fighter.keys()
	if remaining.size() > 1:
		return
	var winner: PowerFighter = null
	if remaining.size() == 1 and is_instance_valid(remaining[0]):
		winner = remaining[0]
	_end_match(winner)

func _end_match(winner: PowerFighter) -> void:
	'''
	Cierra la partida: para el cronómetro, congela al ganador (para que la pantalla final quede quieta)
	y avisa al HUD. El ganador sigue siendo instancia válida, el HUD busca su slot y su nombre al recibirlo.
	'''
	_match_over = true
	_match_running = false
	if winner != null:
		winner.process_mode = Node.PROCESS_MODE_DISABLED
	match_ended.emit(winner)

func _tick_match_time(delta: float) -> void:
	'''
	Suma el tiempo de la partida. Solo avisa al HUD cuando cambia el segundo entero, no cada frame.
	'''
	_match_time += delta
	var second := int(_match_time)
	if second != _last_emitted_second:
		_last_emitted_second = second
		match_time_changed.emit(second)

func _get_power_fighter_label(power_fighter: PowerFighter) -> String:
	'''
	Nombre legible del peleador, pa los print de debug.
	'''
	if power_fighter is Player:
		var player_id: int = (power_fighter as Player).player_id
		return power_fighter.name + str(GlobalUtils.PlayerId.keys()[player_id])
	return power_fighter.name

# Funciones | Inicializar y procesar
func _ready() -> void:
	# Establecer propiedades dependencia
	_play_area = $PlayArea
	_play_area_bounds = GlobalUtils.get_box_bounds(GlobalUtils.get_first_collision_shape(_play_area))
	_spawn_point1 = $SpawnPoint1
	_spawn_point2 = $SpawnPoint2
	_spawn_point3 = $SpawnPoint3
	_spawn_point4 = $SpawnPoint4
	# Camera
	_camera_follow = CAMERA_FOLLOW_PREFAB.instantiate() as CameraFollow
	_camera_follow.camera_area = _play_area # Antes del add_child: su _ready calcula la caja con esto.
	add_child(_camera_follow)
	# El manager solo conecta; que hacer al morir alguien (temblor) lo decide la camara.
	lives_changed.connect(_camera_follow.on_power_fighter_died)
	# Debug
	if _play_area_bounds.size == Vector3.ZERO:
		# Play_area sin configurar; no se detectaran muertes
		push_warning("GameManager: fail open no fail-closed. No detect play area bounds")
	# Spawneo
	_spawn_all_power_fighters()
	# Tiempo inicial, para que el HUD pinte 00:00 desde el primer frame.
	match_time_changed.emit(0)
	# Cuenta regresiva; el cronómetro arranca hasta match_started.
	_run_countdown()

func _physics_process(delta: float) -> void:
	'''
	Va en físicas pa no perder salidas del área 3D (un process normal también serviría).
	'''
	if _match_over:
		return # Partida terminada: ya no se restan vidas por salir del escenario.
	if _match_running:
		_tick_match_time(delta)
	for power_fighter in _lives_of_power_fighter.keys():
		# Si no es instancia valida, forzar olvidar todos sus datos. El handle death, ya lo olvida. Este es verificador.
		if not is_instance_valid(power_fighter):
			_forget_power_fighter(power_fighter)
			continue
		# Recién spawneado o esperando respawn (fuera del árbol): se salta este frame y se revisa cuando vuelva.
		if not power_fighter.is_inside_tree():
			continue
		# Detectar que este fuera del area de juego.
		# Sin bounds (PlayArea sin caja) no se detectan muertes; si no, todos "saldrian" cada frame.
		if _play_area_bounds.size != Vector3.ZERO and not _play_area_bounds.has_point(power_fighter.global_position):
			_handle_power_fighter_death(power_fighter)
	# Fin de partida: se revisa ya con todas las caídas de este frame contadas.
	if _elimination_pending_check:
		_check_match_end()
		
