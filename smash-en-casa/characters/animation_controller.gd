class_name AnimationController
extends Node

var character: Node = null
var anim_player: AnimationPlayer = null
var model_root: Node3D = null
var gogeta_root: Node3D = null
var skeleton: Skeleton3D = null
var vfx_group: Node3D = null

var is_gogeta: bool = false
var is_paused: bool = false
var current_animation_name: String = "Idle"
var active_state_name: String = "Idle"
var state_elapsed: float = 0.0
var active_attack: AttackData = null
var attack_frame: int = 0
var attack_phase: String = "none"
var is_sliding_knockdown: bool = false
var is_double_jumping: bool = false

var target_pivot_rotation_y: float = PI * 0.42
var _pose_initialized: bool = false

# Índices de huesos en Skeleton3D de Gogeta
var _bone_idx: Dictionary = {}

# Pose anatómica de 24-DOF (idéntica a FighterPose en animation_controller.ts)
var _cur_pose: Dictionary = {}
var _tgt_pose: Dictionary = {}

# Nodos 3D de VFX procedurales (idénticos a animation_controller.ts)
var _slash_arc_mesh: MeshInstance3D
var _beam_group: Node3D
var _stardust_orb_mesh: MeshInstance3D
var _charge_ring_mesh: MeshInstance3D
var _spiral_vortex_group: Node3D
var _ki_knee_cone_group: Node3D
var _somersault_vortex_group: Node3D
var _elbow_slash_beam_group: Node3D
var _kick_crescent_arc_group: Node3D
var _divekick_vfx_group: Node3D

func _ready() -> void:
	character = get_parent()
	_cur_pose = _create_default_pose()
	_tgt_pose = _create_default_pose()
	call_deferred("_initialize_controller")

func setup(data: CharacterData = null) -> void:
	if character != null and data != null:
		character.character_data = data
	_initialize_controller()

func set_paused(paused: bool) -> void:
	is_paused = paused
	if anim_player != null:
		if paused:
			anim_player.pause()
		else:
			anim_player.play()

func on_facing_direction_changed(dir: float) -> void:
	set_facing_direction(dir)

func _initialize_controller() -> void:
	if character == null:
		return
	model_root = character.get_node_or_null("Humanoid/ModelRoot") as Node3D
	if model_root == null:
		model_root = character.find_child("ModelRoot", true, false) as Node3D

	skeleton = character.find_child("Skeleton3D", true, false) as Skeleton3D
	anim_player = character.find_child("AnimationPlayer", true, false) as AnimationPlayer

	var char_name: String = ""
	if "character_data" in character and character.character_data != null:
		if "character_name" in character.character_data:
			char_name = str(character.character_data.character_name).to_lower()
		elif "display_name" in character.character_data:
			char_name = str(character.character_data.display_name).to_lower()

	if skeleton != null and (char_name.contains("gogeta") or skeleton.find_bone("Sash") != -1):
		is_gogeta = true
		gogeta_root = skeleton.get_parent() as Node3D
		_cache_gogeta_bones()
		_build_combat_vfx_nodes()
		_inject_exact_gogeta_studio_moveset()
		# Detener AnimationPlayer para que no pise el solver procedural en tiempo real
		if anim_player != null:
			anim_player.stop()
		_update_gogeta_procedural(0.016)

func _cache_gogeta_bones() -> void:
	if skeleton == null:
		return
	var names := ["Pelvis", "Spine", "Head", "ShoulderR", "ElbowR", "ShoulderL", "ElbowL", "HipR", "KneeR", "HipL", "KneeL", "Sash"]
	for b_name in names:
		_bone_idx[b_name] = skeleton.find_bone(b_name)

func _create_default_pose() -> Dictionary:
	return {
		"pelvisOffsetY": 0.0,
		"pelvisOffsetZ": 0.0,
		"pelvisPitch": 0.0,
		"pelvisYaw": 0.0,
		"pelvisRoll": 0.0,
		"spinePitch": 0.0,
		"spineYaw": 0.0,
		"spineRoll": 0.0,
		"headPitch": 0.0,
		"headYaw": 0.0,
		"headRoll": 0.0,
		"armDownR": 1.12,
		"armFwdR": 0.35,
		"armCrossR": 0.35,
		"armRollR": -0.45,
		"elbowBendR": 1.25,
		"armDownL": 1.12,
		"armFwdL": 0.35,
		"armCrossL": 0.35,
		"armRollL": -0.45,
		"elbowBendL": 1.25,
		"hipPitchR": 0.0,
		"hipSplayR": 0.0,
		"kneeBendR": 0.0,
		"hipPitchL": 0.0,
		"hipSplayL": 0.0,
		"kneeBendL": 0.0,
	}

func set_facing_direction(_dir: float, _smooth_turn: bool = false) -> void:
	if model_root != null:
		model_root.rotation = Vector3.ZERO

func play_animation(anim_name: String, _blend_time: float = 0.08, _speed_scale: float = 1.0) -> void:
	current_animation_name = anim_name
	state_elapsed = 0.0
	if anim_name in ["Idle", "Run", "Dash", "Walk", "Jump", "DoubleJump", "Fall", "Hit", "Death", "Squat"]:
		if anim_name in ["Run", "Dash", "Walk"]:
			active_state_name = "Run"
		elif anim_name == "DoubleJump":
			active_state_name = "Jump"
			is_double_jumping = true
		elif anim_name == "Jump":
			active_state_name = "Jump"
			is_double_jumping = false
		else:
			active_state_name = anim_name
		active_attack = null
		attack_phase = "none"
		_hide_all_combat_vfx()

	if not is_gogeta and anim_player != null:
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name, _blend_time, _speed_scale)

func play_attack_animation(anim_name: String, _target_duration: float = 0.0, atk_data: AttackData = null) -> void:
	current_animation_name = anim_name
	active_state_name = "Attack"
	state_elapsed = 0.0
	attack_frame = 1
	attack_phase = "startup"
	if atk_data != null:
		active_attack = atk_data
	elif character != null and "state_machine" in character and character.state_machine.current_state != null:
		if "current_attack_data" in character.state_machine.current_state:
			active_attack = character.state_machine.current_state.current_attack_data

	if not is_gogeta and anim_player != null:
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name, 0.04, 1.0)

func update_attack_frame(frame: int, phase: String, atk_data: AttackData = null) -> void:
	attack_frame = frame
	attack_phase = phase
	if atk_data != null:
		active_attack = atk_data

func _physics_process(delta: float) -> void:
	if is_paused:
		return
	if not is_gogeta or skeleton == null:
		return
	_sync_state_from_character()
	_update_gogeta_procedural(delta)

func _sync_state_from_character() -> void:
	if character == null or not ("state_machine" in character) or character.state_machine == null:
		return
	var st: Node = character.state_machine.current_state
	if st == null:
		return
	var st_name: String = st.name
	if st_name == "Attack":
		active_state_name = "Attack"
		if "current_attack_data" in st and st.current_attack_data != null:
			active_attack = st.current_attack_data
		if "frame_cursor" in st:
			attack_frame = maxi(1, st.frame_cursor)
			var s: int = active_attack.startup_frames if active_attack else 5
			var a: int = active_attack.active_frames if active_attack else 5
			if attack_frame <= s:
				attack_phase = "startup"
			elif attack_frame <= s + a:
				attack_phase = "active"
			else:
				attack_phase = "recovery"
	elif st_name in ["Run", "Dash", "Walk"]:
		active_state_name = "Run"
	elif st_name in ["Jump", "JumpSquat"]:
		active_state_name = "Jump"
		if "jumps_left" in character and "character_data" in character and character.character_data:
			is_double_jumping = character.jumps_left < character.character_data.max_jumps - 1
	elif st_name == "Fall":
		active_state_name = "Fall"
	elif st_name == "Squat":
		active_state_name = "Squat"
	elif st_name == "Hit":
		active_state_name = "Hit"
		if "_is_sliding_knockdown" in st:
			is_sliding_knockdown = st._is_sliding_knockdown
	elif st_name == "Death":
		active_state_name = "Death"
	else:
		active_state_name = "Idle"

func _update_gogeta_procedural(dt: float) -> void:
	var safe_dt: float = minf(dt, 0.05)
	state_elapsed += safe_dt

	_compute_target_pose(state_elapsed)

	var is_attacking: bool = (active_state_name == "Attack" and active_attack != null)
	var is_turn_kick: bool = is_attacking and active_attack.pose_style == "down_special_turn_kick"
	var damp_lambda: float = 19.0 if is_turn_kick else (26.0 if is_attacking else 18.0)

	if model_root != null:
		model_root.rotation = Vector3.ZERO

	# Evitar que los giros de 360°/720° se desenrollen al revés al terminar el ataque
	if absf(_tgt_pose["pelvisPitch"]) < PI and absf(_cur_pose["pelvisPitch"]) >= PI:
		_cur_pose["pelvisPitch"] = wrapf(_cur_pose["pelvisPitch"], -PI, PI)
	if absf(_tgt_pose["pelvisYaw"]) < PI and absf(_cur_pose["pelvisYaw"]) >= PI:
		_cur_pose["pelvisYaw"] = wrapf(_cur_pose["pelvisYaw"], -PI, PI)

	if not _pose_initialized or safe_dt <= 0.0:
		for k in _tgt_pose.keys():
			_cur_pose[k] = _tgt_pose[k]
		_pose_initialized = true
	else:
		for k in _tgt_pose.keys():
			_cur_pose[k] = _damp(_cur_pose[k], _tgt_pose[k], damp_lambda, safe_dt)

	_apply_gogeta_pose(_cur_pose, state_elapsed)
	_update_combat_vfx(state_elapsed)

