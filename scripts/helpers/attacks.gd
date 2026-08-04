extends RefCounted
class_name Attacks

# Ataques en el piso.
var neutral : FightMove
var dash : FightMove
var crouch : FightMove

# Ataques en el aire.
var neutral_air : FightMove
var air_move : FightMove
var air_down : FightMove

func _init(
	p_neutral: FightMove, p_dash: FightMove, p_crouch: FightMove, p_neutral_air: FightMove, p_air_move: FightMove, p_air_down: FightMove
):
	neutral = p_neutral
	dash = p_dash
	crouch = p_crouch
	neutral_air = p_neutral_air
	air_move = p_air_move
	air_down = p_air_down
