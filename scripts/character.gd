extends CharacterBody3D
class_name Character

# Constantes del script.
const MAX_JUMPS := 2

# Propiedades publicas | Gravidad y velocidad.
@export var speed := 14
@export var fall_acceleration := 48
@export var jump_impulse := 25
@export var init_looking_at_right : bool = false


# Propiedades publicas | Materiales y malla
@export var material : Material = null
@export var mesh : Mesh = null

# Propiedades privadas | Movimientos
var move_left: bool = false
var move_right: bool = false
var move_up: bool = false
var move_down: bool = false
var jump: bool = false

# Propiedades privadas | Velocidad y salto
var target_velocity = Vector3.ZERO
var jump_count = 0
var was_jumping = false
var air_count = 0

# Funciones
func _get_initial_facing() -> Vector3:
	if init_looking_at_right:
		return Vector3.RIGHT
	else:
		return Vector3.LEFT

func _set_material( m: Material ) -> void:
	'''
	Establecer material al jugador.
	Aunque preferiblemente sea nomas color. 
	Pero por ahroa, asi ta bien.
	'''
	if material != null:
		$Pivot/Mesh.material_override = m

func _set_mesh( m: Mesh ) -> void:
	'''
	Establecer malla nueva
	'''
	if m != null:
		$Pivot/Mesh.mesh = m

func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Cambiar el color del character
	_set_mesh(mesh)
	_set_material(material)
	
	# Establecer direccion de vista inicial.
	$Pivot.basis = Basis.looking_at( _get_initial_facing() )

func _get_move_direction() -> Vector3:
	'''
	Obtener direccion de movimiento. Tambien sirve para voltear el character.
	'''
	var axis = ( float(int(move_right) -int(move_left)) )
	return Vector3(axis, 0.0, 0.0)

func _collect_input() -> void:
	'''
	Funcion para obtener acciones sobrescritas por otro script hijo de character.
	'''
	pass

func _physics_process(delta: float) -> void:
	'''
	Funcion de procesamiento de fisicas. Tambien tiene metido el movimiento.
	'''
	_collect_input()
	
	var direction := _get_move_direction()
	var on_floor := is_on_floor()
		
	# Calcular velocidad en tierra. Determinar salto
	target_velocity.x = direction.x * speed
	var is_jumping := jump or move_up
	
	# Gravedad | Fuerza vertical. 
	# Contadores a cero, para que no se acumule fuerza vertcal.
	if on_floor:
		target_velocity.y = 0
		air_count = 0
		jump_count = 0
	else:
		target_velocity.y -= fall_acceleration * delta
		air_count += 1
	
	# Salto | Detectar si la tecla de salto se acaba de presionar.
	var jump_pressed := is_jumping and not was_jumping
	was_jumping = is_jumping

	# Salto | Aplicar salto normal o doble segun el caso.
	if jump_pressed and jump_count < MAX_JUMPS:
		target_velocity.y = jump_impulse
		if air_count > 0:
			jump_count = MAX_JUMPS
		else:
			jump_count += 1
	
	# Characeter action states
	var moving = direction.x != 0.0
	var jumping = target_velocity.y > 0
	var falling = not jumping and not on_floor
	var neutral = on_floor and not moving
	var running = on_floor and moving
		
	# Animacion | Movimiento en el piso
	if neutral:
		$Pivot/Mesh.rotation.x = 0
	if running:
		if not $AnimationMesh.is_playing():
			$AnimationMesh.play("run")
	else:
		$AnimationMesh.stop()
	# Animacion | Salto
	if jumping:
		$Pivot/Mesh.rotation.x = -50
	elif falling:
		$Pivot/Mesh.rotation.x = 50
		
	# Animación | Mover direccion visual del player.
	if moving:
		$Pivot.basis = Basis.looking_at(direction)

	# Aplicar movimiento del personaje.
	velocity = target_velocity
	move_and_slide()
