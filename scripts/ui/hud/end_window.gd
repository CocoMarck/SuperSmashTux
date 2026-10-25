class_name EndWindow
extends PanelContainer

'''
Ventana final de la partida: muestra la tarjeta del ganador (tag y retrato) o el empate.
El título lleva el prompt ">" y un cursor parpadeando, igual que el anuncio de "¡PELEA!".
Aparece con el mismo rebote de escala que la cuenta regresiva.
'''

# Constantes
const BLINK_INTERVAL := 0.4
const POP_SCALE := 1.2 # Escala inicial del rebote al aparecer, igual que la cuenta regresiva.
const POP_DURATION := 0.25

# Propiedades privadas
var _blink_tween: Tween = null
var _pop_tween: Tween = null

# Propiedades privadas | Nodos
@onready var _title_text: Label = %TitleText # Título de la barra de la terminal: "Ganador" o "Empate".
@onready var _title: Label = %Title # Título grande: "> ¡SE ACABÓ!" o "> SIN GANADOR".
@onready var _cursor: CanvasItem = %Cursor
@onready var _winner: VBoxContainer = %Winner
@onready var _portrait: PanelContainer = %Portrait
@onready var _portrait_texture: TextureRect = %PortraitTexture
@onready var _initial: Label = %Initial
@onready var _winner_tag: Label = %WinnerTag

# Funciones | Callbacks
func _ready() -> void:
	'''
	Arranca oculto en el juego; el editor sí lo muestra para poder diseñarlo. Lo prende show_winner() o show_draw().
	'''
	visible = false

# Funciones
func show_winner(label: String, color: Color, display_name: String, portrait: Texture2D = null) -> void:
	'''
	Muestra la tarjeta del ganador: tag con su color y retrato.
	Si no hay retrato, se muestra la inicial del nombre en su lugar.
	'''
	_title_text.text = "Ganador"
	_title.text = "> ¡SE ACABÓ!"
	_winner_tag.text = label
	_winner_tag.add_theme_color_override("font_color", color)
	_initial.text = display_name.substr(0, 1).to_upper()

	var has_portrait: bool = portrait != null
	_portrait_texture.texture = portrait
	_portrait_texture.visible = has_portrait
	_initial.visible = not has_portrait

	_portrait.visible = true
	_winner.visible = true
	_show_window()

func show_draw() -> void:
	'''
	Muestra el empate: sin tarjeta, solo "SIN GANADOR".
	'''
	_title_text.text = "Empate"
	_title.text = "> SIN GANADOR"
	_winner.visible = false
	_show_window()

func _show_window() -> void:
	'''
	Muestra la ventana con el rebote de la cuenta regresiva y arranca el parpadeo del cursor.
	'''
	visible = true
	for tween in [_blink_tween, _pop_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	# Pivote al centro con el tamaño mínimo: el contenedor aún no acomoda la ventana recién mostrada,
	# y su tamaño cambia entre ganador y empate.
	pivot_offset = get_combined_minimum_size() / 2.0
	scale = Vector2(POP_SCALE, POP_SCALE)
	_pop_tween = create_tween()
	# `from` explícito: el contenedor regresa la escala a 1 al acomodar el letrero recién mostrado,
	# y si eso pasa antes del primer paso del tween, sin `from` animaría de 1 a 1.
	_pop_tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).from(Vector2(POP_SCALE, POP_SCALE)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Parpadea con transparencia, no con `visible`: así el cursor sigue ocupando su lugar
	# y la ventana no cambia de tamaño en cada parpadeo.
	_cursor.self_modulate.a = 1.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(func() -> void: _cursor.self_modulate.a = 1.0 - _cursor.self_modulate.a).set_delay(BLINK_INTERVAL)