# ============================================================================
# POSE SYNTHESIS 1:1 CON ANIMATION_CONTROLLER.TS
# ============================================================================
func _compute_target_pose(t: float) -> void:
	var p := _tgt_pose
	var breath_freq: float = 2.6 * 1.25
	var breath: float = sin(t * breath_freq)
	var breath2: float = cos(t * breath_freq * 2.0)

	# Base Martial Arts Combat Guard (Gogeta SSJ)
	p["pelvisOffsetY"] = -0.05
	p["pelvisOffsetZ"] = 0.0
	p["pelvisPitch"] = 0.08
	p["pelvisYaw"] = 0.42
	p["pelvisRoll"] = 0.0
	p["spinePitch"] = 0.14
	p["spineYaw"] = -0.18
	p["spineRoll"] = 0.0
	p["headPitch"] = 0.06
	p["headYaw"] = -0.24
	p["headRoll"] = 0.0

	p["armDownR"] = 0.88
	p["armFwdR"] = 0.78
	p["armCrossR"] = 0.34
	p["armRollR"] = -0.62
	p["elbowBendR"] = 1.48

	p["armDownL"] = 1.06
	p["armFwdL"] = 0.16
	p["armCrossL"] = 0.52
	p["armRollL"] = -0.55
	p["elbowBendL"] = 1.58

	p["hipPitchR"] = 0.36
	p["hipSplayR"] = -0.05
	p["kneeBendR"] = 0.48
	p["hipPitchL"] = -0.22
	p["hipSplayL"] = -0.05
	p["kneeBendL"] = 0.32

	if active_state_name == "Hit" or active_state_name == "Death":
		if is_sliding_knockdown:
			p["pelvisOffsetY"] = -0.52
			p["pelvisPitch"] = -1.22
			p["pelvisYaw"] = 0.22
			p["spinePitch"] = -0.18
			p["headPitch"] = -0.42
			p["headYaw"] = 0.28
			p["armDownR"] = 0.68
			p["armFwdR"] = -0.32
			p["armCrossR"] = -0.12
			p["elbowBendR"] = 0.58
			p["armDownL"] = 0.88
			p["armFwdL"] = 0.22
			p["armCrossL"] = 0.38
			p["elbowBendL"] = 1.12
			p["hipPitchR"] = 0.52
			p["kneeBendR"] = 0.68
			p["hipPitchL"] = 0.26
			p["kneeBendL"] = 0.48
			return
		var shake: float = sin(t * 42.0) * 0.06
		p["pelvisOffsetY"] = -0.04
		p["pelvisPitch"] = -0.22
		p["pelvisYaw"] = shake
		p["spinePitch"] = -0.32
		p["headPitch"] = -0.35
		p["armDownR"] = 0.65
		p["armFwdR"] = -0.35
		p["armCrossR"] = -0.15
		p["elbowBendR"] = 0.45
		p["armDownL"] = 0.65
		p["armFwdL"] = -0.35
		p["armCrossL"] = -0.15
		p["elbowBendL"] = 0.45
		p["hipPitchR"] = 0.35
		p["kneeBendR"] = 0.55
		p["hipPitchL"] = 0.22
		p["kneeBendL"] = 0.45
		return

	if active_state_name == "Squat":
		p["pelvisOffsetY"] = -0.18
		p["pelvisPitch"] = 0.22
		p["hipPitchR"] = 0.85
		p["kneeBendR"] = 1.35
		p["hipPitchL"] = 0.45
		p["kneeBendL"] = 1.15
		p["armDownR"] = 1.15
		p["armDownL"] = 1.15
		return

	if active_state_name == "Jump":
		p["pelvisOffsetY"] = 0.06
		p["pelvisYaw"] = 0.08
		p["spinePitch"] = 0.12
		p["headPitch"] = -0.12
		p["armDownR"] = 0.78
		p["armFwdR"] = 0.25
		p["armCrossR"] = 0.20
		p["elbowBendR"] = 1.15
		p["armDownL"] = 0.78
		p["armFwdL"] = 0.25
		p["armCrossL"] = 0.20
		p["elbowBendL"] = 1.15
		p["hipPitchR"] = 0.72
		p["kneeBendR"] = 0.95
		p["hipPitchL"] = 0.28
		p["kneeBendL"] = 0.45
		if is_double_jumping:
			p["pelvisPitch"] = minf(PI * 2.0, t * 13.5)
			p["hipPitchL"] = 0.75
			p["kneeBendL"] = 1.05
		return

	if active_state_name == "Fall":
		var sway: float = sin(t * 6.0) * 0.06
		p["pelvisYaw"] = 0.1
		p["spinePitch"] = 0.14
		p["headPitch"] = 0.15
		p["armDownR"] = 0.68 + sway
		p["armFwdR"] = 0.15
		p["armCrossR"] = 0.12
		p["elbowBendR"] = 0.92
		p["armDownL"] = 0.68 - sway
		p["armFwdL"] = 0.15
		p["armCrossL"] = 0.12
		p["elbowBendL"] = 0.92
		p["hipPitchR"] = 0.38
		p["kneeBendR"] = 0.62
		p["hipPitchL"] = 0.12
		p["kneeBendL"] = 0.35
		return

	if active_state_name == "Run":
		var hover_wave: float = sin(t * 7.5)
		var hover_wave2: float = cos(t * 7.5)
		p["pelvisOffsetY"] = 0.18 + hover_wave * 0.038
		p["pelvisOffsetZ"] = 0.08
		p["pelvisPitch"] = 0.42 + hover_wave * 0.03
		p["pelvisYaw"] = 0.16
		p["pelvisRoll"] = hover_wave2 * 0.03
		p["spinePitch"] = 0.22 + hover_wave * 0.025
		p["spineYaw"] = -0.10
		p["headPitch"] = -0.48 - hover_wave * 0.03
		p["headYaw"] = -0.06
		p["hipPitchR"] = 0.68 + hover_wave * 0.06
		p["hipSplayR"] = -0.08
		p["kneeBendR"] = 1.12 + hover_wave * 0.08
		p["hipPitchL"] = -0.34 - hover_wave * 0.05
		p["hipSplayL"] = -0.08
		p["kneeBendL"] = 0.36 + hover_wave2 * 0.05
		p["armDownR"] = 0.96 + hover_wave * 0.04
		p["armFwdR"] = -0.28 + hover_wave * 0.05
		p["armCrossR"] = 0.18
		p["armRollR"] = -0.35
		p["elbowBendR"] = 0.88 + hover_wave2 * 0.05
		p["armDownL"] = 0.92 - hover_wave * 0.04
		p["armFwdL"] = 0.32 + hover_wave2 * 0.05
		p["armCrossL"] = 0.38
		p["armRollL"] = -0.48
		p["elbowBendL"] = 1.32 - hover_wave * 0.05
		return

	if active_state_name == "Attack" and active_attack != null:
		_compute_attack_pose(active_attack, p)
		return

	# Idle breathing
	var bounce: float = breath * 0.024
	p["pelvisOffsetY"] += bounce
	p["spinePitch"] += breath * 0.032
	p["headPitch"] -= breath * 0.025
	var knee_flex: float = maxf(0.0, -breath) * 0.065
	p["hipPitchR"] += knee_flex * 0.65
	p["kneeBendR"] += knee_flex
	p["hipPitchL"] += knee_flex * 0.55
	p["kneeBendL"] += knee_flex * 0.85
	p["armDownR"] += breath * 0.035
	p["armFwdR"] += breath * 0.04
	p["armDownL"] += breath * 0.03
	p["elbowBendR"] += breath2 * 0.035
	p["elbowBendL"] -= breath2 * 0.035

