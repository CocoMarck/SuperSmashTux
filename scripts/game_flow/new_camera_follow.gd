class_name NewCameraFollow
extends Marker3D

'''
Cámara dinámica: encuadra a todos los peleadores, se aleja cuando se separan y se acerca cuando se juntan. 

Usa dos cajas (camera_area y play_area) que arman tres zonas de encuadre.

Tiene que ser hijo del node del scene
'''

# Propiedades publicas | Area de juego.
@export_group("Areas")
@export var camera_area: Area3D    # caja interior: hasta aqui sigue la camara; mas alla se queda pegada al borde
@export var play_area: Area3D

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
@onready var _camera: Camera3D = get_node("Camera3D")
var _position: Vector2 = Vector2.ZERO
var _distance: float = 0.0
var _target_position: Vector2 = Vector2.ZERO
var _target_distance: float = 0.0
var _camera_area_bounds: AABB
var _play_area_bounds: AABB

# Propiedades privadas | Efectos | Temblor
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
	var collision_shape: CollisionShape3D
	for child in area.get_children():
		collision_shape = child as CollisionShape3D
		if collision_shape != null:
			break
	var box := collision_shape.shape as BoxShape3D
	var half := box.size * 0.5 * collision_shape.global_basis.get_scale()
	return AABB(collision_shape.global_position - half, half * 2.0)

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
	var has_play_bounds := _play_area_bounds.size != Vector3.ZERO
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

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Arrancar el estado de la cámara desde lo que ya trae la escena, pa que el primer frame no pegue un salto.

    Si camera no esta crash. Y esta bien, asi se sabe que algo en la scene esta mal construido.
	'''
	_camera_area_bounds = _get_area_bounds(camera_area)
	_play_area_bounds = _get_area_bounds(play_area)
	_position = Vector2(global_position.x, global_position.y)
	_distance = _camera.position.z
	_target_position = _position
	_target_distance = _distance

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
