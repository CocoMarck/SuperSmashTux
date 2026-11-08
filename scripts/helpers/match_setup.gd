class_name MatchSetup
extends RefCounted

'''
Datos de la partida elegidos en la selección de personaje. Sin nodos: CharacterMenu los llena
antes de cambiar de escena y la partida (GameManager) los lee al arrancar.
'''

# Propiedades públicas
static var lives: int = 3
static var time_limit_minutes: int = 0 # 0 = sin límite.
# Un dict por slot (0..3): { "control": GlobalUtils.ControlType (null si está vacío),
# "config": GlobalUtils.PowerFighterConfig, "player_id": int }.
# player_id es el GlobalUtils.PlayerId si es jugador, o el GlobalUtils.NPCId (en orden de aparición) si es CPU.
static var slots: Array[Dictionary] = []

# Funciones
static func clear() -> void:
	'''
	Regresa todo a sus valores por defecto.
	'''
	lives = 3
	time_limit_minutes = 0
	slots = []
