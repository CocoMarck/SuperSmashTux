class_name MatchTime
extends Node

'''
Reloj de partida. Cuenta la partida, de forma infinita, o limitada. Depende si se establece el limite mayor a cero o no.
'''

# Señales
signal time_changed(seconds: int)
signal time_out # Una sola vez, cuando el límite llega a 0.

# Propiedades publicas
@export_range(0, 99, 1) var time_limit_minutes: int = 0 # 0 = sin límite

# Propiedades privadas
var _remaining_seconds: float = 0.0
var _elapsed_seconds: float = 0.0
var _last_emitted_second: int = -1
var _running: bool = false

# Funciones | Configuración
func setup() -> void:
	'''
	Reinicia el reloj con el límite actual. Se llama antes de la cuenta regresiva para que el HUD puede pintar el tiempo inicial.
	'''
	_remaining_seconds = time_limit_minutes * 60.0
	_elapsed_seconds = 0.0
	_last_emitted_second = -1
	_running = false
	_emit_current_second()

func start() -> void:
	_running = true

func stop() -> void:
	_running = false

func _emit_current_second() -> void:
	var seconds := ceili(_remaining_seconds) if time_limit_minutes > 0 else floori(_elapsed_seconds)
	if seconds == _last_emitted_second:
		return
	_last_emitted_second = seconds
	time_changed.emit(seconds)

# Funciones | Procesamiento
func _process(delta: float) -> void:
	# Es process normal, ya que es full backend, no necesita información de físicas.
	if not _running:
		return
	# Si es cuenta regresiva emite tiempo terminado o segundo acutal. Si es sin limite, solo el segundo actual.
	if time_limit_minutes > 0:
		_remaining_seconds = maxf(_remaining_seconds - delta, 0.0)
		_emit_current_second()
		if _remaining_seconds <= 0.0:
			_running = false
			time_out.emit()
	else:
		_elapsed_seconds += delta
		_emit_current_second()
