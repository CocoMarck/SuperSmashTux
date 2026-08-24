class_name HitboxDamage
extends Hitbox

var _damage : int

func _init(p_config: Dictionary):
	_defaults["damage"] = 1

	super(p_config)

	# Config fixeado con defaults
	var config := _defaults.duplicate()
	config.merge(p_config, true)  # true = p_config gana

	# Damage
	_damage = config["damage"]

	body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node3D) -> void:
	'''
	Golpe a cuerpo. Ya sea character, item, lo que sea.
	'''
	if body == _parent:
		return
	if body is Person:
		print(body.name, " recibio trancazo")
		print(body.damage_percentage)
		body.set_damage_percentage( _damage )
		body.set_damage_move( _damage, _direction )
