class_name Countdown
extends PanelContainer

'''
Número grande de la cuenta regresiva previa a la partida.
'''

# Propiedades privadas
var _tween: Tween = null

# Propiedades privadas | Nodos
@onready var _number: Label = %Number

# Funciones
func show_number(n: int) -> void:
	'''
	Muestra el número con un pequeño rebote de escala (1.2 a 1.0) desde el centro.
	'''
	visible = true
	_number.text = str(n)
	# El pivote al centro depende del tamaño actual, por eso se recalcula en cada tick.
	pivot_offset = size / 2.0
	scale = Vector2(1.2, 1.2)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_now() -> void:
	'''
	Oculta la cuenta regresiva de inmediato.
	'''
	if _tween != null and _tween.is_valid():
		_tween.kill()
	scale = Vector2.ONE
	visible = false
