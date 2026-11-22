class_name MatchMenu
extends CanvasLayer

'''
Pantalla de configuración de partida: escenario, vidas y tiempo. Solo P1 controla (teclado/pad) o el ratón.
Recibe la selección de peleadores que armó CharacterMenu y, al pelear, arma el nivel y arranca la partida.
'''

# Señales
signal back_requested

# Enumeraciones
enum Zone { STAGES, LIVES, TIME }

# Constantes
const STAGE_TILE_SCENE := "res://ui/components/match_menu/stage_tile.tscn"
const FIGHT_HUD_SCENE := "res://ui/fight_hud.tscn"
const LIVES_MIN := 1
const LIVES_MAX := 10
const LIVES_DEFAULT := 3
const TIME_OPTIONS: Array[int] = [0, 1, 2, 3, 5, 10, 15, 20, 30] # Minutos, 0 = sin límite.
const TIME_DEFAULT_INDEX := 0
const HOST_PLAYER := 0 # Solo P1 controla la pantalla.
const NO_STAGE := -1
const STICK_THRESHOLD := 0.5

# Propiedades públicas
var lives: int = LIVES_DEFAULT
var time_index: int = TIME_DEFAULT_INDEX

# Propiedades privadas
var _fighters: Dictionary[int, PowerFighterData] = {}
var _stages: Array[StageCatalog.Entry] = []
var _tiles: Array[StageTile] = []
var _zone: Zone = Zone.STAGES
var _cursor_index: int = 0 # Escenario preseleccionado.
var _chosen_index: int = NO_STAGE
var _held_axes: Dictionary[StringName, bool] = {}

# Propiedades privadas | Nodos
@onready var _stages_container: Container = %Stages
@onready var _back_hint: KeyHint = %BackHint
@onready var _hint_move: KeyHint = %HintMove
@onready var _hint_select: KeyHint = %HintSelect
@onready var _hint_cancel: KeyHint = %HintCancel
@onready var _hint_fight: KeyHint = %HintFight
@onready var _preview_plan: StagePlan = %PreviewPlan
@onready var _preview_glyph: Label = %PreviewGlyph
@onready var _preview_name: Label = %PreviewName
@onready var _lives_row: RuleRow = %LivesRow
@onready var _time_row: RuleRow = %TimeRow
@onready var _ready_banner: ReadyBanner = %ReadyBanner

# Funciones | Callbacks
func _ready() -> void:
	var tile_scene: PackedScene = load(STAGE_TILE_SCENE)
	_stages = StageCatalog.all()
	for i: int in _stages.size():
		var tile: StageTile = tile_scene.instantiate()
		_stages_container.add_child(tile)
		tile.setup(_stages[i])
		tile.pressed.connect(_on_tile_pressed.bind(i))
		tile.hovered.connect(_on_tile_hovered.bind(i))
		_tiles.append(tile)
	_lives_row.step_requested.connect(_on_rule_step.bind(Zone.LIVES))
	_lives_row.hovered.connect(_on_rule_hovered.bind(Zone.LIVES))
	_time_row.step_requested.connect(_on_rule_step.bind(Zone.TIME))
	_time_row.hovered.connect(_on_rule_hovered.bind(Zone.TIME))
	_setup_footer()
	# Los avisos "Esc Regresar" y "Enter Pelear" también se pueden clicar.
	_make_clickable(_back_hint)
	_back_hint.gui_input.connect(_on_back_hint_input)
	_make_clickable(_hint_fight)
	_hint_fight.gui_input.connect(_on_fight_hint_input)
	_ready_banner.answered.connect(_on_banner_answered)
	_refresh()

func _input(event: InputEvent) -> void:
	'''
	Se usa _input y no _unhandled_input para que ningún control con foco se coma las teclas globales.
	'''
	var viewport: Viewport = get_viewport() # La partida puede sacar esta escena del árbol al pelear.
	if _ready_banner.is_open:
		_handle_banner_input(event) # La pregunta bloquea el resto de la pantalla mientras está visible.
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER:
				viewport.set_input_as_handled()
				_ask_ready()
				return
			KEY_ESCAPE:
				viewport.set_input_as_handled()
				back_requested.emit()
				return
	var map: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[HOST_PLAYER as GlobalUtils.PlayerId]
	var was_chosen: bool = _chosen_index != NO_STAGE
	if _just_pressed(event, map.move_left):
		_move_horizontal(-1)
	elif _just_pressed(event, map.move_right):
		_move_horizontal(1)
	elif _just_pressed(event, map.move_up):
		_move_zone(-1)
	elif _just_pressed(event, map.move_down):
		_move_zone(1)
	elif _just_pressed(event, map.attack):
		_select_preselected()
		if not was_chosen and _chosen_index != NO_STAGE:
			_ask_ready() # El letrero aparece al pasar de sin elegido a elegido.
	elif _just_pressed(event, map.power_attack):
		_chosen_index = NO_STAGE
	else:
		return
	viewport.set_input_as_handled()
	_refresh()

