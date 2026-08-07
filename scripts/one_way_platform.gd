class_name OneWayPlatform
extends Platform

# Plataforma que se atraviesa desde abajo, pero en la que te posas al caer encima.

const GROUP_NAME := &"one_way_platforms"

func _get_group_name() -> StringName:
	return GROUP_NAME
