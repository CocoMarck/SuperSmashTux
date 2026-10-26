class_name FightHud
extends CanvasLayer

'''
HUD de partida "Kernel". Es hijo del nodo raíz del nivel (el que tiene GameManager).
- Una placa por peleador (daño, vidas, escudo), una etiqueta flotante y una mini cámara por si sale de cámara.
- Cuenta regresiva, anuncio de pelea y ventana final.
Solo escucha al GameManager, no le manda nada. Su _ready corre ANTES que el del GameManager.
'''

# Constantes
const PLAYER_PLATE_SCENE: PackedScene = preload("res://ui/hud/player_plate.tscn")
const PLAYER_TAG_SCENE: PackedScene = preload("res://ui/hud/player_tag.tscn")
const OFFSCREEN_CAM_SCENE: PackedScene = preload("res://ui/hud/offscreen_cam.tscn")

const DEFAULT_FIGHTER_NAME := "B.O.B" # Si el PowerFighter no trae display_name.
const MAIN_MENU_SCENE := "res://ui/main_menu.tscn" # A donde regresa Esc (aviso "Esc Regresar").
const BODY_OFFSET := Vector3.ZERO # El origen del PowerFighter ya es el centro de su cápsula.
const OFFSCREEN_MARGIN := 16.0 # Distancia de la mini cámara a los bordes de pantalla y a las placas.
# Primer slot que se asigna a los NPC cuando el GameManager aún no avisa el slot.
const FIRST_NPC_SLOT := 2

# Propiedades publicas
@export_group("Tags")
@export var tag_height: float = 1.15 # Cápsula de 1.8 centrada en el origen: la cabeza queda en +0.9.

# Propiedades privadas | Datos de un peleador registrado.
class FighterEntry extends RefCounted:
	var fighter: Variant # PowerFighter, puede quedar liberado, usar is_instance_valid
	var slot: int = 0
	var is_player: bool = true
	var label: String = ""
	var display_name: String = ""
	var color: Color = Color.WHITE
	var max_lives: int = 0
	var lives: int = 0
	var eliminated: bool = false
	var plate: PlayerPlate
	var tag: PlayerTag
	var cam: OffscreenCam

# Propiedades privadas
var _game_manager: GameManager
var _entries: Dictionary = {} # PowerFighter -> FighterEntry
var _discover_fighters: bool = false # Respaldo cuando el GameManager no emite power_fighter_spawned.

# Propiedades privadas | Nodos
@onready var _tag_layer: Control = %TagLayer
@onready var _cam_layer: Control = %CamLayer
@onready var _plates: HBoxContainer = %Plates
@onready var _countdown: Countdown = %Countdown
@onready var _announcement: Announcement = %Announcement
@onready var _end_window: EndWindow = %EndWindow
@onready var _timer_box: Control = %TimerBox
@onready var _back_hint: Control = %BackHint
@onready var _match_timer: Label = %MatchTimer

# Funciones | Callbacks
func _ready() -> void:
	_game_manager = get_parent() as GameManager
	if _game_manager == null:
		push_warning("FightHud: el padre no es un GameManager, el HUD no mostrará nada.")
		return
	_connect_game_manager_signals()

func _unhandled_input(event: InputEvent) -> void:
	'''
	Esc regresa al menú principal. Se revisa la tecla física y no ui_cancel, porque
	ui_cancel también responde al botón B del control y sacaría a alguien a mitad de la pelea.
	'''
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var is_escape := key.physical_keycode == KEY_ESCAPE
	# Con la ventana de fin a la vista, Enter también continúa al menú ("Pulsa Enter para continuar").
	var is_continue := _end_window.visible and key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]
	if is_escape or is_continue:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _process(_delta: float) -> void:
	if _game_manager == null:
		return
	if _discover_fighters:
		_discover_new_fighters()
	if _entries.is_empty():
		return
	var camera := get_viewport().get_camera_3d()
	var screen_rect := get_viewport().get_visible_rect()
	for entry: FighterEntry in _entries.values():
		if not entry.eliminated:
			_update_entry(entry, camera, screen_rect)

# Funciones | Conexión con GameManager
func _connect_game_manager_signals() -> void:
	'''
	Conecta solo las señales que existan (contrato con GameManager). Se usa el nombre porque
	el tipado estático no deja referenciar señales que aún no están declaradas.
	'''
	var handlers: Dictionary = {
		&"power_fighter_spawned": _on_power_fighter_spawned,
		&"lives_changed": _on_lives_changed,
		&"power_fighter_eliminated": _on_power_fighter_eliminated,
		&"countdown_tick": _on_countdown_tick,
		&"fight_announced": _on_fight_announced,
		&"match_started": _on_match_started,
		&"match_ended": _on_match_ended,
		&"match_time_changed": _on_match_time_changed,
	}
	for signal_name: StringName in handlers:
		if _game_manager.has_signal(signal_name):
			_game_manager.connect(signal_name, handlers[signal_name])
	# Sin aviso de spawn, hay que descubrir a los peleadores a mano.
	_discover_fighters = not _game_manager.has_signal(&"power_fighter_spawned")

