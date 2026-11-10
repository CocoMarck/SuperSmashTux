class_name PowerFighterSlots
extends Node

'''
- No debe validar slots. Si no existen crash, y eso esta bien.
Solo tiene data de slots, tiene función para almacenar fighters.
'''

var _slots: Dictionary[int, PowerFighterData]

func set_slot(id: int, data: PowerFighterData) -> void:
	if not data is PowerFighterData:
		assert("Need PowerFighterData, not {data}")
	if not data.config in GlobalUtils.CONFIG_OPTIONS:
		assert("No avaible config.")
	_slots[id] = data
		

func get_slot(id: int) -> PowerFighterData:
	return _slots[id]

func has_slot(id: int) -> bool:
	return _slots.has(id)

func get_slots() -> Dictionary[int, PowerFighterData]:
	return _slots
