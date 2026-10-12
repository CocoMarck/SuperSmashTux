class_name FrameMotionSignals
extends RefCounted

var vertical_force_signals : VerticalForceSignals
var move_signals : MoveSignals
var move_states : MoveStates

var _defaults :Dictionary = {
	"vertical_force_signals": VerticalForceSignals.new(),
	"move_signals": MoveSignals.new(),
	"move_states": MoveStates.new()
}

func _init( p_config: Dictionary ) -> void:
	var config :Dictionary = _defaults.duplicate()
	config.merge(p_config, true)

	vertical_force_signals = config["vertical_force_signals"]
	move_signals = config["move_signals"]
	move_states = config["move_states"]
