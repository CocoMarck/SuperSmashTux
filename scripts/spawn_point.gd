class_name SpawnPoint
extends Marker3D

# Constantes del script.
const CHARACTER_PREFAB = preload("res://prefabs/standard_power_fighter.tscn")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const NPC_SCRIPT = preload("res://scripts/npc.gd")

# Propiedades publicas del script.
@export var init_looking_at_right: bool = false

func spawn(character_type: GlobalUtils.CharacterType, player_id: GlobalUtils.PlayerId, p_init_looking_at_right: bool) -> PowerFighter:
	'''
	Instanciar un personaje en este punto, con el tipo e ID que indique quien llama
	(normalmente el GameManager). El add_child es diferido, pero la referencia que se
	devuelve ya es valida de inmediato, se puede guardar aunque el nodo todavia no
	ande metido en el arbol.
	'''
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
	character.init_looking_at_right = p_init_looking_at_right

	# Posicionar al personaje en este punto de spawn, como hijo directo de la escena.
	character.position = global_position
	get_tree().current_scene.add_child.call_deferred(character)
	return character as PowerFighter