func _compute_attack_pose(atk: AttackData, p: Dictionary) -> void:
	var f: float = float(attack_frame)
	var s: float = float(maxi(1, atk.startup_frames))
	var a: float = float(maxi(1, atk.active_frames))
	var r: float = float(maxi(1, atk.recovery_frames))

	var is_startup: bool = (attack_phase == "startup")
	var is_active: bool = (attack_phase == "active")

	var startup_t: float = _smoothstep(0.0, 1.0, minf(1.0, f / s))
	var active_t: float = _smoothstep(0.0, 1.0, minf(1.0, (f - s) / a))
	var recovery_t: float = _smoothstep(0.0, 1.0, minf(1.0, (f - s - a) / r))

	var strike: float = (-0.35 * startup_t) if is_startup else (1.0 if is_active else (1.0 - recovery_t))
	var extend: float = maxf(0.0, strike)
	var coil: float = maxf(0.0, -strike)

	var style: String = atk.pose_style
	if style == "":
		style = _infer_pose_style(atk)

	match style:
		"jab_double_strike":
			if is_startup:
				p["pelvisYaw"] = -0.25 * startup_t
				p["spineYaw"] = -0.22 * startup_t
				p["armDownL"] = 1.05
				p["armFwdL"] = 0.45 + 0.35 * startup_t
				p["elbowBendL"] = 1.35 * (1.0 - 0.3 * startup_t)
				p["armDownR"] = 1.05
				p["armFwdR"] = 0.58
				p["armCrossR"] = 0.52
				p["elbowBendR"] = 1.52
				p["hipPitchL"] = 0.35 * startup_t
				p["kneeBendL"] = 0.45 * startup_t
			elif is_active:
				var second_hit_start: int = atk.second_hit_frame if atk.second_hit_frame > 0 else int(s + ceil(a * 0.5))
				if attack_frame < second_hit_start:
					p["pelvisYaw"] = -0.38
					p["spineYaw"] = -0.34
					p["spinePitch"] = 0.16
					p["headYaw"] = 0.52
					p["pelvisOffsetZ"] = 0.06
					p["armDownL"] = 1.15
					p["armFwdL"] = 1.28
					p["armCrossL"] = 0.18
					p["armRollL"] = -0.35
					p["elbowBendL"] = 0.12
					p["armDownR"] = 1.05
					p["armFwdR"] = 0.62
					p["armCrossR"] = 0.58
					p["armRollR"] = -0.58
					p["elbowBendR"] = 1.58
					p["hipPitchL"] = 0.42
					p["kneeBendL"] = 0.52
					p["hipPitchR"] = -0.32
					p["kneeBendR"] = 0.22
				else:
					p["pelvisYaw"] = 0.58
					p["spineYaw"] = 0.52
					p["spinePitch"] = 0.24
					p["headYaw"] = -0.68
					p["pelvisOffsetZ"] = 0.12
					p["armDownR"] = 1.16
					p["armFwdR"] = 1.44
					p["armCrossR"] = 0.22
					p["armRollR"] = -0.35
					p["elbowBendR"] = 0.08
					p["armDownL"] = 0.72
					p["armFwdL"] = -0.48
					p["armCrossL"] = -0.18
					p["elbowBendL"] = 1.38
					p["hipPitchL"] = 0.46
					p["kneeBendL"] = 0.56
					p["hipPitchR"] = -0.38
					p["kneeBendR"] = 0.18
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisYaw"] = 0.58 * w + 0.42 * (1.0 - w)
				p["spineYaw"] = 0.52 * w - 0.18 * (1.0 - w)
				p["spinePitch"] = 0.24 * w + 0.14 * (1.0 - w)
				p["armDownR"] = 1.16 * w + 0.88 * (1.0 - w)
				p["armFwdR"] = 1.44 * w + 0.78 * (1.0 - w)
				p["elbowBendR"] = 0.08 * w + 1.48 * (1.0 - w)

		"jab_gut_upper":
			p["pelvisOffsetY"] = -0.06 * (coil + extend)
			p["hipPitchL"] = 0.44 * (coil + extend) + 0.15 * (1.0 - extend - coil)
			p["kneeBendL"] = 0.54 * (coil + extend) + 0.25 * (1.0 - extend - coil)
			p["hipPitchR"] = -0.34 * (coil + extend) + 0.20 * (1.0 - extend - coil)
			p["kneeBendR"] = 0.26
			p["armDownR"] = 1.12
			p["armFwdR"] = 0.28
			p["armCrossR"] = 0.42
			p["armRollR"] = -0.52
			p["elbowBendR"] = 1.48
			if is_startup:
				p["pelvisYaw"] = 0.28 * startup_t
				p["spinePitch"] = 0.18 * startup_t
				p["armDownL"] = 1.26
				p["armFwdL"] = -0.18 * startup_t
				p["armCrossL"] = 0.15
				p["elbowBendL"] = 1.32
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				var rise: float = _smoothstep(0.0, 0.7, active_t) if is_active else 1.0
				p["pelvisYaw"] = -0.28 * w + 0.42 * (1.0 - w)
				p["spineYaw"] = -0.32 * w - 0.18 * (1.0 - w)
				p["spinePitch"] = -0.08 * w + 0.14 * (1.0 - w)
				p["headYaw"] = 0.45 * w - 0.24 * (1.0 - w)
				p["armDownL"] = (1.18 - 0.36 * rise) * w + 1.06 * (1.0 - w)
				p["armFwdL"] = (0.72 + 0.50 * rise) * w + 0.16 * (1.0 - w)
				p["armCrossL"] = 0.28 * w + 0.52 * (1.0 - w)
				p["armRollL"] = -0.65 * w - 0.55 * (1.0 - w)
				p["elbowBendL"] = 1.38 * w + 1.58 * (1.0 - w)

		"jab_axe_vault":
			if is_startup:
				p["pelvisOffsetY"] = 0.14 * startup_t
				p["pelvisYaw"] = 0.08
				p["spinePitch"] = -0.28 * startup_t
				p["headPitch"] = 0.18 * startup_t
				p["armDownR"] = 0.88 - 0.58 * startup_t
				p["armDownL"] = 0.88 - 0.58 * startup_t
				p["armFwdR"] = 0.78 + 0.96 * startup_t
				p["armFwdL"] = 0.78 + 0.96 * startup_t
				p["armCrossR"] = 0.52 * startup_t
				p["armCrossL"] = 0.52 * startup_t
				p["elbowBendR"] = 1.12
				p["elbowBendL"] = 1.12
				p["hipPitchL"] = 0.88 * startup_t
				p["kneeBendL"] = 1.18 * startup_t
				p["hipPitchR"] = -0.28 * startup_t
				p["kneeBendR"] = 0.35 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = 0.18
				p["pelvisPitch"] = 0.34
				p["pelvisYaw"] = 0.0
				p["spinePitch"] = 0.52
				p["headPitch"] = 0.24
				p["armDownR"] = 1.24
				p["armDownL"] = 1.24
				p["armFwdR"] = 0.88
				p["armFwdL"] = 0.88
				p["armCrossR"] = 0.54
				p["armCrossL"] = 0.54
				p["elbowBendR"] = 0.22
				p["elbowBendL"] = 0.22
				p["hipPitchR"] = 0.82
				p["kneeBendR"] = 1.12
				p["hipSplayR"] = 0.22
				p["hipPitchL"] = 0.82
				p["kneeBendL"] = 1.12
				p["hipSplayL"] = 0.22
			else:
				var flip_t: float = _smoothstep(0.0, 0.88, recovery_t)
				var tuck: float = 1.0 - _smoothstep(0.75, 1.0, recovery_t)
				p["pelvisOffsetY"] = sin(flip_t * PI) * 0.28
				p["pelvisPitch"] = flip_t * PI * 2.0
				p["pelvisYaw"] = 0.0
				p["spinePitch"] = 0.45 * tuck
				p["headPitch"] = 0.35 * tuck
				p["armDownR"] = 1.05
				p["armDownL"] = 1.05
				p["armFwdR"] = 0.65 * tuck + 0.78 * (1.0 - tuck)
				p["armFwdL"] = 0.65 * tuck + 0.16 * (1.0 - tuck)
				p["armCrossR"] = 0.48
				p["armCrossL"] = 0.48
				p["elbowBendR"] = 1.52
				p["elbowBendL"] = 1.52
				p["hipPitchR"] = 1.15 * tuck + 0.36 * (1.0 - tuck)
				p["kneeBendR"] = 1.45 * tuck + 0.48 * (1.0 - tuck)
				p["hipPitchL"] = 1.15 * tuck - 0.22 * (1.0 - tuck)
				p["kneeBendL"] = 1.45 * tuck + 0.32 * (1.0 - tuck)

		"rekka_knee_dash":
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			p["pelvisOffsetY"] = 0.14 * w - 0.05 * (1.0 - w)
			p["pelvisOffsetZ"] = 0.15 * w
			p["pelvisPitch"] = 0.34 * w + 0.08 * (1.0 - w)
			p["pelvisYaw"] = 0.22 * w + 0.42 * (1.0 - w)
			p["spinePitch"] = 0.26 * w + 0.14 * (1.0 - w)
			p["spineYaw"] = 0.18 * w - 0.18 * (1.0 - w)
			p["headPitch"] = -0.34 * w + 0.06 * (1.0 - w)
			p["headYaw"] = -0.30 * w - 0.24 * (1.0 - w)
			p["hipPitchR"] = 1.32 * w + 0.36 * (1.0 - w)
			p["kneeBendR"] = 1.58 * w + 0.48 * (1.0 - w)
			p["hipSplayR"] = -0.04
			p["hipPitchL"] = -0.46 * w - 0.22 * (1.0 - w)
			p["kneeBendL"] = 1.18 * w + 0.32 * (1.0 - w)
			p["hipSplayL"] = -0.04
			p["armDownR"] = 0.38 * w + 0.88 * (1.0 - w)
			p["armFwdR"] = -0.65 * w + 0.78 * (1.0 - w)
			p["armCrossR"] = -0.15 * w + 0.34 * (1.0 - w)
			p["armRollR"] = -0.35
			p["elbowBendR"] = 0.62 * w + 1.48 * (1.0 - w)
			p["armDownL"] = 1.12 * w + 1.06 * (1.0 - w)
			p["armFwdL"] = 0.32 * w + 0.16 * (1.0 - w)
			p["armCrossL"] = 0.48 * w + 0.52 * (1.0 - w)
			p["elbowBendL"] = 1.48 * w + 1.58 * (1.0 - w)

		"rekka_knee_rising":
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			p["pelvisOffsetY"] = 0.20 * w - 0.05 * (1.0 - w)
			p["pelvisPitch"] = -0.24 * w + 0.08 * (1.0 - w)
			p["pelvisYaw"] = -0.26 * w + 0.42 * (1.0 - w)
			p["spinePitch"] = 0.18 * w + 0.14 * (1.0 - w)
			p["spineYaw"] = -0.18 * w - 0.18 * (1.0 - w)
			p["headPitch"] = -0.22 * w + 0.06 * (1.0 - w)
			p["headYaw"] = 0.28 * w - 0.24 * (1.0 - w)
			p["hipPitchL"] = 1.52 * w - 0.22 * (1.0 - w)
			p["kneeBendL"] = 1.56 * w + 0.32 * (1.0 - w)
			p["hipSplayL"] = -0.05
			p["hipPitchR"] = -0.38 * w + 0.36 * (1.0 - w)
			p["kneeBendR"] = 0.16 * w + 0.48 * (1.0 - w)
			p["hipSplayR"] = -0.05
			p["armDownR"] = 0.84 * w + 0.88 * (1.0 - w)
			p["armFwdR"] = -0.38 * w + 0.78 * (1.0 - w)
			p["armCrossR"] = 0.24 * w + 0.34 * (1.0 - w)
			p["elbowBendR"] = 1.32 * w + 1.48 * (1.0 - w)
			p["armDownL"] = 0.86 * w + 1.06 * (1.0 - w)
			p["armFwdL"] = -0.32 * w + 0.16 * (1.0 - w)
			p["armCrossL"] = 0.28 * w + 0.52 * (1.0 - w)
			p["elbowBendL"] = 1.35 * w + 1.58 * (1.0 - w)

		"rekka_axe_kick":
			if is_startup:
				p["pelvisOffsetY"] = 0.22 * startup_t
				p["pelvisPitch"] = -0.24 * startup_t
				p["pelvisYaw"] = 0.32 * startup_t
				p["spinePitch"] = -0.18 * startup_t
				p["headPitch"] = 0.16 * startup_t
				p["hipPitchR"] = 0.36 + 1.42 * startup_t
				p["kneeBendR"] = 0.48 * (1.0 - startup_t) + 0.05 * startup_t
				p["hipSplayR"] = 0.10 * startup_t
				p["hipPitchL"] = 0.32 * startup_t
				p["kneeBendL"] = 1.28 * startup_t
				p["armDownR"] = 0.88 - 0.52 * startup_t
				p["armFwdR"] = 0.78 + 0.62 * startup_t
				p["armCrossR"] = 0.38
				p["elbowBendR"] = 1.25
				p["armDownL"] = 1.18
				p["armFwdL"] = -0.32 * startup_t
				p["elbowBendL"] = 0.42
			elif is_active:
				var slash_p: float = _smoothstep(0.0, 0.85, active_t)
				p["pelvisOffsetY"] = 0.18 * (1.0 - slash_p * 0.5)
				p["pelvisPitch"] = -0.18 + 0.38 * slash_p
				p["pelvisYaw"] = 0.36
				p["spinePitch"] = 0.26 * slash_p
				p["spineYaw"] = 0.24
				p["headPitch"] = 0.18
				p["headYaw"] = -0.28
				p["hipPitchR"] = 1.78 - 0.96 * slash_p
				p["kneeBendR"] = 0.05
				p["hipSplayR"] = 0.08
				p["hipPitchL"] = 0.28
				p["kneeBendL"] = 1.35
				p["hipSplayL"] = 0.12
				p["armDownR"] = 0.36
				p["armFwdR"] = 1.38
				p["armCrossR"] = 0.38
				p["elbowBendR"] = 1.22
				p["armDownL"] = 1.22
				p["armFwdL"] = -0.38
				p["armCrossL"] = -0.12
				p["elbowBendL"] = 0.35
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = 0.08 * w - 0.05 * (1.0 - w)
				p["pelvisPitch"] = 0.20 * w + 0.08 * (1.0 - w)
				p["pelvisYaw"] = 0.36 * w + 0.42 * (1.0 - w)
				p["spinePitch"] = 0.26 * w + 0.14 * (1.0 - w)
				p["hipPitchR"] = 0.82 * w + 0.36 * (1.0 - w)
				p["kneeBendR"] = 0.05 * w + 0.48 * (1.0 - w)
				p["hipPitchL"] = 0.28 * w - 0.22 * (1.0 - w)
				p["kneeBendL"] = 1.35 * w + 0.32 * (1.0 - w)
				p["armDownR"] = 0.36 * w + 0.88 * (1.0 - w)
				p["armFwdR"] = 1.38 * w + 0.78 * (1.0 - w)
				p["elbowBendR"] = 1.22 * w + 1.48 * (1.0 - w)
				p["armDownL"] = 1.22 * w + 1.06 * (1.0 - w)
				p["armFwdL"] = -0.38 * w + 0.16 * (1.0 - w)
				p["elbowBendL"] = 0.35 * w + 1.58 * (1.0 - w)

		"side_roundhouse":
			p["pelvisYaw"] = -0.45 * coil + 0.65 * extend
			p["pelvisRoll"] = 0.28 * extend
			p["spinePitch"] = -0.24 * extend
			p["spineYaw"] = 0.35 * extend
			p["hipPitchR"] = -0.35 * coil + 1.35 * extend
			p["hipSplayR"] = 0.35 * extend
			p["kneeBendR"] = 0.95 * coil + 0.08 * extend
			p["hipPitchL"] = -0.15 * extend
			p["kneeBendL"] = 0.25
			p["armDownR"] = 0.85
			p["armFwdR"] = -0.25 * extend
			p["elbowBendR"] = 0.85

		"uppercut_rising":
			p["pelvisOffsetY"] = -0.12 * coil + 0.16 * extend
			p["pelvisYaw"] = -0.35 * coil + 0.48 * extend
			p["spinePitch"] = 0.25 * coil - 0.28 * extend
			p["spineYaw"] = 0.42 * extend
			p["headPitch"] = -0.32 * extend
			p["armDownR"] = 1.25 * coil + 0.35 * extend + 1.08 * (1.0 - extend - coil)
			p["armFwdR"] = -0.25 * coil + 1.75 * extend
			p["armCrossR"] = 0.22 * extend
			p["elbowBendR"] = 1.45 * coil + 0.35 * extend + 1.2 * (1.0 - extend - coil)
			p["hipPitchR"] = 0.45 * coil + 0.55 * extend
			p["kneeBendR"] = 0.65 * coil + 0.72 * extend
			p["hipPitchL"] = 0.45 * coil - 0.15 * extend
			p["kneeBendL"] = 0.65 * coil + 0.15 * extend

		"spiral_kick_low":
			if is_startup:
				p["pelvisOffsetY"] = -0.22 * startup_t
				p["pelvisPitch"] = -PI * 0.48 * startup_t
				p["pelvisYaw"] = 0.0
				p["spinePitch"] = 0.0
				p["spineYaw"] = 0.0
				p["headPitch"] = 0.0
				p["headYaw"] = 0.0
				p["armDownR"] = 0.88 - 2.23 * startup_t
				p["armDownL"] = 1.06 - 2.41 * startup_t
				p["armFwdR"] = 0.78 * (1.0 - startup_t)
				p["armFwdL"] = 0.16 * (1.0 - startup_t)
				p["armCrossR"] = 0.34 * (1.0 - startup_t) + 0.08 * startup_t
				p["armCrossL"] = 0.52 * (1.0 - startup_t) + 0.08 * startup_t
				p["armRollR"] = -0.62 * (1.0 - startup_t)
				p["armRollL"] = -0.55 * (1.0 - startup_t)
				p["elbowBendR"] = 1.48 * (1.0 - startup_t) + 0.08 * startup_t
				p["elbowBendL"] = 1.58 * (1.0 - startup_t) + 0.08 * startup_t
				p["hipPitchR"] = 0.36 * (1.0 - startup_t)
				p["kneeBendR"] = 0.48 * (1.0 - startup_t)
				p["hipSplayR"] = -0.22 * startup_t
				p["hipPitchL"] = -0.22 * (1.0 - startup_t)
				p["kneeBendL"] = 0.32 * (1.0 - startup_t)
				p["hipSplayL"] = -0.22 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = -0.26
				p["pelvisOffsetZ"] = 0.18
				p["pelvisPitch"] = -PI * 0.48
				p["pelvisYaw"] = active_t * PI * 4.0
				p["pelvisRoll"] = 0.0
				p["spinePitch"] = 0.0
				p["spineYaw"] = 0.0
				p["spineRoll"] = 0.0
				p["headPitch"] = 0.0
				p["headYaw"] = 0.0
				p["armDownR"] = -1.35
				p["armDownL"] = -1.35
				p["armFwdR"] = 0.0
				p["armFwdL"] = 0.0
				p["armCrossR"] = 0.08
				p["armCrossL"] = 0.08
				p["armRollR"] = 0.0
				p["armRollL"] = 0.0
				p["elbowBendR"] = 0.08
				p["elbowBendL"] = 0.08
				p["hipPitchR"] = 0.0
				p["kneeBendR"] = 0.0
				p["hipSplayR"] = -0.22
				p["hipPitchL"] = 0.0
				p["kneeBendL"] = 0.0
				p["hipSplayL"] = -0.22
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = -0.26 * w - 0.05 * (1.0 - w)
				p["pelvisPitch"] = -PI * 0.48 * w + 0.08 * (1.0 - w)
				p["pelvisYaw"] = 0.42 * (1.0 - w)
				p["spinePitch"] = 0.14 * (1.0 - w)
				p["spineYaw"] = -0.18 * (1.0 - w)
				p["headYaw"] = -0.24 * (1.0 - w)
				p["armDownR"] = -1.35 * w + 0.88 * (1.0 - w)
				p["armDownL"] = -1.35 * w + 1.06 * (1.0 - w)
				p["armFwdR"] = 0.78 * (1.0 - w)
				p["armFwdL"] = 0.16 * (1.0 - w)
				p["armCrossR"] = 0.08 * w + 0.34 * (1.0 - w)
				p["armCrossL"] = 0.08 * w + 0.52 * (1.0 - w)
				p["elbowBendR"] = 0.08 * w + 1.48 * (1.0 - w)
				p["elbowBendL"] = 0.08 * w + 1.58 * (1.0 - w)
				p["hipPitchR"] = 0.36 * (1.0 - w)
				p["kneeBendR"] = 0.48 * (1.0 - w)
				p["hipSplayR"] = -0.22 * w - 0.05 * (1.0 - w)
				p["hipPitchL"] = -0.22 * (1.0 - w)
				p["kneeBendL"] = 0.32 * (1.0 - w)
				p["hipSplayL"] = -0.22 * w - 0.05 * (1.0 - w)

		"nair_spin":
			var spin_angle: float = (-0.3 * startup_t) if is_startup else ((active_t * PI * 2.0) if is_active else ((1.0 - recovery_t) * 0.4))
			p["pelvisYaw"] = spin_angle
			p["armDownR"] = 0.55
			p["armDownL"] = 0.55
			p["elbowBendR"] = 0.45
			p["elbowBendL"] = 0.45
			p["hipPitchR"] = 0.68 * extend
			p["kneeBendR"] = 0.18
			p["hipPitchL"] = -0.25 * extend
			p["kneeBendL"] = 0.65

		"fair_downward_punch":
			if is_startup:
				p["pelvisPitch"] = -0.15 * startup_t
				p["pelvisYaw"] = -0.38 * startup_t
				p["spinePitch"] = -0.22 * startup_t
				p["spineYaw"] = -0.28 * startup_t
				p["headPitch"] = 0.22 * startup_t
				p["headYaw"] = 0.18 * startup_t
				p["armDownR"] = 0.55 + 0.15 * startup_t
				p["armFwdR"] = -0.55 * startup_t
				p["armCrossR"] = -0.12 * startup_t
				p["armRollR"] = -0.45
				p["elbowBendR"] = 1.62 * startup_t + 0.45 * (1.0 - startup_t)
				p["armDownL"] = 0.85
				p["armFwdL"] = 0.65 * startup_t
				p["armCrossL"] = 0.18 * startup_t
				p["elbowBendL"] = 0.72
				p["hipPitchR"] = 0.35 * startup_t
				p["kneeBendR"] = 0.75 * startup_t
				p["hipPitchL"] = -0.25 * startup_t
				p["kneeBendL"] = 0.45 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = 0.04
				p["pelvisPitch"] = 0.38
				p["pelvisYaw"] = 0.42
				p["pelvisRoll"] = -0.06
				p["spinePitch"] = 0.46
				p["spineYaw"] = 0.35
				p["headPitch"] = 0.38
				p["headYaw"] = -0.15
				p["armDownR"] = 1.05
				p["armFwdR"] = 1.25
				p["armCrossR"] = 0.18
				p["armRollR"] = -0.38
				p["elbowBendR"] = 0.06
				p["armDownL"] = 1.15
				p["armFwdL"] = -0.32
				p["armCrossL"] = 0.22
				p["elbowBendL"] = 1.45
				p["hipPitchR"] = 0.48
				p["kneeBendR"] = 0.65
				p["hipPitchL"] = -0.42
				p["kneeBendL"] = 0.38
			else:
				var rt: float = recovery_t
				p["pelvisPitch"] = 0.38 * (1.0 - rt)
				p["pelvisYaw"] = 0.42 * (1.0 - rt)
				p["spinePitch"] = 0.46 * (1.0 - rt)
				p["headPitch"] = 0.38 * (1.0 - rt)
				p["armDownR"] = 1.05 * (1.0 - rt) + 0.85 * rt
				p["armFwdR"] = 1.25 * (1.0 - rt) + 0.35 * rt
				p["elbowBendR"] = 0.06 * (1.0 - rt) + 1.15 * rt
				p["armDownL"] = 1.15 * (1.0 - rt) + 0.85 * rt
				p["armFwdL"] = -0.32 * (1.0 - rt) + 0.35 * rt
				p["elbowBendL"] = 1.45 * (1.0 - rt) + 1.15 * rt
				p["hipPitchR"] = 0.48 * (1.0 - rt)
				p["kneeBendR"] = 0.65 * (1.0 - rt)
				p["hipPitchL"] = -0.42 * (1.0 - rt)
				p["kneeBendL"] = 0.38 * (1.0 - rt)

		"divekick_down_air":
			if is_startup:
				p["pelvisOffsetY"] = 0.08 * startup_t
				p["pelvisPitch"] = 0.28 * startup_t
				p["spinePitch"] = 0.22 * startup_t
				p["headPitch"] = 0.18 * startup_t
				p["hipPitchR"] = -0.12 * startup_t
				p["kneeBendR"] = 0.58 * startup_t
				p["hipPitchL"] = 0.95 * startup_t
				p["kneeBendL"] = 1.25 * startup_t
				p["armDownR"] = 0.85 - 1.35 * startup_t
				p["armFwdR"] = 0.45 * startup_t
				p["armCrossR"] = 0.18
				p["elbowBendR"] = 1.38
				p["armDownL"] = 1.12
				p["armFwdL"] = 0.25
				p["armCrossL"] = 0.58
				p["elbowBendL"] = 1.48
			elif is_active:
				p["pelvisOffsetY"] = 0.14
				p["pelvisPitch"] = 0.62
				p["pelvisYaw"] = 0.18
				p["pelvisRoll"] = 0.04
				p["spinePitch"] = 0.38
				p["spineYaw"] = 0.12
				p["headPitch"] = 0.36
				p["headYaw"] = -0.16
				p["hipPitchR"] = 0.92
				p["kneeBendR"] = 0.03
				p["hipSplayR"] = 0.04
				p["hipPitchL"] = 1.52
				p["kneeBendL"] = 1.64
				p["hipSplayL"] = -0.06
				p["armDownR"] = -0.58
				p["armFwdR"] = 0.72
				p["armCrossR"] = 0.24
				p["armRollR"] = -0.42
				p["elbowBendR"] = 1.48
				p["armDownL"] = 1.14
				p["armFwdL"] = 0.34
				p["armCrossL"] = 0.68
				p["armRollL"] = -0.32
				p["elbowBendL"] = 1.55
			else:
				p["pelvisOffsetY"] = -0.32 * (1.0 - recovery_t)
				p["pelvisPitch"] = 0.42 * (1.0 - recovery_t)
				p["spinePitch"] = 0.36 * (1.0 - recovery_t)
				p["headPitch"] = 0.22 * (1.0 - recovery_t)
				p["hipPitchR"] = 1.15 * (1.0 - recovery_t)
				p["kneeBendR"] = 1.35 * (1.0 - recovery_t)
				p["hipPitchL"] = 0.92 * (1.0 - recovery_t)
				p["kneeBendL"] = 1.25 * (1.0 - recovery_t)
				p["armDownR"] = 0.88
				p["armFwdR"] = 0.35
				p["elbowBendR"] = 1.20
				p["armDownL"] = 0.96
				p["armFwdL"] = 0.32
				p["elbowBendL"] = 1.30

		"bair_backkick":
			p["pelvisYaw"] = 0.35 * coil - 0.85 * extend
			p["spinePitch"] = 0.28 * extend
			p["headYaw"] = -0.65 * extend
			p["hipPitchL"] = 0.45 * coil - 1.05 * extend
			p["kneeBendL"] = 0.85 * coil + 0.08 * extend
			p["hipPitchR"] = 0.35 * extend
			p["kneeBendR"] = 0.55 * extend
			p["armDownR"] = 0.78
			p["armFwdR"] = 0.55 * extend
			p["armDownL"] = 0.78
			p["armFwdL"] = -0.45 * extend

		"uair_flipkick":
			p["pelvisPitch"] = 0.25 * coil - 0.65 * extend
			p["spinePitch"] = -0.25 * extend
			p["hipPitchR"] = -0.35 * coil + 1.55 * extend
			p["kneeBendR"] = 0.85 * coil + 0.10 * extend
			p["hipPitchL"] = -0.35 * extend
			p["kneeBendL"] = 0.75 * extend
			p["armDownR"] = 0.65
			p["armDownL"] = 0.65

		"beam_charge_thrust":
			if is_startup:
				p["pelvisYaw"] = -0.48 * startup_t
				p["spineYaw"] = -0.35 * startup_t
				p["spinePitch"] = 0.14 * startup_t
				p["pelvisOffsetY"] = -0.06 * startup_t
				p["armDownR"] = 1.15
				p["armFwdR"] = -0.28 * startup_t
				p["armCrossR"] = -0.25 * startup_t
				p["elbowBendR"] = 1.25
				p["armDownL"] = 1.10
				p["armFwdL"] = 0.25 * startup_t
				p["armCrossL"] = 0.75 * startup_t
				p["elbowBendL"] = 1.35
				p["hipPitchR"] = -0.18 * startup_t
				p["kneeBendR"] = 0.35 * startup_t
				p["hipPitchL"] = 0.28 * startup_t
				p["kneeBendL"] = 0.42 * startup_t
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisYaw"] = 0.12 * w
				p["spineYaw"] = 0.08 * w
				p["spinePitch"] = 0.24 * w
				p["pelvisOffsetZ"] = 0.10 * w
				p["armDownR"] = 1.12
				p["armFwdR"] = 1.38 * w + 0.35 * (1.0 - w)
				p["armCrossR"] = 0.42 * w + 0.35 * (1.0 - w)
				p["elbowBendR"] = 0.14 * w + 1.25 * (1.0 - w)
				p["armDownL"] = 1.12
				p["armFwdL"] = 1.38 * w + 0.35 * (1.0 - w)
				p["armCrossL"] = 0.42 * w + 0.35 * (1.0 - w)
				p["elbowBendL"] = 0.14 * w + 1.25 * (1.0 - w)
				p["hipPitchR"] = 0.35 * w
				p["kneeBendR"] = 0.48 * w
				p["hipPitchL"] = -0.28 * w
				p["kneeBendL"] = 0.18 * w

		"up_somersault_vortex":
			if is_startup:
				p["pelvisOffsetY"] = -0.14 * startup_t
				p["pelvisPitch"] = 0.28 * startup_t
				p["pelvisYaw"] = 0.15 * (1.0 - startup_t)
				p["spinePitch"] = 0.36 * startup_t
				p["headPitch"] = 0.22 * startup_t
				p["hipPitchR"] = 0.36 + 1.12 * startup_t
				p["kneeBendR"] = 0.48 + 1.18 * startup_t
				p["hipSplayR"] = -0.15 * startup_t
				p["hipPitchL"] = -0.22 + 1.70 * startup_t
				p["kneeBendL"] = 0.32 + 1.34 * startup_t
				p["hipSplayL"] = -0.15 * startup_t
				p["armDownR"] = 1.08
				p["armFwdR"] = 0.52 * startup_t
				p["armCrossR"] = 0.22
				p["elbowBendR"] = 1.48
				p["armDownL"] = 1.08
				p["armFwdL"] = 0.52 * startup_t
				p["armCrossL"] = 0.22
				p["elbowBendL"] = 1.48
			elif is_active:
				p["pelvisOffsetY"] = 0.16
				p["pelvisPitch"] = active_t * PI * 2.0
				p["pelvisYaw"] = 0.08
				p["pelvisRoll"] = 0.0
				p["spinePitch"] = 0.54
				p["spineYaw"] = 0.0
				p["headPitch"] = 0.26
				p["headYaw"] = -0.08
				p["hipPitchR"] = 1.54
				p["kneeBendR"] = 1.66
				p["hipSplayR"] = -0.18
				p["hipPitchL"] = 1.54
				p["kneeBendL"] = 1.66
				p["hipSplayL"] = -0.18
				p["armDownR"] = 1.08
				p["armFwdR"] = 0.52
				p["armCrossR"] = 0.22
				p["armRollR"] = -0.48
				p["elbowBendR"] = 1.48
				p["armDownL"] = 1.08
				p["armFwdL"] = 0.52
				p["armCrossL"] = 0.22
				p["armRollL"] = -0.48
				p["elbowBendL"] = 1.48
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = 0.16 * w - 0.05 * (1.0 - w)
				p["pelvisPitch"] = 0.12 * w + 0.08 * (1.0 - w)
				p["pelvisYaw"] = 0.42 * (1.0 - w)
				p["spinePitch"] = 0.54 * w + 0.14 * (1.0 - w)
				p["headPitch"] = 0.26 * w + 0.06 * (1.0 - w)
				p["hipPitchR"] = 1.54 * w + 0.36 * (1.0 - w)
				p["kneeBendR"] = 1.66 * w + 0.48 * (1.0 - w)
				p["hipSplayR"] = -0.18 * w - 0.05 * (1.0 - w)
				p["hipPitchL"] = 1.54 * w - 0.22 * (1.0 - w)
				p["kneeBendL"] = 1.66 * w + 0.32 * (1.0 - w)
				p["hipSplayL"] = -0.18 * w - 0.05 * (1.0 - w)
				p["armDownR"] = 1.08 * w + 0.88 * (1.0 - w)
				p["armFwdR"] = 0.52 * w + 0.78 * (1.0 - w)
				p["elbowBendR"] = 1.48

		"up_special_followup_punch":
			if is_startup:
				p["pelvisOffsetY"] = 0.14
				p["pelvisYaw"] = -0.54 * startup_t
				p["spineYaw"] = -0.46 * startup_t
				p["spinePitch"] = -0.12 * startup_t
				p["headYaw"] = 0.52 * startup_t
				p["armDownR"] = 1.04
				p["armFwdR"] = -0.58 * startup_t
				p["armCrossR"] = -0.22 * startup_t
				p["elbowBendR"] = 1.52
				p["armDownL"] = 1.02
				p["armFwdL"] = 1.15 * startup_t
				p["armCrossL"] = 0.25
				p["elbowBendL"] = 0.35
				p["hipPitchL"] = 0.72 * startup_t
				p["kneeBendL"] = 1.12 * startup_t
				p["hipPitchR"] = -0.35 * startup_t
				p["kneeBendR"] = 0.45
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisOffsetY"] = 0.14 * w - 0.05 * (1.0 - w)
				p["pelvisOffsetZ"] = 0.16 * w
				p["pelvisYaw"] = 0.64 * w + 0.42 * (1.0 - w)
				p["spineYaw"] = 0.58 * w - 0.18 * (1.0 - w)
				p["spinePitch"] = 0.28 * w + 0.14 * (1.0 - w)
				p["headYaw"] = -0.72 * w - 0.24 * (1.0 - w)
				p["armDownR"] = 1.12 * w + 0.88 * (1.0 - w)
				p["armFwdR"] = 1.48 * w + 0.78 * (1.0 - w)
				p["armCrossR"] = 0.24 * w + 0.34 * (1.0 - w)
				p["armRollR"] = -0.35
				p["elbowBendR"] = 0.06 * w + 1.48 * (1.0 - w)
				p["armDownL"] = 0.78 * w + 1.06 * (1.0 - w)
				p["armFwdL"] = -0.52 * w + 0.16 * (1.0 - w)
				p["armCrossL"] = -0.18 * w + 0.52 * (1.0 - w)
				p["elbowBendL"] = 1.42 * w + 1.58 * (1.0 - w)
				p["hipPitchL"] = 0.76 * w - 0.22 * (1.0 - w)
				p["kneeBendL"] = 1.15 * w + 0.32 * (1.0 - w)
				p["hipPitchR"] = -0.44 * w + 0.36 * (1.0 - w)
				p["kneeBendR"] = 0.24 * w + 0.48 * (1.0 - w)

		"down_special_elbow_lift":
			if is_startup:
				p["pelvisOffsetY"] = -0.18 * startup_t
				p["pelvisOffsetZ"] = 0.12 * startup_t
				p["pelvisYaw"] = 0.42 + 0.44 * startup_t
				p["spineYaw"] = -0.18 + 0.56 * startup_t
				p["spinePitch"] = 0.14 + 0.12 * startup_t
				p["headYaw"] = -0.24 - 0.38 * startup_t
				p["hipPitchR"] = 0.36 + 0.36 * startup_t
				p["kneeBendR"] = 0.48 + 0.48 * startup_t
				p["hipPitchL"] = -0.22 - 0.36 * startup_t
				p["kneeBendL"] = 0.24
				p["armDownR"] = 0.88 - 0.44 * startup_t
				p["armFwdR"] = 0.78 + 0.64 * startup_t
				p["armCrossR"] = 0.34 + 0.06 * startup_t
				p["elbowBendR"] = 1.48 + 0.22 * startup_t
				p["armDownL"] = 1.05
				p["armFwdL"] = 0.16 - 0.62 * startup_t
				p["armCrossL"] = 0.52 - 0.74 * startup_t
				p["elbowBendL"] = 1.48
			elif is_active:
				var lift_t: float = _smoothstep(0.58, 1.0, active_t)
				p["pelvisOffsetY"] = -0.18 + 0.08 * lift_t
				p["pelvisOffsetZ"] = 0.18 - 0.06 * lift_t
				p["pelvisYaw"] = 0.86 - 0.24 * lift_t
				p["spineYaw"] = 0.38 - 0.16 * lift_t
				p["spinePitch"] = 0.26 - 0.12 * lift_t
				p["spineRoll"] = 0.14 * (1.0 - lift_t)
				p["headYaw"] = -0.62 + 0.22 * lift_t
				p["headPitch"] = -0.14
				p["hipPitchR"] = 0.72 - 0.14 * lift_t
				p["kneeBendR"] = 0.96 - 0.12 * lift_t
				p["hipSplayR"] = -0.12
				p["hipPitchL"] = -0.58 + 0.25 * lift_t
				p["kneeBendL"] = 0.22 + 0.28 * lift_t
				p["hipSplayL"] = -0.12
				p["armDownR"] = 0.44 - 0.14 * lift_t
				p["armFwdR"] = 1.42 + 0.12 * lift_t
				p["armCrossR"] = 0.40 - 0.18 * lift_t
				p["armRollR"] = 0.32
				p["elbowBendR"] = 1.70 - 0.15 * lift_t
				p["armDownL"] = 1.05
				p["armFwdL"] = -0.46 + 0.22 * lift_t
				p["armCrossL"] = -0.22 + 0.18 * lift_t
				p["elbowBendL"] = 1.48
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = -0.10 * w - 0.05 * (1.0 - w)
				p["pelvisYaw"] = 0.62 * w + 0.42 * (1.0 - w)
				p["spineYaw"] = 0.22 * w - 0.18 * (1.0 - w)
				p["spinePitch"] = 0.14
				p["armDownR"] = 0.30 * w + 0.88 * (1.0 - w)
				p["armFwdR"] = 1.54 * w + 0.78 * (1.0 - w)
				p["elbowBendR"] = 1.55 * w + 1.48 * (1.0 - w)

		"down_special_turn_kick":
			if is_startup:
				var turn_ease: float = _smoothstep(0.0, 1.0, startup_t)
				var knee_chamber: float = sin(startup_t * PI * 0.75)
				p["pelvisOffsetY"] = -0.08 * (1.0 - turn_ease) - 0.06 * turn_ease
				p["pelvisOffsetZ"] = 0.12 * turn_ease
				p["pelvisPitch"] = -0.38 * turn_ease
				p["pelvisYaw"] = 0.76 * turn_ease
				p["pelvisRoll"] = -0.52 * turn_ease
				p["spinePitch"] = -0.28 * turn_ease
				p["spineYaw"] = 0.36 * turn_ease
				p["spineRoll"] = -0.38 * turn_ease
				p["headPitch"] = 0.22 * turn_ease
				p["headYaw"] = -0.48 * turn_ease
				p["hipPitchL"] = 1.38 * turn_ease
				p["kneeBendL"] = 1.15 * knee_chamber * (1.0 - 0.65 * turn_ease) + 0.12 * turn_ease
				p["hipSplayL"] = 0.38 * turn_ease
				p["hipPitchR"] = 0.58
				p["kneeBendR"] = 0.84 + 0.42 * turn_ease
				p["hipSplayR"] = -0.20 * turn_ease
				p["armDownR"] = 0.32 * (1.0 - turn_ease) + 0.72 * turn_ease
				p["armFwdR"] = 1.35 * (1.0 - turn_ease) - 0.28 * turn_ease
				p["armCrossR"] = 0.22 * (1.0 - turn_ease) - 0.52 * turn_ease
				p["elbowBendR"] = 1.55 * (1.0 - turn_ease) + 0.22 * turn_ease
				p["armDownL"] = 1.02 * (1.0 - turn_ease) + 0.82 * turn_ease
				p["armFwdL"] = -0.24 * (1.0 - turn_ease) + 0.95 * turn_ease
				p["armCrossL"] = 0.38 * turn_ease
				p["elbowBendL"] = 1.45 * (1.0 - turn_ease) + 1.18 * turn_ease
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisOffsetY"] = -0.06 * w - 0.05 * (1.0 - w)
				p["pelvisOffsetZ"] = 0.14 * w
				p["pelvisPitch"] = -0.38 * w + 0.08 * (1.0 - w)
				p["pelvisYaw"] = 0.76 * w + 0.42 * (1.0 - w)
				p["pelvisRoll"] = -0.52 * w
				p["spinePitch"] = -0.28 * w + 0.14 * (1.0 - w)
				p["spineYaw"] = 0.36 * w - 0.18 * (1.0 - w)
				p["spineRoll"] = -0.38 * w
				p["headPitch"] = 0.22 * w + 0.06 * (1.0 - w)
				p["headYaw"] = -0.48 * w - 0.24 * (1.0 - w)
				p["hipPitchL"] = 1.52 * w - 0.22 * (1.0 - w)
				p["kneeBendL"] = 0.06 * w + 0.32 * (1.0 - w)
				p["hipSplayL"] = 0.42 * w - 0.05 * (1.0 - w)
				p["hipPitchR"] = 0.58 * w + 0.36 * (1.0 - w)
				p["kneeBendR"] = 1.26 * w + 0.48 * (1.0 - w)
				p["hipSplayR"] = -0.22 * w - 0.05 * (1.0 - w)
				p["armDownR"] = 0.72 * w + 0.88 * (1.0 - w)
				p["armFwdR"] = -0.28 * w + 0.78 * (1.0 - w)
				p["armCrossR"] = -0.52 * w + 0.34 * (1.0 - w)
				p["elbowBendR"] = 0.22 * w + 1.48 * (1.0 - w)
				p["armDownL"] = 0.82 * w + 1.06 * (1.0 - w)
				p["armFwdL"] = 0.95 * w + 0.16 * (1.0 - w)
				p["armCrossL"] = 0.38 * w + 0.52 * (1.0 - w)
				p["elbowBendL"] = 1.18 * w + 1.58 * (1.0 - w)

