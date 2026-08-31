class_name PowerAttacks
extends RefCounted

# Ataques en el piso
var ground_neutral : FightMove
var down : FightMove
var up : FightMove

# Ataques en el aire.
var air_neutral : FightMove
var air_down : FightMove
var air_up : FightMove

# Propiedades privadas valorees default
var _defaults :Dictionary = {
	"ground_neutral" : FightMove.new({}),
	"down": FightMove.new({}),
	"up": FightMove.new({}),
	"air_neutral": FightMove.new({}),
	"air_down": FightMove.new({}),
	"air_up": FightMove.new({}),
}

func _init( p_config: Dictionary ) -> void:
	# Config fixeado con defaults
	var config :Dictionary = _defaults.duplicate()
	config.merge(p_config, true)  # true = p_config gana

	# Movimientos de ataque
	ground_neutral = config["ground_neutral"]
	down = config["down"]
	up = config["up"]
	air_neutral = config["air_neutral"]
	air_down = config["air_down"]
	air_up = config["air_up"]
