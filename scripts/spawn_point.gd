extends Marker3D
class_name SpawnPoint

# Constantes del script.
const CHARACTER_PREFAB = preload("res://prefabs/character.tscn")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const NPC_SCRIPT = preload("res://scripts/npc.gd")

# Propiedades publicas del script.
@export var character_type: GlobalUtils.CharacterType = GlobalUtils.CharacterType.PLAYER
@export var player_id: GlobalUtils.PlayerId
@export var init_looking_at_right: bool = false

func _ready() -> void:
	# Instanciar un nuevo personaje y asignarle el script correspondiente segun el tipo de personaje.
	var character = CHARACTER_PREFAB.instantiate()

	match character_type:
		# Jugador: Establecer script correspondiente y asignar ID. El Player resuelve sus inputs y material segun su ID.
		GlobalUtils.CharacterType.PLAYER:
			character.set_script(PLAYER_SCRIPT)
			character.player_id = player_id

		# NPC: Establecer script correspondiente. El NPC resuelve su propio material.
		GlobalUtils.CharacterType.NPC:
			character.set_script(NPC_SCRIPT)

	# Configurar direccion de vista del personaje.
	character.init_looking_at_right = init_looking_at_right

	# Posicionar al personaje en este punto de spawn, como hijo directo de la escena.
	character.position = global_position
	get_tree().current_scene.add_child.call_deferred(character)
