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

	# Preparar instancia
	var power_fighter = POWER_FIGHTER_PREFAB.instantiate()
	match config:
		GlobalUtils.PowerFighterConfig.TUX:
			_build_tux_instance(power_fighter)
	
	# Asignar script
	match control_type:
		GlobalUtils.ControlType.PLAYER:
			power_fighter.set_script(PLAYER_SCRIPT)
		GlobalUtils.ControlType.NPC:
			power_fighter.set_script(NPC_SCRIPT)
	
	match config:
		GlobalUtils.PowerFighterConfig.TUX:
			_apply_tux_config(power_fighter as PowerFighter)
	
	return power_fighter as PowerFighter

static func _build_tux_instance(power_fighter: Node3D) -> void:
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

static func _apply_tux_config(power_fighter: PowerFighter) -> void:
	power_fighter.set_duration_of_anims(0.5)

	# attacks on floor
	power_fighter.attacks.neutral1.duration = 0.33
	power_fighter.attacks.neutral2.duration = 0.4583
	power_fighter.attacks.neutral3.duration = 0.4167
	power_fighter.attacks.dash.duration = 0.375
	power_fighter.attacks.up.duration = 0.375
	power_fighter.attacks.down.duration = 0.375
	power_fighter.attacks.heavy_side.duration = 0.5417
	power_fighter.attacks.heavy_up.duration = 0.5833
	power_fighter.attacks.heavy_down.duration = 0.5833

	# attacks air
	power_fighter.attacks.air_neutral.duration = 0.5
	power_fighter.attacks.air_forward.duration = 0.4583
	power_fighter.attacks.air_back.duration = 0.4583
	power_fighter.attacks.air_up.duration = 0.625

	# power attacks on floor
	power_fighter.power_attacks.standard.duration = 0.5
	power_fighter.power_attacks.up.duration = 0.5
	power_fighter.power_attacks.up.speed = Vector3(6,0,0)
	power_fighter.power_attacks.up.jump_power = 11.0
	power_fighter.power_attacks.down.duration = 1.0417

	# power attacks air
	power_fighter.power_attacks.air_standard.duration = 0.5
	power_fighter.power_attacks.air_up.duration = 0.5
	power_fighter.power_attacks.air_up.speed = Vector3(6,0,0)
	power_fighter.power_attacks.air_up.jump_power = 11.0
	power_fighter.power_attacks.air_down.duration = 1.0417
