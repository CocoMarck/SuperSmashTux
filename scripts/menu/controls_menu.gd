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

var _capturing_player: GlobalUtils.PlayerId
var _capturing_action: StringName
var _capturing_slot: InputSettings.Slot
var _capturing_button: Button
var _capturing_original_text: String

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
	button_1.text = InputSettings.get_bind_text(
		action, InputSettings.Slot.INPUT_MAP_1)
	button_1.pressed.connect(
		_start_capture.bind(
			player_id, action, InputSettings.Slot.INPUT_MAP_1, button_1))
	row.add_child(button_1)

	var button_2 := Button.new()
	button_2.text = InputSettings.get_bind_text(
		action, InputSettings.Slot.INPUT_MAP_2)
	button_2.pressed.connect(
		_start_capture.bind(
			player_id, action, InputSettings.Slot.INPUT_MAP_2, button_2))
	row.add_child(button_2)

	return row

## Guarda en que acción/slot se hizo click para capturar en el siguiente paso.
func _start_capture(
	player_id: GlobalUtils.PlayerId, action: StringName, slot: InputSettings.Slot, button: Button
) -> void:
	_capturing_player = player_id
	_capturing_action = action
	_capturing_slot = slot
	_capturing_button = button
	_capturing_original_text = button.text

# Captura
func _clear_capture() -> void:
	_capturing_action = &""
	_capturing_button = null

func _cancel_capture() -> void:
	if _capturing_button != null:
		_capturing_button.text = _capturing_original_text
	_clear_capture()

## Señal de captura
func _input(event: InputEvent) -> void:
	if _capturing_action.is_empty():
		return
	# Si el evento es de salida, cancelar.
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_capture()
		return
	# Capturar evento
	var new_event: InputEvent = InputSettings.normalize_captured_event(event, _capturing_slot)
	if new_event == null:
		return
	# Guardado de datos. Remplazar con `InputMap`. Función interna de godot.
	InputSettings.apply_binding(_capturing_action, _capturing_slot, new_event)
	InputSettings.save_settings()
	# Poner texto en boton
	_capturing_button.text = InputSettings.get_bind_text(_capturing_action, _capturing_slot)
	_clear_capture()
