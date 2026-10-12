class_name PowerAttacks
extends RefCounted

# Ataques en el piso
var standard : FightMove
var down : FightMove
var up : FightMove

# Ataques en el aire.
var air_standard : FightMove
var air_down : FightMove
var air_up : FightMove

# Propiedades privadas valorees default
var _defaults :Dictionary = {
	"standard" : FightMove.new({}),
	"down": FightMove.new({}),
	"up": FightMove.new({}),
	"air_standard": FightMove.new({}),
	"air_down": FightMove.new({}),
	"air_up": FightMove.new({}),
}

func _init( p_config: Dictionary ) -> void:
	# Config fixeado con defaults
	var config :Dictionary = _defaults.duplicate()
	config.merge(p_config, true)  # true = p_config gana

	# Movimientos de ataque
	standard = config["standard"]
	down = config["down"]
	up = config["up"]
	air_standard = config["air_standard"]
	air_down = config["air_down"]
	air_up = config["air_up"]
