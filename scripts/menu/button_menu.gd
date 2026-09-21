extends Button

const MAION_MENU_SCENE := "res://scenes/main_menu.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_open_main_menu)

func _open_main_menu() -> void:
	get_tree().change_scene_to_file(MAION_MENU_SCENE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
