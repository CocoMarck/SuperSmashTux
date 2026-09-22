## Autoload InputSettings
extends Node

# Constantes
const SAVE_PATH :String = "user://controls.cfg"
const INPUT_MAP_1 :StringName = "input_map_1"
const INPUT_MAP_2 :StringName = "input_map_2"

# Slots de entrada disponibles por arquitectura: dos mapas de input por acción.
enum Slot { INPUT_MAP_1, INPUT_MAP_2 }

# Funciones
func _ready() -> void:
	load_settings() # Cargar en automático la configuración.

func exists_settings() -> bool:
	'''
	Que exista, y esta estructurado correctamente.
	'''
	# Verificar que exista el archivo.
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	# Asegurar que se cargo bien el archivo.
	var cfg := ConfigFile.new()
	return cfg.load(SAVE_PATH) == OK

func load_settings() -> void:
	'''
	Carga la config guardada y la re-aplica al InputMap.
	'''
	# Verificar que exista el archivo.
	if not FileAccess.file_exists(SAVE_PATH):
		return
	# Asegurar que se cargo bien el archivo.
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	# Ahora si cargar configuración.
	for action in _action_names():
		# Obtener nombres de acciones, y determinar que este en el `controls.conf`.
		var events: Array = cfg.get_value("controls", action, [])
		if (
			events.is_empty() and not cfg.has_section_key("controls", action)):
			continue # Esta acción no se toco, conserva su default.
		# Remplazar con `InputMap`. Función interna de godot.
		InputMap.action_erase_events(action)
		for event in events:
			InputMap.action_add_event(action, event)

func save_settings() -> void:
	'''
	Guarda el estado completo de las acciones
	
	Crea nuevo archivo, le añade los valores el archivo do configuración, y guarda.
	'''
	var cfg := ConfigFile.new()
	for action in _action_names():
		cfg.set_value("controls", action, InputMap.action_get_events(action))
	cfg.save(SAVE_PATH)

func _action_names() -> Array[StringName]:
	'''
	Todas las acciones de todos los jugadores, sacadas de `GlobalUtils`.
	player1_left, player2_right, etc...
	'''
	var names: Array[StringName] = []
	for player in GlobalUtils.PLAYER_INPUT_MAPS.values():
		names.append_array([
			player.move_left, player.move_right, player.move_up, player.move_down,
			player.jump, player.attack, player.walk, player.grab, player.shield,
			player.power_attack])
	return names

# Captura de input
func matches_slot(event: InputEvent, slot: Slot) -> bool:
	## Determina que el evento es slot permitido.
	match slot:
		Slot.INPUT_MAP_1:
			return event is InputEventKey or event is InputEventMouseButton
		Slot.INPUT_MAP_2:
			return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return false

func normalize_captured_event(event: InputEvent, slot: Slot) -> InputEvent: 
	## Filtro y normalizar. Retorna input event o valor nulo
	## Si retorna nulo significa que no matchea.
	match slot:
		# 1 para teclado, 2 para joystick
		Slot.INPUT_MAP_1:
			if event is InputEventKey and event.pressed and not event.echo:
				event.device = -1
				return event
		Slot.INPUT_MAP_2:
			if event is InputEventJoypadButton and event.pressed:
				return event
			if event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
				event.axis_value = signf(event.axis_value)
				return event
	return null

func apply_binding(action: StringName, slot: Slot, new_event: InputEvent) -> void:
	## Guardar con InputMap, clase estática de Godot.
	for event in InputMap.action_get_events(action):
		if matches_slot(event, slot):
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, new_event)

func get_bind_text(action: StringName, slot: Slot) -> String:
	## Esta posiblemente no debe estar aquí, pero por ahora lo estará.
	for event in InputMap.action_get_events(action):
		if matches_slot(event, slot):
			return event.as_text()
	return "None"