func _discover_new_fighters() -> void:
	'''
	Respaldo: registra los PowerFighter hijos del GameManager que aún no estén registrados.
	'''
	for child in _game_manager.get_children():
		var power_fighter := child as PowerFighter
		if power_fighter == null or _entries.has(power_fighter):
			continue
		var is_player := power_fighter is Player
		var slot: int = (power_fighter as Player).player_id if is_player else _next_free_slot()
		_register_fighter(power_fighter, slot, is_player, _game_manager.lives_per_character)

func _next_free_slot() -> int:
	var used: Array[int] = []
	for entry: FighterEntry in _entries.values():
		used.append(entry.slot)
	var slot := FIRST_NPC_SLOT
	while slot in used:
		slot += 1
	return slot

# Funciones | Registro de peleadores
func _find_entry(power_fighter: PowerFighter) -> FighterEntry:
	return _entries.get(power_fighter) as FighterEntry

func _register_fighter(power_fighter: PowerFighter, slot: int, is_player: bool, max_lives: int) -> void:
	'''
	Crea placa, etiqueta y mini cámara del peleador. Si ya estaba registrado, solo actualiza sus datos.
	'''
	var entry := _find_entry(power_fighter)
	var is_new := entry == null
	if is_new:
		entry = FighterEntry.new()
		entry.fighter = power_fighter
		_entries[power_fighter] = entry
	entry.slot = slot
	entry.is_player = is_player
	entry.max_lives = max_lives
	entry.lives = max_lives
	entry.label = KernelPalette.slot_label(slot, is_player)
	entry.color = KernelPalette.player_color(slot)
	entry.display_name = str(power_fighter.get("display_name")) if "display_name" in power_fighter else DEFAULT_FIGHTER_NAME

	if is_new:
		# Primero al árbol y luego setup: los nodos únicos se resuelven en _ready.
		entry.plate = PLAYER_PLATE_SCENE.instantiate() as PlayerPlate
		# Sin esto el HBoxContainer estira la placa a su propio alto; se queda en su tamaño, pegada abajo.
		entry.plate.size_flags_vertical = Control.SIZE_SHRINK_END
		_plates.add_child(entry.plate)
		entry.tag = PLAYER_TAG_SCENE.instantiate() as PlayerTag
		_tag_layer.add_child(entry.tag)
		entry.tag.visible = false
		entry.cam = OFFSCREEN_CAM_SCENE.instantiate() as OffscreenCam
		_cam_layer.add_child(entry.cam)
	entry.plate.setup(entry.label, entry.display_name, entry.color, max_lives)
	entry.tag.setup(entry.label, entry.color)
	entry.cam.setup(entry.label, entry.color, power_fighter)
	_sort_plates()

func _sort_plates() -> void:
	'''
	Ordena las placas por slot.
	'''
	var sorted: Array = _entries.values()
	sorted.sort_custom(func(a: FighterEntry, b: FighterEntry) -> bool: return a.slot < b.slot)
	for i in sorted.size():
		var entry: FighterEntry = sorted[i]
		_plates.move_child(entry.plate, i)

# Funciones | Actualización por frame
func _update_entry(entry: FighterEntry, camera: Camera3D, screen_rect: Rect2) -> void:
	'''
	Actualiza daño, escudo, etiqueta flotante y mini cámara de un peleador.
	'''
	# Muerto esperando respawn (fuera del árbol) o ya liberado: nada que mostrar.
	if not is_instance_valid(entry.fighter) or not entry.fighter.is_inside_tree():
		_hide_world_widgets(entry)
		return
	var power_fighter: PowerFighter = entry.fighter
	entry.plate.set_damage(power_fighter.damage_percentage * 100.0)
	entry.plate.set_shield(power_fighter.get_shield_ratio())
	if camera == null:
		return
	var origin := power_fighter.global_position
	# Etiqueta: sigue al peleador aunque se salga de pantalla (decisión de diseño).
	var head := origin + Vector3(0.0, tag_height, 0.0)
	if camera.is_position_behind(head):
		entry.tag.visible = false
	else:
		entry.tag.visible = true
		entry.tag.place_at(camera.unproject_position(head))
	# Mini cámara: solo cuando el cuerpo cae fuera de la pantalla.
	var body := origin + BODY_OFFSET
	if camera.is_position_behind(body):
		entry.cam.set_active(false)
		return
	var body_screen := camera.unproject_position(body)
	# Tapado por las placas cuenta como fuera de cámara: no se alcanza a ver.
	var hidden_by_plates := _plates.get_global_rect().has_point(body_screen)
	if screen_rect.has_point(body_screen) and not hidden_by_plates:
		if entry.cam.visible:
			entry.cam.set_active(false)
		return
	if not entry.cam.visible:
		entry.cam.set_active(true)
	# Con la mini cámara activa la etiqueta sobra y solo se encimaría con las placas.
	entry.tag.visible = false
	_place_offscreen_cam(entry.cam, body_screen, screen_rect)

