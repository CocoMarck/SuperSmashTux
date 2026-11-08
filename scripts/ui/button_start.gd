extends Button

const CHARACTER_SELECT_SCENE := "res://ui/character_select.tscn"

func _ready() -> void:
	pressed.connect(_go_to_character_select)

func _go_to_character_select() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
