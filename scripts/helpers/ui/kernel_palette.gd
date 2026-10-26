class_name KernelPalette
extends RefCounted

# Colores del HUD "Kernel". Los valores viven en theme_kernel.tres, tipo KernelPalette;
# aqui nomas se decide cual toca segun el jugador o el daño.

# Constantes | De donde salen los colores.
const THEME: Theme = preload("res://ui/themes/theme_kernel.tres")
const THEME_TYPE := &"KernelPalette"

# Porcentaje de daño desde el que el número se pinta en rojo (damage_3).
const CRITICAL_DAMAGE_THRESHOLD := 160.0

# Funciones
static func get_color(color_name: StringName) -> Color:
	'''Color con nombre del tipo KernelPalette del theme: ink, ink_muted, player_1..4, damage_1..3.'''
	return THEME.get_color(color_name, THEME_TYPE)

static func damage_color(percent: float) -> Color:
	'''
	Color del porcentaje de daño: más caliente mientras más daño. Con poco daño va el blanco de siempre (ink).
	'''
	if percent < 60.0:
		return get_color(&"ink")
	if percent < 120.0:
		return get_color(&"damage_1")
	if percent < CRITICAL_DAMAGE_THRESHOLD:
		return get_color(&"damage_2")
	return get_color(&"damage_3")

static func player_color(slot: int) -> Color:
	'''
	Color del peleador según su slot (0..3), sea jugador o NPC: el CPU del slot 3 es amarillo
	y el del slot 4 verde, igual que lo serían P3 y P4.
	'''
	return get_color(StringName("player_%d" % (clampi(slot, 0, 3) + 1)))

static func slot_label(slot: int, is_player: bool) -> String:
	'''
	Etiqueta corta del peleador con el número de su slot: "P1".."P4" o "CPU1".."CPU4".
	'''
	var number := clampi(slot, 0, 3) + 1
	return ("P%d" if is_player else "CPU%d") % number
