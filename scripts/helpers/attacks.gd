class_name Attacks
extends RefCounted

# Ataques en el piso.
var neutral : FightMove
var dash : FightMove
var crouch : FightMove
var neutral_up : FightMove

# Ataques en el aire.
var neutral_air : FightMove
var air_move : FightMove
var air_down : FightMove
var air_up : FightMove
var air_back : FightMove

func _init(
	p_neutral: FightMove, 
	p_dash: FightMove, 
	p_crouch: FightMove, 
	p_neutral_up: FightMove,
	
	p_neutral_air: FightMove, 
	p_air_move: FightMove, 
	p_air_down: FightMove,
	p_air_up: FightMove,
	p_air_back: FightMove,
):
	neutral = p_neutral
	dash = p_dash
	neutral_up = p_neutral_up
	crouch = p_crouch
	neutral_air = p_neutral_air
	air_move = p_air_move
	air_down = p_air_down
	air_up = p_air_up
	air_back = p_air_back
