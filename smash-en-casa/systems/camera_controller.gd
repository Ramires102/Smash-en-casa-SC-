class_name CameraController
extends Camera3D

@export var player_1: Node3D
@export var player_2: Node3D

@export var min_distance: float = 12.0
@export var max_distance: float = 24.0
@export var margin: float = 4.0
@export var smooth_speed: float = 5.0

func _physics_process(delta: float) -> void:
	if not player_1 or not player_2:
		return

	var p1_pos: Vector3 = player_1.global_position
	var p2_pos: Vector3 = player_2.global_position
	
	# Punto medio entre luchadores
	var center: Vector3 = (p1_pos + p2_pos) * 0.5
	center.z = 0.0 # Mantener plano 2.5D
	
	# Calcular distancia entre ambos
	var distance: float = p1_pos.distance_to(p2_pos)
	var target_z: float = clamp(distance + margin, min_distance, max_distance)
	
	var target_pos := Vector3(center.x, center.y + 2.0, target_z)
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
