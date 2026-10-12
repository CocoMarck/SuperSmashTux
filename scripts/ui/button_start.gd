extends Button

const LEVEL_SCENE := "res://scenes/levels/map1.tscn"
const FIGHT_HUD_SCENE := "res://ui/fight_hud.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_go_to_battle)

func _go_to_battle() -> void:
	# Agregarle interface a la instancia de nivel.
	var level: Node = load(LEVEL_SCENE).instantiate()
	var canvas_layer: CanvasLayer = load(FIGHT_HUD_SCENE).instantiate()
	level.add_child(canvas_layer)
	# Meter como hijo la scene del level
	get_tree().change_scene_to_node(level)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
