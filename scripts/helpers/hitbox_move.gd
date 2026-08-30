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
var speed: Vector3
var rotation: float
var init_time_ratio: float
var duration: float

var _defaults :Dictionary = {
	"id": 1,
	"damage": 20,
	"position": Vector3(0,0,0),
	"size": Vector3(0.5,0.5,0.5),
	"direction": Vector3(0,0,0),
	"speed": Vector3(0,0,0),
	"rotation": 0.0,
	"init_time_ratio": 0.5,
	"duration": 0.2
}

func _init(p_config: Dictionary) -> void:
	var config := _defaults.duplicate()
	config.merge(p_config, true)

	id = config["id"]
	damage = config["damage"]
	position = config["position"]
	size = config["size"]
	speed = config["speed"]
	rotation = config["rotation"]
	init_time_ratio = config["init_time_ratio"]
	duration = config["duration"]
	direction = config["direction"]
