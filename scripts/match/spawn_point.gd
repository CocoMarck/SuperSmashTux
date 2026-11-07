class_name SpawnPoint
extends Marker3D

# Propiedades publicas del script.
@export var init_looking_at_right: bool = false

func spawn(config: GlobalUtils.PowerFighterConfig, control_type: GlobalUtils.ControlType, player_id: int) -> PowerFighter:
	'''
	Instanciar un personaje en este punto, con el tipo e ID que indique quien llama
	(normalmente el GameManager). El add_child es diferido, pero la referencia que se
	devuelve ya es valida de inmediato, se puede guardar aunque el nodo todavia no
	ande metido en el arbol.
	'''
	var power_fighter :PowerFighter = PowerFighterConfigurer.create(
		config, control_type )
	
	match control_type:
		# El Player resuelve sus inputs y material según su ID.
		GlobalUtils.ControlType.PLAYER:
			power_fighter.player_id = player_id

	# Configurar direccion de vista del personaje.
	power_fighter.init_looking_at_right = init_looking_at_right

	# Posicionar al personaje en este punto de spawn, como hijo directo de la escena.
	power_fighter.position = global_position
	return power_fighter
