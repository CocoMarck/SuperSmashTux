class_name PowerFighterConfigurer

# Constantes prefab
const POWER_FIGHTER_PREFAB = preload("res://prefabs/standard_power_fighter.tscn")

# Funciones
static func create( 
	config_id: StringName, control_type: GlobalUtils.ControlType ) -> PowerFighter:

	# Preparar instancia
	var power_fighter = POWER_FIGHTER_PREFAB.instantiate()
	var person_config: PersonConfig
	var have_character_registy: bool = (
		CharacterRegistry.is_playable(config_id) and config_id != "standard" )
	if have_character_registy:
		var path: String = CharacterRegistry.person_config_path(config_id)
		person_config = _load_person(path)
	if person_config != null:
		_build_instance(power_fighter, person_config)
	
	# Asignar script
	match control_type:
		GlobalUtils.ControlType.PLAYER:
			power_fighter.controller = PlayerController.new()
		GlobalUtils.ControlType.NPC:
			power_fighter.controller = NpcController.new()
		GlobalUtils.ControlType.NONE:
			pass
	
	if have_character_registy:
		_apply_tux_config(power_fighter as PowerFighter, person_config)
	
	return power_fighter as PowerFighter

# Texto de config a clase de config
static func _load_person(path: String) -> PersonConfig:
	'''
	No validar nada, el crash es bueno. Data mala, crash por mal educado. GG.
	'''
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(path)

	var config := PersonConfig.new()
	
	# Identity
	config.id  = String(cfg.get_value("identity", "id"))
	config.model = String( cfg.get_value("identity", "model") )
	config.position_offset = Vector3( cfg.get_value("identity", "position_offset") )
	
	# Momentum
	config.ground_acceleration = float(
		cfg.get_value("momentum", "ground_acceleration"))
	config.ground_friction = float(cfg.get_value("momentum", "ground_friction"))
	config.air_acceleration = float(cfg.get_value("momentum", "air_acceleration"))
	config.knockback_friction = float(cfg.get_value("momentum", "knockback_friction"))

	# Horizontal movement
	config.walking_speed = int(cfg.get_value("horizontal_movement", "walking_speed"))
	config.running_speed = int(cfg.get_value("horizontal_movement", "running_speed"))

	# Vertical movement
	config.jump_impulse = int(cfg.get_value("vertical_movement", "jump_impulse"))

	# Interval
	config.walk_step_interval = float(cfg.get_value("interval", "walk_step_interval"))
	config.run_step_interval = float(cfg.get_value("interval", "run_step_interval"))
	config.crouch_move_step_interval = float(
		cfg.get_value("interval", "crouch_move_step_interval"))

	# Duration of anims
	config.air_jump_duration = float(
		cfg.get_value("duration_of_anims", "air_jump_duration"))

	return config

# Construir instancia
static func _build_instance(power_fighter: Node3D, config: PersonConfig) -> void:
	var visual = power_fighter.get_child(0)
	var asset = visual.get_child(0)

	var loaded_model = load(config.model)
	var new_asset = loaded_model.instantiate()
	var pivot = new_asset.get_child(0)
	var skeleton = pivot.get_child(0)
	var mesh = skeleton.get_child(0) 
	mesh.position = config.position_offset

	visual.add_child(new_asset)
	visual.move_child(new_asset, 0)

	visual.remove_child(asset)
	asset.queue_free()

