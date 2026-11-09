class_name CharacterCatalog
extends RefCounted

'''
Catálogo de personajes del roster de la pantalla de selección, en el orden en que se muestran.
'''

# Constantes
const RANDOM_ID := &"random"
const BOB_MODEL: PackedScene = preload("res://assets/standard_character_a_pose.glb")
const TUX_MODEL: PackedScene = preload("res://assets/tux_fighter.glb")

# Clases
class Entry:
	extends RefCounted

	var id: StringName = &""
	var display_name: String = ""
	var glyph: String = ""
	var is_random: bool = false
	var config: GlobalUtils.PowerFighterConfig = GlobalUtils.PowerFighterConfig.STANDARD
	var model: PackedScene = null # null para Aleatorio.

# Propiedades privadas
static var _entries: Array[Entry] = []

# Funciones
static func all() -> Array[Entry]:
	'''
	Lista de personajes en orden: Aleatorio, B.O.B, Tux. Se arma una sola vez.
	'''
	if _entries.is_empty():
		_entries.append(_make(RANDOM_ID, "Aleatorio", "?", true, GlobalUtils.PowerFighterConfig.STANDARD, null))
		_entries.append(_make(&"bob", "B.O.B", "B", false, GlobalUtils.PowerFighterConfig.STANDARD, BOB_MODEL))
		_entries.append(_make(&"tux", "Tux", "T", false, GlobalUtils.PowerFighterConfig.TUX, TUX_MODEL))
	return _entries

static func get_entry_by_config(config: GlobalUtils.PowerFighterConfig) -> Entry:
	'''
	Primer personaje real (no Aleatorio) con esa configuración, o null si no hay.
	'''
	for entry: Entry in all():
		if not entry.is_random and entry.config == config:
			return entry
	return null

static func get_entry(id: StringName) -> Entry:
	'''
	Entrada por id, o null si no existe.
	'''
	for entry: Entry in all():
		if entry.id == id:
			return entry
	return null

static func _make(
	id: StringName, display_name: String, glyph: String, is_random: bool,
	config: GlobalUtils.PowerFighterConfig, model: PackedScene) -> Entry:
	var entry := Entry.new()
	entry.id = id
	entry.display_name = display_name
	entry.glyph = glyph
	entry.is_random = is_random
	entry.config = config
	entry.model = model
	return entry
