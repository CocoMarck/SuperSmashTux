extends Marker3D

# Camara dinamica: encuadra a todos los peleadores, se aleja cuando se separan y se acerca cuando se juntan. 
# Usa dos cajas (camera_area y play_area) que arman tres zonas de encuadre.

# Propiedades publicas | Game Manager.
@export_group("Game Manager")
@export var game_manager: GameManager   # obligatorio: fuente de verdad del area jugable y de quien anda esperando su respawn

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

# Propiedades publicas | Temblor.
@export_group("Shake")
@export var shake_strength: float = 0.1   # que tan fuerte tiembla la camara mientras alguien espera respawn

# Propiedades privadas.
@onready var _camera: Camera3D = get_node_or_null("Camera3D")
var _position: Vector2 = Vector2.ZERO
var _distance: float = 0.0
var _target_position: Vector2 = Vector2.ZERO
var _target_distance: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Arrancar el estado de la camara desde lo que ya trae la escena, pa que el primer frame no pegue un salto.
	'''
	if game_manager == null:
		push_error("CameraFollow: falta asignar game_manager en el Inspector. La camara no va a funcionar.")
		set_physics_process(false)
		return
	if _camera == null:
		return
	_position = Vector2(global_position.x, global_position.y)
	_distance = _camera.position.z
	_target_position = _position
	_target_distance = _distance

# Funciones | Procesamiento de fisicas.
func _physics_process(delta: float) -> void:
	'''
	Se corre en fisicas y no en _process, pa que vaya al mismo paso que el movimiento de los peleadores.
	'''
	if _camera == null:
		return

	# Recolectar los peleadores cada frame: se spawnean con add_child.call_deferred en spawn_point.gd,
	# asi que a veces todavia no existen cuando la camara arranca.
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	var fighters: Array[PowerFighter] = []
	_collect_characters(scene_root, fighters)
	var fighter_positions: Array[Vector3] = []
	for fighter in fighters:
		fighter_positions.append(fighter.global_position)
	var pending_positions: Array[Vector3] = game_manager.get_pending_respawn_positions()
	if not fighter_positions.is_empty() or not pending_positions.is_empty():
		_update_target(fighter_positions, pending_positions)

	# La ventana la controla GameManager.is_shake_active(), dura respawn_delay y se dispara en
	# cualquier muerte, no solo si el personaje va a volver.
	_shake_offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength)) if game_manager.is_shake_active() else Vector2.ZERO

	_apply_smoothing(delta)
	_apply_transform()

# Funciones propias.
func _collect_characters(node: Node, out: Array[PowerFighter]) -> void:
	'''
	Juntar todos los PowerFighter del arbol. No se baja dentro de uno, porque no hay peleadores
	adentro de otro peleador.
	'''
	for child in node.get_children():
		var character := child as PowerFighter
		if character != null:
			out.append(character)
			continue
		_collect_characters(child, out)

func _distance_for_size(size: Vector2, aspect: float, half_fov_tan: float) -> float:
	'''
	Que tan lejos hay que pararse pa que un rect de este tamaño quepa en el fov de la camara.
	El ancho depende del aspecto del viewport; el alto no, porque el fov es vertical.
	'''
	var half := size * 0.5
	return maxf(half.y, half.x / aspect) / half_fov_tan

func _accumulate_positions(positions: Array[Vector3], has_camera_bounds: bool, camera_bounds: AABB, rect: Rect2, rect_started: bool) -> Dictionary:
	'''
	Recortar cada posicion contra camera_area y sumarla al rect de encuadre.
	Recibe el rect acumulado hasta ahora y devuelve el resultado, asi lo pueden encadenar
	varios grupos de posiciones (peleadores vivos, respawns pendientes) con su propio filtro previo.
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

func _update_target(fighter_positions: Array[Vector3], pending_respawn_positions: Array[Vector3] = []) -> void:
	'''
	Recalcular el rect que encuadra a los peleadores, y de ahi sacar la posicion y distancia objetivo.
	Tres zonas para los peleadores vivos: dentro de camera_area cuenta tal cual, entre camera_area y
	play_area cuenta pero recortado al borde de camera_area (la camara ya no lo sigue mas alla), y fuera
	de play_area no cuenta. Las posiciones de quien espera respawn no se filtran contra play_area: su
	posicion es justo donde murio, que por definicion cae fuera del play_area.
	'''
	var play_bounds := game_manager.get_play_area_bounds()
	var has_play_bounds := play_bounds.size != Vector3.ZERO
	var camera_bounds := _get_area_bounds(camera_area)
	var has_camera_bounds := camera_bounds.size != Vector3.ZERO

	var rect := Rect2()
	var rect_started := false

	var filtered_fighters: Array[Vector3] = []
	for pos in fighter_positions:
		if has_play_bounds and not play_bounds.has_point(pos):
			continue
		filtered_fighters.append(pos)

	var acc := _accumulate_positions(filtered_fighters, has_camera_bounds, camera_bounds, rect, rect_started)
	rect = acc["rect"]
	rect_started = acc["rect_started"]

	acc = _accumulate_positions(pending_respawn_positions, has_camera_bounds, camera_bounds, rect, rect_started)
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
		var d_full := _distance_for_size(Vector2(camera_bounds.size.x, camera_bounds.size.y), aspect, half_fov_tan)

		# Remapear: encimados dan el zoom minimo y esquinas opuestas el maximo, repartido parejo.
		var t := 0.0
		if d_full > 0.0:
			t = clampf(needed / d_full, 0.0, 1.0)
		_target_distance = lerpf(zoom_min_distance, zoom_max_distance, t)
	else:
		# Sin camera area no hay contra que normalizar, asi que se usa la distancia cruda recortada.
		_target_distance = clampf(needed, zoom_min_distance, zoom_max_distance)

	_target_position = rect.get_center()

func _get_area_bounds(area: Area3D) -> AABB:
	'''
	AABB en coordenadas del mundo de la caja de un area, sacada de su BoxShape3D.
	Si no hay area, no tiene CollisionShape3D o no es una caja, se devuelve un AABB vacio,
	que se interpreta como "sin filtro".
	'''
	if area == null:
		return AABB()

	var collision_shape: CollisionShape3D = null
	for child in area.get_children():
		collision_shape = child as CollisionShape3D
		if collision_shape != null:
			break
	if collision_shape == null:
		return AABB()

	var box := collision_shape.shape as BoxShape3D
	if box == null:
		return AABB()

	var half := box.size * 0.5 * collision_shape.global_basis.get_scale()
	var center := collision_shape.global_position
	return AABB(center - half, half * 2.0)

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
