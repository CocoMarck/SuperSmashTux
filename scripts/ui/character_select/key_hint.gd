class_name KeyHint
extends Control

'''
Atajo del pie de la pantalla: tecla (o texto de acción) con su descripción.
Los nodos hijos de la escena deben ser %KeyLabel y %ActionLabel.
'''

# Propiedades públicas
@export var key_text: String = "":
	set(value):
		key_text = value
		_refresh()
@export var action_text: String = "":
	set(value):
		action_text = value
		_refresh()

# Propiedades privadas | Nodos
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
	if not is_node_ready():
		return
	_key_label.text = key_text
	_action_label.text = action_text
