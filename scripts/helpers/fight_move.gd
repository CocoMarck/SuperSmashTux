class_name FightMove
extends RefCounted

'''
Movimiento de ataque. Clase que tiene la data necesaria para hacer los movimientos de ataque.

Indica del movimiento: 
- Nombre de ataque (se usara de animación).
- Si es agarre o no.
- Duración de movimiento. En segundos.
- Si es ataque en el aire.
- Inmunidad o no.
- Si remplazo velocidad vertical, horizontal.
- Veolocidad de desplazamiento durante el ataque.
- Direccion de impulso del ataque.

Indica del hitbox:
- Daño de hitbox
- Posición de hitbox
- Tamaño de hitbox
- Rotación del hitbox
- Ratio de hitbox. Respecto al movimiento. Porcentaje de `0.0` a `1.0`.
- Ratio inverso con respecto a la duraccion del movimiento
'''

# Propiedades publicas configuracion
var name: StringName
var duration: float
var speed: Vector3
var direction: Vector3
var air_attack: bool
var grab_attack: bool
var override_horizontal_move: bool
var override_vertical_move: bool
var immortal: bool

# Propidedes publicas hitbox
var hitbox_damage: int
var hitbox_size: Vector3
var hitbox_position: Vector3
var hitbox_time_ratio: float
var hitbox_rotation: float
var inverted_hitbox_ratio: bool

# Propiedades privadas valores default.
var _defaults := {
	"name": &"snake_case",
	"duration": 0.5,
	"speed": Vector3(0,0,0),
	"direction": Vector3(0,0,0),
	"air_attack": false,
	"grab_attack": false,
	"override_horizontal_move": true,
	"override_vertical_move": false,
	"inmortal": false,
	"hitbox_damage": 20,
	"hitbox_size": Vector3(0.5,0.5,0.5),
	"hitbox_position": Vector3(0,0,0),
	"hitbox_time_ratio": 0.5,
	"hitbox_rotation": 0.0,
	"inverted_hitbox_ratio": true
}


func _init( 
	p_config: Dictionary
) -> void:
	# Config fixeado con defaults
	var config := _defaults.duplicate()
	config.merge(p_config, true)  # true = p_config gana

	# Movimiento
	name = config["name"]
	duration = config["duration"]
	speed = config["speed"]
	direction = config["direction"]
	air_attack = config["air_attack"]
	grab_attack = config["grab_attack"]
	override_horizontal_move = config["override_horizontal_move"]
	override_vertical_move = config["override_vertical_move"]
	immortal = config["immortal"]

	# Hitbox
	hitbox_damage = config["hitbox_damage"]
	hitbox_size = config["hitbox_size"]
	hitbox_position = config["hitbox_position"]
	hitbox_time_ratio = config["hitbox_time_ratio"]
	hitbox_rotation = config["hitbox_rotation"]
	inverted_hitbox_ratio = config["inverted_hitbox_ratio"]

func get_hitbox_time_ratio() -> float:
	return (duration * hitbox_time_ratio)
