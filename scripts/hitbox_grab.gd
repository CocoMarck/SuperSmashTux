class_name HitboxGrab
extends Hitbox

var _count_limit :int = 0
var _limit :int = 1

func _init(p_config: Dictionary):
	_defaults["limit"] = 1
	
	super(p_config)

	# Config fixeado con defaults
	var config := _defaults.duplicate()
	config.merge(p_config, true)  # true = p_config gana

	_limit = config["limit"]

	body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node3D) -> void:
	'''
	Grab a vato. Ya sea character, item, lo que sea.
	'''
	if body == _parent:
		return
	if _count_limit >= _limit:
		return
	if body is Person:
		print(body.name, " Usar a parent para hacer grab")
		_count_limit += 1
		# Usar a parent para hacer grab.
