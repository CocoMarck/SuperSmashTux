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

# Propiedades | Configuración de partida.
@export_group("Match Settings")
@export_range(0.0, 5.0, 0.1) var fight_sign_seconds: float = 1.2  # (1.2) segundos que dura el letrero ¡PELEA! con los peleadores congelados. Con 0 no hay letrero.
@onready var _match_countdown: MatchCountdown = $MatchCountdown

# Propiedades privadas | Estado por personaje | Match lives
@onready var _lives_manager: LivesManager = $LivesManager
var _fighters: Dictionary[int, PowerFighter] = {} # roster para congelar

# Propiedades privadas | Estado de la partida (cronómetro y fin).
var _match_running: bool = false # false durante la cuenta regresiva y tras el fin; el cronómetro solo avanza en true.
var _match_over: bool = false # true una vez emitido match_ended. Ya no se restan vidas ni se vuelve a emitir.

# Propiedades publicas | Cronómetro
@onready var _match_time: MatchTime = $MatchTime

# Propiedades privadas | Dependencias, lo que tiene que tener el mapa.
@onready var _play_area: Area3D = $PlayArea
var _play_area_bounds: AABB = AABB()
@onready var _spawn_point1: SpawnPoint = $SpawnPoint1
@onready var _spawn_point2: SpawnPoint = $SpawnPoint2
@onready var _spawn_point3: SpawnPoint = $SpawnPoint3
@onready var _spawn_point4: SpawnPoint = $SpawnPoint4
var power_fighter_slots: PowerFighterSlots = PowerFighterSlots.new()

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
	Spawnea un peleador por cada slot ocupado, en el SpawnPoint de ese slot (ver `PowerFightersSetup`).
	'''
	var spawn_points = _get_spawn_points()
	for i in range(0, spawn_points.size()):
		# Slot vacío en la selección: no se spawnea nadie ahí.
		var slot: PowerFighterData
		if power_fighter_slots.has_slot(i):
			slot = power_fighter_slots.get_slot(i)
		else:
			continue
		
		# SpawnPoint.spawn se encarga de instanciar y posicionar al peleador.
		var spawn_point = spawn_points[i]
		var power_fighter: PowerFighter = spawn_point.spawn( 
			slot.config, slot.control, slot.player_id )
		power_fighter.material = _get_all_materials()[i]
		var is_player: bool = slot.control == GlobalUtils.ControlType.PLAYER
		
		# Agregarles vidas, y el seguimiento de sus vidas.
		_fighters[i] = power_fighter
		_lives_manager.track(power_fighter, slot.lives, spawn_point.global_position)
		
		# Agregar al mapa
		power_fighter_spawned.emit(power_fighter, i, is_player, slot.lives)
		add_child(power_fighter)

# Funciones | `PowerFighters`
func get_valid_fighters() -> Dictionary[int, PowerFighter]:
	'''
	Devuelve una copia con solo los peleadores cuya instancia sigue viva.
	No devuelve `_fghters` directo para no exponer referencias muertas.
	'''
	var valid: Dictionary[int, PowerFighter] = {}
	for id: int in _fighters.keys():
		var fighter: PowerFighter = _fighters[id]
		if is_instance_valid(fighter):
			valid[id] = fighter
	return valid

func _determine_the_winner() -> int:
	'''
	Determina el ganador. Pioridades:
	- 1. Gana el que tenga mas vidas.
	- 2. Gana el que tenga menos porcentaje de daño.
	- 3. Empate. Retorna un menos uno.
	
	Retorna el id, si es empate menos uno.
	'''
	var valid_fighters :Dictionary[int, PowerFighter] = get_valid_fighters()
	var candidates : Dictionary[int, PowerFighter] = {}
	for id: int  in valid_fighters.keys():
		var fighter: PowerFighter = valid_fighters[id]
		if _lives_manager.get_lives(fighter) <= 0:
			continue
		candidates[id] = fighter
	if candidates.is_empty():
		return -1
	
	# Solo por vidas. Si solo hay uno con vidas actuales maximas, ese es el ganador.
	var max_lives: int = 0
	for fighter in candidates.values():
		max_lives = maxi(max_lives, _lives_manager.get_lives(fighter))
	
	var fighters_with_max_lives: Dictionary[int, PowerFighter] = {}
	for id in candidates.keys():
		var fighter: PowerFighter = candidates[id]
		if _lives_manager.get_lives(fighter) == max_lives:
			fighters_with_max_lives[id] = fighter
	if fighters_with_max_lives.keys().size() == 1:
		return fighters_with_max_lives.keys()[0]
	
	# Empate en vidas. Gana el que tenga menos daño
	var min_damage: float = INF
	for id in fighters_with_max_lives.keys():
		var fighter: PowerFighter = fighters_with_max_lives[id]
		min_damage = minf(min_damage, fighter.damage_percentage)
	
	var fighters_with_min_damage: Dictionary[int, PowerFighter] = {}
	for id in fighters_with_max_lives.keys():
		var fighter: PowerFighter = fighters_with_max_lives[id]
		if is_equal_approx(fighter.damage_percentage, min_damage):
			fighters_with_min_damage[id] = fighter
	
	if fighters_with_min_damage.keys().size() == 1:
		return fighters_with_min_damage.keys()[0]
	return -1

func get_winner() -> PowerFighter:
	'''
	Obtiene el id del ganador determinado, y si existe el id, lo devuelve como `PowerFighter`. De lo contraro retorna `null`.
	
	Es publica porque capaz al hud le intereza saber como estadistica de partida, quien es el actual ganador.
	'''
	var id: int = _determine_the_winner()
	if id >= 0:
		return _fighters[id]
	return null

# Funciones | Flujo de partida (cuenta, fin y cronómetro)
func _set_power_fighters_frozen(frozen: bool) -> void:
	'''
	Congela o descongela a todos los peleadores (jugadores y NPC). Se apaga su process_mode en vez de usar
	Person.block_move, porque ese flag no lo lee nadie. Así tampoco corre su IA, física ni animación.
	'''
	var mode := Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	for power_fighter in get_valid_fighters().values():
		if is_instance_valid(power_fighter):
			power_fighter.process_mode = mode

func _start_countdown() -> void:
	if _match_countdown.has_wait():
		_set_power_fighters_frozen(true)
	_match_countdown.start()

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
	_match_time.stop()

# Funciones | Handlers para `MatchLives`
func _on_lives_changed(power_fighter: PowerFighter, lives: int) -> void:
	lives_changed.emit(power_fighter, lives)

func _on_eliminated(power_fighter: PowerFighter) -> void:
	power_fighter_eliminated.emit(power_fighter)

func _on_death_resolved(remaining: Array[PowerFighter]) -> void:
	if _match_over or remaining.size() > 1:
		return
	_end_match(get_winner())

# Funciones |  Handlers para `MatchTime`
func _on_time_changed(seconds: int):
	match_time_changed.emit(seconds)

func _on_time_out():
	_match_over = true
	_end_match(get_winner())

func set_time_limit(minutes: int) -> void:
	var match_time := get_node_or_null("MatchTime") as MatchTime
	match_time.time_limit_minutes = maxi(minutes, 0)

# Funciones |  Handlers para `Countdown`
func _on_countdown_tick(seconds_left: int) -> void:
	countdown_tick.emit(seconds_left)
	
func _on_countdown_finished() -> void:
	# Letrero de ¡PELEA!
	if fight_sign_seconds > 0.0:
		fight_announced.emit(fight_sign_seconds)
		await get_tree().create_timer(fight_sign_seconds).timeout
		if not is_inside_tree():
			return
	# Empezar a juegar
	_set_power_fighters_frozen(false)
	_match_running = true
	_match_time.start()
	match_started.emit()

func set_countdown_seconds(seconds: int) -> void:
	var match_countdown :MatchCountdown = get_node_or_null("MatchCountdown") as MatchCountdown
	match_countdown.countdown_seconds = seconds

# Funciones | Inicializar y procesar
func _ready() -> void:
	# Establecer propiedades dependencia
	_play_area_bounds = GlobalUtils.get_box_bounds(GlobalUtils.get_first_collision_shape(_play_area))

	# Información de juego
	_lives_manager.setup(self, _play_area_bounds)
	_lives_manager.lives_changed.connect(_on_lives_changed)
	_lives_manager.eliminated.connect(_on_eliminated)
	_lives_manager.deaths_resolved.connect(_on_death_resolved)
	_match_time.time_changed.connect( _on_time_changed )
	_match_time.time_out.connect( _on_time_out )
	_match_time.setup()
	_match_countdown.tick.connect( _on_countdown_tick )
	_match_countdown.finished.connect( _on_countdown_finished )
	
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
	# Cuenta regresiva; el cronómetro arranca hasta match_started.
	_start_countdown()

func _physics_process(delta: float) -> void:
	'''
	Va en físicas pa no perder salidas del área 3D (un process normal también serviría).
	'''
	if _match_over:
		return # Partida terminada: ya no se restan vidas por salir del escenario
		
