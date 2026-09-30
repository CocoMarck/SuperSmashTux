class_name CameraFollow
extends Marker3D

'''
Cámara dinámica: encuadra a todos los peleadores, se aleja cuando se separan y se acerca cuando se juntan.

Es un Marker3D, con hijo Camera3D.
'''

# Propiedades publicas | Area de juego.
@export_group("Areas")
@export var camera_area: Area3D    # caja interior: hasta aqui sigue la camara; mas alla se queda pegada al borde

# Propiedades publicas | Zoom.
@export_group("Zoom")
@export var zoom_min_distance: float = 12.0    # que tan cerca puede llegar la camara
@export var zoom_max_distance: float = 20.0    # que tan lejos puede alejarse la camara

# Propiedades publicas | Suavizado.
@export_group("Smoothing")
@export var pan_speed: float = 4.0         # que tan rapido sigue la posicion x/y al objetivo
@export var zoom_out_speed: float = 3.0    # que tan rapido se aleja cuando los peleadores se separan
@export var zoom_in_speed: float = 2.0     # que tan rapido se acerca cuando los peleadores se juntan

# Propiedades publicas | Efectos | Temblor
@export_group("Shake")
@export var shake_strength: float = 0.1   # que tan fuerte tiembla la camara mientras alguien espera respawn

# Propiedades privadas | Normal work
var _camera: Camera3D
var _position: Vector2 = Vector2.ZERO
var _distance: float = 0.0
var _target_position: Vector2 = Vector2.ZERO
var _target_distance: float = 0.0
var _camera_area_bounds: AABB

# Propiedades privadas | Efectos | Temblor
var _shake_end_time_msec: int = 0
var _shake_offset: Vector2 = Vector2.ZERO

# Funciones propias
func _get_power_fighters() -> Array[PowerFighter]:
	var power_fighters : Array[PowerFighter] = []
	for child in get_parent().get_children():
		var power_fighter := child as PowerFighter
		if power_fighter != null:
			power_fighters.append(power_fighter)
	return power_fighters

func _get_area_bounds(area: Area3D) -> AABB:
	'''
	AABB en coordenadas del mundo de la caja de un area, sacada de su BoxShape3D.
	'''
	var collision_shape: CollisionShape3D = null
	for child in area.get_children():
		collision_shape = child as CollisionShape3D
		if collision_shape != null:
			break
	var box := collision_shape.shape as BoxShape3D
	var half := box.size * 0.5 * collision_shape.global_basis.get_scale()
	return AABB(collision_shape.global_position - half, half * 2.0)

func _distance_for_size(size: Vector2, aspect: float, half_fov_tan: float) -> float:
	'''
	Que tan lejos hay que pararse pa que un rect de este tamaño quepa en el fov de la camara. El ancho depende del aspecto del viewport; el alto no, porque el fov es vertical.
	'''
	var half := size * 0.5
	return maxf(half.y, half.x / aspect) / half_fov_tan

func _accumulate_positions(
	positions: Array[Vector3], has_camera_bounds: bool, 
	camera_bounds: AABB, rect: Rect2, rect_started: bool) -> Dictionary:
	'''
	Recortar cada posicion contra camera_area y sumarla al rect de encuadre. Recibe el rect acumulado hasta ahora y devuelve el resultado, asi lo pueden encadenar varios grupos de posiciones (peleadores vivos, respawns pendientes) con su propio filtro previo.
	'''
	for pos in positions:
		# Recortar la posicion al borde de camera_area: asi sigue contando pal encuadre,
		# pero la camara se queda detenida en el limite en vez de seguirla mas lejos.
		if has_camera_bounds:
			pos = pos.clamp(camera_bounds.position, camera_bounds.end)
		var origin := Vector2(pos.x, pos.y)
		var entry_rect := Rect2(origin, Vector2.ZERO)
		if rect_started:
			rect = rect.merge(entry_rect)
		else:
			rect = entry_rect
			rect_started = true
	return {"rect": rect, "rect_started": rect_started}

