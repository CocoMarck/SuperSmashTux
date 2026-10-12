class_name MoveStates
extends RefCounted

var walking: bool
var moving: bool
var jumping: bool
var rising: bool
var falling: bool

var neutral: bool
var running: bool
var neutral_up: bool
var neutral_crouch: bool
var crouch_move: bool

var neutral_air: bool
var air_move: bool
var air_up: bool
var air_down: bool
var air_forward: bool
var air_back: bool

var _defaults :Dictionary = {
	"walking": false, "moving": false, "rising": false, "jumping": false, 
	"falling": false, "neutral": false, "running": false, "neutral_up": false, 
	"neutral_crouch": false, "crouch_move": false, "neutral_air": false, "air_move": false, "air_up": false, "air_down": false, "air_forward": false, "air_back": false,
}

func _init(
	p_config: Dictionary = {}
) -> void:
	# Config fixeado con defaults
	var config := _defaults.duplicate()
	config.merge(p_config, true)  # true = p_config gana
	
	walking = config["walking"]
	moving = config["moving"]
	jumping = config["jumping"]
	rising = config["rising"]
	falling = config["falling"]

	neutral = config["neutral"]
	running = config["running"]
	neutral_up = config["neutral_up"]
	neutral_crouch = config["neutral_crouch"]
	crouch_move = config["crouch_move"]

	neutral_air = config["neutral_air"]
	air_move = config["air_move"]
	air_up = config["air_up"]
	air_down = config["air_down"]
	air_forward = config["air_forward"]
	air_back = config["air_back"]