# ============================================================================
# APLICACIÓN DE POSE AL SKELETON3D (12 HUESOS)
# ============================================================================
func _apply_gogeta_pose(p: Dictionary, t: float) -> void:
	if skeleton == null:
		return

	# 0. Pelvis (posición + rotación XYZ)
	var b_pelvis: int = _bone_idx.get("Pelvis", -1)
	if b_pelvis != -1:
		skeleton.set_bone_pose_position(b_pelvis, Vector3(0.0, 0.90 + float(p["pelvisOffsetY"]), float(p["pelvisOffsetZ"])))
		skeleton.set_bone_pose_rotation(b_pelvis, _quat_euler_xyz(p["pelvisPitch"], p["pelvisYaw"], p["pelvisRoll"]))

	# 1. Spine (YXZ)
	var b_spine: int = _bone_idx.get("Spine", -1)
	if b_spine != -1:
		skeleton.set_bone_pose_rotation(b_spine, _quat_euler_yxz(p["spinePitch"], p["spineYaw"], p["spineRoll"]))

	# 2. Head (YXZ)
	var b_head: int = _bone_idx.get("Head", -1)
	if b_head != -1:
		skeleton.set_bone_pose_rotation(b_head, _quat_euler_yxz(p["headPitch"], p["headYaw"], p["headRoll"]))

	# 3 & 4. ShoulderR & ElbowR (-X side)
	var b_sh_r: int = _bone_idx.get("ShoulderR", -1)
	if b_sh_r != -1:
		skeleton.set_bone_pose_rotation(b_sh_r, _build_shoulder_char_quat(-1.0, p["armDownR"], p["armFwdR"], p["armCrossR"], p["armRollR"]))
	var b_el_r: int = _bone_idx.get("ElbowR", -1)
	if b_el_r != -1:
		skeleton.set_bone_pose_rotation(b_el_r, Quaternion(Vector3.UP, float(p["elbowBendR"])))

	# 5 & 6. ShoulderL & ElbowL (+X side)
	var b_sh_l: int = _bone_idx.get("ShoulderL", -1)
	if b_sh_l != -1:
		skeleton.set_bone_pose_rotation(b_sh_l, _build_shoulder_char_quat(1.0, p["armDownL"], p["armFwdL"], p["armCrossL"], p["armRollL"]))
	var b_el_l: int = _bone_idx.get("ElbowL", -1)
	if b_el_l != -1:
		skeleton.set_bone_pose_rotation(b_el_l, Quaternion(Vector3.UP, -float(p["elbowBendL"])))

	# 7 & 8. HipR & KneeR (-X side)
	var b_hip_r: int = _bone_idx.get("HipR", -1)
	if b_hip_r != -1:
		skeleton.set_bone_pose_rotation(b_hip_r, _quat_euler_xyz(-float(p["hipPitchR"]), 0.0, -float(p["hipSplayR"])))
	var b_knee_r: int = _bone_idx.get("KneeR", -1)
	if b_knee_r != -1:
		skeleton.set_bone_pose_rotation(b_knee_r, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendR"]))))

	# 9 & 10. HipL & KneeL (+X side)
	var b_hip_l: int = _bone_idx.get("HipL", -1)
	if b_hip_l != -1:
		skeleton.set_bone_pose_rotation(b_hip_l, _quat_euler_xyz(-float(p["hipPitchL"]), 0.0, float(p["hipSplayL"])))
	var b_knee_l: int = _bone_idx.get("KneeL", -1)
	if b_knee_l != -1:
		skeleton.set_bone_pose_rotation(b_knee_l, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendL"]))))

	# 11. Sash (cinta de la cintura)
	var b_sash: int = _bone_idx.get("Sash", -1)
	if b_sash != -1:
		var is_hover_dash: bool = (active_state_name == "Run")
		var sash_wave_z: float = (sin(t * 11.5) * 0.14 + 0.12) if is_hover_dash else (sin(t * 5.2) * 0.08 + 0.06)
		var sash_pitch: float = (0.42 + cos(t * 11.0) * 0.10) if is_hover_dash else (-float(p["hipPitchR"]) * 0.55 + cos(t * 4.5) * 0.06)
		skeleton.set_bone_pose_rotation(b_sash, _quat_euler_xyz(sash_pitch, 0.0, -sash_wave_z))

# ============================================================================
# 11 VFX 3D DE COMBATE (IDÉNTICOS A ANIMATION_CONTROLLER.TS)
# ============================================================================
func _build_combat_vfx_nodes() -> void:
	if vfx_group != null:
		return
	var parent_3d: Node3D = gogeta_root if gogeta_root != null else model_root
	if parent_3d == null:
		return
	vfx_group = Node3D.new()
	vfx_group.name = "CombatVfxGroup"
	parent_3d.add_child(vfx_group)

	_slash_arc_mesh = _create_torus_mesh(0.68, 0.08, Color(0.98, 0.75, 0.14, 0.88))
	_charge_ring_mesh = _create_torus_mesh(0.45, 0.025, Color(0.98, 0.75, 0.14, 0.75))
	_stardust_orb_mesh = _create_sphere_mesh(0.65, Color(0.98, 0.75, 0.14, 0.8))
	_beam_group = _create_beam_group()
	_spiral_vortex_group = _create_spiral_vortex_group()
	_ki_knee_cone_group = _create_ki_knee_cone_group()
	_somersault_vortex_group = _create_somersault_vortex_group()
	_elbow_slash_beam_group = _create_elbow_slash_beam_group()
	_kick_crescent_arc_group = _create_kick_crescent_arc_group()
	_divekick_vfx_group = _create_divekick_vfx_group()

	for node in [
		_slash_arc_mesh, _charge_ring_mesh, _stardust_orb_mesh, _beam_group,
		_spiral_vortex_group, _ki_knee_cone_group, _somersault_vortex_group,
		_elbow_slash_beam_group, _kick_crescent_arc_group, _divekick_vfx_group
	]:
		node.visible = false
		vfx_group.add_child(node)

func _hide_all_combat_vfx() -> void:
	if vfx_group == null:
		return
	for child in vfx_group.get_children():
		if child is Node3D:
			child.visible = false

func _update_combat_vfx(elapsed: float) -> void:
	if vfx_group == null:
		return
	_hide_all_combat_vfx()

	if active_state_name == "Run":
		_charge_ring_mesh.visible = true
		_charge_ring_mesh.position = Vector3(0.0, 0.95, -0.22)
		var pulse: float = 0.65 + sin(elapsed * 18.0) * 0.12
		_charge_ring_mesh.scale = Vector3.ONE * pulse
		_charge_ring_mesh.rotation = Vector3(0.35, 0.0, elapsed * 12.0)
		return

	if active_state_name != "Attack" or active_attack == null:
		return

	var off_x: float = active_attack.hitbox_offset.x
	var off_y: float = active_attack.hitbox_offset.y
	var rad: float = active_attack.hitbox_radius if active_attack.hitbox_radius > 0.0 else 0.75

	if attack_phase == "startup":
		_charge_ring_mesh.visible = true
		_charge_ring_mesh.position = Vector3(0.0, off_y, 0.25)
		var s: float = 0.35 + sin(elapsed * 25.0) * 0.12
		_charge_ring_mesh.scale = Vector3.ONE * s
		_charge_ring_mesh.rotation = Vector3(0.0, 0.0, elapsed * 10.0)
		return

	if attack_phase != "active":
		return

	var vfx: String = active_attack.vfx_type
	if vfx == "":
		vfx = _infer_vfx_type(active_attack)

	match vfx:
		"spiral_vortex":
			_spiral_vortex_group.visible = true
			_spiral_vortex_group.position = Vector3(0.0, 0.68, 0.12)
			_spiral_vortex_group.rotation = Vector3(0.0, 0.0, elapsed * 32.0)
		"somersault_vortex_blue":
			_somersault_vortex_group.visible = true
			_somersault_vortex_group.position = Vector3(0.0, 1.08, 0.08)
			_somersault_vortex_group.rotation = Vector3(0.0, PI * 0.5, -elapsed * 26.0)
			_somersault_vortex_group.scale = Vector3.ONE * (1.0 + sin(elapsed * 38.0) * 0.06)
		"diagonal_elbow_slash_blue":
			_elbow_slash_beam_group.visible = true
			_elbow_slash_beam_group.position = Vector3(-0.08, 0.96, 0.16)
			_elbow_slash_beam_group.rotation = Vector3(-0.82, 0.0, 0.10)
			var p: float = 1.0 + sin(elapsed * 36.0) * 0.12
			_elbow_slash_beam_group.scale = Vector3(p, 1.05, p)
		"crescent_kick_arc_blue":
			_kick_crescent_arc_group.visible = true
			_kick_crescent_arc_group.position = Vector3(0.0, 1.18, 0.24)
			_kick_crescent_arc_group.rotation = Vector3(0.12, PI * 0.5, 0.35 - elapsed * 6.5)
			var p: float = 1.0 + sin(elapsed * 30.0) * 0.06
			_kick_crescent_arc_group.scale = Vector3(p, p, 1.15)
		"ki_divekick_trail":
			_divekick_vfx_group.visible = true
			_divekick_vfx_group.position = Vector3(-0.16, 0.32, 0.52)
			_divekick_vfx_group.rotation = Vector3(0.72, 0.0, -0.06)
			var p: float = 1.0 + sin(elapsed * 38.0) * 0.08
			_divekick_vfx_group.scale = Vector3(p, p, 1.18)
		"ki_knee_cone":
			_ki_knee_cone_group.visible = true
			_ki_knee_cone_group.position = Vector3(0.0, 1.12, 0.55)
			_ki_knee_cone_group.rotation = Vector3(0.0, 0.0, elapsed * 26.0)
			var p: float = 1.0 + sin(elapsed * 40.0) * 0.10
			_ki_knee_cone_group.scale = Vector3(p, p, 1.15)
		"ki_knee_rising":
			_ki_knee_cone_group.visible = true
			_ki_knee_cone_group.position = Vector3(0.0, 1.38, 0.42)
			_ki_knee_cone_group.rotation = Vector3(-0.85, 0.0, elapsed * 28.0)
			var p: float = 1.0 + sin(elapsed * 42.0) * 0.12
			_ki_knee_cone_group.scale = Vector3(p, p, 1.25)
		"axe_crescent_blue":
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(0.22, 0.74, 0.97, 0.90))
			_slash_arc_mesh.position = Vector3(0.0, 1.25, 0.78)
			_slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, -0.35 - elapsed * 14.0)
			_slash_arc_mesh.scale = Vector3(1.48, 1.48, 1.85)
		"downward_punch_arc":
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(0.98, 0.75, 0.14, 0.90))
			_slash_arc_mesh.position = Vector3(0.0, off_y, off_x * 0.85)
			_slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, -1.05 - elapsed * 6.0)
			_slash_arc_mesh.scale = Vector3(rad * 1.35, rad * 1.35, rad * 1.45)
		"ki_beam":
			_beam_group.visible = true
			_beam_group.position = Vector3(0.0, off_y, 0.65)
			_beam_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
			var p: float = 1.0 + sin(elapsed * 45.0) * 0.18
			_beam_group.scale = Vector3(1.0, p, p)
		_:
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(0.98, 0.75, 0.14, 0.88))
			_slash_arc_mesh.position = Vector3(0.0, off_y, off_x * 0.75)
			var ang_deg: float = active_attack.knockback_angle if active_attack.knockback_angle != 0.0 else (active_attack.angle_degrees if "angle_degrees" in active_attack else 45.0)
			_slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, deg_to_rad(ang_deg - 45.0) + elapsed * 8.0)
			_slash_arc_mesh.scale = Vector3.ONE * (rad * 1.15)

