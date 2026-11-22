@tool
class_name RuleRow
extends PanelContainer

'''
Fila de una regla de partida (Vidas, Tiempo): "> Vidas  detalle  ‹ 3 ›".
Con foco muestra el cursor parpadeando. Solo las flechas son clicables.
Es @tool para que el editor muestre el texto que pone cada instancia.
'''

# Señales
signal step_requested(direction: int) # -1 flecha izquierda, 1 flecha derecha.
signal hovered # El puntero entró a la fila.

# Constantes
const BLINK_INTERVAL := 0.4
const TEXT_FOCUSED := Color("#E6EDF3")
const TEXT_NORMAL := Color("#C9D1DB")

# Propiedades públicas
@export var rule_text: String = "":
	set(value):
		rule_text = value
		_refresh()
@export var detail_text: String = "":
	set(value):
		detail_text = value
		_refresh()
@export var value_text: String = "":
	set(value):
		value_text = value
		_refresh()
@export var focused: bool = false:
	set(value):
		focused = value
		_refresh()

# Propiedades privadas
var _blink_tween: Tween = null

# Propiedades privadas | Nodos
@onready var _cursor: Label = %Cursor
@onready var _rule_label: Label = %RuleLabel
@onready var _detail_label: Label = %DetailLabel
@onready var _arrows: Array[Label] = [%PrevArrow, %NextArrow] # ‹ resta, › suma.
@onready var _value_label: Label = %ValueLabel

# Funciones | Callbacks
func _ready() -> void:
	# Solo las flechas son clicables; el resto de la fila solo avisa el hover.
	for child: Control in find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in _arrows.size():
		_arrows[i].mouse_filter = Control.MOUSE_FILTER_STOP
		_arrows[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if not Engine.is_editor_hint():
			_arrows[i].gui_input.connect(_on_arrow_input.bind(-1 if i == 0 else 1))
			_arrows[i].mouse_entered.connect(hovered.emit)
	if not Engine.is_editor_hint():
		mouse_entered.connect(hovered.emit)
	_refresh()

func _exit_tree() -> void:
	_stop_blink()

# Funciones
func setup(rule: String, detail: String, value: String) -> void:
	'''
	Define el nombre de la regla, su detalle y su valor actual.
	'''
	rule_text = rule
	detail_text = detail
	value_text = value

func set_value(value: String) -> void:
	value_text = value

func _on_arrow_input(event: InputEvent, direction: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		step_requested.emit(direction)

func _refresh() -> void:
	if not is_node_ready():
		return
	_rule_label.text = rule_text
	_detail_label.text = detail_text
	_detail_label.visible = not detail_text.is_empty()
	_value_label.text = value_text
	theme_type_variation = &"KnRuleRowFocused" if focused else &"KnRuleRow"
	_rule_label.add_theme_color_override(&"font_color", TEXT_FOCUSED if focused else TEXT_NORMAL)
	_refresh_blink()

func _refresh_blink() -> void:
	'''
	El cursor ocupa siempre su lugar: parpadea con el alfa (sin foco, alfa 0) para que el layout no brinque.
	'''
	if not focused or Engine.is_editor_hint():
		_stop_blink()
		_cursor.self_modulate.a = 1.0 if focused else 0.0
		return
	if _blink_tween != null and _blink_tween.is_valid():
		return # Ya parpadea: no reiniciar el ciclo en cada repintado.
	_cursor.self_modulate.a = 1.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(func() -> void: _cursor.self_modulate.a = 1.0 - _cursor.self_modulate.a).set_delay(BLINK_INTERVAL)

func _stop_blink() -> void:
	if _blink_tween != null:
		_blink_tween.kill()
		_blink_tween = null
