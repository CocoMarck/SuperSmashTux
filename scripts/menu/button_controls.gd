extends Button

const CONTROL_SCENE := "res://scenes/controls.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_open_controls)

func _open_controls() -> void:
	get_tree().change_scene_to_file(CONTROL_SCENE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
