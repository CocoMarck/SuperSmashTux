extends CharacterBody3D

# Velocidad de player, y acelearacion de caida.
@export var speed = 14
@export var fall_acceleration = 48
@export var jump_impulse = 20

# Propiedad necesaria para gravedad.
var target_velocity = Vector3.ZERO

# Funcion de procesamiento de fisicas. Tambien teine metido el movimiento.
func _physics_process(delta):
	var direction = Vector3.ZERO
	
	# Direcciones del player
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	
	# Mover direccion visual plaeyer
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.basis = Basis.looking_at(direction)
	
	# Volocidad en terra
	target_velocity.x = direction.x * speed
		
	# Volocidad vertical. Gravedad
	var jump = (Input.is_action_pressed("jump") == true ) or (Input.is_action_pressed("move_up") == true)
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta
	else:
		if jump:
			target_velocity.y = jump_impulse
	
	# Mover personaje
	velocity = target_velocity
	move_and_slide()
