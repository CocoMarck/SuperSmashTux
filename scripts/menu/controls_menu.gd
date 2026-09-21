## Para `controls.tscn`
extends Node2D

# Texto de configuración, y orden de opciones.
const ACTION_LEBELS :Dictionary = {
	# Person
	"move_left": "Move to the left", "move_right": "Move to the right",
	"move_up": "Up actions", "move_down": "Down actions", "jump": "Jump",
	"walk": "Walk", 
	
	# Fighter and PowerFighter
	"attack": "Attack", "grab": "Grabbing",
	"shield": "Use defence", "power_attack": "Powerful attack",}

# Slots de entrada disponibles por arquitectura: dos mapas de input por acción.
enum Slot { INPUT_MAP_1, INPUT_MAP_2 }

var _capturing_player: GlobalUtils.PlayerId
var _capturing_action: StringName
var _capturing_slot: Slot
var _capturing_button: Button

func _ready() -> void:
	# Construir contenido de pestañas.
	var tabs :Dictionary = {
		# TabContainer/VBoxContainer
		GlobalUtils.PlayerId.PLAYER_1: $TabContainer/Player1,
		GlobalUtils.PlayerId.PLAYER_2: $TabContainer/Player2,}
	for player_id in tabs:
		_build_player_tab(player_id, tabs[player_id])
	# Asegurar archivo de configuracion
	InputSettings.save_settings()

## Llena el `VBoxContainer` de un juegador con una fila por acción.
func _build_player_tab(player_id: GlobalUtils.PlayerId, box: VBoxContainer) -> void:
	var pm: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[player_id]
	for base in ACTION_LEBELS.keys():
		var action: StringName = _resolve_action(pm, base)
		box.add_child(_make_row(player_id, ACTION_LEBELS[base], action))

## Devuelve el `StringName` real de la acción de un jugador según su nombre base.
func _resolve_action(pm: PlayerInputMap, base: String) -> StringName:
	match base:
		"move_left": return pm.move_left
		"move_right": return pm.move_right
		"move_up": return pm.move_up
		"move_down": return pm.move_down
		"jump": return pm.jump
		"walk": return pm.walk
		
		"attack": return pm.attack
		"grab": return pm.grab
		"shield": return pm.shield
		"power_attack": return pm.power_attack
	return &""

## Crea la fila con nombre de la acción y sus botones de teclado/pad
func _make_row(player_id: GlobalUtils.PlayerId, label_text: String, action: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var button_1 := Button.new()
	button_1.text = _get_bind_text(action, Slot.INPUT_MAP_1)
	button_1.pressed.connect(
		_start_capture.bind(player_id, action, Slot.INPUT_MAP_1, button_1))
	row.add_child(button_1)

	var button_2 := Button.new()
	button_2.text = _get_bind_text(action, Slot.INPUT_MAP_2)
	button_2.pressed.connect(
		_start_capture.bind(player_id, action, Slot.INPUT_MAP_2, button_2))
	row.add_child(button_2)

	return row

## Texto a mostrar del bind actual de una acción para un slot dado.
func _get_bind_text(action: StringName, slot: Slot) -> String:
	for event in InputMap.action_get_events(action):
		if _matches_slot(event, slot):
			return event.as_text()
	return "None"

## Indica si un evento corresponde al slot (input_map_1 o input_map_2):
func _matches_slot(event: InputEvent, slot: Slot) -> bool:
	match slot:
		Slot.INPUT_MAP_1:
			return event is InputEventKey or event is InputEventMouseButton
		Slot.INPUT_MAP_2:
			return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return false

## Guarda en que acción/slot se hizo click para capturar en el siguiente paso.
func _start_capture(
	player_id: GlobalUtils.PlayerId, action: StringName, slot: Slot, button: Button
) -> void:
	_capturing_player = player_id
	_capturing_action = action
	_capturing_slot = slot
	_capturing_button = button


## Señal de captura
#func _input(event: InputEvent) -> void:
#    if _capturing_action.is_empty():
#        return
#    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
#        return
