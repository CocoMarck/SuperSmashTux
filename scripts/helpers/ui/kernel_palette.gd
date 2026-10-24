class_name KernelPalette
extends RefCounted

'''
Paleta de colores del HUD "Kernel", y utilidades para colorear según jugador o daño.
'''

# Constantes | Tinta
const INK := Color("#E6EDF3")
const INK_SOFT := Color("#C9D1DB")
const INK_MUTED := Color("#8B95A3")
const ON_INK := Color("#0E1116")
const OK := Color("#6FCF97")

# Constantes | Colores por jugador
const PLAYER_1 := Color("#F07178")
const PLAYER_2 := Color("#6CB6FF")
const PLAYER_3 := Color("#E6C46A")
const PLAYER_4 := Color("#6FCF97")
const PLAYER_CPU := Color("#9AA4B2")

# Constantes | Colores del porcentaje de daño
const DMG_0 := INK
const DMG_1 := Color("#EBD9A8")
const DMG_2 := Color("#F0A868")
const DMG_3 := Color("#F2645F")

# Porcentaje de daño desde el que el número se pinta en rojo (DMG_3).
const CRITICAL_DAMAGE_THRESHOLD := 160.0

# Colores de jugador indexados por slot (0..3).
const _PLAYER_COLORS: Array[Color] = [PLAYER_1, PLAYER_2, PLAYER_3, PLAYER_4]

# Funciones
static func damage_color(percent: float) -> Color:
	'''
	Color del porcentaje de daño: más caliente mientras más daño.
	'''
	if percent < 60.0:
		return DMG_0
	if percent < 120.0:
		return DMG_1
	if percent < CRITICAL_DAMAGE_THRESHOLD:
		return DMG_2
	return DMG_3

static func player_color(slot: int, _is_player: bool) -> Color:
	'''
	Color del peleador según su slot (0..3), sea jugador o NPC: el CPU del slot 3 es amarillo
	y el del slot 4 verde, igual que lo serían P3 y P4.
	'''
	return _PLAYER_COLORS[clampi(slot, 0, _PLAYER_COLORS.size() - 1)]

static func slot_label(slot: int, is_player: bool) -> String:
	'''
	Etiqueta corta del peleador con el número de su slot: "P1".."P4" o "CPU1".."CPU4".
	'''
	var number := clampi(slot, 0, 3) + 1
	return ("P%d" if is_player else "CPU%d") % number

static func to_hex(c: Color) -> String:
	'''
	Color en formato "#rrggbb", para usarlo en BBCode.
	'''
	return "#" + c.to_html(false)
