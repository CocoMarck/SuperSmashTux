class_name MarchingBorder
extends Control

'''
Borde discontinuo que gira en sentido horario alrededor de su propio rectángulo ("marching ants").
Se agrega como hijo encima de lo que decora. El trazo se centra en el borde del control, así que
el padre decide cuánto adentro cae. El avance sale del reloj global: no se reinicia al reconstruir
a su padre y todos los bordes del mismo tipo van sincronizados.
'''

# Propiedades públicas
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()
@export var width: float = 2.0
@export var dash: float = 8.0
@export var gap: float = 6.0
@export var speed: float = 40.0 # px/s.
@export var radii: Vector4 = Vector4(5, 5, 5, 5) # Esquinas: arriba-izq, arriba-der, abajo-der, abajo-izq.
@export var arc_step: float = 2.0 # Distancia aproximada entre puntos al muestrear cada guion.
var active: bool = false:
	set(value):
		active = value
		visible = value
		set_process(value)
		queue_redraw()

# Propiedades privadas
var _segments: Array[Dictionary] = []
var _segments_key: String = ""
var _total: float = 0.0

# Funciones | Callbacks
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _ready() -> void:
	set_process(active)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not active or size.x <= 0.0 or size.y <= 0.0:
		return
	_ensure_segments()
	var length: float = period()
	var count: int = pattern_count()
	var dash_length: float = length * dash / (dash + gap)
	var steps: int = maxi(1, ceili(dash_length / arc_step))
	var shift: float = current_offset()
	for k: int in count:
		var start: float = shift + float(k) * length
		var points := PackedVector2Array()
		for i: int in steps + 1:
			points.append(point_at(start + dash_length * float(i) / float(steps)))
		draw_polyline(points, color, width, true)

# Funciones
func perimeter_length() -> float:
	_ensure_segments()
	return _total

func pattern_count() -> int:
	return maxi(1, roundi(perimeter_length() / (dash + gap)))

func period() -> float:
	'''
	Largo de un guion + hueco, ajustado para que quepa un número entero de veces en el perímetro:
	así el patrón es continuo al dar la vuelta.
	'''
	return perimeter_length() / float(pattern_count())

func current_offset() -> float:
	'''
	Desfase actual del patrón, según el reloj global.
	'''
	return fposmod(float(Time.get_ticks_msec()) / 1000.0 * speed, period())

func point_at(distance: float) -> Vector2:
	'''
	Punto del perímetro a esa distancia del inicio del lado superior, en sentido horario (con vuelta).
	'''
	_ensure_segments()
	var d: float = fposmod(distance, _total)
	for segment: Dictionary in _segments:
		var length: float = segment["length"]
		if d <= length:
			if segment["arc"]:
				var angle: float = float(segment["angle"]) + (d / float(segment["radius"]) if float(segment["radius"]) > 0.0 else 0.0)
				return (segment["from"] as Vector2) + Vector2.from_angle(angle) * float(segment["radius"])
			return (segment["from"] as Vector2).lerp(segment["to"], d / length if length > 0.0 else 0.0)
		d -= length
	return _segments[0]["from"]

func _ensure_segments() -> void:
	var key: String = "%s|%s" % [size, radii]
	if key == _segments_key:
		return
	_segments_key = key
	_segments.clear()
	var max_radius: float = minf(size.x, size.y) / 2.0
	var tl: float = clampf(radii.x, 0.0, max_radius)
	var tr: float = clampf(radii.y, 0.0, max_radius)
	var br: float = clampf(radii.z, 0.0, max_radius)
	var bl: float = clampf(radii.w, 0.0, max_radius)
	var w: float = size.x
	var h: float = size.y
	_add_line(Vector2(tl, 0.0), Vector2(w - tr, 0.0))
	_add_arc(Vector2(w - tr, tr), tr, -PI / 2.0)
	_add_line(Vector2(w, tr), Vector2(w, h - br))
	_add_arc(Vector2(w - br, h - br), br, 0.0)
	_add_line(Vector2(w - br, h), Vector2(bl, h))
	_add_arc(Vector2(bl, h - bl), bl, PI / 2.0)
	_add_line(Vector2(0.0, h - bl), Vector2(0.0, tl))
	_add_arc(Vector2(tl, tl), tl, PI)
	_total = 0.0
	for segment: Dictionary in _segments:
		_total += float(segment["length"])

func _add_line(from: Vector2, to: Vector2) -> void:
	_segments.append({"arc": false, "from": from, "to": to, "length": from.distance_to(to)})

func _add_arc(center: Vector2, radius: float, start_angle: float) -> void:
	_segments.append({"arc": true, "from": center, "radius": radius, "angle": start_angle, "length": PI * radius / 2.0})
