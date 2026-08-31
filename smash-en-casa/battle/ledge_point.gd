class_name LedgePoint
extends Area2D

## Punto de agarre de borde 2D (Ledge Grab).
## 1.0 = Borde izquierdo (mira a la derecha)
## -1.0 = Borde derecho (mira a la izquierda)
@export var ledge_direction: float = 1.0

@export var snap_offset: Vector2 = Vector2(0.0, 18.0)
@export var getup_stand_offset: Vector2 = Vector2(28.0, -18.0)
@export var getup_roll_offset: Vector2 = Vector2(90.0, -18.0)

var current_occupant: Node = null

var occupant: Node:
	get: return current_occupant

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

func get_stand_position_2d() -> Vector2:
	var offset_x: float = absf(getup_stand_offset.x) * ledge_direction
	return Vector2(global_position.x, global_position.y) + Vector2(offset_x, getup_stand_offset.y)

func get_roll_position_2d() -> Vector2:
	var offset_x: float = absf(getup_roll_offset.x) * ledge_direction
	return Vector2(global_position.x, global_position.y) + Vector2(offset_x, getup_roll_offset.y)

func get_hang_position_2d() -> Vector2:
	var offset_x: float = absf(snap_offset.x) * (-ledge_direction)
	return Vector2(global_position.x, global_position.y) + Vector2(offset_x, snap_offset.y)
