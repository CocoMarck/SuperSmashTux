extends CharacterBody3D

# Constantes del script.
const MAX_JUMPS = 2

# Propiedades publicas del script.
@export var player_id : GlobalConstants.PlayerId
@export var mat_player_1 : Material
@export var mat_player_2 : Material
@export var initial_facing : Vector3 = Vector3.RIGHT
@export var speed = 14
@export var fall_acceleration = 48
@export var jump_impulse = 25

# Propiedades privadas del script.
var target_velocity = Vector3.ZERO
var jump_count = 0
var was_jumping = false

func _ready() -> void:
	# Cambiar el color del jugador dependiendo su ID.
	match player_id:
		GlobalConstants.PlayerId.PLAYER_1:
			$Pivot/CharacterMesh.material_override = mat_player_1
		GlobalConstants.PlayerId.PLAYER_2:
			$Pivot/CharacterMesh.material_override = mat_player_2

	# Establecer direccion de vista inicial.
	$Pivot.basis = Basis.looking_at(initial_facing)

# Funcion de procesamiento de fisicas. Tambien tiene metido el movimiento.
func _physics_process(delta):
	var direction = Vector3.ZERO
	var is_jumping = false

	# Direcciones de movimiento y salto según el Id de jugador.
	match player_id:
		GlobalConstants.PlayerId.PLAYER_1:
			if Input.is_physical_key_pressed(KEY_D): # Derecha J1
				direction.x += 1
			if Input.is_physical_key_pressed(KEY_A): # Izquierda J1
				direction.x -= 1
			is_jumping = Input.is_physical_key_pressed(KEY_W) # Salto J1
		GlobalConstants.PlayerId.PLAYER_2:
			if Input.is_physical_key_pressed(KEY_RIGHT): # Derecha J2
				direction.x += 1
			if Input.is_physical_key_pressed(KEY_LEFT): # Izquierda J2
				direction.x -= 1
			is_jumping = Input.is_physical_key_pressed(KEY_UP) # Salto J2

	# Mover direccion visual player.
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.basis = Basis.looking_at(direction)

	# Calcular velocidad en tierra.
	target_velocity.x = direction.x * speed
	
	# Detectar si la tecla de salto se acaba de presionar.
	var jump_pressed = is_jumping and not was_jumping
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

	# Aplicar movimiento del personaje.
	velocity = target_velocity
	move_and_slide()
