extends Character
'''
El NPC, pos se mueve solo.
'''

func _collect_input() -> void:
	'''
	Nomas para que salte como loquita el npc
	'''
	_move_left = false
	_move_right = false
	_move_up = false
	_move_down = false
	
	# Lo pongo asi, porque el jump del character es hasta un nuevo false, no continuo
	if _jump == false:
		_jump = true
	else:
		_jump = false
