class_name CameraFollow
extends Marker3D

# Camara dinamica que encuadra a todos los peleadores con zoom. El pivot (Marker3D) se mueve en X/Y
# y la Camera3D hija solo en Z. Cada frame: _update_target y luego _move_camera.
# Busca a los peleadores entre los hijos de su padre (el GameManager), asi que tiene que colgar de el.
# Se instancia desde prefabs/camera_follow.tscn; camera_area se asigna antes del add_child.

# Propiedades publicas | Area de juego.
@export_group("Areas")
@export var camera_area: Area3D    # quien este fuera de esta caja ya no cuenta pal encuadre

# Propiedades publicas | Zoom.
@export_group("Zoom")
@export var zoom_min_distance: float = 12.0
@export var zoom_max_distance: float = 30.0

# Propiedades publicas | Suavizado.
@export_group("Smoothing")
@export var pan_speed: float = 4.0
@export var zoom_out_speed: float = 3.0
@export var zoom_in_speed: float = 2.0

# Propiedades publicas | Efectos | Temblor
@export_group("Shake")
@export var shake_strength: float = 0.1
@export var shake_duration_ms: int = 500   # cuanto tiembla cada vez que muere alguien

# Propiedades privadas | Encuadre
@onready var _camera: Camera3D = $Camera3D    # la del prefab; ahi se ajustan fov y distancia inicial
var _camera_area_bounds: AABB
var _position: Vector2 = Vector2.ZERO    # posicion actual del pivot, sin temblor
var _distance: float = 0.0
var _target_position: Vector2 = Vector2.ZERO
var _target_distance: float = 0.0

# Propiedades privadas | Efectos | Temblor
var _shake_end_time_msec: int = 0

# Funciones | Ayudantes
func _distance_for_size(size: Vector2, aspect: float, half_fov_tan: float) -> float:
	'''Distancia pa que un rect quepa en el fov. El ancho depende del aspecto; el alto no, porque el fov es vertical.'''
	var half := size * 0.5
	return maxf(half.y, half.x / aspect) / half_fov_tan

# Funciones | Encuadre y movimiento
func _update_target() -> void:
	'''
	Recalcula el objetivo (centro y distancia) pa encuadrar a los peleadores dentro de camera_area.
	Sin peleadores que encuadrar, el objetivo no cambia.
	'''
	var has_camera_bounds := _camera_area_bounds.size != Vector3.ZERO

	# Rect que encuadra a los peleadores dentro del area. Los PowerFighter son hermanos de la camara.
	var rect := Rect2()
	var rect_started := false
	for child in get_parent().get_children():
		var power_fighter := child as PowerFighter
		if power_fighter == null:
			continue
		var pos := power_fighter.global_position
		if has_camera_bounds and not _camera_area_bounds.has_point(pos):
			continue
		var point := Vector2(pos.x, pos.y)
		if rect_started:
			rect = rect.expand(point)
		else:
			rect = Rect2(point, Vector2.ZERO)
			rect_started = true
	if not rect_started:
		return

	# Distancia necesaria pa que el rect completo quepa en el fov vertical de la camara.
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := (viewport_size.x / viewport_size.y) if viewport_size.y > 0.0 else 1.0
	var half_fov_tan := tan(deg_to_rad(_camera.fov * 0.5))
	var needed := _distance_for_size(rect.size, aspect, half_fov_tan)

	if has_camera_bounds:
		# Cuanta distancia pediria el caso extremo: peleadores en esquinas opuestas de la camera area.
		var d_full := _distance_for_size(Vector2(_camera_area_bounds.size.x, _camera_area_bounds.size.y), aspect, half_fov_tan)

		# Remapear: encimados dan el zoom minimo y esquinas opuestas el maximo, repartido parejo.
		var t := 0.0
		if d_full > 0.0:
			t = clampf(needed / d_full, 0.0, 1.0)
		_target_distance = lerpf(zoom_min_distance, zoom_max_distance, t)
	else:
		# Sin camera area no hay contra que normalizar, asi que se usa la distancia cruda recortada.
		_target_distance = clampf(needed, zoom_min_distance, zoom_max_distance)

	_target_position = rect.get_center()

func _move_camera(delta: float) -> void:
	'''
	Desliza pivot y distancia hacia el objetivo (suavizado independiente del framerate).
	Alejar rapido y acercar lento es a proposito: si tarda en alejarse saca gente de pantalla,
	y si se acerca muy rapido marea. El temblor no se guarda en _position, solo se aplica en este frame.
	'''
	# Suavizado
	var pan_weight := 1.0 - exp(-pan_speed * delta)
	_position = _position.lerp(_target_position, pan_weight)

	var zoom_speed := zoom_out_speed if _target_distance > _distance else zoom_in_speed
	var zoom_weight := 1.0 - exp(-zoom_speed * delta)
	_distance = lerpf(_distance, _target_distance, zoom_weight)

	# Temblor
	var shake_offset := Vector2.ZERO
	if is_shake_active():
		shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength) )

	# Aplicar: el pivot lleva el encuadre en X/Y, la camara hija nomas la distancia en Z.
	global_position = Vector3(_position.x + shake_offset.x, _position.y + shake_offset.y, global_position.z)
	_camera.position = Vector3(0.0, 0.0, _distance)

# Funciones | Efectos
func shake(milliseconds: int) -> void:
	'''Hace temblar la camara durante N ms desde ahora.'''
	_shake_end_time_msec = Time.get_ticks_msec() + int(milliseconds)

func on_power_fighter_died(_power_fighter: PowerFighter, _lives: int) -> void:
	'''
	Escucha la señal lives_changed del GameManager (la conecta el al crear la camara).
	La camara decide el efecto: hoy un temblor de shake_duration_ms en cada muerte.
	'''
	shake(shake_duration_ms)

func is_shake_active() -> bool:
	return Time.get_ticks_msec() < _shake_end_time_msec

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Arranca desde la posicion actual pa que el primer frame no pegue un salto; la distancia inicial
	sale de la Camera3D del prefab. Si falta camera_area truena a proposito: asi se nota que la escena esta mal armada.
	'''
	# Camera 3D
	_camera.current = true
	_camera_area_bounds = GlobalUtils.get_box_bounds(GlobalUtils.get_first_collision_shape(camera_area))
	# Movimiento de la camara
	_position = Vector2(global_position.x, global_position.y)
	_distance = _camera.position.z
	_target_position = _position
	_target_distance = _distance

# Funciones | Procesamiento de fisicas.
func _physics_process(delta: float) -> void:
	'''Va en fisicas y no en _process pa ir al mismo paso que los peleadores.'''
	_update_target()
	_move_camera(delta)
