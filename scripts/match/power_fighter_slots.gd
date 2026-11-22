class_name PowerFighterSlots
extends Node

'''
- No debe validar slots. Si no existen crash, y eso esta bien.
Solo tiene data de slots, tiene función para almacenar fighters.
'''

var _slots: Dictionary[int, PowerFighterData]

func set_slot(id: int, data: PowerFighterData) -> void:
	# assert(condición, mensaje): un assert("texto") a secas nunca falla, porque el texto cuenta como true.
	assert(data != null, "Need PowerFighterData, not null.")
	assert(
		CharacterRegistry.is_playable(data.config_id), # Acepta ocultos (ej. debug).
		"No avaible config id: %s" % data.config_id)
	_slots[id] = data
		

func get_slot(id: int) -> PowerFighterData:
	return _slots[id]

func has_slot(id: int) -> bool:
	return _slots.has(id)

func get_slots() -> Dictionary[int, PowerFighterData]:
	return _slots
