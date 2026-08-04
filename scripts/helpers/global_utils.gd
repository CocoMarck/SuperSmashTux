# Archivo de constantes y enumeraciones globales del proyecto.
class_name GlobalUtils

# Enumeracion de IDs posibles de jugadores.
enum PlayerId { PLAYER_1, PLAYER_2 }

# Enumeracion de tipos de entidad que un SpawnPoint puede generar.
enum EntityType { PLAYER, NPC }

# Nombres de acciones del Input Map por jugador, usado por SpawnPoint para armar el PlayerInputMap del jugador.
static func get_player_actions(player_id: PlayerId) -> PlayerInputMap:
	match player_id:
		PlayerId.PLAYER_1:
			return PlayerInputMap.new(
				"player1_move_left", "player1_move_right", "player1_move_up",
				"player1_move_down", "player1_jump", "player1_attack"
			)
		PlayerId.PLAYER_2:
			return PlayerInputMap.new(
				"player2_move_left", "player2_move_right", "player2_move_up",
				"player2_move_down", "player2_jump", "player2_attack"
			)
		_:
			return null
