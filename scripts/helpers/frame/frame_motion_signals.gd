class_name FrameMotionSignals
extends RefCounted

var vertical_force_signals : VerticalForceSignals
var move_signals : MoveSignals
var move_states : MoveStates
var jump_signals : JumpSignals
var holding_onto_the_ledge : bool

var _defaults :Dictionary = {
	"vertical_force_signals": VerticalForceSignals.new(),
	"move_signals": MoveSignals.new(),
	"move_states": MoveStates.new(),
	"jump_signals": JumpSignals.new(),
	"holding_onto_the_ledge": false
}

func _init( p_config: Dictionary ) -> void:
	var config :Dictionary = _defaults.duplicate()
	config.merge(p_config, true)

	vertical_force_signals = config["vertical_force_signals"]
	move_signals = config["move_signals"]
	move_states = config["move_states"]
	jump_signals = config["jump_signals"]
	holding_onto_the_ledge = config["holding_onto_the_ledge"]
