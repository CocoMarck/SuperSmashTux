class_name Attacks
extends RefCounted

# Ataques en el piso.
var ground_neutral1 : FightMove
var ground_neutral2 : FightMove
var ground_neutral3 : FightMove
var down : FightMove
var dash : FightMove
var forward : FightMove
var up : FightMove
var heavy_side : FightMove
var heavy_up : FightMove
var heavy_down : FightMove

# Ataques en el aire.
var air_neutral : FightMove
var air_back : FightMove
var air_forward : FightMove
var air_down : FightMove
var air_up : FightMove

func _init(
	# Ataques en el piso.
	p_ground_neutral1 : FightMove,
	p_ground_neutral2 : FightMove,
	p_ground_neutral3 : FightMove,
	p_down : FightMove,
	p_up : FightMove,
	p_dash : FightMove,
	p_forward : FightMove,
	p_heavy_side : FightMove,
	p_heavy_up : FightMove,
	p_heavy_down : FightMove,

	# Ataques en el aire.
	p_air_neutral : FightMove,
	p_air_down : FightMove,
	p_air_up : FightMove,
	p_air_forward : FightMove,
	p_air_back : FightMove
):
	# Ataques en el piso.
	ground_neutral1 = p_ground_neutral1
	ground_neutral2 = p_ground_neutral2
	ground_neutral3 = p_ground_neutral3
	down = p_down
	up = p_up
	dash = p_dash
	forward = p_forward
	heavy_side = p_heavy_side
	heavy_up = p_heavy_up
	heavy_down = p_heavy_down

	# Ataques en el aire.
	air_neutral = p_air_neutral
	air_back = p_air_back
	air_forward = p_air_forward
	air_down = p_air_down
	air_up = p_air_up
