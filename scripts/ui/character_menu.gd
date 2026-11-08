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
	var card_index: int = 0
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
var _held_axes: Dictionary[StringName, bool] = {}
var _banner_visible: bool = false
var _banner_dismissed: bool = false # Esc lo ocultó; vuelve cuando la condición pase de falsa a verdadera.
var _banner_blink_tween: Tween = null
var _banner_pop_tween: Tween = null

# Propiedades privadas | Nodos
@onready var _tiles_container: Container = %Tiles
@onready var _banner: Control = %ReadyBanner
@onready var _banner_cursor: CanvasItem = %BannerCursor
@onready var _banner_prompt: Control = $Root/ReadyBanner/Row/Prompt
@onready var _lives_rule: RuleSelector = %LivesRule
@onready var _time_rule: RuleSelector = %TimeRule
@onready var _footer: Container = %Footer

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
	# Solo "Pulsa [Enter] para pelear" recibe clics; el resto del letrero deja pasar el ratón a las tarjetas de abajo.
	_banner_prompt.mouse_filter = Control.MOUSE_FILTER_STOP
	_banner_prompt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_banner_prompt.gui_input.connect(_on_banner_prompt_input)
	_reset_model()
	_refresh.call_deferred() # Con el layout ya acomodado, para que el letrero rebote desde su centro.

func _input(event: InputEvent) -> void:
	'''
	Se usa _input y no _unhandled_input para que ningún control con foco se coma las teclas globales.
	Tab, Enter y Esc son teclas físicas: ui_accept/ui_cancel las comparten todos los pads.
	'''
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_TAB:
				get_viewport().set_input_as_handled()
				_add_cpu(NO_SLOT, true)
				return
			KEY_ENTER, KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				if _banner_visible:
					_start_match()
				return
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				if _banner_visible:
					_banner_dismissed = true # Con el letrero a la vista, Esc solo lo cancela.
					_update_banner()
				else:
					get_tree().change_scene_to_file(MAIN_MENU_SCENE)
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
	Muestra u oculta el letrero "¡LISTOS!" con rebote al aparecer y el cursor parpadeando.
	'''
	_kill_banner_tweens()
	_banner.visible = show_banner
	if not show_banner:
		return
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2(POP_SCALE, POP_SCALE)
	_banner_pop_tween = create_tween()
	_banner_pop_tween.tween_property(_banner, "scale", Vector2.ONE, POP_DURATION).from(Vector2(POP_SCALE, POP_SCALE)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_cursor.self_modulate.a = 1.0
	_banner_blink_tween = create_tween().set_loops()
	_banner_blink_tween.tween_callback(func() -> void: _banner_cursor.self_modulate.a = 1.0 - _banner_cursor.self_modulate.a).set_delay(BLINK_INTERVAL)

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
	MatchSetup.clear()
	MatchSetup.lives = lives
	MatchSetup.time_limit_minutes = TIME_OPTIONS[time_index]
	var pool: Array[CharacterCatalog.Entry] = []
	for entry: CharacterCatalog.Entry in _roster:
		if not entry.is_random:
			pool.append(entry)
	var npc_count: int = 0
	for i: int in SLOT_COUNT:
		var slot: SlotModel = _slots[i]
		var data: Dictionary = {"control": null, "config": GlobalUtils.PowerFighterConfig.STANDARD, "player_id": -1}
		if slot.kind != SlotKind.EMPTY:
			var entry: CharacterCatalog.Entry = CharacterCatalog.get_entry(slot.fighter_id)
			if entry == null or entry.is_random:
				entry = pool.pick_random()
			data["config"] = entry.config
			if slot.kind == SlotKind.PLAYER:
				data["control"] = GlobalUtils.ControlType.PLAYER
				data["player_id"] = i
			else:
				data["control"] = GlobalUtils.ControlType.NPC
				data["player_id"] = npc_count
				npc_count += 1
		MatchSetup.slots.append(data)
	var level: Node = load(LEVEL_SCENE).instantiate()
	level.add_child(load(FIGHT_HUD_SCENE).instantiate())
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
		cursor.card_index = i
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

func _allowed_cards(human: int) -> Array[int]:
	'''
	Tarjetas a las que puede saltar un humano: la suya y las de CPU, menos las que el ratón está eligiendo.
	'''
	var allowed: Array[int] = []
	for i: int in SLOT_COUNT:
		if _slots[i].controller == CONTROLLER_MOUSE:
			continue
		if i == human or _slots[i].kind == SlotKind.CPU:
			allowed.append(i)
	return allowed

func _restore_unattended(slot: SlotModel) -> void:
	'''
	Una tarjeta no se queda eligiendo sin controlador: vuelve a READY con lo que tenía antes de elegir.
	Solo un CPU recién agregado que nunca eligió queda pendiente (CHOOSING sin controlador).
	'''
	if slot.kind == SlotKind.EMPTY or slot.state != SlotCard.State.CHOOSING:
		return
	slot.fighter_id = slot.backup_fighter_id
	if slot.kind == SlotKind.CPU and not slot.confirmed:
		return # CPU recién agregado que nunca eligió: queda pendiente, en CHOOSING sin controlador.
	slot.state = SlotCard.State.READY

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
	El cursor del humano vuelve a las tarjetas, sobre la suya, sin controlar nada.
	'''
	var cursor: CursorModel = _cursors[human]
	cursor.zone = Zone.CARDS
	cursor.card_index = human
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

