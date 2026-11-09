class_name MainMenu
extends CanvasLayer

# Menú principal: Start abre la selección de personaje y Controls el menú de controles.

# Constantes
const CHARACTER_MENU_SCENE := "res://ui/character_menu.tscn"
const CONTROLS_MENU_SCENE := "res://ui/controls_menu.tscn"

# Propiedades privadas | Nodos
@onready var _start_button: Button = %ButtonStart
@onready var _controls_button: Button = %ButtonControls

# Funciones | Callbacks
func _ready() -> void:
	_start_button.pressed.connect(_open_scene.bind(CHARACTER_MENU_SCENE))
	_controls_button.pressed.connect(_open_scene.bind(CONTROLS_MENU_SCENE))

# Funciones
func _open_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
