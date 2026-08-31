# Archivo de constantes y enumeraciones globales del proyecto.
class_name GlobalUtils

# Enumeracion de tipos de personaje que un SpawnPoint puede generar.
enum CharacterType { PLAYER, NPC }

# Enumeracion de IDs posibles de jugadores.
enum PlayerId { PLAYER_1, PLAYER_2 }

# Enumeracion de IDs posibles de NPCs.
enum NPCId { NPC_1, NPC_2, NPC_3, NPC_4 }

# Mapa de input de cada jugador, usado por Player para resolver sus controles segun su ID. Se construye una sola vez al cargar el script.
static var PLAYER_INPUT_MAPS: Dictionary[PlayerId, PlayerInputMap] = {
	PlayerId.PLAYER_1: PlayerInputMap.new(
		&"player1_move_left", &"player1_move_right", &"player1_move_up",
		&"player1_move_down", &"player1_jump", &"player1_attack", 
		&"player1_walk", &"player1_grab", &"player1_shield", "player1_power_attack"
	),
	PlayerId.PLAYER_2: PlayerInputMap.new(
		&"player2_move_left", &"player2_move_right", &"player2_move_up",
		&"player2_move_down", &"player2_jump", &"player2_attack", 
		&"player2_walk", &"player2_grab", &"player2_shield", "player2_power_attack"
	),
}

# Material de cada jugador segun su ID, usado por Player (cuando no hay material puesto a mano en el editor).
const PLAYER_MATERIALS: Dictionary[PlayerId, Material] = {
	PlayerId.PLAYER_1: preload("res://materials/mat_red.tres"),
	PlayerId.PLAYER_2: preload("res://materials/mat_blue.tres"),
}

# Material de los NPC, usado por NPC (cuando no hay material puesto a mano en el editor).
const NPC_MATERIAL: Material = preload("res://materials/mat_yellow.tres")
