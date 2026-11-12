class_name CharacterMenu
extends CanvasLayer

'''
Pantalla de selección de personaje. Guarda el modelo de estado (4 slots, un cursor por jugador humano y el ratón),
aplica las reglas de elegir/cancelar/CPU y lo pinta con apply_state(). Al arrancar llena MatchSetup.
'''

# Enumeraciones
enum SlotKind { EMPTY, PLAYER, CPU }
enum Zone { ROSTER, CARDS }

# Constantes
const ROSTER_TILE_SCENE := "res://ui/components/character_menu/roster_tile.tscn"
const MAIN_MENU_SCENE := "res://ui/main_menu.tscn"
const LEVEL_SCENE := "res://scenes/levels/map1.tscn"
const FIGHT_HUD_SCENE := "res://ui/fight_hud.tscn"
const BLINK_INTERVAL := 0.4
const POP_SCALE := 1.2 # Escala inicial del rebote al aparecer, igual que el anuncio de la partida.
const POP_DURATION := 0.25
const SLOT_COUNT := 4
const HUMAN_COUNT := 2 # P1 = slot 0 y P2 = slot 1, siempre unidos.
const CONTROLLER_NONE := -2
const CONTROLLER_MOUSE := -1 # Los humanos usan su número (0, 1).
const NO_SLOT := -1
const CPU_CONTROLLER := 0 # Solo P1 controla la selección de los CPU (sin ratón).
const LIVES_MIN := 1
const LIVES_MAX := 9
const TIME_OPTIONS: Array[int] = [0, 2, 3, 5, 8] # Minutos, 0 = sin límite.
const STICK_THRESHOLD := 0.5
const KEY_SEPARATOR := " · "

# Clases
class SlotModel:
	extends RefCounted

	var kind: SlotKind = SlotKind.EMPTY
	var fighter_id: StringName = CharacterCatalog.RANDOM_ID
	var state: SlotCard.State = SlotCard.State.CHOOSING
	var controller: int = CONTROLLER_NONE
	var backup_fighter_id: StringName = CharacterCatalog.RANDOM_ID # Lo que tenía la tarjeta antes de empezar a elegir.
	var confirmed: bool = false # Si ya se eligió un personaje alguna vez (un jugador recién unido no).

class CursorModel:
	extends RefCounted

	var zone: Zone = Zone.ROSTER
	var tile_index: int = 0
	var controlled_slot: int = NO_SLOT
	var joined: bool = false

# Propiedades públicas
var lives: int = 3
var time_index: int = 0

# Propiedades privadas
var _tiles: Dictionary[StringName, RosterTile] = {}
var _roster: Array[CharacterCatalog.Entry] = []
var _cards: Array[SlotCard] = []
var _slots: Array[SlotModel] = []
var _cursors: Array[CursorModel] = []
var _mouse_slot: int = NO_SLOT
var _p1_bot: bool = false # Modo bot de P1 (teclado/pad): apunta a la tarjeta donde irá un CPU.
var _p1_bot_target: int = NO_SLOT
var _mouse_bot: bool = false # Modo bot del ratón: el destino es la tarjeta bajo el puntero.
var _mouse_bot_target: int = NO_SLOT
var _last_bot_target: int = NO_SLOT # Último destino del modo bot (compartido entre teclado y ratón).
var _held_axes: Dictionary[StringName, bool] = {}
var _banner_visible: bool = false
var _hint_move: KeyHint = null
var _hint_select: KeyHint = null
var _hint_cancel: KeyHint = null
var _hint_fight: KeyHint = null
var _banner_dismissed: bool = false # Esc lo ocultó con todos READY; Enter lo vuelve a mostrar, o reaparece cuando la condición pase de falsa a verdadera.
var _banner_option: int = 0 # 0 = Sí, 1 = No.
var _banner_cursor_on: bool = true
var _banner_blink_tween: Tween = null
var _banner_pop_tween: Tween = null

# Propiedades privadas | Nodos
@onready var _tiles_container: Container = %Tiles
@onready var _banner: Control = %ReadyBanner
@onready var _banner_options: Array[Control] = [%YesOption, %NoOption]
@onready var _banner_cursors: Array[Label] = [%YesCursor, %NoCursor]
@onready var _banner_texts: Array[Label] = [%YesText, %NoText]
@onready var _lives_rule: RuleSelector = %LivesRule
@onready var _time_rule: RuleSelector = %TimeRule
@onready var _footer: Container = %Footer
@onready var _back_hint: KeyHint = %BackHint

