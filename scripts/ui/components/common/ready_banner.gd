class_name ReadyBanner
extends PanelContainer

'''
Letrero de pregunta Sí/No con título configurable (title_text), el cursor ">" parpadeando delante de la opción
activa y rebote al aparecer. No lee el input map: la pantalla que lo usa le enruta el teclado y escucha answered.
'''

# Señales
signal answered(yes: bool)

# Constantes
const BLINK_INTERVAL := 0.4
const POP_SCALE := 1.2 # Escala inicial del rebote al aparecer, igual que el anuncio de la partida.
const POP_DURATION := 0.25
const OPTION_YES := 0
const OPTION_NO := 1

# Propiedades públicas
@export var title_text: String = "¿LISTOS?":
	set(value):
		title_text = value
		if is_node_ready():
			_title.text = title_text
var is_open: bool = false

# Propiedades privadas
var _option: int = OPTION_YES
var _cursor_on: bool = true
var _blink_tween: Tween = null
var _pop_tween: Tween = null

# Propiedades privadas | Nodos
@onready var _title: Label = %Title
@onready var _options: Array[Control] = [%YesOption, %NoOption]
@onready var _cursors: Array[Label] = [%YesCursor, %NoCursor]
@onready var _texts: Array[Label] = [%YesText, %NoText]

# Funciones | Callbacks
func _ready() -> void:
	visible = false
	_title.text = title_text
	# Cada opción se selecciona con el hover y se confirma con clic; sus hijos no tapan el ratón.
	for i: int in _options.size():
		_options[i].mouse_filter = Control.MOUSE_FILTER_STOP
		_options[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for child: Control in _options[i].find_children("*", "Control", true, false):
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_options[i].mouse_entered.connect(select_option.bind(i))
		_options[i].gui_input.connect(_on_option_input.bind(i))
	_refresh_options()

func _exit_tree() -> void:
	_kill_tweens()

# Funciones
func popup() -> void:
	'''
	Muestra el letrero con rebote desde su centro. Siempre arranca en "Sí" con el cursor parpadeando.
	'''
	_kill_tweens()
	is_open = true
	visible = true
	_option = OPTION_YES
	_cursor_on = true
	_refresh_options()
	pivot_offset = size / 2.0
	scale = Vector2(POP_SCALE, POP_SCALE)
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).from(Vector2(POP_SCALE, POP_SCALE)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(func() -> void:
		_cursor_on = not _cursor_on
		_refresh_options()).set_delay(BLINK_INTERVAL)

func close() -> void:
	_kill_tweens()
	is_open = false
	visible = false

func select_option(index: int) -> void:
	if not is_open or index == _option:
		return
	_option = index
	_cursor_on = true
	_refresh_options()

func move_option(direction: int) -> void:
	select_option(clampi(_option + direction, OPTION_YES, OPTION_NO))

func confirm() -> void:
	'''
	Responde con la opción activa; quien escucha decide si cierra el letrero.
	'''
	if is_open:
		answered.emit(_option == OPTION_YES)

func _on_option_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and is_open:
		_option = index
		confirm()

func _refresh_options() -> void:
	'''
	Opción activa en ink con el ">" parpadeando (alfa, para no mover el texto); la otra en muted y sin cursor.
	'''
	for i: int in _options.size():
		var selected: bool = i == _option
		_texts[i].add_theme_color_override(&"font_color", KernelPalette.get_color(&"ink") if selected else KernelPalette.get_color(&"ink_muted"))
		_cursors[i].self_modulate.a = 1.0 if selected and _cursor_on else 0.0

func _kill_tweens() -> void:
	for tween: Tween in [_blink_tween, _pop_tween]:
		if tween != null:
			tween.kill()
	_blink_tween = null
	_pop_tween = null