# Funciones
func setup(fighters: Dictionary[int, PowerFighterData]) -> void:
	'''
	Recibe los peleadores por slot (sin vidas): las vidas se aplican al arrancar la partida.
	'''
	_fighters = fighters

func _make_clickable(hint: KeyHint) -> void:
	hint.mouse_filter = Control.MOUSE_FILTER_STOP
	hint.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for child: Control in hint.find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Funciones | Input
func _just_pressed(event: InputEvent, action: StringName) -> bool:
	'''
	Un paso por pulsación. El stick manda un evento por movimiento, así que se detecta el cruce del umbral.
	'''
	if not event.is_action(action):
		return false
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var down: bool = absf(motion.axis_value) >= STICK_THRESHOLD and event.is_action_pressed(action)
		var was_down: bool = _held_axes.get(action, false)
		_held_axes[action] = down
		return down and not was_down
	return event.is_action_pressed(action, false)

func _move_horizontal(direction: int) -> void:
	match _zone:
		Zone.STAGES:
			if _stage_locked():
				return
			_cursor_index = wrapi(_cursor_index + direction, 0, _stages.size())
		Zone.LIVES, Zone.TIME:
			_step_rule(_zone, direction)

func _move_zone(direction: int) -> void:
	_zone = clampi(_zone + direction, Zone.STAGES, Zone.TIME) as Zone

func _step_rule(zone: Zone, direction: int) -> void:
	if zone == Zone.LIVES:
		lives = clampi(lives + direction, LIVES_MIN, LIVES_MAX)
	else:
		time_index = clampi(time_index + direction, 0, TIME_OPTIONS.size() - 1)

func _select_preselected() -> void:
	if _zone == Zone.STAGES and not _stage_locked():
		_chosen_index = _cursor_index

func _stage_locked() -> bool:
	'''
	Con un escenario elegido no se puede preseleccionar ni elegir otro hasta soltarlo con L.
	'''
	return _chosen_index != NO_STAGE

# Funciones | Callbacks de UI
func _on_tile_hovered(index: int) -> void:
	if _ready_banner.is_open:
		return
	_zone = Zone.STAGES
	if not _stage_locked():
		_cursor_index = index
	_refresh()

func _on_tile_pressed(index: int) -> void:
	'''
	Clic elige la casilla; otro clic sobre la elegida la suelta (como L). Las demás no responden mientras haya una elegida.
	'''
	if _ready_banner.is_open:
		return
	_zone = Zone.STAGES
	if not _stage_locked():
		_cursor_index = index
		_chosen_index = index
		_ask_ready()
	elif index == _chosen_index:
		_chosen_index = NO_STAGE
	_refresh()

func _on_rule_hovered(zone: Zone) -> void:
	if _ready_banner.is_open:
		return
	_zone = zone
	_refresh()

func _on_rule_step(direction: int, zone: Zone) -> void:
	if _ready_banner.is_open:
		return
	_zone = zone
	_step_rule(zone, direction)
	_refresh()

func _on_back_hint_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and not _ready_banner.is_open:
		get_viewport().set_input_as_handled()
		back_requested.emit()

func _on_fight_hint_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_ask_ready()

func _on_banner_answered(yes: bool) -> void:
	'''
	Sí arranca la partida; No oculta el letrero y deja el escenario elegido.
	'''
	if yes:
		_fight()
	else:
		_hide_banner()

# Funciones | Letrero
func _ask_ready() -> void:
	'''
	Muestra la pregunta "¿LISTOS?" solo si hay escenario elegido.
	'''
	if _chosen_index == NO_STAGE or _ready_banner.is_open:
		return
	_ready_banner.popup()
	_refresh()

