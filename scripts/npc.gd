class_name NPC
extends PowerFighter

# NPC
var _try_recovery = false
var _invert_pin = false
var _npc_horizontal_move = true
var _pin_left = true
var _pin_right = false

# Funciones | Apariencia.
func _get_default_material() -> Material:
	'''
	Material propio de los NPC.
	'''
	return GlobalUtils.NPC_MATERIAL

# Funciones | Procesar AI
func _process_ai(delta, frame: FrameMotionSignals):
	'''
	Recomendado hacer esto modular, por ahora puede ser súper monolítico.
	'''
	# Todavia no tiene movimiento horizontal, solo salta en su lugar.
	_move_left = false
	_move_right = false
	_move_up = false
	_move_down = false
	_attack = false
	_jump = false
	_move_down = true

	# Validar que existan datos para el NPC
	if frame == null:
		return
	
	# Mover NPC
	_invert_pin = false
	if not frame.vertical_force_signals.on_floor and not _try_recovery:
		_invert_pin = true
		_try_recovery = true
		_jump = true
	if _try_recovery and frame.vertical_force_signals.on_floor:
		_try_recovery = false
		_attack = true
		

	if _npc_horizontal_move:
		# Invertir dirección
		if _invert_pin:
			if _pin_left:
				_pin_right = true
				_pin_left = false
			elif _pin_right:
				_pin_left = true
				_pin_right = false
		# Mover, ya sea izq o der. No ambos.
		if not (_pin_left and _pin_right):
			_move_left = _pin_left
			_move_right = _pin_right
			
	if frame.vertical_force_signals.on_floor:
		_jump = false

# Funciones | Probablemente no se use
func _collect_input() -> void:
	pass
