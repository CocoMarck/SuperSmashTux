extends Button

const MENU_SCENE := "res://scenes/menu.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_open_menu)

func _open_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
