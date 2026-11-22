class_name StageTile
extends Control

'''
Casilla de un escenario: plano (o "?" con Aleatorio) y nombre.
Solo pinta lo que le piden; la lógica de selección vive en MatchMenu.
'''

# Señales
signal pressed
signal hovered # El puntero entró a la casilla.

# Enumeraciones
enum State { NORMAL, PRESELECT, CHOSEN }

# Constantes
const VARIATIONS: Dictionary[State, StringName] = {
	State.NORMAL: &"KnWindow",
	State.PRESELECT: &"KnStagePreselect",
	State.CHOSEN: &"KnStageChosen",
}
const MARCH_DASH := 8.0 # Mismo borde que gira que el destino del modo bot de las tarjetas.
const MARCH_GAP := 6.0
const MARCH_SPEED := 40.0
const MARCH_WIDTH := 2.0
const CORNER_RADIUS := 6.0

# Propiedades públicas
var entry: StageCatalog.Entry = null

# Propiedades privadas | Nodos
@onready var _frame: PanelContainer = %Frame
@onready var _plan: StagePlan = %Plan
@onready var _glyph: Label = %Glyph
@onready var _name_label: Label = %NameLabel
@onready var _march: MarchingBorder = %March

# Funciones | Callbacks
func _ready() -> void:
	# Sin foco: solo reacciona al clic y no se come Enter de la pantalla.
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(hovered.emit)
	# Los hijos no deben tapar la forma del cursor: solo la casilla recibe el hover.
	for child: Control in find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_march.color = KernelPalette.get_color(&"ink_muted")
	_march.width = MARCH_WIDTH
	_march.dash = MARCH_DASH
	_march.gap = MARCH_GAP
	_march.speed = MARCH_SPEED
	var corner: float = CORNER_RADIUS - MARCH_WIDTH / 2.0
	_march.radii = Vector4(corner, corner, corner, corner)
	set_state(State.NORMAL)

func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()

# Funciones
func setup(p_entry: StageCatalog.Entry) -> void:
	'''
	Muestra el nombre y el plano del escenario (Aleatorio lleva "?" en lugar del plano).
	'''
	entry = p_entry
	_name_label.text = p_entry.display_name
	_glyph.visible = p_entry.is_random
	_plan.visible = not p_entry.is_random
	if not p_entry.is_random:
		_plan.scene_path = p_entry.scene_path

func set_state(state: State) -> void:
	'''
	NORMAL: ventana común. PRESELECT: borde gris que gira. CHOSEN: marco fijo gris claro.
	'''
	_frame.theme_type_variation = VARIATIONS[state]
	_march.active = state == State.PRESELECT