# Aplicar configuración
static func _apply_tux_config(
	power_fighter: PowerFighter, person_config: PersonConfig) -> void:
	power_fighter.id = person_config.id
	
	# Person config
	power_fighter.set_duration_of_anims(person_config.air_jump_duration)
	power_fighter.set_momentum(
		person_config.ground_acceleration, person_config.ground_friction, 
		person_config.air_acceleration, person_config.knockback_friction)
	# ^
	# | ground_acceleration, ground_friction, air_acceleration, knockback_friction

	power_fighter.jump_impulse = person_config.jump_impulse
	power_fighter.walking_speed = person_config.walking_speed
	power_fighter.running_speed = person_config.running_speed
	power_fighter.walk_step_interval = person_config.walk_step_interval
	power_fighter.run_step_interval = person_config.run_step_interval
	power_fighter.crouch_move_step_interval = person_config.crouch_move_step_interval

	# attacks on floor
	power_fighter.attacks.neutral1.duration = 0.33
	power_fighter.attacks.neutral1.hitboxes_moves[0].init_time_ratio = 0.45
	power_fighter.attacks.neutral1.hitboxes_moves[0].duration = 0.1
	power_fighter.attacks.neutral1.hitboxes_moves[0].damage = 5
	power_fighter.attacks.neutral1.hitboxes_moves[0].direction = Vector3(
		0.4, 0.25, 0.0)
	power_fighter.attacks.neutral1.hitboxes_moves[0].position = Vector3(
		0.6, 0.4, 0.0)
	
	
	power_fighter.attacks.neutral2.duration = 0.4583
	power_fighter.attacks.neutral2.speed = Vector3(0,0,0)
	power_fighter.attacks.neutral2.hitboxes_moves[0].init_time_ratio = 0.5
	power_fighter.attacks.neutral2.hitboxes_moves[0].duration = 0.1
	power_fighter.attacks.neutral2.hitboxes_moves[0].damage = 5
	power_fighter.attacks.neutral2.hitboxes_moves[0].direction = Vector3(
		0.4, 0.25, 0.0)
	power_fighter.attacks.neutral2.hitboxes_moves[0].position = Vector3(
		0.6, 0.5, 0.0)
	
	power_fighter.attacks.neutral3.duration = 0.4167
	power_fighter.attacks.neutral3.hitboxes_moves[0].duration = 0.2
	power_fighter.attacks.neutral3.hitboxes_moves[0].init_time_ratio = 0.5
	power_fighter.attacks.neutral3.hitboxes_moves[0].damage = 20
	power_fighter.attacks.neutral3.hitboxes_moves[0].direction = Vector3(
		0.75, 0.75, 0.0)
	power_fighter.attacks.neutral3.hitboxes_moves[0].position = Vector3(
		0.65, 0.05, 0.0)
	
	power_fighter.attacks.dash.duration = 0.375
	power_fighter.attacks.dash.hitboxes_moves[0].damage = 7
	power_fighter.attacks.dash.hitboxes_moves[0].duration = 0.3
	power_fighter.attacks.dash.hitboxes_moves[0].init_time_ratio = 0.3
	power_fighter.attacks.dash.hitboxes_moves[0].position = Vector3(
		0.45, -0.3, 0.0)
	power_fighter.attacks.dash.hitboxes_moves[0].direction = Vector3(
		1.0, 0.9, 0.0)
	
	power_fighter.attacks.up.duration = 0.375
	power_fighter.attacks.down.duration = 0.375
	power_fighter.attacks.heavy_side.duration = 0.5417
	power_fighter.attacks.heavy_up.duration = 0.5833
	
	power_fighter.attacks.heavy_down.duration = 0.5833
	power_fighter.attacks.heavy_down.hitboxes_moves = [
		HitboxMove.new({
			"id": 1, "damage": 20, "size": Vector3(0.5,0.5,1.0),
			"position": Vector3(0.7, -0.95, 0), "direction": Vector3(1.0,0.75,0.0),
			"init_time_ratio": 0.4, "duration": 0.1
		}),
		HitboxMove.new({
			"id": 2, "damage": 20, "size": Vector3(0.5,0.5,1.0),
			"position": Vector3(-0.7, -0.95, 0), "direction": Vector3(-1.0,0.75,0.0),
			"init_time_ratio": 0.4, "duration": 0.1
		})
	]

	# attacks air
	power_fighter.attacks.air_neutral.duration = 0.5
	power_fighter.attacks.air_neutral.hitboxes_moves = [
		HitboxMove.new({
			"id": 1, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(1.0, -0.45, 0), "direction": Vector3(1,-1,0),
			"init_time_ratio": 0.3, "duration": 0.2
		}),
		HitboxMove.new({
			"id": 2, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.8, -0.55, 0), "direction": Vector3(-1,-1,0),
			"init_time_ratio": 0.3, "duration": 0.2
		}),
		HitboxMove.new({
			"id": 3, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.7, 0.2, 0.0), "direction": Vector3(1,1,0),
			"init_time_ratio": 0.3, "duration": 0.2
		}),
		HitboxMove.new({
			"id": 4, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.5, 0.2, 0.0), "direction": Vector3(-1,1,0),
			"init_time_ratio": 0.3, "duration": 0.2
		})
	]
	
	power_fighter.attacks.air_forward.duration = 0.4583
	power_fighter.attacks.air_back.duration = 0.4583
	power_fighter.attacks.air_up.duration = 0.625

	# power attacks on floor
	power_fighter.power_attacks.standard.duration = 0.5
	power_fighter.power_attacks.up.duration = 0.5
	power_fighter.power_attacks.up.speed = Vector3(6,0,0)
	
	power_fighter.power_attacks.up.jump_power = 11.0
	power_fighter.power_attacks.up.hitboxes_moves = [
		HitboxMove.new({
			"id": 1, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.5,1.0,0),
			"init_time_ratio": 0.3, "duration": 0.05
		}),
		HitboxMove.new({
			"id": 2, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.5,1.0,0),
			"init_time_ratio": 0.4, "duration": 0.05
		}),
		HitboxMove.new({
			"id": 3, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.5,1.0,0),
			"init_time_ratio": 0.5, "duration": 0.05
		}),
		HitboxMove.new({
			"id": 4, "damage": 5.0, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.75,1.0,0),
			"init_time_ratio": 0.6, "duration": 0.05
		}),
	]
	
	power_fighter.power_attacks.down.duration = 1.0417
	power_fighter.power_attacks.down.hitboxes_moves = [
		# Frente
		HitboxMove.new({
			"id": 1, "damage": 5, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(1.0,-0.15,0.0), "direction": Vector3(-1.0,0.25,0.0),
			"init_time_ratio": 0.5, "duration": 0.08
		}),
		HitboxMove.new({
			"id": 2, "damage": 5, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(1.0,-0.15,0.0), "direction": Vector3(-1.0,0.25,0.0),
			"init_time_ratio": 0.6, "duration": 0.08
		}),
		HitboxMove.new({
			"id": 3, "damage": 5, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(1.0,-0.15,0.0), "direction": Vector3(-1.0,0.25,0.0),
			"init_time_ratio": 0.7, "duration": 0.08
		}),
		HitboxMove.new({
			"id": 4, "damage": 10, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(1.0,-0.15,0.0), "direction": Vector3(0.0,0.75,0.0),
			"init_time_ratio": 0.8, "duration": 0.08
		}),
		# Espalda
		HitboxMove.new({
			"id": 5, "damage": 5, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(-1.0,-0.15,0.0), "direction": Vector3(1.0,0.25,0.0),
			"init_time_ratio": 0.5, "duration": 0.08
		}),
		HitboxMove.new({
			"id": 6, "damage": 5, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(-1.0,-0.15,0.0), "direction": Vector3(1.0,0.25,0.0),
			"init_time_ratio": 0.6, "duration": 0.08
		}),
		HitboxMove.new({
			"id": 7, "damage": 5, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(-1.0,-0.15,0.0), "direction": Vector3(1.0,0.25,0.0),
			"init_time_ratio": 0.7, "duration": 0.08
		}),
		HitboxMove.new({
			"id": 8, "damage": 10, "size": Vector3(0.5,0.5,0.75),
			"position": Vector3(-1.0,-0.15,0.0), "direction": Vector3(0.0,0.75,0.0),
			"init_time_ratio": 0.8, "duration": 0.08
		})
	]

	# power attacks air
	power_fighter.power_attacks.air_standard.duration = 0.5
	power_fighter.power_attacks.air_up.duration = 0.5
	power_fighter.power_attacks.air_up.speed = Vector3(6,0,0)
	
	power_fighter.power_attacks.air_up.jump_power = 11.0
	power_fighter.power_attacks.air_up.hitboxes_moves = [
		HitboxMove.new({
			"id": 1, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.5,1.0,0),
			"init_time_ratio": 0.3, "duration": 0.05
		}),
		HitboxMove.new({
			"id": 2, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.5,1.0,0),
			"init_time_ratio": 0.4, "duration": 0.05
		}),
		HitboxMove.new({
			"id": 3, "damage": 5, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.5,1.0,0),
			"init_time_ratio": 0.5, "duration": 0.05
		}),
		HitboxMove.new({
			"id": 4, "damage": 5.0, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.0, 1.2, 0), "direction": Vector3(0.75,1.0,0),
			"init_time_ratio": 0.6, "duration": 0.05
		}),
	]
	
	power_fighter.power_attacks.air_down.duration = 1.0417
	power_fighter.power_attacks.air_down.hitboxes_moves = [
		# Frente
		HitboxMove.new({
			"id": 1, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.7,0.6,0.0), "direction": Vector3(-1.0,-1.0,0.0),
			"init_time_ratio": 0.2, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 2, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.8,-0.5,0.0), "direction": Vector3(-1.0,1.0,0.0),
			"init_time_ratio": 0.2, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 3, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.7,0.6,0.0), "direction": Vector3(-1.0,-1.0,0.0),
			"init_time_ratio": 0.4, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 4, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.8,-0.5,0.0), "direction": Vector3(-1.0,1.0,0.0),
			"init_time_ratio": 0.4, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 5, "damage": 3, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.7,0.6,0.0), "direction": Vector3(1.0,1.0,0.0),
			"init_time_ratio": 0.6, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 6, "damage": 3, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(0.8,-0.5,0.0), "direction": Vector3(1.0,-1.0,0.0),
			"init_time_ratio": 0.6, "duration": 0.18
		}),
		
		# Espalda
		HitboxMove.new({
			"id": 7, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.7,0.6,0.0), "direction": Vector3(-1.0,-1.0,0.0),
			"init_time_ratio": 0.2, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 8, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.8,-0.5,0.0), "direction": Vector3(-1.0,1.0,0.0),
			"init_time_ratio": 0.2, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 9, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.7,0.6,0.0), "direction": Vector3(-1.0,-1.0,0.0),
			"init_time_ratio": 0.4, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 10, "damage": 2, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.8,-0.5,0.0), "direction": Vector3(-1.0,1.0,0.0),
			"init_time_ratio": 0.4, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 11, "damage": 3, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.7,0.6,0.0), "direction": Vector3(-1.0,1.0,0.0),
			"init_time_ratio": 0.6, "duration": 0.18
		}),
		HitboxMove.new({
			"id": 12, "damage": 3, "size": Vector3(0.5,0.5,0.5),
			"position": Vector3(-0.8,-0.5,0.0), "direction": Vector3(-1.0,-1.0,0.0),
			"init_time_ratio": 0.6, "duration": 0.18
		}),
	]
