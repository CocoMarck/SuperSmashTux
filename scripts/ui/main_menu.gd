class_name MainMenu
extends CanvasLayer

# Menú principal: Start abre la selección de personaje y Controls el menú de controles.

# Constantes
const CHARACTER_MENU_SCENE := "res://ui/character_menu.tscn"
const CONTROLS_MENU_SCENE := "res://ui/controls_menu.tscn"

# Constantes DEBUG. No deben estar aquí, pero por debug lo están.
const LEVEL_SCENE := "res://scenes/levels/map1.tscn"
const FIGHT_HUD_SCENE := "res://ui/fight_hud.tscn"

# Propiedades privadas | Nodos
@onready var _start_button: Button = %ButtonStart
@onready var _controls_button: Button = %ButtonControls

# Funciones | Callbacks
func _ready() -> void:
	#_start_button.pressed.connect(_open_scene.bind(CHARACTER_MENU_SCENE))
	_start_button.pressed.connect( _start_debug_match ) # Debug
	_controls_button.pressed.connect(_open_scene.bind(CONTROLS_MENU_SCENE))

# Funciones
func _open_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _start_debug_match() -> void:
	# Para probar el juego de manera rápida

	# Instanciar
	var level: GameManager = load(LEVEL_SCENE).instantiate() as GameManager
	level.add_child(load(FIGHT_HUD_SCENE).instantiate())
	
	# Configurar
	level.fight_sign_seconds = 0
	level.set_time_limit(0)
	level.set_countdown_seconds(0)

	# Agregar información de peleadores
	var data_p1 : PowerFighterData = PowerFighterData.new()
	data_p1.lives = 1
	data_p1.config = GlobalUtils.PowerFighterConfig.TUX
	data_p1.control = GlobalUtils.ControlType.PLAYER
	data_p1.player_id = 0
	
	var data_p2 : PowerFighterData = PowerFighterData.new()
	data_p2.lives = 1
	data_p2.config = GlobalUtils.PowerFighterConfig.TUX
	data_p2.control = GlobalUtils.ControlType.PLAYER
	data_p2.player_id = 1
	
	level.power_fighter_slots.set_slot(2, data_p1)
	level.power_fighter_slots.set_slot(3, data_p2)

	get_tree().change_scene_to_node(level)
