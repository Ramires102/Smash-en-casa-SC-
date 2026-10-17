class_name CameraController
extends Camera3D

@export var player_1: Node
@export var player_2: Node

@export var min_distance: float = 12.0
@export var max_distance: float = 22.0
@export var margin: float = 4.5
@export var smooth_speed: float = 5.5
@export var shake_enabled: bool = true

var _shake_intensity: float = 0.0

func _ready() -> void:
	h_offset = 0.0
	v_offset = 0.0
	if not Events.camera_shake_requested.is_connected(_on_camera_shake_requested):
		Events.camera_shake_requested.connect(_on_camera_shake_requested)

func _exit_tree() -> void:
	if Events.camera_shake_requested.is_connected(_on_camera_shake_requested):
		Events.camera_shake_requested.disconnect(_on_camera_shake_requested)

func _on_camera_shake_requested(intensity: float) -> void:
	if not shake_enabled:
		return
	_shake_intensity = maxf(_shake_intensity, clampf(intensity * 0.015, 0.02, 0.18))

func _physics_process(delta: float) -> void:
	if not player_1 or not player_2:
		return

	var p1_pos := _get_player_3d_position(player_1)
	var p2_pos := _get_player_3d_position(player_2)
	
	# Punto medio horizontal estable entre luchadores
	var center_x: float = (p1_pos.x + p2_pos.x) * 0.5
	
	# Amortiguación vertical: evita que la cámara salte bruscamente con cada salto o flinch
	var avg_y: float = (p1_pos.y + p2_pos.y) * 0.5
	var target_y: float = clampf(avg_y * 0.5 + 1.8, 0.8, 4.5)
	
	# Distancia de encuadre suave y estable
	var dist_x: float = absf(p1_pos.x - p2_pos.x)
	var dist_y: float = absf(p1_pos.y - p2_pos.y)
	var view_distance: float = maxf(dist_x * 0.85, dist_y * 1.25)
	var target_z: float = clampf(view_distance + margin, min_distance, max_distance)
	
	var target_pos := Vector3(center_x, target_y, target_z)
	
	# Interpolación suave y cinematográfica
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	if _shake_intensity > 0.001 and shake_enabled:
		h_offset = randf_range(-_shake_intensity, _shake_intensity)
		v_offset = randf_range(-_shake_intensity, _shake_intensity)
		_shake_intensity = move_toward(_shake_intensity, 0.0, 0.95 * delta)
	else:
		_shake_intensity = 0.0
		h_offset = 0.0
		v_offset = 0.0


## Obtiene la posición física canónica (2D proyectada a 3D) para evitar vibraciones visuales
func _get_player_3d_position(p: Node) -> Vector3:
	if p is Character:
		return Vector3(p.global_position.x / Constants.UNIT_SIZE, -p.global_position.y / Constants.UNIT_SIZE, 0.0)
	elif "global_position" in p:
		if p.global_position is Vector2:
			return Vector3(p.global_position.x / Constants.UNIT_SIZE, -p.global_position.y / Constants.UNIT_SIZE, 0.0)
		elif p.global_position is Vector3:
			return p.global_position
	return Vector3.ZERO
