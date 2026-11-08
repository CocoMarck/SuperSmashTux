class_name CharacterSelect
extends CanvasLayer

'''
Pantalla de selección de personaje. Fase visual: arma el roster y las 4 tarjetas, y expone
apply_state() para pintar cualquier estado. La lógica de elegir (mover marcadores, CPU, mouse) viene después.
'''

# Constantes
const ROSTER_TILE_SCENE := "res://ui/character_select/roster_tile.tscn"
const MAIN_MENU_SCENE := "res://ui/main_menu.tscn"
const LEVEL_SCENE := "res://scenes/levels/map1.tscn"
const FIGHT_HUD_SCENE := "res://ui/fight_hud.tscn"
const BLINK_INTERVAL := 0.4
const POP_SCALE := 1.2 # Escala inicial del rebote al aparecer, igual que el anuncio de la partida.
const POP_DURATION := 0.25
const SLOT_COUNT := 4

# Propiedades privadas
var _tiles: Dictionary[StringName, RosterTile] = {}
var _cards: Array[SlotCard] = []
var _banner_blink_tween: Tween = null
var _banner_pop_tween: Tween = null

# Propiedades privadas | Nodos
@onready var _tiles_container: Container = %Tiles
@onready var _banner: Control = %ReadyBanner
@onready var _banner_cursor: CanvasItem = %BannerCursor

# Funciones | Callbacks
func _ready() -> void:
	_cards = [%Card1, %Card2, %Card3, %Card4]
	var tile_scene: PackedScene = load(ROSTER_TILE_SCENE)
	for entry: CharacterCatalog.Entry in CharacterCatalog.all():
		var tile: RosterTile = tile_scene.instantiate()
		_tiles_container.add_child(tile)
		tile.setup(entry)
		_tiles[entry.id] = tile
	_banner.visible = false
	apply_state(_initial_state())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	elif event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_start_match()

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

func _initial_state() -> Array[Dictionary]:
	'''
	P1 y P2 jugadores eligiendo sobre Aleatorio, P1 activa; P3 y P4 libres.
	'''
	var slots: Array[Dictionary] = []
	for i: int in SLOT_COUNT:
		var is_player: bool = i < 2
		slots.append({
			"kind": "player" if is_player else "empty",
			"fighter": CharacterCatalog.RANDOM_ID,
			"state": SlotCard.State.CHOOSING if is_player else SlotCard.State.EMPTY,
			"active": i == 0,
			"controller": -1,
		})
	return slots

func _kill_banner_tweens() -> void:
	for tween: Tween in [_banner_blink_tween, _banner_pop_tween]:
		if tween != null:
			tween.kill()
	_banner_blink_tween = null
	_banner_pop_tween = null

func _start_match() -> void:
	'''
	Arranca la partida. Las elecciones todavía no viajan al GameManager (fase de lógica).
	'''
	var level: Node = load(LEVEL_SCENE).instantiate()
	level.add_child(load(FIGHT_HUD_SCENE).instantiate())
	get_tree().change_scene_to_node(level)
