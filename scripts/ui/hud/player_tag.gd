class_name PlayerTag
extends VBoxContainer

'''
Etiqueta flotante sobre un peleador (texto + puntero). Puede salirse de pantalla a propósito,
ver docs/ui/nota-ui-responsiva.md.
'''

# Propiedades privadas | Nodos
@onready var _tag_label: Label = %TagLabel
@onready var _pointer_shape: Polygon2D = %PointerShape

# Funciones
func setup(label: String, color: Color) -> void:
	'''
	Pone el texto y colorea texto y puntero con el color del jugador.
	'''
	_tag_label.text = label
	_tag_label.add_theme_color_override("font_color", color)
	_pointer_shape.color = color

func place_at(screen_pos: Vector2) -> void:
	'''
	Coloca la etiqueta para que la punta del puntero (centro de la base) quede en screen_pos.
	No se recorta al viewport.
	'''
	position = screen_pos - Vector2(size.x / 2.0, size.y)
