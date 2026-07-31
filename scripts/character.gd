extends CharacterBody3D
class_name Character

# Constantes del script.
const MAX_JUMPS := 2

# Propiedades publicas | Gravidad y velocidad.
@export var speed := 14
@export var fall_acceleration := 48
@export var jump_impulse := 25
@export var init_looking_at_right : bool = false

# Propiedades publicas | Materiales
@export var material : Material = null

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

# Funciones
func _get_initial_facing() -> Vector3:
	if init_looking_at_right:
		return Vector3.RIGHT
	else:
		return Vector3.LEFT

func _set_material() -> void:
	'''
	Establecer material al jugador.
	Aunque preferiblemente sea nomas color. 
	Pero por ahroa, asi ta bien.
	'''
	if material != null:
		$Pivot/CharacterMesh.material_override = material

func _ready() -> void:
	'''
	Inicializar el character, con sus colorines, materiales etc.
	'''
	# Cambiar el color del character
	_set_material()
	
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
		
	# Calcular velocidad en tierra. Determinar salto
	target_velocity.x = direction.x * speed
	var is_jumping := jump or move_up
	
	# Detectar si la tecla de salto se acaba de presionar.
	var jump_pressed := is_jumping and not was_jumping
	was_jumping = is_jumping

	# Aplicar salto/doble salto o gravedad segun el caso.
	if jump_pressed and jump_count < MAX_JUMPS:
		target_velocity.y = jump_impulse
		jump_count += 1
	elif not is_on_floor():
		target_velocity.y -= fall_acceleration * delta
		
	# Reiniciar el contador de saltos al aterrizar.
	if is_on_floor() and not jump_pressed:
		jump_count = 0
		
	# Animación | Mover direccion visual del player.
	if direction.x != 0.0:
		$Pivot.basis = Basis.looking_at(Vector3(direction.x, 0.0, 0.0))

	# Aplicar movimiento del personaje.
	velocity = target_velocity
	move_and_slide()
