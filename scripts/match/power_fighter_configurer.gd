class_name PowerFighterConfigurer

# Constantes prefab
const POWER_FIGHTER_PREFAB = preload("res://prefabs/standard_power_fighter.tscn")

# Constantes del script.
const PLAYER_SCRIPT = preload("res://scripts/characters/player.gd")
const NPC_SCRIPT = preload("res://scripts/characters/npc.gd")

# Assets de personajes
const TUX_FIGHTER_ASSET = preload("res://assets/tux_fighter.glb")

# Funciones
static func create( 
	config: GlobalUtils.PowerFighterConfig, control_type: GlobalUtils.ControlType ) -> PowerFighter:

	# Preparar instncia
	var power_fighter = POWER_FIGHTER_PREFAB.instantiate()
	match config:
		GlobalUtils.PowerFighterConfig.TUX:
			_apply_tux_config(power_fighter)
	
	# Asignar script
	match control_type:
		GlobalUtils.ControlType.PLAYER:
			power_fighter.set_script(PLAYER_SCRIPT)
		GlobalUtils.ControlType.NPC:
			power_fighter.set_script(NPC_SCRIPT)
	
	return power_fighter as PowerFighter

static func _apply_tux_config(power_fighter: Node3D) -> void:
	var visual = power_fighter.get_child(0)
	var asset = visual.get_child(0)

	var new_asset = TUX_FIGHTER_ASSET.instantiate()
	var pivot = new_asset.get_child(0)
	var skeleton = pivot.get_child(0)
	var mesh = skeleton.get_child(0) 
	mesh.position.y = -1.2

	visual.add_child(new_asset)
	visual.move_child(new_asset, 0)

	visual.remove_child(asset)
	asset.queue_free()
	