func _place_offscreen_cam(cam: OffscreenCam, body_screen: Vector2, screen_rect: Rect2) -> void:
	'''
	Pega la mini cámara al borde más cercano, a la altura del peleador, sin taparse con las placas
	ni con los avisos de arriba (Esc y cronómetro).
	'''
	var area := screen_rect.grow(-OFFSCREEN_MARGIN)
	var plates_rect := _plates.get_global_rect()
	if plates_rect.size.y > 0.0:
		# Se quita de la pantalla la franja ocupada por las placas (arriba o abajo).
		if plates_rect.get_center().y > screen_rect.get_center().y:
			area.end.y = minf(area.end.y, plates_rect.position.y - OFFSCREEN_MARGIN)
		else:
			area = _cut_area_top(area, plates_rect.end.y + OFFSCREEN_MARGIN)
	# Se quita la franja de arriba que ocupan el aviso de Esc y el cronómetro, si se ven.
	for widget: Control in [_back_hint, _timer_box]:
		if widget.visible:
			area = _cut_area_top(area, widget.get_global_rect().end.y + OFFSCREEN_MARGIN)
	var cam_size := cam.size.max(cam.get_combined_minimum_size())
	var min_center := area.position + cam_size / 2.0
	var max_center := area.end - cam_size / 2.0
	# Si el área es más chica que la cámara, se deja pegada al mínimo.
	max_center = max_center.max(min_center)
	cam.global_position = body_screen.clamp(min_center, max_center) - cam_size / 2.0

func _cut_area_top(area: Rect2, top: float) -> Rect2:
	'''
	Sube el borde de arriba del área sin mover el de abajo (asignar position.y movería todo el rect).
	'''
	var bottom := area.end.y
	area.position.y = maxf(area.position.y, top)
	area.end.y = maxf(bottom, area.position.y)
	return area

func _hide_world_widgets(entry: FighterEntry) -> void:
	if entry.tag != null:
		entry.tag.visible = false
	if entry.cam != null and entry.cam.visible:
		entry.cam.set_active(false)

# Funciones | Señales del GameManager
func _on_power_fighter_spawned(power_fighter: PowerFighter, slot: int, is_player: bool, max_lives: int) -> void:
	_register_fighter(power_fighter, slot, is_player, max_lives)

func _on_lives_changed(power_fighter: PowerFighter, lives: int) -> void:
	var entry := _find_entry(power_fighter)
	if entry == null:
		return
	entry.lives = lives
	entry.plate.set_lives(lives)

func _on_power_fighter_eliminated(power_fighter: PowerFighter) -> void:
	var entry := _find_entry(power_fighter)
	if entry == null:
		return
	entry.eliminated = true
	entry.lives = 0
	entry.plate.set_out(true)
	entry.plate.set_lives(0)
	if entry.tag != null:
		entry.tag.queue_free()
		entry.tag = null
	if entry.cam != null:
		entry.cam.queue_free()
		entry.cam = null

func _on_countdown_tick(seconds_left: int) -> void:
	_countdown.show_number(seconds_left)

func _on_fight_announced(duration: float) -> void:
	'''
	Acabó la cuenta: ¡PELEA! dura lo mismo que el GameManager tiene congelados a los peleadores.
	'''
	_countdown.hide_now()
	_announcement.show_text("> ¡PELEA!", duration)

func _on_match_started() -> void:
	_countdown.hide_now()
	# Respaldo: un GameManager sin aviso de ¡PELEA! lo muestra aquí, ya con la partida corriendo.
	if not _game_manager.has_signal(&"fight_announced"):
		_announcement.show_text()

func _on_match_time_changed(seconds: int) -> void:
	'''
	Cronómetro de la partida en mm:ss, arriba a la derecha. Oculto hasta el primer aviso,
	así un mapa sin cronómetro no muestra 00:00.
	'''
	var safe_seconds := maxi(seconds, 0)
	_match_timer.text = "%02d:%02d" % [floori(safe_seconds / 60.0), safe_seconds % 60]
	_timer_box.visible = true

func _on_match_ended(winner: PowerFighter) -> void:
	var entry := _find_entry(winner) if is_instance_valid(winner) else null
	if entry == null:
		_end_window.show_draw()
	else:
		_end_window.show_winner(entry.label, entry.color, entry.display_name)
