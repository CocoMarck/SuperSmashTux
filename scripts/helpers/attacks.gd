extends RefCounted
class_name Attacks

# Parametros: name, duration, damage, stop x move, stop y move, speed 3d, air_attack, hitbox_position, animation_name, mesh_rotation_x

# Ataques en el piso.
var neutral := FightMove.new(
	"neutral", 0.2, 5, true, false, Vector3(0,0,0), false, Vector3(0.3, 0.1, 0),
	&"neutral_attack"
)
var dash := FightMove.new(
	"dash", 0.3, 10, true, false, Vector3(22,0,0), false, Vector3(0.5, -0.5, 0),
	&"dash_attack"
)
var crouch := FightMove.new(
	"crouch", 0.2, 5, true, false, Vector3(0,0,0), false, Vector3(0.6, -0.5, 0),
	&"crouch_attack"
)

# Ataques en el aire.
var neutral_air := FightMove.new(
	"neutral_air", 0.4, 5, false, false, Vector3(0,0,0), true, Vector3(0.5, -0.6, 0),
	&"", 45.0
)
var air_move := FightMove.new(
	"air_move", 0.3, 10, false, false, Vector3(0,0,0), true, Vector3(0.6, 0, 0),
	&"", 90.0
)
var air_down := FightMove.new(
	"air_down", 0.3, 10, false, false, Vector3(0,0,0), true, Vector3(0.1, -0.7, 0),
	&"", 0.0
)
