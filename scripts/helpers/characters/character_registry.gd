class_name CharacterRegistry
extends RefCounted

'''
- Lee `identities.cfg`, este archivo almacena `id` como sección, y `nombre`. En el futuro quizás almacene `description`
- Los id son string tipo `snake_case`, si no lo son, manda error/ignora.
- `hidden = true` (opcional) saca al personaje de la selección, pero sigue siendo creable.
'''

# Constantes
const IDENTITIES_PATH := "res://data/power_fighters/identities.cfg"
const DATA_DIR := "res://data/power_fighters/"

# Constantes | Personaje base/dummy hardcodeado. NO debe vivir en ningún `cfg`, o file data. Su movement final, moveset final, todo vive en code. GUI del prefab es solo ajuste temporal. No migrar a data solo por "higiene".
const STANDARD_ID := &"standard"
const STANDARD_NAME := "B.O.B"
const STANDARD_MODEL_PATH := "res://assets/models/standard/standard_character_a_pose.glb" # Malla que ya trae el prefab.

# Propiedades privadas
static var _ids: Array[StringName] = []
static var _names: Dictionary[StringName, String] = {}
static var _hidden: Array[StringName] = []
static var _snake_regex: RegEx = null
static var _loaded := false


# Funcs Log
static func _fail(message: String) -> void:
	push_error("CharacterRegistry: " + message)
	assert(false, message)


# Funcs Text
static func is_snake_case(id: StringName) -> bool:
	if _snake_regex == null:
		_snake_regex = RegEx.new()
		_snake_regex.compile("^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$")
	return _snake_regex.search(String(id)) != null


# Funcs data load
static func _ensure_loaded():
	'''
	Asegurar carga de data. Si no existe muy posible crash
	'''
	if _loaded:
		return
	var cfg := ConfigFile.new()
	var err := cfg.load(IDENTITIES_PATH)
	if err != OK:
		_fail("don't load %s (error %d)" %[IDENTITIES_PATH, err])
	
	_names[STANDARD_ID] = STANDARD_NAME
	_ids.append(STANDARD_ID)
	for section: String in cfg.get_sections():
		var id := StringName(section)
		if id == STANDARD_ID:
			_fail("don't use the id `%s` in %s" % [STANDARD_ID, IDENTITIES_PATH])
			continue
		if not is_snake_case(id):
			_fail("id no `snake_case`: `%s`" % section)
			continue
		if _names.has(id):
			_fail("duplicated id: %s" % section)
			continue
	
		var value: Variant = cfg.get_value(section, "name", null)
		if not value is String or String(value).is_empty():
			_fail("invalid name in [%s]" % section)
			continue
		
		_names[id] = String(value)
		_ids.append(id)
		if bool(cfg.get_value(section, "hidden", false)):
			_hidden.append(id)

	_loaded = true

# Funcs data public
static func playable_ids() -> Array[StringName]:
	'''
	Obtener los id que se muestran en la selección (sin los `hidden`), en orden de `identities.cfg`.
	'''
	_ensure_loaded()
	var result: Array[StringName] = []
	for id: StringName in _ids:
		if not _hidden.has(id):
			result.append(id)
	return result

static func display_name(id: StringName) -> String:
	_ensure_loaded()
	if not _names.has(id):
		_fail("don't exists: %s" % id)
		return id
	return _names[id]

static func is_playable(id: StringName) -> bool:
	# Incluye ocultos: se pueden crear aunque no salgan en la selección.
	_ensure_loaded()
	return _ids.has(id)

# Funcs data person/fighter/power_fighter/ cfg.
static func person_config_path(id: StringName) -> String:
	'''
	Obtener archivo de configuración del personaje.
	'''
	_ensure_loaded()
	if not is_playable(id):
		_fail("parson config don't exist for: %s" % id)
		return ""
	return DATA_DIR + String(id) + ".person.cfg"

static func load_person_config(path: String) -> PersonConfig:
	'''
	No validar nada, el crash es bueno. Data mala, crash por mal educado. GG.
	'''
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(path)
	
	var config := PersonConfig.new()
	# Identity
	config.id  = String(cfg.get_value("identity", "id"))
	config.model = String( cfg.get_value("identity", "model") )
	config.position_offset = Vector3( cfg.get_value("identity", "position_offset") )
	
	# Momentum
	config.ground_acceleration = float(
		cfg.get_value("momentum", "ground_acceleration"))
	config.ground_friction = float(cfg.get_value("momentum", "ground_friction"))
	config.air_acceleration = float(cfg.get_value("momentum", "air_acceleration"))
	config.knockback_friction = float(cfg.get_value("momentum", "knockback_friction"))

	# Horizontal movement
	config.walking_speed = int(cfg.get_value("horizontal_movement", "walking_speed"))
	config.running_speed = int(cfg.get_value("horizontal_movement", "running_speed"))

	# Vertical movement
	config.jump_impulse = int(cfg.get_value("vertical_movement", "jump_impulse"))

	# Interval
	config.walk_step_interval = float(cfg.get_value("interval", "walk_step_interval"))
	config.run_step_interval = float(cfg.get_value("interval", "run_step_interval"))
	config.crouch_move_step_interval = float(
		cfg.get_value("interval", "crouch_move_step_interval"))

	# Duration of anims
	config.air_jump_duration = float(
		cfg.get_value("duration_of_anims", "air_jump_duration"))
	
	# Offset of anims
	config.hanging_anim_offset = Vector3(cfg.get_value("anim_offset", "hanging_anim_offset"))

	return config

static func has_person_config(id: StringName) -> bool:
	if id == STANDARD_ID:
		return false
	var path: String = person_config_path(id)
	return path != "" and FileAccess.file_exists(path)

static func model_path(id: StringName) -> String:
	'''
	Obtener path de modelo de personaje.
	'''
	if id == STANDARD_ID:
		return STANDARD_MODEL_PATH
	else:
		var config_path: String = person_config_path(id)
		var config: PersonConfig = load_person_config(config_path)
		return config.model
