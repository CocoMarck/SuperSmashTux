class_name SlotCard
extends PanelContainer

'''
Tarjeta de un slot de jugador en la selección de personaje: tag, nombre, preview 3D y estado.
Solo pinta lo que le piden; la lógica de selección vive en CharacterSelect.
'''

# Señales
signal pressed

# Enumeraciones
enum State { EMPTY, CHOOSING, READY }

# Constantes
const BLINK_INTERVAL := 0.4
const BORDER_COLOR := Color("#343C48")
const NAME_COLOR_CHOOSING := Color("#C9D1DB")
const CORNER_RADIUS := 6.0
const ACTIVE_BORDER_WIDTH := 2
const DASH_LENGTH := 6.0
const DASH_GAP := 4.0

# Propiedades privadas
var _slot: int = 0
var _is_cpu: bool = false
var _state: State = State.EMPTY
var _fighter: CharacterCatalog.Entry = null
var _active: bool = false
var _controller_slot: int = -1
var _blink_tween: Tween = null
var _shown_preview_key: String = ""
var _card_style: StyleBoxFlat = null # Copia propia del tema, para no mutar el recurso compartido.

# Propiedades privadas | Nodos
@onready var _tag_label: Label = %TagLabel
@onready var _name_label: Label = %NameLabel
@onready var _empty_body: Control = %EmptyBody
@onready var _art: Control = %Art
@onready var _preview: CharacterPreview = %Preview
@onready var _art_glyph: Label = %ArtGlyph
@onready var _shadow: Control = %Shadow
@onready var _footer: Control = %Footer
@onready var _status_ok: Control = %StatusOk
@onready var _status_choosing: Control = %StatusChoosing
@onready var _cursor: CanvasItem = %Cursor
@onready var _kind_label: Label = %KindLabel

# Funciones | Callbacks
func _ready() -> void:
	var base := get_theme_stylebox(&"panel") as StyleBoxFlat
	_card_style = base.duplicate() as StyleBoxFlat
	add_theme_stylebox_override(&"panel", _card_style)
	_refresh()

func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()

func _draw() -> void:
	'''
	Borde discontinuo de la tarjeta vacía (el stylebox no lo soporta).
	'''
	if _state != State.EMPTY:
		return
	var rect := Rect2(Vector2.ZERO, size).grow(-0.5)
	var r: float = CORNER_RADIUS
	var left: float = rect.position.x
	var top: float = rect.position.y
	var right: float = rect.end.x
	var bottom: float = rect.end.y
	_draw_dashed(Vector2(left + r, top), Vector2(right - r, top))
	_draw_dashed(Vector2(right, top + r), Vector2(right, bottom - r))
	_draw_dashed(Vector2(right - r, bottom), Vector2(left + r, bottom))
	_draw_dashed(Vector2(left, bottom - r), Vector2(left, top + r))
	# Esquinas: un arco corto por cada una, como si fuera un guion más.
	draw_arc(Vector2(right - r, top + r), r, -PI / 2.0, 0.0, 6, BORDER_COLOR, 1.0)
	draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI / 2.0, 6, BORDER_COLOR, 1.0)
	draw_arc(Vector2(left + r, bottom - r), r, PI / 2.0, PI, 6, BORDER_COLOR, 1.0)
	draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 6, BORDER_COLOR, 1.0)

# Funciones
func set_slot(slot: int, is_cpu: bool) -> void:
	'''
	Define el slot (0..3) y si lo juega un CPU: cambia el tag, el color y el tipo.
	'''
	_slot = clampi(slot, 0, 3)
	_is_cpu = is_cpu
	_refresh()

func set_state(state: State) -> void:
	_state = state
	_refresh()

func set_fighter(entry: CharacterCatalog.Entry) -> void:
	'''
	Define el personaje de la tarjeta (nombre y preview 3D; Aleatorio muestra "?").
	'''
	_fighter = entry
	_refresh()

