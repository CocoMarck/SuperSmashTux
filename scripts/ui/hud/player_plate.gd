class_name PlayerPlate
extends PanelContainer

'''
Placa de un peleador en el HUD: chip de slot, nombre, retrato, daño, barra de vidas (HP) y escudo.
Solo muestra datos, no tiene lógica de partida.
'''

# Constantes
const MAX_HP_SEGMENTS := 10 # Con más vidas máximas, cada segmento agrupa varias vidas.
const HP_SEGMENT_HEIGHT := 3.0 # Mismo alto que el escudo.
const SHIELD_SEGMENTS := 5 # Un segmento por segundo de GameBalance.SHIELD_DURATION (5 s).
const SHIELD_SEGMENT_HEIGHT := 3.0
const OUT_ALPHA := 0.55

# Propiedades privadas | Estado, para no reconstruir nodos si nada cambió.
var _max_lives: int = 0
var _chip_color: Color = KernelPalette.get_color(&"ink")
var _last_damage: int = -1
var _last_lives: int = -1
var _last_hp_segments: int = -1
var _last_shield_segments: int = -1

# Propiedades privadas | Nodos
@onready var _slot_label: Label = %SlotLabel
@onready var _name_label: Label = %NameLabel
@onready var _portrait_texture: TextureRect = %PortraitTexture
@onready var _initial: Label = %Initial
@onready var _damage: Control = %Damage
@onready var _damage_value: Label = %DamageValue
@onready var _damage_unit: Label = %DamageUnit
@onready var _out_label: Control = %OutLabel
@onready var _hp_meter: Container = %HpMeter
@onready var _shield_meter: Container = %ShieldMeter

# Funciones | Configuración
func setup(label: String, display_name: String, color: Color, max_lives: int) -> void:
	'''
	Configura la placa: chip con color del jugador, nombre tal como viene e inicial en mayúscula.
	Llamar con la placa ya dentro del árbol (los nodos únicos se resuelven en _ready).
	'''
	_max_lives = max_lives
	_chip_color = color
	_slot_label.text = label
	_slot_label.add_theme_color_override("font_color", color)
	_name_label.text = display_name # Tal como viene: puede ser una sigla, como B.O.B.
	_initial.text = display_name.left(1).to_upper()
	_last_damage = -1
	_last_lives = -1
	_last_hp_segments = -1
	_last_shield_segments = -1
	set_lives(max_lives)
	set_damage(0.0)
	set_shield(1.0)

func set_portrait(texture: Texture2D) -> void:
	'''
	Muestra el retrato y oculta la inicial que hace de respaldo.
	'''
	_portrait_texture.texture = texture
	_portrait_texture.visible = texture != null
	_initial.visible = texture == null

# Funciones | Actualización
func set_damage(percent: float) -> void:
	'''
	Muestra el daño como entero, coloreado según gravedad.
	'''
	var rounded := roundi(percent)
	if rounded == _last_damage:
		return
	_last_damage = rounded
	_damage_value.text = str(rounded)
	var color := KernelPalette.damage_color(rounded)
	_damage_value.add_theme_color_override("font_color", color)
	_damage_unit.add_theme_color_override("font_color", color)

func set_lives(lives: int) -> void:
	'''
	Dibuja las vidas como barra segmentada (HP). Una vida = un segmento mientras el máximo sea
	de hasta MAX_HP_SEGMENTS; con más, las vidas se reparten entre los segmentos. Redondea hacia
	arriba: con al menos una vida siempre se ve un segmento lleno; con 0 la barra queda vacía.
	'''
	var segments := clampi(_max_lives, 1, MAX_HP_SEGMENTS)
	if lives == _last_lives and segments == _last_hp_segments:
		return
	_last_lives = lives
	var rebuild := segments != _last_hp_segments
	_last_hp_segments = segments
	var filled := 0
	if lives > 0:
		filled = clampi(ceili(float(lives) / float(maxi(_max_lives, 1)) * segments), 1, segments)
	# Crear los segmentos solo si cambió su cantidad, después solo se cambia su variación de tema.
	if rebuild or _hp_meter.get_child_count() != segments:
		_clear_children(_hp_meter)
		for i in segments:
			var segment := Panel.new()
			segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			segment.custom_minimum_size.y = HP_SEGMENT_HEIGHT
			_hp_meter.add_child(segment)
	for i in segments:
		var segment := _hp_meter.get_child(i) as Panel
		segment.theme_type_variation = &"KnHpOn" if i < filled else &"KnSegOff"

func set_shield(ratio: float) -> void:
	'''
	Dibuja el escudo en SHIELD_SEGMENTS segmentos. Redondea hacia arriba: mientras quede
	algo de escudo se ve al menos un segmento; cero segmentos = escudo vacío.
	El color de los segmentos lo define el tema ("KnSegOn" encendidos, "KnSegOff" apagados).
	'''
	var segments := clampi(ceili(ratio * SHIELD_SEGMENTS), 0, SHIELD_SEGMENTS)
	if segments == _last_shield_segments:
		return
	_last_shield_segments = segments
	# Crear los segmentos una sola vez, después solo se cambia su variación de tema.
	if _shield_meter.get_child_count() != SHIELD_SEGMENTS:
		_clear_children(_shield_meter)
		for i in SHIELD_SEGMENTS:
			var segment := Panel.new()
			segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			segment.custom_minimum_size.y = SHIELD_SEGMENT_HEIGHT
			_shield_meter.add_child(segment)
	for i in SHIELD_SEGMENTS:
		var segment := _shield_meter.get_child(i) as Panel
		segment.theme_type_variation = &"KnSegOn" if i < segments else &"KnSegOff"

func set_out(out: bool) -> void:
	'''
	Marca al peleador como eliminado: oculta el daño, muestra "out" y atenúa la placa.
	'''
	_damage.visible = not out
	_out_label.visible = out
	modulate.a = OUT_ALPHA if out else 1.0
	_slot_label.add_theme_color_override("font_color", KernelPalette.get_color(&"ink_muted") if out else _chip_color)

# Funciones | Utilidades privadas
func _clear_children(container: Node) -> void:
	'''
	Quita los hijos de inmediato (remove_child) para que no se mezclen con los nuevos antes del queue_free.
	'''
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