func _update_target(positions: Array[Vector3]):
	'''
	Recalcular el rect que encuadra a las pos, y de ahi sacar la distancia objetivo.
	
	Tres zonas para los pos: dentro de camera_area cuenta tal cual, cuenta pero recortado al borde de camera_area (la camara ya no lo sigue mas alla). Las posiciones de quien espera respawn no se filtran contra play_area: su posicion es justo donde murio, que por definicion cae fuera del play_area.
	'''
	# Variables necesarias
	var has_camera_bounds := _camera_area_bounds.size != Vector3.ZERO
	var rect := Rect2()
	var rect_started := false

	# Solo posiciones en el area
	var filtered_positions: Array[Vector3] = []
	for pos in positions:
		if has_camera_bounds and not _camera_area_bounds.has_point(pos):
			continue
		filtered_positions.append(pos)
	
	# Obtener valores de movimiento
	var acc := _accumulate_positions(filtered_positions, has_camera_bounds, _camera_area_bounds, rect, rect_started)
	rect = acc["rect"]
	rect_started = acc["rect_started"]

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

# Aplicar movmiento
func _apply_smoothing(delta: float) -> void:
	'''
	Suavizado amortiguado exponencial, independiente del framerate.
	Alejar rapido y acercar lento es a proposito: si tarda en alejarse saca gente de pantalla,
	pero si se acerca muy rapido marea al que esta viendo.
	'''
	var pan_weight := 1.0 - exp(-pan_speed * delta)
	_position = _position.lerp(_target_position, pan_weight)

	var zoom_speed := zoom_out_speed if _target_distance > _distance else zoom_in_speed
	var zoom_weight := 1.0 - exp(-zoom_speed * delta)
	_distance = lerpf(_distance, _target_distance, zoom_weight)

func _apply_transform() -> void:
	'''
	Mandar la posicion y distancia calculadas al pivot y a la camara.
	El pivot lleva el encuadre en X/Y, la camara hija nomas la distancia en Z.
	Si alguien anda esperando su respawn, se le suma un tembloron aleatorio pa el efecto caricaturesco.
	'''
	global_position = Vector3(_position.x + _shake_offset.x, _position.y + _shake_offset.y, global_position.z)
	_camera.position = Vector3(0.0, 0.0, _distance)


# Efectos
func shake(milliseconds: int) -> void:
	_shake_end_time_msec = Time.get_ticks_msec() + int(milliseconds)

func is_shake_active() -> bool:
	return Time.get_ticks_msec() < _shake_end_time_msec

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Arrancar el estado de la cámara desde lo que ya trae la escena, pa que el primer frame no pegue un salto.

    Si camera no esta crash. Y esta bien, asi se sabe que algo en la scene esta mal construido.
	'''
	# Camera 3D
	_camera.fov = 30.0
	_camera.position = Vector3(0.0, 0.0, 29.0)
	_camera.current = true
	_camera_area_bounds = _get_area_bounds(camera_area)
	add_child(_camera)
	# Movement of camera
	_position = Vector2(global_position.x, global_position.y)
	_distance = _camera.position.z
	_target_position = _position
	_target_distance = _distance

func _init(area: Area3D = null, camera: Camera3D = null):
	if area != null:
		camera_area = area
	if camera != null:
		_camera = camera
	else:
		_camera = Camera3D.new()

# Funciones | Procesamiento de fisicas.
func _physics_process(delta: float) -> void:
	'''
	Se corre en fisicas y no en _process, pa que vaya al mismo paso que el movimiento de los peleadores.
	'''
	# Recolectar peleadores. Sus posiciones. Actualizar lo que tiene que seguir la camara.
	var power_fighters: Array[PowerFighter] = _get_power_fighters()
	var power_fighters_positions: Array[Vector3] = []
	for power_fighter in power_fighters:
		power_fighters_positions.append(power_fighter.global_position)
	if not power_fighters_positions.is_empty():
		_update_target(power_fighters_positions)

	# Cuando se piden efectos de camera.
	_shake_offset = Vector2.ZERO
	if is_shake_active():
		_shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength) )
	else:
		_shake_offset = Vector2.ZERO

	# Aplicar todote
	_apply_smoothing(delta)
	_apply_transform()
