class_name Announcement
extends PanelContainer

'''
Anuncio corto estilo terminal (por ejemplo "> ¡PELEA!") con cursor parpadeando.
Aparece con el mismo rebote de escala que la cuenta regresiva y se oculta solo pasado su tiempo.
'''

# Constantes
const BLINK_INTERVAL := 0.4
const POP_SCALE := 1.2 # Escala inicial del rebote al aparecer, igual que la cuenta regresiva.
const POP_DURATION := 0.25

# Propiedades privadas
var _blink_tween: Tween = null
var _hide_tween: Tween = null
var _pop_tween: Tween = null

# Propiedades privadas | Nodos
@onready var _text: Label = %Text
@onready var _cursor: CanvasItem = %Cursor

# Funciones
func show_text(text: String = "> ¡PELEA!", duration: float = 1.2) -> void:
	'''
	Muestra el texto con el cursor parpadeando, y lo oculta tras `duration` segundos.
	'''
	_text.text = text
	visible = true
	_kill_tweens()
	# Pivote al centro con el tamaño mínimo: el contenedor aún no acomoda el letrero recién mostrado,
	# así que `size` puede venir de otro texto.
	pivot_offset = get_combined_minimum_size() / 2.0
	scale = Vector2(POP_SCALE, POP_SCALE)
	_pop_tween = create_tween()
	# `from` explícito: el contenedor regresa la escala a 1 al acomodar el letrero recién mostrado,
	# y si eso pasa antes del primer paso del tween, sin `from` animaría de 1 a 1.
	_pop_tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).from(Vector2(POP_SCALE, POP_SCALE)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# El cursor parpadea con transparencia, no con `visible`: así sigue ocupando su lugar
	# y el letrero no cambia de tamaño en cada parpadeo.
	_cursor.visible = true
	_cursor.self_modulate.a = 1.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(func() -> void: _cursor.self_modulate.a = 1.0 - _cursor.self_modulate.a).set_delay(BLINK_INTERVAL)
	_hide_tween = create_tween()
	_hide_tween.tween_interval(duration)
	_hide_tween.tween_callback(_hide_now)

func _hide_now() -> void:
	_kill_tweens()
	scale = Vector2.ONE
	visible = false

func _kill_tweens() -> void:
	for tween in [_blink_tween, _hide_tween, _pop_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
