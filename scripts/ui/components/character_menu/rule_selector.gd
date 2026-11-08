class_name RuleSelector
extends Control

'''
Chip de regla de partida (Vidas, Tiempo) con flechas: "‹ Vidas  3 ›".
'''

# Señales
signal step_requested(direction: int) # -1 flecha izquierda, 1 flecha derecha.

# Propiedades públicas
@export var label_text: String = "":
	set(value):
		label_text = value
		_refresh()
@export var value_text: String = "":
	set(value):
		value_text = value
		_refresh()

# Propiedades privadas | Nodos
@onready var _label: Label = %LabelText
@onready var _value: Label = %ValueText

# Funciones | Callbacks
func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND # Todo el chip es clicable (mitad izquierda resta, derecha suma).
	_refresh()

func _gui_input(event: InputEvent) -> void:
	'''
	Clic en la mitad izquierda o derecha del chip para cambiar el valor.
	'''
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		step_requested.emit(-1 if mouse.position.x < size.x / 2.0 else 1)

# Funciones
func setup(label: String, value: String) -> void:
	'''
	Define el nombre de la regla y su valor actual.
	'''
	label_text = label
	value_text = value

func set_value(value: String) -> void:
	value_text = value

func _refresh() -> void:
	if not is_node_ready():
		return
	_label.text = label_text
	_value.text = value_text
