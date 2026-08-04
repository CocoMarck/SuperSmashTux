extends Marker3D

# Constantes del script.
const CHARACTER_PREFAB = preload("res://prefabs/character.tscn")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const NPC_SCRIPT = preload("res://scripts/npc.gd")

# Propiedades publicas del script.
@export var entity_type: GlobalConstants.EntityType = GlobalConstants.EntityType.PLAYER
@export var player_id: GlobalConstants.PlayerId

func _ready() -> void:
	# Instanciar un nuevo personaje y asignarle el script segun el tipo de entidad.
	var character = CHARACTER_PREFAB.instantiate()

	match entity_type:
		GlobalConstants.EntityType.PLAYER:
			character.set_script(PLAYER_SCRIPT)
			character.player_id = player_id

			# Establecer la direccion de vista del jugador segun su ID.
			match player_id:
				GlobalConstants.PlayerId.PLAYER_1:
					character.init_looking_at_right = true
				GlobalConstants.PlayerId.PLAYER_2:
					character.init_looking_at_right = false

		GlobalConstants.EntityType.NPC:
			character.set_script(NPC_SCRIPT)

	# Posicionar al personaje en este punto de spawn, como hijo directo de la escena.
	character.position = global_position
	get_tree().current_scene.add_child.call_deferred(character)
