class_name KeyText
extends RefCounted

'''
Textos de teclas para los avisos de la UI, leídos del Input Map (siguen bien si se reasignan controles).
'''

# Constantes
const SEPARATOR := " · "

# Funciones
static func action_key(action: StringName) -> String:
	'''
	Texto de la tecla de teclado asignada a la acción, o "?" si no tiene.
	'''
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			var text: String = key.as_text_physical_keycode() if key.physical_keycode != KEY_NONE else key.as_text_keycode()
			return text.replace(" (Physical)", "")
	return "?"

static func action_pair(first: StringName, second: StringName) -> String:
	'''
	Teclas de dos acciones juntas, por ejemplo las de P1 y P2: "K · Num 1".
	'''
	return action_key(first) + SEPARATOR + action_key(second)
