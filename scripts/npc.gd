extends Character
'''
El NPC, pos se mueve solo.
'''

func _collect_input() -> void:
	'''
	Nomas para que salte como loquita el npc
	'''
	move_left = false
	move_right = false
	move_up = false
	move_down = false
	
	# Lo pongo asi, porque el jump del character es hasta un nuevo false, no continuo
	if jump == false:
		jump = true
	else:
		jump = false