# ============================================================================
# INYECCIÓN AUTOMÁTICA DEL MOVESET EXACTO DE GOGETA_DATA.TS
# ============================================================================
func _inject_exact_gogeta_studio_moveset() -> void:
	if character == null or not ("character_data" in character) or character.character_data == null:
		return
	var moveset = character.character_data.moveset
	if moveset == null:
		return

	# 1. Neutral Jab 1 -> 2 -> 3
	var jab3 := _make_atk("gogeta_jab_3", "Jab 3: Doble Mazo y Voltereta (3/3)", "AttackNeutral3", "jab_axe_vault", "slash_gold", 11.5, 8.2, 0.15, 42.0, 8, 7, 16, Vector2(1.05, 1.05), 0.78, Vector2(5.4, 5.8), 2)
	jab3.vault_behind_on_hit = true
	var jab2 := _make_atk("gogeta_jab_2", "Jab 2: Golpe al Estómago (2/3)", "AttackNeutral2", "jab_gut_upper", "slash_gold", 6.5, 2.8, 0.03, 68.0, 5, 7, 11, Vector2(0.98, 1.32), 0.72, Vector2(3.2, 0.0), 3)
	jab2.combo_next = jab3
	var jab1 := _make_atk("gogeta_jab_1", "Jab 1: Dos Golpes Rápidos (1/3)", "AttackNeutral", "jab_double_strike", "slash_gold", 3.5, 2.2, 0.02, 25.0, 3, 9, 10, Vector2(0.98, 1.18), 0.68, Vector2(2.4, 0.0), 2)
	jab1.second_hit_frame = 8
	jab1.combo_next = jab2

	# 2. Tilts
	var side_tilt := _make_atk("gogeta_side_tilt", "Fusion Spin Kick", "AttackSide", "side_roundhouse", "slash_gold", 11.0, 7.2, 0.14, 32.0, 8, 6, 14, Vector2(1.2, 1.15), 0.72, Vector2(4.5, 0.0), 6)
	var up_tilt := _make_atk("gogeta_up_tilt", "Rising Dragon Upper", "AttackUp", "uppercut_rising", "slash_gold", 9.5, 6.8, 0.13, 84.0, 6, 7, 12, Vector2(0.45, 1.95), 0.75, Vector2.ZERO, 0)
	var down_tilt := _make_atk("gogeta_down_tilt", "Patada Voladora en Espiral", "AttackDown", "spiral_kick_low", "spiral_vortex", 9.5, 6.4, 0.12, 62.0, 6, 11, 12, Vector2(1.15, 0.62), 0.76, Vector2(8.8, 1.4), 4)

	# 3. Aerials
	var nair := _make_atk("gogeta_nair", "Aura Vortex Spin", "NeutralAir", "nair_spin", "slash_gold", 9.0, 5.8, 0.11, 45.0, 5, 10, 9, Vector2(0.0, 1.15), 1.05, Vector2.ZERO, 0, true)
	var fair := _make_atk("gogeta_fair", "Forward Air: Puño Descendente", "ForwardAir", "fair_downward_punch", "downward_punch_arc", 12.0, 7.8, 0.15, 295.0, 7, 6, 12, Vector2(1.18, 0.88), 0.84, Vector2(2.2, 0.6), 2, true)
	var bair := _make_atk("gogeta_bair", "Reverse Heel Thrust", "BackAir", "bair_backkick", "slash_gold", 14.0, 8.2, 0.17, 148.0, 9, 5, 14, Vector2(-1.15, 1.15), 0.74, Vector2.ZERO, 0, true)
	var uair := _make_atk("gogeta_uair", "Somersault Flash Kick", "UpAir", "uair_flipkick", "slash_gold", 11.5, 7.0, 0.14, 88.0, 7, 7, 11, Vector2(0.15, 2.1), 0.80, Vector2.ZERO, 0, true)
	var dair := _make_atk("gogeta_dair", "Down Air: Meteor Divekick", "DownAir", "divekick_down_air", "ki_divekick_trail", 13.5, 8.4, 0.16, 295.0, 7, 24, 11, Vector2(0.96, 0.18), 0.95, Vector2.ZERO, 0, true)
	dair.is_divekick = true
	dair.landing_lag_frames = 9
	dair.sliding_knockdown = true

	# 4. Specials
	var neutral_sp := _make_atk("gogeta_neutral_special", "Big Bang Kamehameha", "SpecialNeutral", "beam_charge_thrust", "ki_beam", 16.5, 9.0, 0.18, 30.0, 12, 10, 16, Vector2(1.95, 1.25), 1.15, Vector2.ZERO, 0)
	neutral_sp.spawns_projectile = false

	var rekka3 := _make_atk("gogeta_side_special_3", "Rekka 3: Patada de Hacha (3/3)", "SpecialSide3", "rekka_axe_kick", "axe_crescent_blue", 13.5, 8.8, 0.16, 285.0, 7, 7, 15, Vector2(1.08, 1.15), 0.92, Vector2(2.2, -8.5), 7)
	rekka3.snap_in_front_of_opponent = true
	var rekka2 := _make_atk("gogeta_side_special_2", "Rekka 2: Rodillazo en Salto (2/3)", "SpecialSide2", "rekka_knee_rising", "ki_knee_rising", 8.5, 5.2, 0.06, 76.0, 5, 9, 13, Vector2(0.95, 1.48), 0.84, Vector2(4.8, 11.2), 2)
	rekka2.combo_next = rekka3
	var rekka1 := _make_atk("gogeta_side_special_1", "Rekka 1: Rodillazo Volador (1/3)", "SpecialSide", "rekka_knee_dash", "ki_knee_cone", 7.5, 3.6, 0.04, 38.0, 6, 9, 13, Vector2(1.18, 1.12), 0.86, Vector2(11.4, 1.2), 2)
	rekka1.combo_next = rekka2

	var up_sp_punch := _make_atk("gogeta_up_special_punch", "Up Special: Piña Explosiva (Remate)", "SpecialUp2", "up_special_followup_punch", "slash_gold", 10.5, 9.2, 0.17, 36.0, 5, 6, 14, Vector2(1.05, 1.25), 0.96, Vector2(2.6, 2.4), 1)
	var up_sp := _make_atk("gogeta_up_special", "Up Special: Voltereta en Diagonal", "SpecialUp", "up_somersault_vortex", "somersault_vortex_blue", 5.5, 3.4, 0.03, 68.0, 5, 12, 13, Vector2(0.35, 1.12), 1.12, Vector2(6.4, 13.5), 3)
	up_sp.second_hit_frame = 11
	up_sp.drag_defender_on_hit = true
	up_sp.auto_followup_on_hit = up_sp_punch

	var down_sp_kick := _make_atk("gogeta_down_special_kick", "Down Special (2/2): Giro y Patada", "SpecialDown2", "down_special_turn_kick", "crescent_kick_arc_blue", 11.5, 9.8, 0.19, 28.0, 13, 16, 18, Vector2(1.25, 1.22), 1.12, Vector2(2.4, 2.2), 4)
	down_sp_kick.flip_facing_on_start = true
	var down_sp_elbow := _make_atk("gogeta_down_special", "Down Special (1/2): Codazo Cambia-Lado", "SpecialDown", "down_special_elbow_lift", "diagonal_elbow_slash_blue", 6.0, 3.2, 0.02, 115.0, 9, 18, 12, Vector2(1.08, 1.15), 1.05, Vector2(7.8, 0.0), 2)
	down_sp_elbow.toss_behind_on_hit = true
	down_sp_elbow.auto_followup_on_hit = down_sp_kick
	down_sp_elbow.auto_followup_always = true
	down_sp_elbow.combo_next = down_sp_kick

	_set_slot_if_exists(moveset, ["neutral_attack", "neutral", "jab"], jab1)
	_set_slot_if_exists(moveset, ["side_tilt", "forward_tilt", "attack_side"], side_tilt)
	_set_slot_if_exists(moveset, ["up_tilt", "attack_up"], up_tilt)
	_set_slot_if_exists(moveset, ["down_tilt", "attack_down"], down_tilt)
	_set_slot_if_exists(moveset, ["neutral_air", "nair"], nair)
	_set_slot_if_exists(moveset, ["forward_air", "fair"], fair)
	_set_slot_if_exists(moveset, ["back_air", "bair"], bair)
	_set_slot_if_exists(moveset, ["up_air", "uair"], uair)
	_set_slot_if_exists(moveset, ["down_air", "dair"], dair)
	_set_slot_if_exists(moveset, ["special_neutral", "neutral_special"], neutral_sp)
	_set_slot_if_exists(moveset, ["special_side", "side_special"], rekka1)
	_set_slot_if_exists(moveset, ["special_up", "up_special"], up_sp)
	_set_slot_if_exists(moveset, ["special_down", "down_special"], down_sp_elbow)

