class_name MatchCountdown
extends Node

'''
Cuenta regresiva previa a la pelea. Puede ser al empezar partida, al poner pausa, o etc. Si la tiempo de cuenta es cero o menor; pasa directo a la pelea. Solo cuenta y envía por señal eso. 

No meterle mas cosas como por ejemplo; congelar al peleador mientras se cuenta, o mostrar el letrero de ¡PELEA!.
'''

# Señales
signal tick(seconds_left: int)
signal finished

# Propiedades publicas
@export_group("Match Countdown")
@export_range(0, 9, 1) var countdown_seconds: int = 3

# Propiedades privadas
var _remaining: float = 0.0
var _last_emmited: int = -1
var _running: bool = false

# Funciones configuración
func has_wait() -> bool:
	'''
	Si hay algo que esperar antes de pelear: cuenta, letrero o ambos.
	'''
	return countdown_seconds > 0

# Funciones | Secuencia
func start() -> void:
	if _running:
		return
	_remaining = float(countdown_seconds)
	_last_emmited = countdown_seconds
	if not has_wait():
		finished.emit()
		return
	_running = true
	set_process(true)
	tick.emit(countdown_seconds)

func stop() -> void:
	_running = false
	set_process(false)

# Funciones| Procesamiento
func _process(delta: float) -> void:
	if not _running:
		return
	# Valor en segundos float usando delta
	_remaining -= delta
	if _remaining <= 0.0:
		_running = false
		set_process(false)
		finished.emit()
		return
	# Cuando el segundo actual no coincide con el anterior.
	var seconds_left := ceili(_remaining)
	if seconds_left != _last_emmited:
		_last_emmited = seconds_left
		tick.emit(seconds_left)