# Funciones | Callbacks
func _ready() -> void:
	_cards = [%Card1, %Card2, %Card3, %Card4]
	var tile_scene: PackedScene = load(ROSTER_TILE_SCENE)
	_roster = CharacterCatalog.all()
	for i: int in _roster.size():
		var tile: RosterTile = tile_scene.instantiate()
		_tiles_container.add_child(tile)
		tile.setup(_roster[i])
		tile.pressed.connect(_on_tile_pressed.bind(i))
		tile.hovered.connect(_on_tile_hovered.bind(i))
		_tiles[_roster[i].id] = tile
	for i: int in SLOT_COUNT:
		_cards[i].pressed.connect(_on_card_pressed.bind(i))
	_lives_rule.setup("Vidas", str(lives))
	_lives_rule.step_requested.connect(_on_lives_step)
	_time_rule.setup("Tiempo", _time_text())
	_time_rule.step_requested.connect(_on_time_step)
	_setup_footer()
	for i: int in SLOT_COUNT:
		var join_key: String = _action_key_text(GlobalUtils.PLAYER_INPUT_MAPS[i as GlobalUtils.PlayerId].attack) if i < HUMAN_COUNT else ""
		_cards[i].set_join_prompt(i < HUMAN_COUNT, join_key)
	_banner.visible = false
	# Cada opción del letrero se selecciona con el hover y se confirma con clic; los hijos no tapan el ratón.
	for i: int in _banner_options.size():
		_banner_options[i].mouse_entered.connect(_select_banner_option.bind(i))
		_banner_options[i].gui_input.connect(_on_banner_option_input.bind(i))
	_refresh_banner_options()
	# El aviso "Esc Regresar" también se puede clicar: hace lo mismo que Esc.
	_back_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	_back_hint.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for child: Node in _back_hint.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_hint.gui_input.connect(_on_back_hint_input)
	_reset_model()
	_refresh.call_deferred() # Con el layout ya acomodado, para que el letrero rebote desde su centro.

func _input(event: InputEvent) -> void:
	'''
	Se usa _input y no _unhandled_input para que ningún control con foco se coma las teclas globales.
	Tab, Enter y Esc son teclas físicas: ui_accept/ui_cancel las comparten todos los pads.
	'''
	if _banner_visible:
		_handle_banner_input(event) # La pregunta bloquea el resto de la pantalla mientras está visible.
		return
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		_toggle_mouse_bot(mouse.position)
		_refresh()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _mouse_bot:
		var hovered: int = _bot_target_at(motion.position)
		if hovered != NO_SLOT: # Al sacar el puntero de las tarjetas el borde se queda donde estaba.
			_set_mouse_target(hovered)
		_refresh()
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_TAB:
				get_viewport().set_input_as_handled()
				_toggle_p1_bot()
				_refresh()
				return
			KEY_ENTER, KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				if _banner_visible:
					_start_match()
				elif _banner_dismissed:
					_banner_dismissed = false # Oculto por Esc con todos READY: Enter lo vuelve a mostrar.
					_update_banner()
					_update_hints()
				return
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				_go_back()
				return
	for human: int in HUMAN_COUNT:
		if _handle_player_event(human, event):
			get_viewport().set_input_as_handled()
			return

# Funciones
func apply_state(slots: Array[Dictionary]) -> void:
	'''
	Repinta tarjetas y pestañas. Un dict por slot (hasta 4):
	{ "kind": "player"|"cpu"|"empty", "fighter": StringName, "state": SlotCard.State, "active": bool, "controller": int }
	'''
	var tabs_by_tile: Dictionary[StringName, Array] = {}
	for i: int in mini(slots.size(), SLOT_COUNT):
		var data: Dictionary = slots[i]
		var kind: String = String(data.get("kind", "empty"))
		var state: SlotCard.State = data.get("state", SlotCard.State.EMPTY) as SlotCard.State
		if kind == "empty":
			state = SlotCard.State.EMPTY
		var fighter_id: StringName = StringName(data.get("fighter", CharacterCatalog.RANDOM_ID))
		var entry: CharacterCatalog.Entry = CharacterCatalog.get_entry(fighter_id)

		var card: SlotCard = _cards[i]
		card.set_slot(i, kind == "cpu")
		card.set_fighter(entry)
		card.set_state(state)
		card.set_active(bool(data.get("active", false)), int(data.get("controller", -1)))

		if state != SlotCard.State.EMPTY and entry != null:
			if not tabs_by_tile.has(entry.id):
				tabs_by_tile[entry.id] = []
			tabs_by_tile[entry.id].append({
				"slot": i,
				"label": KernelPalette.slot_label(i, kind != "cpu"),
				"choosing": state == SlotCard.State.CHOOSING,
			})

	for id: StringName in _tiles:
		var tabs: Array[Dictionary] = []
		tabs.assign(tabs_by_tile.get(id, []))
		_tiles[id].set_tabs(tabs)

