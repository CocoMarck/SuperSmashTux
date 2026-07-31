extends Marker3D

# Constantes del script.
const CHARACTER_PREFAB = preload("res://prefabs/character.tscn")

# Propiedades publicas del script.
@export var player_id : GlobalConstants.PlayerId

func _ready() -> void:
	# Instanciar un nuevo personaje y asignarle su ID.
	var character = CHARACTER_PREFAB.instantiate()
	character.player_id = player_id
	
	# Establecer la direccion de vista del personaje segun su ID.
	match player_id:
		GlobalConstants.PlayerId.PLAYER_1:
			character.initial_facing = Vector3.RIGHT
		GlobalConstants.PlayerId.PLAYER_2:
			character.initial_facing = Vector3.LEFT
	
	# Posicionar al personaje en este punto de spawn, como hijo directo de la escena.
	character.position = global_position
	get_tree().current_scene.add_child.call_deferred(character)
