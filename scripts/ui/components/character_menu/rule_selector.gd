@tool
class_name RuleSelector
extends Control

'''
Chip de regla de partida (Vidas, Tiempo) con flechas: "‹ Vidas  3 ›".
Es @tool para que el editor muestre el nombre y valor que pone cada instancia.
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
@onready var _arrows: Array[Label] = [%PrevArrow, %NextArrow] # ‹ resta, › suma.

# Funciones | Callbacks
func _ready() -> void:
	# Solo las flechas son clicables: ‹ resta y › suma. El resto del chip no reacciona.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in _arrows.size():
		_arrows[i].mouse_filter = Control.MOUSE_FILTER_STOP
		_arrows[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if not Engine.is_editor_hint():
			_arrows[i].gui_input.connect(_on_arrow_input.bind(-1 if i == 0 else 1))
	_refresh()

# Funciones
func setup(label: String, value: String) -> void:
	'''
	Define el nombre de la regla y su valor actual.
	'''
	label_text = label
	value_text = value

func set_value(value: String) -> void:
	value_text = value

func set_arrows_cursor(shape: Control.CursorShape) -> void:
	'''
	Forma del cursor sobre las flechas (flecha normal cuando la pantalla las bloquea).
	'''
	for arrow: Label in _arrows:
		arrow.mouse_default_cursor_shape = shape

func _on_arrow_input(event: InputEvent, direction: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		step_requested.emit(direction)

func _refresh() -> void:
	if not is_node_ready():
		return
	_label.text = label_text
	_value.text = value_text
