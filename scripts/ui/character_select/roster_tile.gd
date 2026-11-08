class_name RosterTile
extends Control

'''
Casilla del roster: glifo, nombre y las pestañas de los jugadores que la tienen marcada.
Solo pinta lo que le piden; la lógica de selección vive en CharacterSelect.
'''

# Señales
signal pressed

# Constantes
const TAB_FONT_SIZE := 10
const TAB_PADDING := Vector4(5, 2, 4, 3) # Izquierda, arriba, derecha, abajo.
const TAB_BORDER := 1
const TAB_MARGIN := 1.0 # Distancia al borde de la casilla.
const TAB_BOTTOM_TOP := 68.0
const TAB_BG_PRESELECT := Color("#0E1116")
const TAB_TEXT_CHOSEN := Color("#0E1116")
# Radios por slot (tl, tr, br, bl).
const TAB_RADII: Array[Vector4i] = [
	Vector4i(4, 3, 3, 0),
	Vector4i(3, 4, 0, 3),
	Vector4i(0, 3, 3, 0),
	Vector4i(3, 0, 0, 3),
]

# Propiedades públicas
var entry: CharacterCatalog.Entry = null

# Propiedades privadas | Nodos
@onready var _glyph: Label = %Glyph
@onready var _name_label: Label = %NameLabel
@onready var _tabs: Control = %Tabs

# Funciones | Callbacks
func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
	elif event.is_action_pressed(&"ui_accept"):
		pressed.emit()
		accept_event()

# Funciones
func setup(p_entry: CharacterCatalog.Entry) -> void:
	'''
	Muestra el nombre y el glifo del personaje (Aleatorio lleva "?").
	'''
	entry = p_entry
	_glyph.text = p_entry.glyph
	_name_label.text = p_entry.display_name

func set_tabs(tabs: Array[Dictionary]) -> void:
	'''
	Repinta las pestañas. Cada dict: { "slot": int 0..3, "label": String, "choosing": bool }.
	'''
	for child: Node in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	for tab: Dictionary in tabs:
		_tabs.add_child(_build_tab(int(tab.get("slot", 0)), String(tab.get("label", "")), bool(tab.get("choosing", false))))

func _build_tab(slot: int, text: String, choosing: bool) -> Label:
	slot = clampi(slot, 0, 3)
	var color: Color = KernelPalette.player_color(slot)
	var style := StyleBoxFlat.new()
	style.bg_color = TAB_BG_PRESELECT if choosing else color
	style.set_border_width_all(TAB_BORDER)
	style.border_color = color
	style.content_margin_left = TAB_PADDING.x
	style.content_margin_top = TAB_PADDING.y
	style.content_margin_right = TAB_PADDING.z
	style.content_margin_bottom = TAB_PADDING.w
	var radii: Vector4i = TAB_RADII[slot]
	style.corner_radius_top_left = radii.x
	style.corner_radius_top_right = radii.y
	style.corner_radius_bottom_right = radii.z
	style.corner_radius_bottom_left = radii.w

	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"KnChip" # Solo por la fuente extrabold.
	label.add_theme_font_size_override(&"font_size", TAB_FONT_SIZE)
	label.add_theme_color_override(&"font_color", color if choosing else TAB_TEXT_CHOSEN)
	label.add_theme_stylebox_override(&"normal", style)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Ancla a la esquina que toca según el slot y crece hacia adentro de la casilla.
	var on_right: bool = slot % 2 == 1
	var top: float = TAB_MARGIN if slot < 2 else TAB_BOTTOM_TOP
	label.anchor_left = 1.0 if on_right else 0.0
	label.anchor_right = label.anchor_left
	label.anchor_top = 0.0
	label.anchor_bottom = 0.0
	label.offset_left = -TAB_MARGIN if on_right else TAB_MARGIN
	label.offset_right = label.offset_left
	label.offset_top = top
	label.offset_bottom = top
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN if on_right else Control.GROW_DIRECTION_END
	label.grow_vertical = Control.GROW_DIRECTION_END
	return label
