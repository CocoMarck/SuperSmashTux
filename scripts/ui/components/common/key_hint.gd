@tool
class_name KeyHint
extends PanelContainer

# Aviso de tecla: la tecla en su recuadro y la acción al lado ("Esc Pausar", "Enter Elegir").
# Una sola pieza para todos los avisos; la variante decide el estilo según dónde va.
# Es @tool para que el editor muestre la variante elegida.

# Enumeraciones
enum Variant {
	FOOTER, # Pie de un menú: sin fondo, texto de 13 px.
	OVERLAY, # Sobre el juego: fondo semitransparente, texto de 18 px.
	SOLID, # Sobre un fondo opaco: fondo sólido, texto de 18 px.
}

# Constantes | Variaciones del theme por variante: [panel, recuadro de tecla, texto de tecla, texto de acción].
const VARIANT_STYLES: Dictionary[Variant, Array] = {
	Variant.FOOTER: [&"KnHintBare", &"KnKeySmall", &"KnTileName", &"KnFooterText"],
	Variant.OVERLAY: [&"KnHint", &"KnHintKey", &"KnHintText", &"KnHintText"],
	Variant.SOLID: [&"KnPanelSolid", &"KnHintKey", &"KnHintText", &"KnHintText"],
}

# Propiedades públicas
@export var variant: Variant = Variant.FOOTER:
	set(value):
		variant = value
		_refresh()
@export var key_text: String = "Esc":
	set(value):
		key_text = value
		_refresh()
@export var action_text: String = "Regresar":
	set(value):
		action_text = value
		_refresh()

@export var enabled: bool = true:
	set(value):
		enabled = value
		_refresh()

# Constantes
const DISABLED_ALPHA := 0.35 # Aviso apagado: se ve atenuado pero no se oculta ni se mueve.

# Propiedades privadas | Nodos
@onready var _key_chip: PanelContainer = %KeyChip
@onready var _key_label: Label = %KeyLabel
@onready var _action_label: Label = %ActionLabel

# Funciones | Callbacks
func _ready() -> void:
	_refresh()

# Funciones
func setup(key: String, action: String) -> void:
	'''
	Define el texto de la tecla y de la acción.
	'''
	key_text = key
	action_text = action

func _refresh() -> void:
	modulate.a = 1.0 if enabled else DISABLED_ALPHA
	if not is_node_ready():
		return
	var styles: Array = VARIANT_STYLES[variant]
	theme_type_variation = styles[0]
	_key_chip.theme_type_variation = styles[1]
	_key_label.theme_type_variation = styles[2]
	_action_label.theme_type_variation = styles[3]
	_key_label.text = key_text
	_action_label.text = action_text
