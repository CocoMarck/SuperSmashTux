class_name CharacterCatalog
extends RefCounted

'''
Catálogo de personajes del roster de la pantalla de selección, en el orden en que se muestran.
'''

# Constantes
const RANDOM_ID := &"random"
const STANDARD_MODEL: PackedScene = preload("res://assets/standard_character_a_pose.glb")

# Clases
class Entry:
	extends RefCounted

	var config_id: StringName = &""
	var display_name: String = ""
	var glyph: String = ""
	var is_random: bool = false
	var model: PackedScene = null # null para Aleatorio.

# Propiedades privadas
static var _entries: Array[Entry] = []

# Funciones DATA
static func _make(
	config_id: StringName, display_name: String, glyph: String, is_random: bool,
	model: PackedScene) -> Entry:
	var entry := Entry.new()
	entry.config_id = config_id
	entry.display_name = display_name
	entry.glyph = glyph
	entry.is_random = is_random
	entry.model = model
	return entry

static func _model_for(id: StringName) -> PackedScene:
	if id == CharacterRegistry.STANDARD_ID:
		return STANDARD_MODEL
	var config_path: String = CharacterRegistry.person_config_path(id)
	var person_config: PersonConfig = CharacterRegistry.load_person_config(
		config_path)
	var model := load(person_config.model) as PackedScene
	return model

# Funciones texto
static func _glyph_for(display_name: String) -> String:
	if display_name.is_empty():
		return "?"
	return display_name.substr(0, 1).to_upper()

# Funciones catalogo
static func all() -> Array[Entry]:
	'''
	Lista de personajes en orden: Aleatorio, B.O.B, Tux. Se arma una sola vez.
	'''
	if _entries.is_empty():
		_entries.append(_make(RANDOM_ID, "Random", "?", true, null))
		for id: StringName in CharacterRegistry.playable_ids():
			var name := CharacterRegistry.display_name(id)
			_entries.append( 
				_make(id, name, _glyph_for(name), false, _model_for(id)) )
	return _entries

static func get_entry_by_config_id(config_id: StringName) -> Entry:
	'''
	Primer personaje real (no Aleatorio) con esa configuración, o null si no hay.
	'''
	for entry: Entry in all():
		if not entry.is_random and entry.config_id == config_id:
			return entry
	return null

static func get_entry(id: StringName) -> Entry:
	'''
	Entrada por id, o null si no existe.
	'''
	for entry: Entry in all():
		if entry.config_id == id:
			return entry
	return null
