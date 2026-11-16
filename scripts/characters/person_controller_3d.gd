class_name PersonController3D
extends Node3D

# Input
var _input: MoveInput = MoveInput.new()

# Funciones esenciales.
func _init() -> void:
	pass

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

# De interfaz
func get_input(delta: float, frame: FrameMotionSignals) -> MoveInput:
	# Retorna `MoveInput`. El delta y frame, puede que ni lo use el player controller, pero el npc controller probablemente si.
	return _input
