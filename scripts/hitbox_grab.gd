class_name HitboxGrab
extends Hitbox
'''
# HitboxGrab

Sirve para enviar señal de agarre. 
- Tiene un life time para el grabbing de algun body.
- Mantiene spawn de grab si es que hay agarre.

#### Esto va en Person
- Bloquea movimiento de victima. Y lo pone en estado de `grabbed`.

#### Esto va en Fighter
- Este spawnea el `HitboxGrab`
- Pone al victiamario en estado de `grabbing`
- El victimario obiene coordenadas xy del centro del Area3D, y mentiene a la victima alli. Siempre y cuando esten `on_floor` ambos.
- El victimario puede hacer `queue_free` al `HitboxGrab`.
'''

# Usa de la constante `GameBalance.GRAB_DURATION`

var _count_limit :int = 0
var _limit :int = 1
var _grabbing_lifetime :float = 0.0
var _grabbing :bool = false

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
		_count_limit += 1
		_grabbing = true
		_grabbing_lifetime = GameBalance.GRAB_DURATION
		# Usar a parent para hacer grab.
		if _parent is Fighter:
			_parent.grabbing_person(body)
			

func _process(delta: float) -> void:
	if _grabbing:
		if _grabbing_lifetime <= 0:
			self.queue_free()
		_grabbing_lifetime -= delta
	
	elif _good_lifetime():
		if _lifetime <= 0:
			self.queue_free()
		_lifetime -= delta