func _hide_banner() -> void:
	_ready_banner.close()
	_refresh()

func _handle_banner_input(event: InputEvent) -> void:
	'''
	Con el letrero visible solo responde P1 (← → mueven, attack confirma, cancelar = No), Enter, Esc y el ratón.
	El resto del teclado se consume para que nadie toque la pantalla.
	'''
	var viewport: Viewport = get_viewport() # La partida puede sacar esta escena del árbol al confirmar.
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER:
				viewport.set_input_as_handled()
				_ready_banner.confirm()
				return
			KEY_ESCAPE:
				viewport.set_input_as_handled()
				_hide_banner()
				return
	var map: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[HOST_PLAYER as GlobalUtils.PlayerId]
	if _just_pressed(event, map.move_left):
		_ready_banner.move_option(-1)
	elif _just_pressed(event, map.move_right):
		_ready_banner.move_option(1)
	elif _just_pressed(event, map.attack):
		_ready_banner.confirm()
	elif _just_pressed(event, map.power_attack):
		_hide_banner()
	elif key == null:
		return
	viewport.set_input_as_handled() # Cualquier otra tecla tampoco toca la pantalla mientras está la pregunta.

# Funciones | Partida
func _fight() -> void:
	'''
	Arranca la partida solo si hay escenario elegido.
	'''
	if _chosen_index == NO_STAGE:
		return
	_start_match(StageCatalog.resolve(_stages[_chosen_index]))

func _start_match(stage: StageCatalog.Entry) -> void:
	'''
	Instancia el nivel (un GameManager) con su hud, tiempo y peleadores con vidas, y cambia la escena a él.
	'''
	var level: GameManager = load(stage.scene_path).instantiate() as GameManager
	level.add_child(load(FIGHT_HUD_SCENE).instantiate())
	level.set_time_limit(TIME_OPTIONS[time_index])
	for slot: int in _fighters:
		var data: PowerFighterData = _fighters[slot]
		data.lives = lives
		level.power_fighter_slots.set_slot(slot, data)
	get_tree().change_scene_to_node(level)

# Funciones | Pintado
func _setup_footer() -> void:
	var map: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[HOST_PLAYER as GlobalUtils.PlayerId]
	_hint_move.setup("← ↑ ↓ →", "Mover") # Solo flechas: WASD son de P2.
	_hint_select.setup(KeyText.action_key(map.attack), "Seleccionar")
	_hint_cancel.setup(KeyText.action_key(map.power_attack), "Cancelar")
	_hint_fight.setup("Enter", "Pelear")

func _preview_entry() -> StageCatalog.Entry:
	'''
	En la zona de escenarios muestra el preseleccionado; en las reglas, el elegido (o el último preseleccionado).
	'''
	if _zone != Zone.STAGES and _chosen_index != NO_STAGE:
		return _stages[_chosen_index]
	return _stages[_cursor_index]

func _refresh() -> void:
	for i: int in _tiles.size():
		var state: StageTile.State = StageTile.State.NORMAL
		if i == _chosen_index:
			state = StageTile.State.CHOSEN
		elif _zone == Zone.STAGES and i == _cursor_index:
			state = StageTile.State.PRESELECT
		_tiles[i].set_state(state)
		var clickable: bool = not _stage_locked() or i == _chosen_index # La elegida se suelta con clic.
		_tiles[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW

	var preview: StageCatalog.Entry = _preview_entry()
	_preview_name.text = preview.display_name
	_preview_glyph.visible = preview.is_random
	_preview_plan.visible = not preview.is_random
	if not preview.is_random:
		_preview_plan.scene_path = preview.scene_path

	_lives_row.value_text = str(lives)
	_lives_row.focused = _zone == Zone.LIVES
	_time_row.value_text = _time_text()
	_time_row.focused = _zone == Zone.TIME

	var has_chosen: bool = _chosen_index != NO_STAGE
	_hint_move.enabled = true
	_hint_select.enabled = _zone == Zone.STAGES and not has_chosen
	_hint_cancel.enabled = has_chosen
	_hint_fight.enabled = has_chosen
	_hint_fight.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_chosen else Control.CURSOR_ARROW

func _time_text() -> String:
	var minutes: int = TIME_OPTIONS[time_index]
	return "∞" if minutes == 0 else "%d min" % minutes