func _set_slot_if_exists(moveset: Resource, prop_names: Array[String], atk: AttackData) -> void:
	for p_name in prop_names:
		if p_name in moveset:
			moveset.set(p_name, atk)

func _make_atk(
	id_str: String, disp: String, anim: String, style: String, vfx: String,
	dmg: float, bkb: float, kbg: float, ang: float,
	s_f: int, a_f: int, r_f: int,
	hb_off: Vector2, hb_rad: float,
	imp: Vector2, imp_frame: int, aerial: bool = false
) -> AttackData:
	var a := AttackData.new()
	a.id = id_str
	a.display_name = disp
	a.animation_name = anim
	a.pose_style = style
	a.vfx_type = vfx
	a.damage = dmg
	a.base_knockback = bkb
	a.knockback_scaling = kbg
	a.knockback_angle = ang
	a.startup_frames = s_f
	a.active_frames = a_f
	a.recovery_frames = r_f
	a.hitbox_offset = Vector3(hb_off.x, hb_off.y, 0.0)
	a.hitbox_radius = hb_rad
	a.hitbox_size = Vector2(hb_rad * 2.0, hb_rad * 2.0)
	a.self_impulse = Vector3(imp.x, imp.y, 0.0)
	a.self_impulse_frame = imp_frame
	a.is_aerial = aerial
	a.divekick_speed = Vector2(13.5 * Constants.UNIT_SIZE, 20.0 * Constants.UNIT_SIZE)
	return a

