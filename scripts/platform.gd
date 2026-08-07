@abstract
class_name Platform
extends StaticBody3D

# Clase abstracta papa de las plataformas del juego.
# Centraliza el registro en grupo y el calculo de la cara superior via collision shape.
# Las plataformas se definen con un BoxShape3D.

# Constantes del script.
const GROUP_NAME := &"platforms"

# Propiedades privadas | Forma de la plataforma.
@onready var _collision_shape: CollisionShape3D = _get_first_collision_shape()

# Funciones | Inicializar.
func _ready() -> void:
	'''
	Apuntar la plataforma al grupo comun. Es un solo grupo pa todas; de que tipo es cada una
	lo dice su clase, no el grupo. Si un hijo sobrescribe _ready() tiene que llamar super()
	o la plataforma se queda fuera del grupo y nadie la va a ver.
	'''
	add_to_group(GROUP_NAME)

# Funciones propias.
func _get_first_collision_shape() -> CollisionShape3D:
	'''
	Buscar el primer CollisionShape3D hijo directo de la plataforma.
	'''
	for child in get_children():
		if child is CollisionShape3D:
			return child
	return null

func get_top_y() -> float:
	'''
	Altura (Y global) de la cara superior de la plataforma, segun su caja.
	Ojo que esto ignora la rotacion; pa saber si algo anda encima de una plataforma inclinada,
	usa is_above_surface() en vez de esta.
	'''
	var box := _get_box()
	if box == null:
		return global_position.y
	var half_height := box.size.y * 0.5
	var scale_y := _collision_shape.global_basis.get_scale().y
	return _collision_shape.global_position.y + (half_height * scale_y)

func _get_box() -> BoxShape3D:
	'''
	El BoxShape3D de la plataforma, o null si no tiene collision shape o si le metieron otra geometria.
	Por aqui nomas se trabaja con cajas, aqui no hacemos otras cosas.
	'''
	if _collision_shape == null:
		return null
	return _collision_shape.shape as BoxShape3D

func get_surface_normal() -> Vector3:
	'''
	Normal global de la cara +Y de la plataforma. Es el "para arriba" propio de la plataforma,
	asi que si esta inclinada, la normal viene inclinada igual.
	'''
	if _collision_shape == null:
		return Vector3.UP
	return _collision_shape.global_basis.y.normalized()

func is_above_surface(global_point: Vector3, margin: float = 0.0) -> bool:
	'''
	Saber si un punto global cae del lado de afuera de la cara +Y de la plataforma.
	Se trabaja con el plano de esa cara, no con alturas Y a pelo, asi la rotacion no estorba.
	El margin es una tolerancia en unidades globales pa perdonar al que anda pegadito a la superficie.
	'''
	var box := _get_box()
	if box == null:
		return global_point.y >= global_position.y - margin
	var normal := get_surface_normal()
	var half_height := (box.size.y * 0.5) * _collision_shape.global_basis.get_scale().y
	var surface_point := _collision_shape.global_position + (normal * half_height)
	return (global_point - surface_point).dot(normal) >= -margin
