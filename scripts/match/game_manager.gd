class_name GameManager
extends Node
'''
Este script debe estar en el nodo padre del mapa. Es directamente el mapa.

Reglas de la partida: spawnea 4 peleadores (slots 1-2 Player, 3-4 NPC), gestiona vidas, muertes por salir del `PlayArea` y `respawn`, y lleva la cuenta regresiva, el cronómetro y el fin.
- Instancia la `CameraFollow` desde su prefab.
- Avisa al HUD mediante señales.
- Necesita en el mapa: `PlayArea` (`Area3D` con `CollisionShape3D` de caja) y `SpawnPoint1..4`.
'''

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
@export_range(0, 9, 1) var countdown_seconds: int = 0   # (3) segundos de cuenta regresiva antes de pelear. Con 0 no hay cuenta.
@export_range(0.0, 5.0, 0.1) var fight_sign_seconds: float = 0  # (1.2) segundos que dura el letrero ¡PELEA! con los peleadores congelados. Con 0 no hay letrero.


# Propiedades privadas | Estado por personaje | Match lives
var _lives_manager: LivesManager
var _fighters: Array[PowerFighter] = [] # roster para congelar

# Propiedades privadas | Estado de la partida (cronómetro y fin).
var _match_time: float = 0.0 # Segundos transcurridos desde que arrancó la partida (sin contar la cuenta regresiva).
var _last_emitted_second: int = 0
var _match_running: bool = false # false durante la cuenta regresiva y tras el fin; el cronómetro solo avanza en true.
var _match_over: bool = false # true una vez emitido match_ended. Ya no se restan vidas ni se vuelve a emitir.

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
func _get_match_slots() -> Array[Dictionary]:
	'''
	Slots elegidos en la selección de personaje (MatchSetup.slots). Si vienen vacíos (map1 abierto
	directo desde el editor), respaldo: 2 Player + 2 NPC con personaje aleatorio.
	'''
	if not MatchSetup.slots.is_empty():
		return MatchSetup.slots
	var config_options := [GlobalUtils.PowerFighterConfig.STANDARD, GlobalUtils.PowerFighterConfig.TUX]
	var slots: Array[Dictionary] = []
	for i in range(0, 4):
		var control := GlobalUtils.ControlType.PLAYER if i < 2 else GlobalUtils.ControlType.NPC
		slots.append({ "control": control, "config": config_options.pick_random(), "player_id": i })
	return slots

func _spawn_all_power_fighters() -> void:
	'''
	Spawnea un peleador por cada slot ocupado, en el SpawnPoint de ese slot (ver _get_match_slots).
	'''
	var spawn_points = _get_spawn_points()
	var slots := _get_match_slots()
	for i in range(0, mini(spawn_points.size(), slots.size())):
		# Slot vacío en la selección: no se spawnea nadie ahí.
		var slot: Dictionary = slots[i]
		if slot.get("control") == null:
			continue
		# SpawnPoint.spawn se encarga de instanciar y posicionar al peleador.
		var spawn_point = spawn_points[i]
		var control: GlobalUtils.ControlType = slot["control"]
		var is_player := control == GlobalUtils.ControlType.PLAYER
		var power_fighter: PowerFighter = spawn_point.spawn( slot["config"], control, slot["player_id"] )
		power_fighter.material = _get_all_materials()[i]
		# Agregarles el seguimiento de sus vidas.
		_fighters.append(power_fighter)
		_lives_manager.track(power_fighter, lives_per_character, spawn_point.global_position)
		# Agregar al mapa
		add_child(power_fighter)

		power_fighter_spawned.emit(power_fighter, i, is_player, lives_per_character)

# Funciones | Flujo de partida (cuenta, fin y cronómetro)
func _set_power_fighters_frozen(frozen: bool) -> void:
	'''
	Congela o descongela a todos los peleadores (jugadores y NPC). Se apaga su process_mode en vez de usar
	Person.block_move, porque ese flag no lo lee nadie. Así tampoco corre su IA, física ni animación.
	'''
	var mode := Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	for power_fighter in _fighters:
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

func _end_match(winner: PowerFighter) -> void:
	'''
	Cierra la partida: para el cronómetro, congela al ganador (para que la pantalla final quede quieta)
	y avisa al HUD. El ganador sigue siendo instancia válida, el HUD busca su slot y su nombre al recibirlo.
	'''
	_match_over = true
	_match_running = false
	_lives_manager.stop()
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

# Funciones | Handlers para `MatchLives`
func _on_lives_changed(power_fighter: PowerFighter, lives: int) -> void:
	lives_changed.emit(power_fighter, lives)

func _on_eliminated(power_fighter: PowerFighter) -> void:
	power_fighter_eliminated.emit(power_fighter)

func _on_death_resolved(remaining: Array[PowerFighter]) -> void:
	if _match_over or remaining.size() > 1:
		return
	var winner: PowerFighter = null
	if remaining.size() == 1 and is_instance_valid(remaining[0]):
		winner = remaining[0]
	_end_match(winner)

# Funciones | Inicializar y procesar
func _ready() -> void:
	# Establecer propiedades dependencia
	_play_area = $PlayArea
	_play_area_bounds = GlobalUtils.get_box_bounds(GlobalUtils.get_first_collision_shape(_play_area))
	_spawn_point1 = $SpawnPoint1
	_spawn_point2 = $SpawnPoint2
	_spawn_point3 = $SpawnPoint3
	_spawn_point4 = $SpawnPoint4
	_lives_manager = $LivesManager

	# Información de juego
	_lives_manager.setup(self, _play_area_bounds)
	_lives_manager.lives_changed.connect(_on_lives_changed)
	_lives_manager.eliminated.connect(_on_eliminated)
	_lives_manager.deaths_resolved.connect(_on_death_resolved)
	add_child(_lives_manager)
	
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
	_lives_manager.start()
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
		