func set_active(active: bool, controller_slot: int = -1) -> void:
	'''
	Marca la tarjeta como la que se está moviendo: borde de 2 px del color de quien la mueve.
	'''
	_active = active
	_controller_slot = controller_slot
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	var player_color: Color = KernelPalette.player_color(_slot)
	var muted: Color = KernelPalette.get_color(&"ink_muted")
	var is_empty: bool = _state == State.EMPTY

	# Titlebar
	_tag_label.text = KernelPalette.slot_label(_slot, not _is_cpu)
	_tag_label.add_theme_color_override(&"font_color", muted if is_empty else player_color)
	if is_empty:
		_name_label.text = "libre"
		_name_label.add_theme_color_override(&"font_color", muted)
	else:
		_name_label.text = _fighter.display_name if _fighter != null else ""
		_name_label.add_theme_color_override(&"font_color",
			KernelPalette.get_color(&"ink") if _state == State.READY else NAME_COLOR_CHOOSING)

	# Cuerpo
	_empty_body.visible = is_empty
	_art.visible = not is_empty
	_footer.visible = not is_empty
	_status_ok.visible = _state == State.READY
	_status_choosing.visible = _state == State.CHOOSING
	_kind_label.text = _kind_text()
	_refresh_preview()
	_refresh_border()
	_refresh_blink()
	queue_redraw()

func _kind_text() -> String:
	if not _is_cpu:
		return "JUGADOR"
	if _controller_slot >= 0 and _controller_slot != _slot:
		return "CPU · P%d" % (_controller_slot + 1)
	return "CPU"

func _refresh_preview() -> void:
	'''
	Evita reinstanciar el modelo si no cambió el personaje ni el slot.
	'''
	var wants_model: bool = _state != State.EMPTY and _fighter != null and not _fighter.is_random
	_art_glyph.visible = _state != State.EMPTY and _fighter != null and _fighter.is_random
	_art_glyph.text = "?"
	# La sombra del piso solo tiene sentido con un modelo encima.
	_shadow.visible = wants_model
	var key: String = "%s:%d" % [_fighter.id, _slot] if wants_model else ""
	if key == _shown_preview_key:
		return
	_shown_preview_key = key
	if wants_model:
		_preview.show_character(_fighter, _slot)
	else:
		_preview.clear()

func _refresh_border() -> void:
	'''
	Borde normal de 1 px, activo de 2 px con el color de quien mueve la tarjeta, o sin borde si está vacía
	(ahí lo dibuja _draw discontinuo). El margen interno es fijo para que el contenido no brinque.
	'''
	_card_style.set_content_margin_all(float(ACTIVE_BORDER_WIDTH) / 2.0)
	if _state == State.EMPTY:
		_card_style.set_border_width_all(0)
	elif _active:
		_card_style.set_border_width_all(ACTIVE_BORDER_WIDTH)
		var who: int = _controller_slot if _controller_slot >= 0 else _slot
		_card_style.border_color = KernelPalette.player_color(who)
	else:
		_card_style.set_border_width_all(1)
		_card_style.border_color = BORDER_COLOR

func _refresh_blink() -> void:
	if _state == State.CHOOSING and _blink_tween != null and _blink_tween.is_valid():
		return # Ya parpadea: no reiniciar el ciclo en cada repintado.
	if _blink_tween != null:
		_blink_tween.kill()
		_blink_tween = null
	_cursor.self_modulate.a = 1.0
	if _state != State.CHOOSING:
		return
	# El cursor parpadea con transparencia para no mover el texto de al lado.
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(func() -> void: _cursor.self_modulate.a = 1.0 - _cursor.self_modulate.a).set_delay(BLINK_INTERVAL)

func _draw_dashed(from: Vector2, to: Vector2) -> void:
	var length: float = from.distance_to(to)
	var direction: Vector2 = from.direction_to(to)
	var traveled: float = 0.0
	while traveled < length:
		var end: float = minf(traveled + DASH_LENGTH, length)
		draw_line(from + direction * traveled, from + direction * end, BORDER_COLOR, 1.0)
		traveled += DASH_LENGTH + DASH_GAP
