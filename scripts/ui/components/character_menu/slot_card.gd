class_name SlotCard
extends PanelContainer

# Tarjeta de un slot de jugador en la selección de personaje: tag, nombre, preview 3D y estado.
# Solo pinta lo que le piden; la lógica de selección vive en CharacterMenu.
# El preview es un mundo 3D propio (Feed) donde el personaje gira; solo renderiza mientras hay modelo.

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
const MARCH_DASH := 8.0 # Guiones del borde que gira en elección.
const MARCH_GAP := 6.0
const MARCH_SPEED := 40.0 # px/s, en sentido horario.
const MARCH_WIDTH := 2.0
const SECONDS_PER_TURN := 6.0
const FAST_TURN_DURATION := 0.6 # Vuelta rápida al elegir, termina de frente.
const FAST_TURN_TRANS := Tween.TRANS_CUBIC
const FAST_TURN_EASE := Tween.EASE_OUT
const IDLE_ANIMATION := &"idle"
const TUX_MESH_OFFSET_Y := -1.2 # Mismo ajuste que PowerFighterConfigurer._build_tux_instance.
const FILL_RATIO := 0.7 # Parte del alto del preview que ocupa el personaje.
const FEET_RATIO := 0.12 # Espacio bajo los pies, como fracción del alto visible.

# Propiedades publicas | Encuadre de la cámara del preview.
@export_group("Camera")
@export var camera_distance: float = 0.0 # Con 0 se calcula con el tamaño del modelo.
@export var camera_height: float = 0.0 # Con 0 se calcula con el tamaño del modelo.

# Propiedades privadas
var _slot: int = 0
var _is_cpu: bool = false
var _state: State = State.EMPTY
var _fighter: CharacterCatalog.Entry = null
var _active: bool = false
var _controller_slot: int = -1
var _blink_tween: Tween = null
var _shown_preview_key: String = ""
var _targeted: bool = false
var _join_prompt_enabled: bool = false # Slot de humano: la tarjeta vacía muestra "[tecla] o [Clic izq.] para unirte".
var _join_key_normal: String = ""
var _join_key_targeted: String = "" # Tecla de P1, que maneja el modo bot por teclado.
var _spinning: bool = false # Giro lento continuo mientras se elige.
var _fast_turn_tween: Tween = null
var _card_style: StyleBoxFlat = null # Copia propia del tema, para no mutar el recurso compartido.
var _marching: bool = false # En elección con controlador: el borde discontinuo gira.
var _border_overlay: MarchingBorder = null # Borde que gira encima del contenido.
var _model: Node3D = null # Modelo que gira en el preview; null con Aleatorio o tarjeta vacía.

# Propiedades privadas | Nodos
@onready var _tag_label: Label = %TagLabel
@onready var _name_label: Label = %NameLabel
@onready var _empty_body: Control = %EmptyBody
@onready var _art: Control = %Art
@onready var _feed: Control = %Feed
@onready var _viewport: SubViewport = %Viewport
@onready var _camera: Camera3D = %Camera
@onready var _turntable: Node3D = %Turntable
@onready var _art_glyph: Label = %ArtGlyph
@onready var _shadow: Control = %Shadow
@onready var _footer: Control = %Footer
@onready var _status_ok: Control = %StatusOk
@onready var _status_choosing: Control = %StatusChoosing
@onready var _cursor: CanvasItem = %Cursor
@onready var _kind_label: Label = %KindLabel
@onready var _join_row: Control = %JoinRow
@onready var _join_key: Label = %JoinKey
@onready var _join_press: Label = $VBox/EmptyBody/JoinRow/Press
@onready var _join_click_key: Label = $VBox/EmptyBody/JoinRow/JoinClickChip/Key
@onready var _join_suffix: Label = $VBox/EmptyBody/JoinRow/Join
@onready var _cpu_row: Control = $VBox/EmptyBody/Row2
@onready var _choosing_text: Label = $VBox/Footer/Row/StatusChoosing/ChoosingText

