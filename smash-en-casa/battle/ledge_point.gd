# ==============================================================================
# LedgePoint — Punto de Agarre en el Borde de la Plataforma (Capa 32)
# ==============================================================================
# Define una esquina del escenario donde un jugador en caída puede colgarse
# (Ledge Grab). Solo un jugador puede ocupar el mismo borde a la vez.
# ==============================================================================
class_name LedgePoint
extends Area2D

## 1.0 = Borde izquierdo (al colgarse mira a la derecha); -1.0 = Borde derecho (mira a la izquierda).
@export var ledge_direction: float = 1.0
@export var snap_offset: Vector2 = Vector2(0.0, 18.0)
@export var getup_stand_offset: Vector2 = Vector2(28.0, -18.0)
@export var getup_roll_offset: Vector2 = Vector2(90.0, -18.0)

var current_occupant: Node = null

var occupant: Node:
	get:
		return current_occupant

func _ready() -> void:
	add_to_group("LedgePoint")
	collision_layer = 32
	collision_mask = 32

func can_occupy(character: Node) -> bool:
	return current_occupant == null or current_occupant == character

func occupy(character: Node) -> void:
	current_occupant = character

func release(character: Node) -> void:
	if current_occupant == character:
		current_occupant = null

func get_hang_position_2d() -> Vector2:
	return global_position + Vector2(absf(snap_offset.x) * (-ledge_direction), snap_offset.y)

func get_stand_position_2d() -> Vector2:
	return global_position + Vector2(absf(getup_stand_offset.x) * ledge_direction, getup_stand_offset.y)

func get_roll_position_2d() -> Vector2:
	return global_position + Vector2(absf(getup_roll_offset.x) * ledge_direction, getup_roll_offset.y)
