class_name HitboxMove
extends RefCounted
'''
Para fight move
'''

var id: int
var damage: int
var position: Vector3
var size: Vector3
var direction: Vector3
var rotation: float
var init_time_ratio: float
var duration: float

# AreaGravity3D
var fall_acceleration: float
var use_gravity: bool
var bounce: bool
var bounce_impulse: float
var speed: float

var _defaults :Dictionary = {
	"id": 1,
	"damage": 20,
	"position": Vector3(0,0,0),
	"size": Vector3(0.5,0.5,0.5),
	"direction": Vector3(0,0,0),
	"rotation": 0.0,
	"init_time_ratio": 0.5,
	"duration": 0.2,
	"use_gravity": false,
	"fall_acceleration": 0.0,
	"bounce": false,
	"speed": 0.0,
	"bounce_impulse": 0.0,
}

func _init(p_config: Dictionary) -> void:
	var config := _defaults.duplicate()
	config.merge(p_config, true)

	id = config["id"]
	damage = config["damage"]
	position = config["position"]
	size = config["size"]
	rotation = config["rotation"]
	init_time_ratio = config["init_time_ratio"]
	duration = config["duration"]
	direction = config["direction"]
	
	use_gravity = config["use_gravity"]
	fall_acceleration = config["fall_acceleration"]
	bounce = config["bounce"]
	bounce_impulse = config["bounce_impulse"]
	speed = config["speed"]
