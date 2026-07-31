extends CharacterBody3D

# Enumeracion de IDs posibles de jugadores.
enum PlayerId { PLAYER_1, PLAYER_2 }

# Propiedades publicas del script.
@export var player_id : PlayerId
@export var mat_player_1 : Material
@export var mat_player_2 : Material
@export var speed = 14
@export var fall_acceleration = 48
@export var jump_impulse = 25

# Propiedades privadas del script.
var target_velocity = Vector3.ZERO

func _ready() -> void:
	# Cambiar el color del jugador dependiendo su ID.
	match player_id:
		PlayerId.PLAYER_1:
			$Pivot/CharacterMesh.material_override = mat_player_1
		PlayerId.PLAYER_2:
			$Pivot/CharacterMesh.material_override = mat_player_2

# Funcion de procesamiento de fisicas. Tambien tiene metido el movimiento.
func _physics_process(delta):
	var direction = Vector3.ZERO
	var is_jumping = false
	
	# Direcciones de movimiento y salto según el Id de jugador.
	match player_id:
		PlayerId.PLAYER_1:
			if Input.is_key_pressed(KEY_D): # Derecha J1
				direction.x += 1
			if Input.is_key_pressed(KEY_A): # Izquierda J1
				direction.x -= 1
			is_jumping = Input.is_key_pressed(KEY_W) # Salto J1
		PlayerId.PLAYER_2:
			if Input.is_key_pressed(KEY_RIGHT): # Derecha J2
				direction.x += 1
			if Input.is_key_pressed(KEY_LEFT): # Izquierda J2
				direction.x -= 1
			is_jumping = Input.is_key_pressed(KEY_UP) # Salto J2
	
	# Mover direccion visual plaeyer.
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.basis = Basis.looking_at(direction)
	
	# Volocidad en terra.
	target_velocity.x = direction.x * speed
		
	# Aplicar gravedad o impulso de salto segun el caso.
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta
	elif is_jumping:
		target_velocity.y = jump_impulse
		
	# Aplicar movimiento del personaje.
	velocity = target_velocity
	move_and_slide()