# Funciones | Callbacks
func _ready() -> void:
	var base := get_theme_stylebox(&"panel") as StyleBoxFlat
	_card_style = base.duplicate() as StyleBoxFlat
	add_theme_stylebox_override(&"panel", _card_style)
	# La escena trae un modelo de muestra para que el preview se vea en el editor; en juego lo pone _show_model().
	for child: Node in _turntable.get_children():
		_turntable.remove_child(child)
		child.queue_free()
	# Los hijos no deben tapar la forma del cursor: solo la tarjeta recibe el hover.
	for child: Control in find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border_overlay = MarchingBorder.new()
	_border_overlay.width = MARCH_WIDTH
	_border_overlay.dash = MARCH_DASH
	_border_overlay.gap = MARCH_GAP
	_border_overlay.speed = MARCH_SPEED
	var corner: float = CORNER_RADIUS - MARCH_WIDTH / 2.0 # Radio de la línea central del trazo.
	_border_overlay.radii = Vector4(corner, corner, corner, corner)
	add_child(_border_overlay) # El contenedor lo acomoda en el área de contenido (1 px adentro del borde).
	set_process(false)
	_refresh()

func _process(delta: float) -> void:
	'''
	Gira el modelo del preview; solo corre mientras hay uno.
	'''
	if _spinning:
		_turntable.rotation.y = wrapf(_turntable.rotation.y + TAU / SECONDS_PER_TURN * delta, 0.0, TAU)

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

func set_join_prompt(show_prompt: bool, key_text: String = "") -> void:
	'''
	Tarjeta vacía de un slot de humano: muestra "[tecla] o [Clic izq.] para unirte". Los demás slots lo ocultan.
	La fila "[Tab] o [Clic der.] agregar CPU" se queda en todos.
	'''
	_join_prompt_enabled = show_prompt
	_join_key_normal = key_text
	_refresh()

func set_targeted(targeted: bool, join_key: String = "") -> void:
	'''
	Modo bot: marca la tarjeta como destino de un CPU (borde discontinuo fijo y "> asignar CPU" / "> cambiar CPU").
	Una tarjeta vacía apuntada muestra solo "[join_key] o [Clic izq.] para asignar".
	'''
	_targeted = targeted
	_join_key_targeted = join_key
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
	var empty_targeted: bool = is_empty and _targeted
	_join_row.visible = _join_prompt_enabled or empty_targeted
	_cpu_row.visible = not empty_targeted
	_join_press.visible = false # Sin "Pulsa": basta con las teclas.
	_join_click_key.text = "Clic izq."
	_join_suffix.text = "para asignar" if empty_targeted else "para unirte"
	var key_text: String = _join_key_targeted if empty_targeted and _join_key_targeted != "" else _join_key_normal
	if key_text != "":
		_join_key.text = key_text
	_art.visible = not is_empty
	_footer.visible = not is_empty or _targeted
	_status_ok.visible = _state == State.READY and not _targeted
	_status_choosing.visible = _state == State.CHOOSING or _targeted
	_choosing_text.text = ("> asignar CPU" if is_empty else "> cambiar CPU") if _targeted else "> eligiendo"
	_kind_label.text = "CPU" if _targeted and is_empty else _kind_text()
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
	if key != _shown_preview_key:
		_shown_preview_key = key
		_clear_model()
		if wants_model:
			_show_model(_fighter)
	_update_spin()

func _show_model(entry: CharacterCatalog.Entry) -> void:
	'''
	Pone el modelo del personaje en el preview, con su material de siempre, y prende el render y el giro.
	'''
	if entry.model == null:
		return
	_model = entry.model.instantiate() as Node3D
	_turntable.add_child(_model)
	_turntable.rotation.y = 0.0

	# La estructura del glb es Raíz/Pivot/Skeleton3D/Mesh y Raíz/AnimationPlayer.
	var mesh := _find_mesh(_model)
	if mesh != null:
		if entry.config == GlobalUtils.PowerFighterConfig.TUX:
			mesh.position.y = TUX_MESH_OFFSET_Y
		_frame_camera(mesh)

	var animation_player := _model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation(IDLE_ANIMATION):
		animation_player.get_animation(IDLE_ANIMATION).loop_mode = Animation.LOOP_LINEAR
		animation_player.play(IDLE_ANIMATION)
	_set_preview_running(true)

func _clear_model() -> void:
	'''
	Quita el modelo del preview y apaga el render y el giro.
	'''
	_set_preview_running(false)
	_kill_fast_turn()
	_spinning = false
	if _model != null:
		_turntable.remove_child(_model)
		_model.queue_free()
		_model = null
	_update_processing()

func _set_preview_running(running: bool) -> void:
	'''
	El SubViewport solo dibuja mientras hay un modelo que mostrar, igual que la OffscreenCam.
	Apagado se oculta, para que no se quede viendo el último cuadro del modelo anterior.
	'''
	_update_processing()
	_feed.visible = running
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if running else SubViewport.UPDATE_DISABLED
	)

