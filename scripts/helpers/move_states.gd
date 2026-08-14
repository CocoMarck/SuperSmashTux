class_name MoveStates
extends RefCounted

var walking: bool
var moving: bool
var jumping: bool
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

func _init(
	p_walking: bool, p_moving: bool, p_jumping: bool, p_falling: bool, 
	p_neutral: bool, p_running: bool, p_neutral_up: bool, p_neutral_crouch: bool, p_crouch_move: bool,
	p_neutral_air: bool, p_air_move: bool, p_air_up:bool , p_air_down: bool, p_air_forward: bool, p_air_back: bool
):
	walking = p_walking
	moving = p_moving
	jumping = p_jumping
	falling = p_falling

	neutral = p_neutral
	running = p_running
	neutral_up = p_neutral_up
	neutral_crouch = p_neutral_crouch
	crouch_move = p_crouch_move

	neutral_air = p_neutral_air
	air_move = p_air_move
	air_up = p_air_up
	air_down = p_air_down
	air_forward = p_air_forward
	air_back = p_air_back
