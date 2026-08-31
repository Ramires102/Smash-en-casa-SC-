class_name CameraController
extends Camera3D

@export var player_1: Node
@export var player_2: Node

@export var min_distance: float = 12.0
@export var max_distance: float = 24.0
@export var margin: float = 4.0
@export var smooth_speed: float = 7.0
@export var shake_enabled: bool = true
@export var shake_min_intensity: float = 8.0
@export var shake_decay_speed: float = 24.0
@export var shake_translation_scale: float = 0.012
@export var shake_intensity_scale: float = 0.06
@export var shake_max_trauma: float = 0.08
@export var shake_frequency: float = 16.0
@export var shake_vertical_ratio: float = 0.20

var _shake_trauma: float = 0.0
var _rng := RandomNumberGenerator.new()
var _shake_time: float = 0.0
var _shake_phase_x: float = 0.0
var _shake_phase_y: float = 0.0

func _ready() -> void:
	_rng.randomize()
	_shake_phase_x = _rng.randf_range(0.0, TAU)
	_shake_phase_y = _rng.randf_range(0.0, TAU)
	if not Events.camera_shake_requested.is_connected(_on_camera_shake_requested):
		Events.camera_shake_requested.connect(_on_camera_shake_requested)

func _exit_tree() -> void:
	if Events.camera_shake_requested.is_connected(_on_camera_shake_requested):
		Events.camera_shake_requested.disconnect(_on_camera_shake_requested)

func _on_camera_shake_requested(intensity: float) -> void:
	if not shake_enabled:
		return
	if intensity < shake_min_intensity:
		return
	var normalized_intensity: float = (intensity - shake_min_intensity) / maxf(1.0, 14.0 - shake_min_intensity)
	var added_trauma: float = normalized_intensity * shake_intensity_scale
	_shake_trauma = clampf(_shake_trauma + added_trauma, 0.0, shake_max_trauma)

func _physics_process(delta: float) -> void:
	if not player_1 or not player_2:
		return

	var p1_pos := _get_player_3d_position(player_1)
	var p2_pos := _get_player_3d_position(player_2)
	
	# Punto medio entre luchadores en el espacio 3D
	var center: Vector3 = (p1_pos + p2_pos) * 0.5
	center.z = 0.0
	
	var distance: float = p1_pos.distance_to(p2_pos)
	var target_z: float = clamp(distance + margin, min_distance, max_distance)
	
	var target_pos := Vector3(center.x, center.y + 2.0, target_z)
	var base_pos: Vector3 = global_position.lerp(target_pos, smooth_speed * delta)

	if _shake_trauma > 0.0:
		_shake_trauma = maxf(0.0, _shake_trauma - (shake_decay_speed * delta))
		var shake_strength: float = _shake_trauma * _shake_trauma
		_shake_time += delta * shake_frequency
		var shake_offset := Vector3(
			sin(_shake_time + _shake_phase_x) * shake_translation_scale * shake_strength,
			sin((_shake_time * 1.27) + _shake_phase_y) * shake_translation_scale * shake_vertical_ratio * shake_strength,
			0.0
		)
		global_position = base_pos + shake_offset
		return

	global_position = base_pos

func _get_player_3d_position(p: Node) -> Vector3:
	if p is Character and p.visual_root_3d:
		return p.visual_root_3d.global_position
	elif "global_position" in p:
		if p.global_position is Vector2:
			return Vector3(p.global_position.x / Constants.UNIT_SIZE, -p.global_position.y / Constants.UNIT_SIZE, 0.0)
		elif p.global_position is Vector3:
			return p.global_position
	return Vector3.ZERO
