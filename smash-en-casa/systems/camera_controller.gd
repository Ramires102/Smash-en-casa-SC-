class_name CameraController
extends Camera3D

@export var player_1: Node
@export var player_2: Node
@export var player_3: Node
@export var player_4: Node

var players: Array[Node] = []

@export var min_distance: float = 11.5
@export var max_distance: float = 26.0
@export var margin: float = 4.8
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
	var active_targets: Array[Node] = _get_active_players()
	if active_targets.is_empty():
		return

	if active_targets.size() == 1:
		var p_pos := _get_player_3d_position(active_targets[0])
		global_position.x = lerpf(global_position.x, p_pos.x, minf(1.0, smooth_speed_x * delta))
		global_position.y = lerpf(global_position.y, p_pos.y + 1.8, minf(1.0, smooth_speed_y * delta))
		global_position.z = lerpf(global_position.z, min_distance, minf(1.0, smooth_speed_z * delta))
		_apply_shake(delta)
		return

	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	var avg_lead := Vector2.ZERO

	for p in active_targets:
		var pos_3d := _get_player_3d_position(p)
		min_x = minf(min_x, pos_3d.x)
		max_x = maxf(max_x, pos_3d.x)
		min_y = minf(min_y, pos_3d.y)
		max_y = maxf(max_y, pos_3d.y)

		if "velocity" in p and p.velocity is Vector2:
			avg_lead += Vector2(
				clampf(p.velocity.x * velocity_lead_factor, -1.8, 1.8),
				clampf(-p.velocity.y * velocity_lead_factor * 0.6, -1.2, 1.2)
			)

	avg_lead /= float(active_targets.size())

	var center_x: float = clampf((min_x + max_x) * 0.5 + avg_lead.x, -18.0, 18.0)
	var avg_y: float = (min_y + max_y) * 0.5 + avg_lead.y
	var target_y: float = clampf(avg_y * 0.72 + 1.6, -2.5, 12.0)

	var dist_x: float = max_x - min_x
	var dist_y: float = max_y - min_y
	var view_distance: float = maxf(dist_x * 0.82, dist_y * 1.30)
	var target_z: float = clampf(view_distance + margin, min_distance, max_distance)

	global_position.x = lerpf(global_position.x, center_x, minf(1.0, smooth_speed_x * delta))
	global_position.y = lerpf(global_position.y, target_y, minf(1.0, smooth_speed_y * delta))
	global_position.z = lerpf(global_position.z, target_z, minf(1.0, smooth_speed_z * delta))

	_apply_shake(delta)

func _apply_shake(delta: float) -> void:
	if _shake_intensity > 0.001 and shake_enabled:
		h_offset = randf_range(-_shake_intensity, _shake_intensity)
		v_offset = randf_range(-_shake_intensity, _shake_intensity)
		_shake_intensity = move_toward(_shake_intensity, 0.0, 1.35 * delta)
	else:
		_shake_intensity = 0.0
		h_offset = 0.0
		v_offset = 0.0

func _get_active_players() -> Array[Node]:
	var list: Array[Node] = []
	var pool: Array[Node] = []
	if not players.is_empty():
		pool.append_array(players)
	else:
		for p in [player_1, player_2, player_3, player_4]:
			if p != null:
				pool.append(p)

	for p in pool:
		if is_instance_valid(p) and p.is_inside_tree() and p.visible:
			if "state_machine" in p and p.state_machine and p.state_machine.current_state:
				if p.state_machine.current_state.name.to_lower() == "death":
					continue
			list.append(p)
	return list

func _get_player_3d_position(p: Node) -> Vector3:
	if p is Character:
		return Vector3(p.global_position.x / Constants.UNIT_SIZE, -p.global_position.y / Constants.UNIT_SIZE, 0.0)
	elif "global_position" in p:
		if p.global_position is Vector2:
			return Vector3(p.global_position.x / Constants.UNIT_SIZE, -p.global_position.y / Constants.UNIT_SIZE, 0.0)
		elif p.global_position is Vector3:
			return p.global_position
	return Vector3.ZERO