func show_ready_banner(show_banner: bool) -> void:
	'''
	Muestra u oculta la pregunta "¿LISTOS PARA PELEAR?" con rebote al aparecer. Siempre arranca en "Sí",
	con el cursor ">" parpadeando delante de la opción elegida.
	'''
	_kill_banner_tweens()
	_banner.visible = show_banner
	if not show_banner:
		return
	_banner_option = 0
	_banner_cursor_on = true
	_refresh_banner_options()
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2(POP_SCALE, POP_SCALE)
	_banner_pop_tween = create_tween()
	_banner_pop_tween.tween_property(_banner, "scale", Vector2.ONE, POP_DURATION).from(Vector2(POP_SCALE, POP_SCALE)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_blink_tween = create_tween().set_loops()
	_banner_blink_tween.tween_callback(func() -> void:
		_banner_cursor_on = not _banner_cursor_on
		_refresh_banner_options()).set_delay(BLINK_INTERVAL)

func _refresh_banner_options() -> void:
	'''
	Opción elegida en ink con el ">" parpadeando (alfa, para no mover el texto); la otra en muted y sin cursor.
	'''
	for i: int in _banner_options.size():
		var selected: bool = i == _banner_option
		_banner_texts[i].add_theme_color_override(&"font_color", KernelPalette.get_color(&"ink") if selected else KernelPalette.get_color(&"ink_muted"))
		_banner_cursors[i].self_modulate.a = 1.0 if selected and _banner_cursor_on else 0.0

func _select_banner_option(index: int) -> void:
	if not _banner_visible or index == _banner_option:
		return
	_banner_option = index
	_banner_cursor_on = true
	_refresh_banner_options()

func _confirm_banner() -> void:
	'''
	Sí arranca la partida; No oculta el letrero (igual que Esc).
	'''
	if _banner_option == 0:
		_start_match()
	else:
		_hide_banner()

func _go_back() -> void:
	'''
	Esc o clic en "Esc Regresar": con la pregunta a la vista solo la oculta; si no, regresa al menú principal.
	'''
	if _banner_visible:
		_hide_banner()
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_back_hint_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_go_back()

func _hide_banner() -> void:
	_banner_dismissed = true
	_update_banner()
	_update_hints()

func _handle_banner_input(event: InputEvent) -> void:
	'''
	Con el letrero visible solo responde él, y solo con los controles de P1 (el anfitrión) o el ratón:
	izquierda/derecha cambian la opción, Enter o attack confirman, Esc o cancelar lo ocultan. El resto del teclado y los pads se consume para que nadie toque las tarjetas.
	'''
	var viewport: Viewport = get_viewport() # La partida puede sacar esta escena del árbol al confirmar.
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER:
				viewport.set_input_as_handled()
				_confirm_banner()
				return
			KEY_ESCAPE:
				viewport.set_input_as_handled()
				_hide_banner()
				return
	# Las demás teclas: solo los controles de P1, el anfitrión, responden la pregunta.
	for human: int in [0]:
		var map: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[human as GlobalUtils.PlayerId]
		if _just_pressed(event, map.move_left):
			viewport.set_input_as_handled()
			_select_banner_option(0)
		elif _just_pressed(event, map.move_right):
			viewport.set_input_as_handled()
			_select_banner_option(1)
		elif _just_pressed(event, map.attack):
			viewport.set_input_as_handled()
			_confirm_banner()
		elif _just_pressed(event, map.power_attack):
			viewport.set_input_as_handled()
			_hide_banner()
		else:
			continue
		return
	if key != null:
		viewport.set_input_as_handled() # Cualquier otra tecla no toca las tarjetas mientras está la pregunta.

func _on_banner_option_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and _banner_visible:
		_banner_option = index
		_confirm_banner()

func _kill_banner_tweens() -> void:
	for tween: Tween in [_banner_blink_tween, _banner_pop_tween]:
		if tween != null:
			tween.kill()
	_banner_blink_tween = null
	_banner_pop_tween = null

func _start_match() -> void:
	'''
	Llena MatchSetup con la selección (Aleatorio se resuelve aquí) y arranca la partida.
	'''
	var pool: Array[CharacterCatalog.Entry] = []
	for entry: CharacterCatalog.Entry in _roster:
		if not entry.is_random:
			pool.append(entry)
	var npc_count: int = 0
	
	# Instanciar Nivel; que es un `GameManager`. Y meterle el hud.
	var level: GameManager = load(LEVEL_SCENE).instantiate() as GameManager
	level.add_child(load(FIGHT_HUD_SCENE).instantiate())
	level.set_time_limit(TIME_OPTIONS[time_index])
	
	# Agregar datos de peleadores al game manager.
	for i: int in SLOT_COUNT:
		var data : PowerFighterData = PowerFighterData.new()
		var slot: SlotModel = _slots[i]
		if slot.kind != SlotKind.EMPTY:
			var entry: CharacterCatalog.Entry = CharacterCatalog.get_entry(slot.fighter_id)
			if entry == null or entry.is_random:
				entry = pool.pick_random()
			data.lives = lives
			data.config = entry.config
			if slot.kind == SlotKind.PLAYER:
				data.control = GlobalUtils.ControlType.PLAYER
				data.player_id = i
			else:
				data.control = GlobalUtils.ControlType.NPC
				data.player_id = npc_count
				npc_count += 1
			level.power_fighter_slots.set_slot(i, data)
	
	# Cambiar de scene, al nodo del nivel
	get_tree().change_scene_to_node(level)

# Funciones | Modelo
func _reset_model() -> void:
	_slots.clear()
	_cursors.clear()
	_mouse_slot = NO_SLOT
	for i: int in SLOT_COUNT:
		var slot := SlotModel.new()
		slot.state = SlotCard.State.READY # Si nadie elige, queda Aleatorio.
		_slots.append(slot)
	for i: int in HUMAN_COUNT:
		var cursor := CursorModel.new()
		_cursors.append(cursor)

func _tile_index_of(fighter_id: StringName) -> int:
	for i: int in _roster.size():
		if _roster[i].id == fighter_id:
			return i
	return 0

func _controlled(cursor: CursorModel) -> SlotModel:
	'''
	Tarjeta que controla un humano, o null si no controla ninguna.
	'''
	return _slots[cursor.controlled_slot] if cursor.controlled_slot != NO_SLOT else null

func _restore_unattended(slot: SlotModel) -> void:
	'''
	Una tarjeta no se queda eligiendo sin controlador: vuelve a READY con lo que tenía antes de elegir.
	Un CPU recién agregado que nunca eligió se quita al soltarlo.
	'''
	if slot.kind == SlotKind.EMPTY or slot.state != SlotCard.State.CHOOSING:
		return
	slot.fighter_id = slot.backup_fighter_id
	slot.state = SlotCard.State.READY
	if slot.kind == SlotKind.CPU and not slot.confirmed:
		slot.kind = SlotKind.EMPTY # CPU recién agregado que nunca eligió: se quita al soltarlo.

func _release_controller(controller: int) -> void:
	'''
	Suelta la tarjeta que controla un controlador (humano o ratón). No mueve su cursor.
	'''
	var index: int = _mouse_slot if controller == CONTROLLER_MOUSE else _cursors[controller].controlled_slot
	if index == NO_SLOT:
		return
	var slot: SlotModel = _slots[index]
	if slot.controller == controller:
		slot.controller = CONTROLLER_NONE
		_restore_unattended(slot)
	if controller == CONTROLLER_MOUSE:
		_mouse_slot = NO_SLOT
	else:
		_cursors[controller].controlled_slot = NO_SLOT

func _return_home(human: int) -> void:
	'''
	El cursor del humano deja de controlar: si está unido vuelve a las tarjetas sobre la suya; si no, queda sin zona.
	'''
	var cursor: CursorModel = _cursors[human]
	cursor.zone = Zone.CARDS if cursor.joined else Zone.ROSTER
	cursor.controlled_slot = NO_SLOT

func _evict(index: int) -> void:
	'''
	Le quita la tarjeta a quien la controle; un humano desplazado regresa a su propia tarjeta.
	'''
	var slot: SlotModel = _slots[index]
	var old: int = slot.controller
	if old == CONTROLLER_NONE:
		return
	slot.controller = CONTROLLER_NONE
	_restore_unattended(slot)
	if old == CONTROLLER_MOUSE:
		_mouse_slot = NO_SLOT
		return
	_return_home(old)

func _take_control(controller: int, index: int) -> void:
	'''
	El controlador pasa a elegir en la tarjeta indicada (CHOOSING). Si otro controlador la está
	eligiendo, no se puede tomar (vale para humanos y ratón).
	'''
	var slot: SlotModel = _slots[index]
	if slot.kind == SlotKind.EMPTY:
		return
	if slot.controller != CONTROLLER_NONE and slot.controller != controller:
		return
	if controller >= 0 and controller != CPU_CONTROLLER and slot.kind == SlotKind.CPU:
		return
	if slot.controller == controller:
		if controller != CONTROLLER_MOUSE:
			_cursors[controller].zone = Zone.ROSTER
			_cursors[controller].tile_index = _tile_index_of(slot.fighter_id)
		return
	_release_controller(controller)
	_evict(index)
	slot.controller = controller
	slot.backup_fighter_id = slot.fighter_id
	slot.state = SlotCard.State.CHOOSING
	if controller == CONTROLLER_MOUSE:
		_mouse_slot = index
	else:
		var cursor: CursorModel = _cursors[controller]
		cursor.controlled_slot = index
		cursor.zone = Zone.ROSTER
		cursor.tile_index = _tile_index_of(slot.fighter_id)

func _pick(slot: SlotModel, fighter_id: StringName) -> void:
	slot.fighter_id = fighter_id
	slot.backup_fighter_id = fighter_id
	slot.confirmed = true
	slot.state = SlotCard.State.READY

func _join(human: int) -> void:
	'''
	El humano se une: su tarjeta pasa a CHOOSING con Aleatorio y su cursor a ROSTER. Tiene prioridad sobre un CPU.
	'''
	if _slots[human].kind == SlotKind.CPU:
		_remove_cpu(human)
	var slot: SlotModel = _slots[human]
	var cursor: CursorModel = _cursors[human]
	slot.kind = SlotKind.PLAYER
	slot.confirmed = false
	slot.fighter_id = CharacterCatalog.RANDOM_ID
	slot.backup_fighter_id = CharacterCatalog.RANDOM_ID
	slot.state = SlotCard.State.CHOOSING
	slot.controller = human
	cursor.joined = true
	cursor.zone = Zone.ROSTER
	cursor.controlled_slot = human
	cursor.tile_index = _tile_index_of(slot.fighter_id)

func _join_by_mouse(human: int) -> void:
	'''
	El ratón une al jugador: su tarjeta queda CHOOSING con Aleatorio, controlada por el ratón; su cursor queda en CARDS.
	'''
	var slot: SlotModel = _slots[human]
	var cursor: CursorModel = _cursors[human]
	slot.kind = SlotKind.PLAYER
	slot.confirmed = false
	slot.fighter_id = CharacterCatalog.RANDOM_ID
	slot.controller = CONTROLLER_NONE
	cursor.joined = true
	_return_home(human)
	_take_control(CONTROLLER_MOUSE, human)

func _leave(human: int) -> void:
	'''
	El jugador se sale: su tarjeta queda vacía y su cursor desaparece.
	'''
	_release_controller(human)
	_slots[human].kind = SlotKind.EMPTY
	_slots[human].state = SlotCard.State.READY
	_cursors[human].joined = false
	_cursors[human].zone = Zone.ROSTER

func _add_cpu(index: int = NO_SLOT) -> void:
	'''
	Agrega un CPU en CHOOSING con Aleatorio en el slot indicado, o en el primer vacío en orden de slots (P1 → P4).
	Quien lo agrega lo toma enseguida (modo bot), así que no queda sin controlador.
	Si un humano se une después en ese slot, el humano tiene prioridad y el CPU se quita.
	'''
	if index == NO_SLOT:
		for i: int in SLOT_COUNT:
			if _slots[i].kind == SlotKind.EMPTY:
				index = i
				break
	if index == NO_SLOT or _slots[index].kind != SlotKind.EMPTY:
		return
	var slot: SlotModel = _slots[index]
	slot.kind = SlotKind.CPU
	slot.controller = CONTROLLER_NONE
	slot.fighter_id = CharacterCatalog.RANDOM_ID
	slot.backup_fighter_id = CharacterCatalog.RANDOM_ID
	slot.state = SlotCard.State.CHOOSING
	slot.confirmed = false

func _remove_cpu(index: int) -> void:
	_evict(index)
	_slots[index].kind = SlotKind.EMPTY
	_slots[index].state = SlotCard.State.READY

# Funciones | Modo bot
func _bot_targets() -> Array[int]:
	'''
	Destinos válidos de un CPU: tarjetas vacías y de CPU que nadie esté eligiendo.
	'''
	var targets: Array[int] = []
	for i: int in SLOT_COUNT:
		var slot: SlotModel = _slots[i]
		if slot.kind == SlotKind.EMPTY or (slot.kind == SlotKind.CPU and slot.controller == CONTROLLER_NONE):
			targets.append(i)
	return targets

func _p1_is_busy() -> bool:
	var cursor: CursorModel = _cursors[CPU_CONTROLLER]
	return cursor.controlled_slot != NO_SLOT or (cursor.joined and _slots[CPU_CONTROLLER].state == SlotCard.State.CHOOSING)

func _toggle_p1_bot() -> void:
	if _p1_bot:
		_p1_bot = false
		return
	var targets: Array[int] = _bot_targets()
	if _p1_is_busy() or targets.is_empty():
		return
	_p1_bot = true
	_set_p1_target(_initial_bot_target(targets))

func _toggle_mouse_bot(position: Vector2) -> void:
	if _mouse_bot:
		_mouse_bot = false
		_mouse_bot_target = NO_SLOT
		return
	# Solo entra con un clic derecho sobre una tarjeta que sea destino válido; el borde queda en ESA tarjeta.
	var hovered: int = _bot_target_at(position)
	if _mouse_slot != NO_SLOT or hovered == NO_SLOT:
		return
	_mouse_bot = true
	_set_mouse_target(hovered)

func _initial_bot_target(targets: Array[int]) -> int:
	'''
	Destino con el que arranca el modo bot: el último recordado si sigue siendo válido; si no, el primero.
	'''
	return _last_bot_target if targets.has(_last_bot_target) else targets[0]

func _set_p1_target(index: int) -> void:
	_p1_bot_target = index
	_last_bot_target = index

func _set_mouse_target(index: int) -> void:
	_mouse_bot_target = index
	_last_bot_target = index

func _bot_target_at(position: Vector2) -> int:
	var targets: Array[int] = _bot_targets()
	for i: int in targets:
		if _cards[i].get_global_rect().has_point(position):
			return i
	return NO_SLOT

func _bot_confirm(controller: int, index: int) -> void:
	'''
	Confirma el destino: en una tarjeta vacía crea un CPU en CHOOSING con Aleatorio; en un CPU lo toma para cambiarlo.
	Quien lo confirma lo controla y sale del modo bot.
	'''
	if index == NO_SLOT or not _bot_targets().has(index):
		return
	if _slots[index].kind == SlotKind.EMPTY:
		_add_cpu(index)
	_take_control(controller, index)
	if controller == CONTROLLER_MOUSE:
		_mouse_bot = false
		_mouse_bot_target = NO_SLOT
	else:
		_p1_bot = false

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

func _handle_player_event(human: int, event: InputEvent) -> bool:
	var map: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[human as GlobalUtils.PlayerId]
	if human == CPU_CONTROLLER and _p1_bot:
		return _handle_p1_bot_event(map, event)
	if not _cursors[human].joined and _cursors[human].controlled_slot == NO_SLOT:
		# Solo el ataque principal lo une (y no cuenta como elección); las demás acciones se ignoran pero se consumen.
		if _just_pressed(event, map.attack):
			_join(human)
			_refresh()
			return true
		for action: StringName in [map.move_left, map.move_right, map.move_up, map.move_down, map.jump,
				map.walk, map.grab, map.shield, map.power_attack]:
			if event.is_action(action):
				return true
		return false
	if _just_pressed(event, map.move_left):
		_move_horizontal(human, -1)
	elif _just_pressed(event, map.move_right):
		_move_horizontal(human, 1)
	elif _just_pressed(event, map.attack):
		_confirm(human)
	elif _just_pressed(event, map.power_attack):
		_cancel(human)
	else:
		return false
	_refresh()
	return true

func _handle_p1_bot_event(map: PlayerInputMap, event: InputEvent) -> bool:
	'''
	Modo bot de P1: izquierda/derecha mueven el destino, attack confirma, cancelar sale. El resto se consume.
	'''
	if _just_pressed(event, map.move_left):
		_move_bot_target(-1)
	elif _just_pressed(event, map.move_right):
		_move_bot_target(1)
	elif _just_pressed(event, map.attack):
		_bot_confirm(CPU_CONTROLLER, _p1_bot_target)
	elif _just_pressed(event, map.power_attack):
		_p1_bot = false
	else:
		for action: StringName in [map.move_up, map.move_down, map.jump, map.walk, map.grab, map.shield]:
			if event.is_action(action):
				return true
		return false
	_refresh()
	return true

func _move_bot_target(direction: int) -> void:
	var targets: Array[int] = _bot_targets()
	if targets.is_empty():
		return
	_set_p1_target(targets[wrapi(maxi(targets.find(_p1_bot_target), 0) + direction, 0, targets.size())])

func _move_horizontal(human: int, direction: int) -> void:
	# Solo mueve la preselección en ROSTER; en reposo (CARDS) las flechas no hacen nada.
	var cursor: CursorModel = _cursors[human]
	if cursor.zone != Zone.ROSTER:
		return
	var slot: SlotModel = _controlled(cursor)
	cursor.tile_index = wrapi(cursor.tile_index + direction, 0, _roster.size())
	if slot != null:
		slot.fighter_id = _roster[cursor.tile_index].id # Preselección.

func _confirm(human: int) -> void:
	var cursor: CursorModel = _cursors[human]
	if cursor.zone == Zone.CARDS:
		return # En reposo, elegir no hace nada; reabrir la tarjeta es con cancelar.
	var slot: SlotModel = _controlled(cursor)
	if slot == null or slot.state != SlotCard.State.CHOOSING:
		return
	_pick(slot, _roster[cursor.tile_index].id)
	slot.controller = CONTROLLER_NONE
	_return_home(human)

func _cancel(human: int) -> void:
	var cursor: CursorModel = _cursors[human]
	if cursor.zone == Zone.ROSTER:
		var slot: SlotModel = _controlled(cursor)
		if slot == null:
			return
		if slot.kind == SlotKind.PLAYER:
			_leave(human) # Cancelar eligiendo en su propia tarjeta saca al jugador.
			return
		if slot.kind == SlotKind.CPU:
			_remove_cpu(_cursors[human].controlled_slot) # Igual que un jugador: cancelar eligiendo lo quita.
		else:
			_release_controller(human)
		_return_home(human)
		return
	# En reposo, cancelar reabre SU tarjeta READY en CHOOSING; cancelar de nuevo eligiendo saca al jugador.
	var own: SlotModel = _slots[human]
	if cursor.joined and own.kind == SlotKind.PLAYER and own.state == SlotCard.State.READY and own.controller == CONTROLLER_NONE:
		_take_control(human, human)

# Funciones | Callbacks de UI
func _on_tile_pressed(index: int) -> void:
	if _banner_visible:
		return
	if _mouse_slot == NO_SLOT:
		return
	_pick(_slots[_mouse_slot], _roster[index].id)
	_release_controller(CONTROLLER_MOUSE)
	_refresh()

func _on_tile_hovered(index: int) -> void:
	if _banner_visible:
		return
	'''
	Pasar el puntero por una casilla mueve la preselección de la tarjeta que tiene el ratón (se queda al salir).
	'''
	if _mouse_slot == NO_SLOT:
		return
	var slot: SlotModel = _slots[_mouse_slot]
	if slot.state != SlotCard.State.CHOOSING or slot.fighter_id == _roster[index].id:
		return
	slot.fighter_id = _roster[index].id
	_refresh()

func _on_card_pressed(index: int) -> void:
	if _banner_visible:
		return
	if _mouse_bot:
		_bot_confirm(CONTROLLER_MOUSE, index)
	elif _slots[index].kind == SlotKind.EMPTY:
		# Solo los slots de humano: el clic une al jugador. Los CPU se agregan con el modo bot.
		if index < HUMAN_COUNT:
			_join_by_mouse(index)
	elif _slots[index].controller == CONTROLLER_MOUSE:
		_mouse_cancel(index)
	else:
		_take_control(CONTROLLER_MOUSE, index)
	_refresh()

func _mouse_cancel(index: int) -> void:
	'''
	Segundo clic del ratón sobre la tarjeta que está eligiendo: si es CPU se quita, si es un jugador se sale.
	'''
	var slot: SlotModel = _slots[index]
	if slot.kind == SlotKind.CPU:
		_remove_cpu(index)
		return
	_release_controller(CONTROLLER_MOUSE)
	slot.kind = SlotKind.EMPTY
	slot.state = SlotCard.State.READY
	_cursors[index].joined = false
	_cursors[index].controlled_slot = NO_SLOT

func _on_lives_step(direction: int) -> void:
	if _banner_visible:
		return
	lives = clampi(lives + direction, LIVES_MIN, LIVES_MAX)
	_lives_rule.set_value(str(lives))

func _on_time_step(direction: int) -> void:
	if _banner_visible:
		return
	time_index = clampi(time_index + direction, 0, TIME_OPTIONS.size() - 1)
	_time_rule.set_value(_time_text())

# Funciones | Pintado
func _time_text() -> String:
	var minutes: int = TIME_OPTIONS[time_index]
	return "∞" if minutes == 0 else "%d min" % minutes

func _action_key_text(action: StringName) -> String:
	'''
	Texto de la tecla de teclado asignada a la acción, leída del Input Map (sigue bien si se reasignan controles).
	'''
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			var text: String = key.as_text_physical_keycode() if key.physical_keycode != KEY_NONE else key.as_text_keycode()
			return text.replace(" (Physical)", "")
	return "?"

func _action_pair_text(first: StringName, second: StringName) -> String:
	return _action_key_text(first) + KEY_SEPARATOR + _action_key_text(second)

func _update_hints() -> void:
	'''
	Enciende o apaga los avisos del pie según lo que haría cada acción ahora mismo para P1 o P2.
	'''
	var can_move: bool = false
	var can_select: bool = false
	var can_cancel: bool = false
	for human: int in HUMAN_COUNT:
		can_move = can_move or _can_move(human)
		can_select = can_select or _can_confirm(human)
		can_cancel = can_cancel or _can_cancel(human)
	_hint_move.enabled = can_move
	_hint_select.enabled = can_select
	_hint_cancel.enabled = can_cancel
	_hint_fight.enabled = _banner_visible or _banner_dismissed # Oculto por Esc, Enter lo vuelve a mostrar.

func _can_move(human: int) -> bool:
	if human == CPU_CONTROLLER and _p1_bot:
		return true
	var cursor: CursorModel = _cursors[human]
	return cursor.zone == Zone.ROSTER and _controlled(cursor) != null

func _can_confirm(human: int) -> bool:
	if human == CPU_CONTROLLER and _p1_bot:
		return true
	var cursor: CursorModel = _cursors[human]
	if not cursor.joined and cursor.controlled_slot == NO_SLOT:
		return true # Unirse.
	if cursor.zone == Zone.ROSTER:
		var slot: SlotModel = _controlled(cursor)
		return slot != null and slot.state == SlotCard.State.CHOOSING
	return false

func _can_cancel(human: int) -> bool:
	if human == CPU_CONTROLLER and _p1_bot:
		return true
	var cursor: CursorModel = _cursors[human]
	if cursor.zone == Zone.ROSTER:
		return _controlled(cursor) != null
	var own: SlotModel = _slots[human]
	return cursor.joined and own.kind == SlotKind.PLAYER and own.state == SlotCard.State.READY and own.controller == CONTROLLER_NONE

func _setup_footer() -> void:
	var map_1: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[GlobalUtils.PlayerId.PLAYER_1]
	var map_2: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[GlobalUtils.PlayerId.PLAYER_2]
	var texts: Array[Array] = [
		["← ↑ ↓ → · WASD", "Mover"],
		[_action_pair_text(map_1.attack, map_2.attack), "Seleccionar"],
		[_action_pair_text(map_1.power_attack, map_2.power_attack), "Cancelar"],
		["Enter", "Confirmar"],
	]
	var hints: Array[Node] = _footer.get_children()
	for i: int in hints.size():
		var hint := hints[i] as KeyHint
		if hint == null:
			continue
		if i < texts.size():
			hint.setup(texts[i][0], texts[i][1])
		else:
			hint.visible = false
	_hint_move = hints[0] as KeyHint
	_hint_select = hints[1] as KeyHint
	_hint_cancel = hints[2] as KeyHint
	_hint_fight = hints[3] as KeyHint

func _sanitize_bot() -> void:
	'''
	Los destinos del modo bot se revalidan en cada repintado (alguien pudo tomar la tarjeta apuntada).
	'''
	var targets: Array[int] = _bot_targets()
	if _p1_bot:
		if targets.is_empty() or _p1_is_busy():
			_p1_bot = false
		elif not targets.has(_p1_bot_target):
			_set_p1_target(targets[0])
	if _mouse_bot:
		if targets.is_empty() or _mouse_slot != NO_SLOT:
			_mouse_bot = false
			_mouse_bot_target = NO_SLOT
		elif not targets.has(_mouse_bot_target):
			_set_mouse_target(_initial_bot_target(targets))

func _refresh() -> void:
	_sanitize_bot()
	var data: Array[Dictionary] = []
	for i: int in SLOT_COUNT:
		var slot: SlotModel = _slots[i]
		var active: bool = false
		var controller: int = -1
		if slot.kind != SlotKind.EMPTY and slot.controller != CONTROLLER_NONE:
			controller = slot.controller
			active = slot.state == SlotCard.State.CHOOSING
		data.append({
			"kind": ["empty", "player", "cpu"][slot.kind],
			"fighter": slot.fighter_id,
			"state": slot.state if slot.kind != SlotKind.EMPTY else SlotCard.State.EMPTY,
			"active": active,
			"controller": controller,
		})
	apply_state(data)
	for i: int in SLOT_COUNT:
		_cards[i].set_targeted((_p1_bot and i == _p1_bot_target) or (_mouse_bot and i == _mouse_bot_target),
				_action_key_text(GlobalUtils.PLAYER_INPUT_MAPS[GlobalUtils.PlayerId.PLAYER_1].attack))
	_update_banner()
	_update_hints()
	_update_cursor_shapes()

func _update_cursor_shapes() -> void:
	'''
	Mano solo donde un clic hace algo: tarjetas que el ratón puede tomar o quitar y, mientras el ratón
	elige en una tarjeta, las casillas del roster. Flecha en tarjetas que elige un humano.
	'''
	var rule_cursor: Control.CursorShape = Control.CURSOR_ARROW if _banner_visible else Control.CURSOR_POINTING_HAND
	_lives_rule.set_arrows_cursor(rule_cursor)
	_time_rule.set_arrows_cursor(rule_cursor)
	for i: int in SLOT_COUNT:
		var slot: SlotModel = _slots[i]
		var clickable: bool
		if _banner_visible:
			clickable = false # Mientras la pregunta está visible, las tarjetas no reciben clics.
		elif _mouse_bot:
			clickable = _bot_targets().has(i)
		elif slot.kind == SlotKind.EMPTY:
			clickable = i < HUMAN_COUNT # En los demás slots el clic no hace nada.
		else:
			clickable = slot.controller == CONTROLLER_NONE or slot.controller == CONTROLLER_MOUSE
		_cards[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	var mouse_choosing: bool = not _banner_visible and _mouse_slot != NO_SLOT and _slots[_mouse_slot].state == SlotCard.State.CHOOSING
	for tile: RosterTile in _tiles.values():
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if mouse_choosing else Control.CURSOR_ARROW

func _update_banner() -> void:
	var fighters: int = 0
	var all_ready: bool = true
	for slot: SlotModel in _slots:
		if slot.kind == SlotKind.EMPTY:
			continue
		fighters += 1
		if slot.state != SlotCard.State.READY:
			all_ready = false
	var condition: bool = fighters >= 2 and all_ready
	if not condition:
		_banner_dismissed = false
	var should_show: bool = condition and not _banner_dismissed
	if should_show != _banner_visible:
		_banner_visible = should_show
		show_ready_banner(should_show)