func _add_cpu(index: int = NO_SLOT, auto_assign: bool = false) -> void:
	'''
	Agrega un CPU en CHOOSING con Aleatorio en el slot indicado, o en el primer vacío en orden de slots (P1 → P4).
	Con auto_assign lo toma el primer humano libre o, si no hay, el ratón; si nadie, queda pendiente.
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
	if auto_assign:
		_assign_new_cpu(index)
	_refresh()

func _assign_new_cpu(index: int) -> void:
	for human: int in HUMAN_COUNT:
		var busy: bool = _cursors[human].controlled_slot != NO_SLOT or _slots[human].state == SlotCard.State.CHOOSING
		if _cursors[human].joined and not busy:
			_take_control(human, index)
			return
	if _mouse_slot == NO_SLOT:
		_take_control(CONTROLLER_MOUSE, index)

func _remove_cpu(index: int) -> void:
	_evict(index)
	_slots[index].kind = SlotKind.EMPTY
	_slots[index].state = SlotCard.State.READY

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
	if not _cursors[human].joined:
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
	elif _just_pressed(event, map.move_up):
		_move_vertical(human, -1)
	elif _just_pressed(event, map.move_down):
		_move_vertical(human, 1)
	elif _just_pressed(event, map.attack):
		_confirm(human)
	elif _just_pressed(event, map.power_attack):
		_cancel(human)
	else:
		return false
	_refresh()
	return true

func _move_horizontal(human: int, direction: int) -> void:
	var cursor: CursorModel = _cursors[human]
	if cursor.zone == Zone.ROSTER:
		var slot: SlotModel = _controlled(cursor)
		cursor.tile_index = wrapi(cursor.tile_index + direction, 0, _roster.size())
		if slot != null:
			slot.fighter_id = _roster[cursor.tile_index].id # Preselección.
	else:
		var allowed: Array[int] = _allowed_cards(human)
		if allowed.is_empty():
			return
		var position: int = maxi(allowed.find(cursor.card_index), 0)
		cursor.card_index = allowed[wrapi(position + direction, 0, allowed.size())]

func _move_vertical(human: int, direction: int) -> void:
	# Hoy el roster es una sola fila: abajo pasa a las tarjetas y arriba regresa.
	var cursor: CursorModel = _cursors[human]
	if direction > 0 and cursor.zone == Zone.ROSTER:
		cursor.zone = Zone.CARDS
		cursor.card_index = cursor.controlled_slot if cursor.controlled_slot != NO_SLOT else human
	elif direction < 0 and cursor.zone == Zone.CARDS:
		var slot: SlotModel = _controlled(cursor)
		if slot == null:
			return # No controla nada: no hay a quién elegirle.
		cursor.zone = Zone.ROSTER
		cursor.tile_index = _tile_index_of(slot.fighter_id)

func _confirm(human: int) -> void:
	var cursor: CursorModel = _cursors[human]
	if cursor.zone == Zone.CARDS:
		# Sobre su propia tarjeta solo retoma la que ya controla; reabrir una elección es con cancelar.
		if cursor.card_index == human and _slots[human].controller != human:
			return
		_take_control(human, cursor.card_index)
		return
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
	var target: int = cursor.card_index
	if target == human:
		# Deshace su elección: la tarjeta vuelve a CHOOSING con el mismo personaje, y cancelar de nuevo la regresa a READY.
		var own: SlotModel = _slots[human]
		if own.kind == SlotKind.PLAYER and own.state == SlotCard.State.READY and own.controller == CONTROLLER_NONE:
			_take_control(human, human)
		return
	if _slots[target].kind != SlotKind.CPU:
		return
	var allowed: Array[int] = _allowed_cards(human)
	var next: int = allowed[wrapi(allowed.find(target) + 1, 0, allowed.size())]
	_remove_cpu(target)
	cursor.zone = Zone.CARDS
	cursor.card_index = next if next != target else human

# Funciones | Callbacks de UI
func _on_tile_pressed(index: int) -> void:
	if _mouse_slot == NO_SLOT:
		return
	_pick(_slots[_mouse_slot], _roster[index].id)
	_release_controller(CONTROLLER_MOUSE)
	_refresh()

func _on_tile_hovered(index: int) -> void:
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
	if _slots[index].kind == SlotKind.EMPTY:
		# Como unirse: hay que elegir personaje para que quede READY. En slots de humano entra el jugador, en los demás un CPU.
		if index < HUMAN_COUNT:
			_join_by_mouse(index)
		else:
			_add_cpu(index)
			_take_control(CONTROLLER_MOUSE, index)
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

func _on_banner_prompt_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and _banner_visible:
		_start_match()

func _on_lives_step(direction: int) -> void:
	lives = clampi(lives + direction, LIVES_MIN, LIVES_MAX)
	_lives_rule.set_value(str(lives))

func _on_time_step(direction: int) -> void:
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

func _setup_footer() -> void:
	var map_1: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[GlobalUtils.PlayerId.PLAYER_1]
	var map_2: PlayerInputMap = GlobalUtils.PLAYER_INPUT_MAPS[GlobalUtils.PlayerId.PLAYER_2]
	var texts: Array[Array] = [
		["Clic", "Tomar / Elegir / Quitar"],
		["Flechas · WASD", "Mover"],
		[_action_pair_text(map_1.attack, map_2.attack), "Elegir"],
		[_action_pair_text(map_1.power_attack, map_2.power_attack), "Cancelar"],
		["Tab", "Agregar CPU"],
		["Enter", "Pelear"],
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

func _sanitize_cursors() -> void:
	'''
	Un cursor en CARDS no puede quedarse sobre una tarjeta que ya no puede usar (por ejemplo, un CPU quitado).
	'''
	for human: int in HUMAN_COUNT:
		var cursor: CursorModel = _cursors[human]
		if cursor.joined and cursor.zone == Zone.CARDS and not _allowed_cards(human).has(cursor.card_index):
			var allowed: Array[int] = _allowed_cards(human)
			cursor.card_index = human if allowed.is_empty() or allowed.has(human) else allowed[0]

func _refresh() -> void:
	_sanitize_cursors()
	_update_cursor_shapes()
	var data: Array[Dictionary] = []
	for i: int in SLOT_COUNT:
		var slot: SlotModel = _slots[i]
		var active: bool = false
		var controller: int = -1
		if slot.kind != SlotKind.EMPTY and slot.controller != CONTROLLER_NONE:
			controller = slot.controller
			active = slot.state == SlotCard.State.CHOOSING
			if controller >= 0 and _cursors[controller].zone == Zone.CARDS:
				active = false # Su borde está en la tarjeta donde apunta.
		data.append({
			"kind": ["empty", "player", "cpu"][slot.kind],
			"fighter": slot.fighter_id,
			"state": slot.state if slot.kind != SlotKind.EMPTY else SlotCard.State.EMPTY,
			"active": active,
			"controller": controller,
		})
	for human: int in HUMAN_COUNT:
		var cursor: CursorModel = _cursors[human]
		if cursor.joined and cursor.zone == Zone.CARDS and _slots[cursor.card_index].kind != SlotKind.EMPTY \
				and _slots[cursor.card_index].controller != CONTROLLER_MOUSE:
			data[cursor.card_index]["active"] = true
			data[cursor.card_index]["controller"] = human
	apply_state(data)
	_update_banner()

func _update_cursor_shapes() -> void:
	'''
	Mano solo donde un clic hace algo: tarjetas que el ratón puede tomar o quitar y, mientras el ratón
	elige en una tarjeta, las casillas del roster. Flecha en tarjetas que elige un humano.
	'''
	for i: int in SLOT_COUNT:
		var slot: SlotModel = _slots[i]
		var clickable: bool = slot.kind == SlotKind.EMPTY or slot.controller == CONTROLLER_NONE \
				or slot.controller == CONTROLLER_MOUSE
		_cards[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	var mouse_choosing: bool = _mouse_slot != NO_SLOT and _slots[_mouse_slot].state == SlotCard.State.CHOOSING
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