# ============================================================================
# HELPERS MATEMÁTICOS Y DE GEOMETRÍA 3D VFX
# ============================================================================
static func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t: float = clampf((x - edge0) / maxf(0.0001, edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func _damp(cur: float, tgt: float, lambda_val: float, dt: float) -> float:
	return lerpf(cur, tgt, 1.0 - exp(-lambda_val * dt))

static func _quat_euler_xyz(rx: float, ry: float, rz: float) -> Quaternion:
	return Quaternion(Vector3.RIGHT, rx) * Quaternion(Vector3.UP, ry) * Quaternion(Vector3.BACK, rz)

static func _quat_euler_yxz(rx: float, ry: float, rz: float) -> Quaternion:
	return Quaternion(Vector3.UP, ry) * Quaternion(Vector3.RIGHT, rx) * Quaternion(Vector3.BACK, rz)

static func _build_shoulder_char_quat(side_sign: float, arm_down: float, arm_fwd: float, arm_cross: float, arm_roll: float) -> Quaternion:
	var q1 := Quaternion(Vector3.RIGHT, arm_roll)
	var q2 := Quaternion(Vector3.BACK, -side_sign * arm_down)
	var q3 := Quaternion(Vector3.RIGHT, -arm_fwd)
	var q4 := Quaternion(Vector3.UP, -side_sign * arm_cross)
	return q4 * q3 * q2 * q1

func _infer_pose_style(atk: AttackData) -> String:
	match atk.animation_name:
		"AttackNeutral": return "jab_double_strike"
		"AttackNeutral2": return "jab_gut_upper"
		"AttackNeutral3": return "jab_axe_vault"
		"AttackSide": return "side_roundhouse"
		"AttackUp": return "uppercut_rising"
		"AttackDown": return "spiral_kick_low"
		"NeutralAir": return "nair_spin"
		"ForwardAir": return "fair_downward_punch"
		"BackAir": return "bair_backkick"
		"UpAir": return "uair_flipkick"
		"DownAir": return "divekick_down_air"
		"SpecialNeutral": return "beam_charge_thrust"
		"SpecialSide": return "rekka_knee_dash"
		"SpecialSide2": return "rekka_knee_rising"
		"SpecialSide3": return "rekka_axe_kick"
		"SpecialUp": return "up_somersault_vortex"
		"SpecialUp2": return "up_special_followup_punch"
		"SpecialDown": return "down_special_elbow_lift"
		"SpecialDown2": return "down_special_turn_kick"
	return "jab_combo"

func _infer_vfx_type(atk: AttackData) -> String:
	match _infer_pose_style(atk):
		"spiral_kick_low": return "spiral_vortex"
		"rekka_knee_dash": return "ki_knee_cone"
		"rekka_knee_rising": return "ki_knee_rising"
		"rekka_axe_kick": return "axe_crescent_blue"
		"up_somersault_vortex": return "somersault_vortex_blue"
		"down_special_elbow_lift": return "diagonal_elbow_slash_blue"
		"down_special_turn_kick": return "crescent_kick_arc_blue"
		"divekick_down_air": return "ki_divekick_trail"
		"fair_downward_punch": return "downward_punch_arc"
		"beam_charge_thrust": return "ki_beam"
	return "slash_gold"

func _make_unshaded_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	return m

func _set_mesh_color(mi: MeshInstance3D, col: Color) -> void:
	if mi and mi.material_override is StandardMaterial3D:
		(mi.material_override as StandardMaterial3D).albedo_color = col

func _create_torus_mesh(outer_r: float, thickness: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.01, outer_r - thickness)
	torus.outer_radius = outer_r + thickness
	mi.mesh = torus
	mi.rotation.x = PI * 0.5
	mi.material_override = _make_unshaded_mat(col)
	return mi

func _create_sphere_mesh(rad: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = rad
	sp.height = rad * 2.0
	mi.mesh = sp
	mi.material_override = _make_unshaded_mat(col)
	return mi

func _create_cyl_mesh(top_r: float, bot_r: float, h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = h
	mi.mesh = cyl
	mi.material_override = _make_unshaded_mat(col)
	return mi

func _create_beam_group() -> Node3D:
	var grp := Node3D.new()
	var core := _create_sphere_mesh(0.42, Color(0.88, 0.96, 1.0, 0.95))
	grp.add_child(core)
	var cyl := _create_cyl_mesh(0.28, 0.36, 2.6, Color(0.22, 0.74, 0.97, 0.88))
	cyl.rotation.z = -PI * 0.5
	cyl.position.x = 1.35
	grp.add_child(cyl)
	return grp

func _create_spiral_vortex_group() -> Node3D:
	var grp := Node3D.new()
	var z_list := [-0.58, 0.0, 0.58]
	var r_list := [0.56, 0.68, 0.52]
	for i in range(3):
		var ring := _create_torus_mesh(r_list[i], 0.028, Color(0.97, 0.98, 1.0, 0.82) if i == 1 else Color(0.99, 0.90, 0.54, 0.65))
		ring.position = Vector3(0.0, 0.0, z_list[i])
		grp.add_child(ring)
	return grp

func _create_ki_knee_cone_group() -> Node3D:
	var grp := Node3D.new()
	var outer_cone := _create_cyl_mesh(0.02, 0.62, 1.65, Color(0.22, 0.74, 0.97, 0.52))
	outer_cone.rotation.x = PI * 0.5
	grp.add_child(outer_cone)
	var inner_cone := _create_cyl_mesh(0.01, 0.38, 1.45, Color(0.88, 0.95, 1.0, 0.78))
	inner_cone.rotation.x = PI * 0.5
	inner_cone.position.z = 0.12
	grp.add_child(inner_cone)
	var ring := _create_torus_mesh(0.46, 0.032, Color(0.49, 0.83, 0.99, 0.88))
	ring.position.z = 0.35
	grp.add_child(ring)
	return grp

func _create_somersault_vortex_group() -> Node3D:
	var grp := Node3D.new()
	var b1 := _create_torus_mesh(0.96, 0.068, Color(0.15, 0.39, 0.92, 0.88))
	var b2 := _create_torus_mesh(0.92, 0.052, Color(0.22, 0.74, 0.97, 0.84))
	b2.position.z = 0.04
	var w1 := _create_torus_mesh(0.76, 0.024, Color(0.97, 0.98, 1.0, 0.82))
	w1.position.z = -0.05
	grp.add_child(b1)
	grp.add_child(b2)
	grp.add_child(w1)
	return grp

func _create_elbow_slash_beam_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_cyl_mesh(0.22, 0.28, 2.45, Color(0.15, 0.39, 0.92, 0.72)))
	grp.add_child(_create_cyl_mesh(0.13, 0.18, 2.52, Color(0.22, 0.74, 0.97, 0.88)))
	grp.add_child(_create_cyl_mesh(0.06, 0.09, 2.58, Color(1.0, 1.0, 1.0, 0.98)))
	var flash := _create_sphere_mesh(0.28, Color(1.0, 1.0, 1.0, 0.95))
	flash.position = Vector3(0.0, 1.15, 0.0)
	grp.add_child(flash)
	return grp

func _create_kick_crescent_arc_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_torus_mesh(1.32, 0.14, Color(0.11, 0.31, 0.85, 0.82)))
	var mid := _create_torus_mesh(1.30, 0.09, Color(0.22, 0.74, 0.97, 0.90))
	mid.position.z = 0.02
	grp.add_child(mid)
	var core := _create_torus_mesh(1.28, 0.045, Color(1.0, 1.0, 1.0, 0.96))
	core.position.z = 0.04
	grp.add_child(core)
	return grp

func _create_divekick_vfx_group() -> Node3D:
	var grp := Node3D.new()
	var outer_cone := _create_cyl_mesh(0.02, 0.52, 2.35, Color(0.22, 0.74, 0.97, 0.65))
	outer_cone.rotation.x = PI * 0.5
	grp.add_child(outer_cone)
	var inner_cone := _create_cyl_mesh(0.01, 0.32, 2.15, Color(1.0, 1.0, 1.0, 0.92))
	inner_cone.rotation.x = PI * 0.5
	inner_cone.position.z = 0.15
	grp.add_child(inner_cone)
	var tip_ring := _create_torus_mesh(0.48, 0.038, Color(0.49, 0.83, 0.99, 0.92))
	tip_ring.position.z = 1.12
	grp.add_child(tip_ring)
	return grp
