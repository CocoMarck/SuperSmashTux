class_name PowerFighterConfigurer

# Constantes prefab
# Este es el standard prefab. Es la base/dummy. Sin cfg, ni build especial, por diseño. No "arreglar" cargando un `cfg` o algo asi. Los cambios finales del moveset van en code.
const POWER_FIGHTER_PREFAB = preload("res://prefabs/standard_power_fighter.tscn")

# Funciones
static func create( 
	config_id: StringName, control_type: GlobalUtils.ControlType ) -> PowerFighter:

	# Preparar instancia
	var power_fighter = POWER_FIGHTER_PREFAB.instantiate()
	var person_config: PersonConfig
	var fighter_config: FighterConfig
	var power_fighter_config: PowerFighterConfig

	# Obtener configs
	var has_person_config: bool = CharacterRegistry.has_person_config(config_id)
	var has_fighter_config: bool = CharacterRegistry.has_fighter_config(config_id)
	var has_power_fighter_config: bool = CharacterRegistry.has_power_fighter_config(config_id)

	if has_person_config:
		person_config = CharacterRegistry.load_person_config(
			CharacterRegistry.person_config_path(config_id) )
	if has_fighter_config:
		fighter_config = CharacterRegistry.load_fighter_config(
			CharacterRegistry.fighter_config_path(config_id) )
	if has_power_fighter_config:
		power_fighter_config = CharacterRegistry.load_power_fighter_config(
			CharacterRegistry.power_fighter_config_path(config_id) )
	
	# Construir instancia solo si existe person. `<id>.person.cfg` es el requisito mínimo para un nuevo personaje.
	if has_person_config:
		_build_instance(power_fighter, person_config)
	
	# Establecer configuración al personaje
	if has_person_config:
		_apply_person_config(power_fighter, person_config)
	if has_fighter_config:
		_apply_fighter_config(power_fighter, fighter_config)
	if has_power_fighter_config:
		_apply_power_fighter_config(power_fighter, power_fighter_config)

	# Establecer tipo de control
	match control_type:
		GlobalUtils.ControlType.PLAYER:
			power_fighter.controller = PlayerController.new()
		GlobalUtils.ControlType.NPC:
			power_fighter.controller = NpcController.new()
		GlobalUtils.ControlType.NONE:
			pass
	
	return power_fighter

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
static func _apply_person_config(
	power_fighter: PowerFighter, person_config: PersonConfig) -> void:
	'''
	Movimiento e identidad desde `<id>.person.cfg`. Aplica a cualquier personaje.
	'''
	power_fighter.id = person_config.id
	
	# Person config
	power_fighter.set_duration_of_anims(person_config.air_jump_duration)
	power_fighter.set_momentum(
		person_config.ground_acceleration, person_config.ground_friction, 
		person_config.air_acceleration, person_config.knockback_friction)
	# ^
	# | ground_acceleration, ground_friction, air_acceleration, knockback_friction
	power_fighter.set_anim_offset(person_config.hanging_anim_offset)

	power_fighter.jump_impulse = person_config.jump_impulse
	power_fighter.walking_speed = person_config.walking_speed
	power_fighter.running_speed = person_config.running_speed
	power_fighter.walk_step_interval = person_config.walk_step_interval
	power_fighter.run_step_interval = person_config.run_step_interval
	power_fighter.crouch_move_step_interval = person_config.crouch_move_step_interval

static func _apply_fighter_config(
	power_fighter: PowerFighter, fighter_config: FighterConfig) -> void:
	'''
	Aca se podria validar cada ataque (por motivos debug, o protejer el juego), pero creo que es mejor crash si esta mal el `FightMove`.
	'''
	# Fight moves
	power_fighter.fight_moves_with_simple_sound = fighter_config.fight_moves_with_simple_sound
	power_fighter.fight_moves_with_hitspawn_sound = fighter_config.fight_moves_with_hitspawn_sound
	
	# Attacks
	power_fighter.attacks = fighter_config.attacks

static func _apply_power_fighter_config(
	power_fighter: PowerFighter, power_fighter_config: PowerFighterConfig) -> void:
	'''
	'''
	power_fighter.power_attacks = power_fighter_config.power_attacks
