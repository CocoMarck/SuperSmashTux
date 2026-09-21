## Autoload InputSettings
extends Node

const SAVE_PATH :String = "user://controls.cfg"
const INPUT_MAP_1 :StringName = "input_map_1"
const INPUT_MAP_2 :StringName = "input_map_2"

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	'''
	Carga la config guardada y la reaplica al InputMap.
	'''
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for action in _action_names():
		var events: Array = cfg.get_value("controls", action, [])
		if (
			events.is_empty() and not cfg.has_section_key("controls", action)):
			continue # Esta acción no se toco, conserva su default.
		InputMap.action_erase_events(action)
		for event in events:
			InputMap.action_add_event(action, event)

func save_settings() -> void:
	'''
	Guarda el estado completo de las acciones
	'''
	var cfg := ConfigFile.new()
	for action in _action_names():
		cfg.set_value("controls", action, InputMap.action_get_events(action))
	cfg.save(SAVE_PATH)

func _action_names() -> Array[StringName]:
	'''
	Todas las acciones de todos los jugadores, sacadas de `GlobalUtils`
	'''
	var names: Array[StringName] = []
	for player in GlobalUtils.PLAYER_INPUT_MAPS.values():
		names.append_array([
			player.move_left, player.move_right, player.move_up, player.move_down,
			player.jump, player.attack, player.walk, player.grab, player.shield,
			player.power_attack])
	return names
