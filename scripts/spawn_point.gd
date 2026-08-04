extends Marker3D
class_name SpawnPoint

# Constantes del script.
const CHARACTER_PREFAB = preload("res://prefabs/character.tscn")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const NPC_SCRIPT = preload("res://scripts/npc.gd")

# Propiedades publicas del script.
@export var entity_type: GlobalUtils.EntityType = GlobalUtils.EntityType.PLAYER
@export var player_id: GlobalUtils.PlayerId
@export var init_looking_at_right: bool = false
@export var material_player_1: Material = null
@export var material_player_2: Material = null
@export var material_npc: Material = null

func _ready() -> void:
	# Instanciar un nuevo personaje y asignarle el script correspondiente segun la entidad.
	var character = CHARACTER_PREFAB.instantiate()

	match entity_type:
		# Jugador: Establecer script correspondiente, asignar ID, mapa de acciones de input y material.
		GlobalUtils.EntityType.PLAYER:
			character.set_script(PLAYER_SCRIPT)
			character.player_id = player_id
			character.actions = GlobalUtils.get_player_actions(player_id)

			match player_id:
				GlobalUtils.PlayerId.PLAYER_1:
					character.material = material_player_1
				GlobalUtils.PlayerId.PLAYER_2:
					character.material = material_player_2

		# NPC: Establecer script correspondiente y material.
		GlobalUtils.EntityType.NPC:
			character.set_script(NPC_SCRIPT)
			character.material = material_npc

	# Direccion de vista, despues de set_script — cambiar de script resetea las propiedades previas.
	character.init_looking_at_right = init_looking_at_right

	# Posicionar al personaje en este punto de spawn, como hijo directo de la escena.
	character.position = global_position
	get_tree().current_scene.add_child.call_deferred(character)