func _update_spin() -> void:
	'''
	En CHOOSING el modelo gira lento; al pasar a READY da una vuelta rápida y queda de frente.
	Si arranca en READY (repintado) queda de frente sin vuelta.
	'''
	var has_model: bool = _model != null
	if _state == State.CHOOSING and has_model:
		_kill_fast_turn()
		_spinning = true
	elif _spinning:
		_spinning = false
		if has_model:
			_start_fast_turn()
	elif not _is_fast_turning():
		_turntable.rotation.y = 0.0
	_update_processing()

func _is_fast_turning() -> bool:
	return _fast_turn_tween != null and _fast_turn_tween.is_valid() and _fast_turn_tween.is_running()

func _kill_fast_turn() -> void:
	if _fast_turn_tween != null:
		_fast_turn_tween.kill()
		_fast_turn_tween = null

func _start_fast_turn() -> void:
	_kill_fast_turn()
	var start: float = wrapf(_turntable.rotation.y, 0.0, TAU)
	_turntable.rotation.y = start
	# Del ángulo actual al siguiente múltiplo de TAU, más una vuelta completa.
	_fast_turn_tween = create_tween().set_trans(FAST_TURN_TRANS).set_ease(FAST_TURN_EASE)
	_fast_turn_tween.tween_property(_turntable, "rotation:y", TAU * 2.0, FAST_TURN_DURATION)
	_fast_turn_tween.tween_callback(func() -> void: _turntable.rotation.y = 0.0)

func _update_processing() -> void:
	set_process(_model != null and _spinning)

func _find_mesh(root: Node) -> MeshInstance3D:
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	return meshes[0] as MeshInstance3D if not meshes.is_empty() else null

func _frame_camera(mesh: MeshInstance3D) -> void:
	'''
	Pone la cámara de frente al modelo: ocupa FILL_RATIO del alto y los pies quedan cerca del fondo.
	'''
	var aabb: AABB = mesh.transform * mesh.get_aabb()
	var visible_height: float = aabb.size.y / FILL_RATIO
	var half_fov: float = deg_to_rad(_camera.fov) / 2.0
	var distance: float = camera_distance if camera_distance > 0.0 else visible_height / (2.0 * tan(half_fov))
	var height: float = camera_height if camera_height > 0.0 else aabb.position.y + visible_height * (0.5 - FEET_RATIO)
	_camera.position = Vector3(0.0, height, distance)
	_camera.rotation = Vector3.ZERO

func _refresh_border() -> void:
	'''
	Borde normal de 1 px, activo de 2 px con el color del propio slot de la tarjeta, o sin borde si está vacía
	(ahí lo dibuja _draw discontinuo). El margen interno es fijo para que el contenido no brinque.
	'''
	_card_style.set_content_margin_all(float(ACTIVE_BORDER_WIDTH) / 2.0)
	_marching = _active and _state == State.CHOOSING
	_update_processing()
	# En elección, el color del slot de la tarjeta; quién la mueve ya lo dice el texto ("CPU · P1").
	# Como destino del modo bot gira igual pero en gris: el color del slot llega hasta que entra a elegir.
	_border_overlay.color = KernelPalette.get_color(&"ink_muted") if _targeted else KernelPalette.player_color(_slot)
	_border_overlay.rotating = true
	_border_overlay.active = _marching or _targeted
	if _state == State.EMPTY or _marching or _targeted:
		_card_style.set_border_width_all(0) # En elección el borde lo dibuja el overlay.
	elif _state == State.READY:
		# Marco definitivo de una tarjeta confirmada: 2 px del color de su slot, sin importar quién la confirmó.
		_card_style.set_border_width_all(ACTIVE_BORDER_WIDTH)
		_card_style.border_color = KernelPalette.player_color(_slot)
	else:
		_card_style.set_border_width_all(1)
		_card_style.border_color = BORDER_COLOR

func _refresh_blink() -> void:
	var blinks: bool = _state == State.CHOOSING or _targeted
	if blinks and _blink_tween != null and _blink_tween.is_valid():
		return # Ya parpadea: no reiniciar el ciclo en cada repintado.
	if _blink_tween != null:
		_blink_tween.kill()
		_blink_tween = null
	_cursor.self_modulate.a = 1.0
	if not blinks:
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
