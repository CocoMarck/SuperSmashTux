class_name LivesManager
extends Node

'''
Manejo de vidas de la partida: descuenta al salir del `PlayArea`, respawnea con delay y elimina al que queda sin vidas. No consulta a otros módulos: el `GameManager` le inyecta el área y le registra cada peleador con `track()`. Avisa con señales.
'''

# Señales
signal lives_changed(power_fighter: PowerFighter, lives: int)
signal eliminated(power_fighter: PowerFighter)
signal respawned(power_fighter: PowerFighter)
signal deaths_resolved(remaining: Array[PowerFighter]) 

# Propiedades publicas
@export_range(0.0, 5.0, 0.05) var respawn_delay: float = 1.0

# Propiedades privadas
var _fighter_parent: Node   # GameManager: Ahí cuelgan los peleadores
var _play_area_bounds: AABB
var _lives: Dictionary[PowerFighter, int] = {}
var _respawn_position : Dictionary[PowerFighter, Vector3] = {}
var _death_position: Dictionary[PowerFighter, Vector3] = {}     # Futuro: Efectos de cámara.
var _active: bool = false
var _had_elimination_this_frame: bool = false

# Funciones | Configuración
func setup(fighter_parent: Node, play_area_bounds: AABB) -> void:
	'''
	Lo que necesita del mapa para poder trabajar.
	'''
	_fighter_parent = fighter_parent
	_play_area_bounds = play_area_bounds

func track(power_fighter: PowerFighter, max_lives: int, respawn_position: Vector3) -> void:
	'''
	Registra un peleador recién spawneado y su punto de reaparición
	'''
	_lives[power_fighter] = max_lives
	_respawn_position[power_fighter] = respawn_position

func start() -> void:
	'''
	Empieza a contar muertes (después de spawnear a todos).
	'''
	_active = true

func stop() -> void:
	_active = false

# Funcione obtener vidas
func get_lives(power_fighter: PowerFighter) -> int:
	return _lives.get(power_fighter, 0)

# Funciones | Muerte y respawn
func _is_out_of_bounds(position: Vector3) -> bool:
	return (
		_play_area_bounds.size != Vector3.ZERO and 
		not _play_area_bounds.has_point(position) )

func _handle_death(power_fighter: PowerFighter) -> void:
	_lives[power_fighter] -= 1
	lives_changed.emit(power_fighter, _lives[power_fighter])
	# Debug
	print(
		"%s: morido por la patria; le quedan %d" % 
		[_get_label(power_fighter), _lives[power_fighter]] )
	# Sin vidas: adiós
	if _lives[power_fighter] == 0:
		_had_elimination_this_frame = true
		eliminated.emit(power_fighter)
		power_fighter.queue_free()
		_forget(power_fighter)
		return
	# Guardar dónde cayó y sacarlo de la escene mientras espera.
	_death_position[power_fighter] = power_fighter.global_position
	if _fighter_parent != null:
		_fighter_parent.remove_child(power_fighter)
	# Respawn con delay
	if respawn_delay > 0.0:
		await get_tree().create_timer(respawn_delay).timeout
	# Reaparecer solo si sigue viva la instancia.
	if not is_instance_valid(power_fighter) or _fighter_parent == null:
		return
	_fighter_parent.add_child(power_fighter)
	power_fighter.respawn(_respawn_position[power_fighter])
	_death_position.erase(power_fighter)
	respawned.emit(power_fighter)

func _forget(power_fighter: PowerFighter) -> void:
	'''
	Olvida por completo a un peleador que ya no existe
	'''
	_lives.erase(power_fighter)
	_respawn_position.erase(power_fighter)
	_death_position.erase(power_fighter)

# Funciones | Utilidades
func _remaining_fighters() -> Array[PowerFighter]:
	var remaining: Array[PowerFighter] = []
	for power_fighter in _lives.keys():
		remaining.append(power_fighter)
	return remaining

func _get_label(power_fighter: PowerFighter) -> String:
	'''
	Nombre legible del peleador, para los prints de debug.
	'''
	if power_fighter is Player:
		var player_id: int = (power_fighter as Player).player_id
		return power_fighter.name + str(GlobalUtils.PlayerId.keys()[player_id])
	return power_fighter.name

# Funciones | Procesamiento
func _physics_process(_delta: float) -> void:
	if not _active:
		return
	_had_elimination_this_frame = false
	for power_fighter in _lives.keys():
		# Si no es instancia valida olvidar por si algo lo liberó por fuera.
		if not is_instance_valid(power_fighter):
			_forget(power_fighter)
			continue
		# Recién spawneado o esperando respawn (fuera de árbol): se revisa cuando vuela
		if not power_fighter.is_inside_tree():
			continue
		if _is_out_of_bounds(power_fighter.global_position):
			_handle_death(power_fighter)
	# Fin de partida: ya con todas las caídas de este frame contadas.
	if _had_elimination_this_frame:
		deaths_resolved.emit( _remaining_fighters() )
