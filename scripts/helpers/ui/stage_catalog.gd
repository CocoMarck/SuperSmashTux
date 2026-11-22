class_name StageCatalog
extends RefCounted

'''
Catálogo de escenarios de la pantalla de configuración de partida, en el orden en que se muestran.
'''

# Constantes
const RANDOM_ID := &"random"

# Clases
class Entry:
	extends RefCounted

	var id: StringName = &""
	var display_name: String = ""
	var scene_path: String = "" # Vacío para Aleatorio.
	var is_random: bool = false

# Propiedades privadas
static var _entries: Array[Entry] = []

# Funciones DATA
static func _make(id: StringName, display_name: String, scene_path: String, is_random: bool) -> Entry:
	var entry := Entry.new()
	entry.id = id
	entry.display_name = display_name
	entry.scene_path = scene_path
	entry.is_random = is_random
	return entry

# Funciones catalogo
static func all() -> Array[Entry]:
	'''
	Lista de escenarios en orden: Aleatorio, Mapa 1. Se arma una sola vez.
	'''
	if _entries.is_empty():
		_entries.append(_make(RANDOM_ID, "Random", "", true))
		_entries.append(_make(&"map1", "Mapa 1", "res://scenes/levels/map1.tscn", false))
	return _entries

static func get_entry(id: StringName) -> Entry:
	'''
	Entrada por id, o null si no existe.
	'''
	for entry: Entry in all():
		if entry.id == id:
			return entry
	return null

static func resolve(entry: Entry) -> Entry:
	'''
	Escenario real a jugar: el mismo si ya es real; si es Aleatorio, uno al azar de los reales.
	'''
	if entry != null and not entry.is_random:
		return entry
	var pool: Array[Entry] = []
	for candidate: Entry in all():
		if not candidate.is_random:
			pool.append(candidate)
	return pool.pick_random()
