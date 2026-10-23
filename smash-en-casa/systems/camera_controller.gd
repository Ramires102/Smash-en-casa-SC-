class_name CameraController
extends Camera3D

@export var player_1: Node
@export var player_2: Node

@export var min_distance: float = 11.5
@export var max_distance: float = 24.0
@export var margin: float = 4.2
@export var smooth_speed_x: float = 10.5
@export var smooth_speed_y: float = 7.5
@export var smooth_speed_z: float = 8.0
@export var velocity_lead_factor: float = 0.0018
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
	_shake_intensity = maxf(_shake_intensity, clampf(intensity * 0.022, 0.03, 0.28))

func _physics_process(delta: float) -> void:
	if not player_1 or not player_2:
		return

	var p1_pos := _get_player_3d_position(player_1)
	var p2_pos := _get_player_3d_position(player_2)
	var lead := _get_velocity_lead(player_1, player_2)

	var center_x: float = clampf((p1_pos.x + p2_pos.x) * 0.5 + lead.x, -16.0, 16.0)
	var avg_y: float = (p1_pos.y + p2_pos.y) * 0.5 + lead.y
	var target_y: float = clampf(avg_y * 0.72 + 1.6, -2.5, 11.5)

	var dist_x: float = absf(p1_pos.x - p2_pos.x)
	var dist_y: float = absf(p1_pos.y - p2_pos.y)
	var view_distance: float = maxf(dist_x * 0.82, dist_y * 1.30)
	var target_z: float = clampf(view_distance + margin, min_distance, max_distance)

	global_position.x = lerpf(global_position.x, center_x, minf(1.0, smooth_speed_x * delta))
	global_position.y = lerpf(global_position.y, target_y, minf(1.0, smooth_speed_y * delta))
	global_position.z = lerpf(global_position.z, target_z, minf(1.0, smooth_speed_z * delta))

	if _shake_intensity > 0.001 and shake_enabled:
		h_offset = randf_range(-_shake_intensity, _shake_intensity)
		v_offset = randf_range(-_shake_intensity, _shake_intensity)
		_shake_intensity = move_toward(_shake_intensity, 0.0, 1.35 * delta)
	else:
		_shake_intensity = 0.0
		h_offset = 0.0
		v_offset = 0.0

func _get_velocity_lead(p1: Node, p2: Node) -> Vector2:
	var v1 := Vector2.ZERO
	var v2 := Vector2.ZERO
	if "velocity" in p1 and p1.velocity is Vector2:
		v1 = p1.velocity
	if "velocity" in p2 and p2.velocity is Vector2:
		v2 = p2.velocity
	var avg_vel := (v1 + v2) * 0.5
	return Vector2(
		clampf(avg_vel.x * velocity_lead_factor, -1.8, 1.8),
		clampf(-avg_vel.y * velocity_lead_factor * 0.6, -1.2, 1.2)
	)

func _get_player_3d_position(p: Node) -> Vector3:
	if p is Character:
		return Vector3(p.global_position.x / Constants.UNIT_SIZE, -p.global_position.y / Constants.UNIT_SIZE, 0.0)
	elif "global_position" in p:
		if p.global_position is Vector2:
			return Vector3(p.global_position.x / Constants.UNIT_SIZE, -p.global_position.y / Constants.UNIT_SIZE, 0.0)
		elif p.global_position is Vector3:
			return p.global_position
	return Vector3.ZERO
