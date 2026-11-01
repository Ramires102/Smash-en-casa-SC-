# ==============================================================================
# ProceduralPoseSolver — Síntesis Matemática de Poses 3D (Gogeta SSJ y Sans)
# ==============================================================================
# Algunos modelos 3D (como Gogeta SSJ y Sans) se animan de manera 100% procedural
# calculando rotaciones articulares por código en cada frame (24 grados de libertad:
# pelvis, columna, cabeza, hombros, codos, caderas y rodillas) en lugar de leer
# keyframes fijos de un archivo .glb.
# ==============================================================================
class_name ProceduralPoseSolver
extends RefCounted

#region Creación e Inicialización de Rigs
static func create_default_pose() -> Dictionary:
	return {
		"pelvisOffsetY": 0.0, "pelvisOffsetZ": 0.0,
		"pelvisPitch": 0.0, "pelvisYaw": 0.0, "pelvisRoll": 0.0,
		"spinePitch": 0.0, "spineYaw": 0.0, "spineRoll": 0.0,
		"headPitch": 0.0, "headYaw": 0.0, "headRoll": 0.0,
		"armDownR": 1.12, "armFwdR": 0.35, "armCrossR": 0.35, "armRollR": -0.45, "elbowBendR": 1.25,
		"armDownL": 1.12, "armFwdL": 0.35, "armCrossL": 0.35, "armRollL": -0.45, "elbowBendL": 1.25,
		"hipPitchR": 0.0, "hipSplayR": 0.0, "kneeBendR": 0.0,
		"hipPitchL": 0.0, "hipSplayL": 0.0, "kneeBendL": 0.0
	}

static func init_gogeta_bones(skeleton: Skeleton3D) -> Dictionary:
	var bones: Dictionary = {}
	if skeleton == null:
		return bones
	for b_name in ["Pelvis", "Spine", "Head", "ShoulderR", "ElbowR", "ShoulderL", "ElbowL", "HipR", "KneeR", "HipL", "KneeL", "Sash"]:
		bones[b_name] = skeleton.find_bone(b_name)
	return bones

static func init_sans_bindings(skeleton: Skeleton3D, model_root: Node3D) -> Dictionary:
	var bindings: Dictionary = {}
	if skeleton == null or model_root == null:
		return bindings
	_hide_extra_sans_meshes(model_root)

	var skel_to_model_quat: Quaternion = (model_root.global_transform.basis.inverse() * skeleton.global_transform.basis).get_rotation_quaternion().normalized()
	for idx in range(skeleton.get_bone_count()):
		var b_name: String = skeleton.get_bone_name(idx)
		var local_rest_quat: Quaternion = skeleton.get_bone_rest(idx).basis.get_rotation_quaternion().normalized()
		var bone_skel_rest_quat: Quaternion = skeleton.get_bone_global_rest(idx).basis.get_rotation_quaternion().normalized()
		var char_rest_quat: Quaternion = (skel_to_model_quat * bone_skel_rest_quat).normalized()
		bindings[b_name] = {
			"idx": idx,
			"local_rest": local_rest_quat,
			"char_rest": char_rest_quat,
			"inv_char_rest": char_rest_quat.inverse()
		}
	return bindings

static func _hide_extra_sans_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.name.to_lower() != "sans":
			child.visible = false
		_hide_extra_sans_meshes(child)
#endregion

#region Cálculo de Pose Objetivo por Estado y Ataque
static func compute_target_pose(
	p: Dictionary,
	t: float,
	is_gogeta: bool,
	is_sans: bool,
	active_state_name: String,
	is_sliding_knockdown: bool,
	is_double_jumping: bool,
	active_attack: AttackData,
	attack_frame: int,
	attack_phase: String
) -> void:
	var breath_speed: float = 2.6 if is_gogeta else 2.1
	var breath_freq: float = breath_speed * 1.25
	var breath: float = sin(t * breath_freq)
	var breath2: float = cos(t * breath_freq * 2.0)

	p["pelvisOffsetY"] = -0.05 if is_gogeta else 0.0
	p["pelvisOffsetZ"] = 0.0
	p["pelvisPitch"] = 0.08 if is_gogeta else 0.0
	p["pelvisYaw"] = 0.42 if is_gogeta else 0.12
	p["pelvisRoll"] = 0.0
	p["spinePitch"] = 0.14 if is_gogeta else -0.03
	p["spineYaw"] = -0.18 if is_gogeta else -0.04
	p["spineRoll"] = 0.0
	p["headPitch"] = 0.06 if is_gogeta else 0.02
	p["headYaw"] = -0.24 if is_gogeta else -0.08
	p["headRoll"] = 0.0

	if is_gogeta:
		p["armDownR"] = 0.88; p["armFwdR"] = 0.78; p["armCrossR"] = 0.34; p["armRollR"] = -0.62; p["elbowBendR"] = 1.48
		p["armDownL"] = 1.06; p["armFwdL"] = 0.16; p["armCrossL"] = 0.52; p["armRollL"] = -0.55; p["elbowBendL"] = 1.58
		p["hipPitchR"] = 0.36; p["hipSplayR"] = -0.05; p["kneeBendR"] = 0.48
		p["hipPitchL"] = -0.22; p["hipSplayL"] = -0.05; p["kneeBendL"] = 0.32
	else:
		p["armDownR"] = 1.18; p["armFwdR"] = 0.18; p["armCrossR"] = 0.42; p["armRollR"] = -0.45; p["elbowBendR"] = 1.22
		p["armDownL"] = 1.18; p["armFwdL"] = 0.18; p["armCrossL"] = 0.42; p["armRollL"] = -0.45; p["elbowBendL"] = 1.22
		p["hipPitchR"] = 0.08; p["hipSplayR"] = 0.0; p["kneeBendR"] = 0.16
		p["hipPitchL"] = -0.04; p["hipSplayL"] = 0.0; p["kneeBendL"] = 0.14

	if active_state_name == "Hit" or active_state_name == "Death":
		if is_sliding_knockdown:
			p["pelvisOffsetY"] = -0.52; p["pelvisPitch"] = -1.22; p["pelvisYaw"] = 0.22
			p["spinePitch"] = -0.18; p["headPitch"] = -0.42; p["headYaw"] = 0.28
			p["armDownR"] = 0.68; p["armFwdR"] = -0.32; p["armCrossR"] = -0.12; p["elbowBendR"] = 0.58
			p["armDownL"] = 0.88; p["armFwdL"] = 0.22; p["armCrossL"] = 0.38; p["elbowBendL"] = 1.12
			p["hipPitchR"] = 0.52; p["kneeBendR"] = 0.68; p["hipPitchL"] = 0.26; p["kneeBendL"] = 0.48
			return
		var shake: float = sin(t * 42.0) * 0.06
		p["pelvisOffsetY"] = -0.04; p["pelvisPitch"] = -0.22; p["pelvisYaw"] = shake
		p["spinePitch"] = -0.32; p["headPitch"] = -0.35
		p["armDownR"] = 0.65; p["armFwdR"] = -0.35; p["armCrossR"] = -0.15; p["elbowBendR"] = 0.45
		p["armDownL"] = 0.65; p["armFwdL"] = -0.35; p["armCrossL"] = -0.15; p["elbowBendL"] = 0.45
		p["hipPitchR"] = 0.35; p["kneeBendR"] = 0.55; p["hipPitchL"] = 0.22; p["kneeBendL"] = 0.45
		return

	if active_state_name == "Jump":
		p["pelvisOffsetY"] = 0.06; p["pelvisYaw"] = 0.08; p["spinePitch"] = 0.12; p["headPitch"] = -0.12
		p["armDownR"] = 0.78; p["armFwdR"] = 0.25; p["armCrossR"] = 0.20; p["elbowBendR"] = 1.15
		p["armDownL"] = 0.78; p["armFwdL"] = 0.25; p["armCrossL"] = 0.20; p["elbowBendL"] = 1.15
		p["hipPitchR"] = 0.72; p["kneeBendR"] = 0.95; p["hipPitchL"] = 0.28; p["kneeBendL"] = 0.45
		if is_double_jumping:
			p["pelvisPitch"] = minf(PI * 2.0, t * 13.5)
			p["hipPitchL"] = 0.75; p["kneeBendL"] = 1.05
		return

	if active_state_name == "Fall":
		var sway: float = sin(t * 6.0) * 0.06
		p["pelvisYaw"] = 0.1; p["spinePitch"] = 0.14; p["headPitch"] = 0.15
		p["armDownR"] = 0.68 + sway; p["armFwdR"] = 0.15; p["armCrossR"] = 0.12; p["elbowBendR"] = 0.92
		p["armDownL"] = 0.68 - sway; p["armFwdL"] = 0.15; p["armCrossL"] = 0.12; p["elbowBendL"] = 0.92
		p["hipPitchR"] = 0.38; p["kneeBendR"] = 0.62; p["hipPitchL"] = 0.12; p["kneeBendL"] = 0.35
		return

	if active_state_name == "Run":
		if is_gogeta:
			var hw: float = sin(t * 7.5)
			var hw2: float = cos(t * 7.5)
			p["pelvisOffsetY"] = 0.18 + hw * 0.038; p["pelvisOffsetZ"] = 0.08
			p["pelvisPitch"] = 0.42 + hw * 0.03; p["pelvisYaw"] = 0.16; p["pelvisRoll"] = hw2 * 0.03
			p["spinePitch"] = 0.22 + hw * 0.025; p["spineYaw"] = -0.10
			p["headPitch"] = -0.48 - hw * 0.03; p["headYaw"] = -0.06
			p["hipPitchR"] = 0.68 + hw * 0.06; p["hipSplayR"] = -0.08; p["kneeBendR"] = 1.12 + hw * 0.08
			p["hipPitchL"] = -0.34 - hw * 0.05; p["hipSplayL"] = -0.08; p["kneeBendL"] = 0.36 + hw2 * 0.05
			p["armDownR"] = 0.96 + hw * 0.04; p["armFwdR"] = -0.28 + hw * 0.05; p["armCrossR"] = 0.18; p["armRollR"] = -0.35; p["elbowBendR"] = 0.88 + hw2 * 0.05
			p["armDownL"] = 0.92 - hw * 0.04; p["armFwdL"] = 0.32 + hw2 * 0.05; p["armCrossL"] = 0.38; p["armRollL"] = -0.48; p["elbowBendL"] = 1.32 - hw * 0.05
			return
		var phase: float = t * 11.5
		var sin_p: float = sin(phase)
		var cos_p: float = cos(phase)
		p["pelvisOffsetY"] = (absf(cos_p) - 0.35) * 0.07
		p["pelvisPitch"] = 0.08; p["pelvisYaw"] = -sin_p * 0.18; p["pelvisRoll"] = cos_p * 0.04
		p["spinePitch"] = 0.22 * 0.65; p["spineYaw"] = sin_p * 0.24
		p["headPitch"] = -p["spinePitch"] * 0.55; p["headYaw"] = -sin_p * 0.08
		p["hipPitchR"] = sin_p * 0.78 + 0.08; p["kneeBendR"] = maxf(0.08, (-cos_p * 0.5 + 0.5) * 0.95); p["hipSplayR"] = 0.0
		p["hipPitchL"] = -sin_p * 0.78 + 0.08; p["kneeBendL"] = maxf(0.08, (cos_p * 0.5 + 0.5) * 0.95); p["hipSplayL"] = 0.0
		p["armDownR"] = 1.12; p["armFwdR"] = -sin_p * 0.72 + 0.18; p["armCrossR"] = 0.22; p["elbowBendR"] = 1.35 + (-sin_p * 0.2)
		p["armDownL"] = 1.12; p["armFwdL"] = sin_p * 0.72 + 0.18; p["armCrossL"] = 0.22; p["elbowBendL"] = 1.35 + (sin_p * 0.2)
		return

	if active_state_name == "Attack" and active_attack != null:
		compute_attack_pose(active_attack, p, attack_frame, attack_phase, is_sans)
		return

	# Respiración natural en reposo (Idle)
	p["pelvisOffsetY"] += breath * 0.024
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

static func compute_attack_pose(atk: AttackData, p: Dictionary, attack_frame: int, attack_phase: String, is_sans: bool) -> void:
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

	match atk.pose_style:
		"jab_double_strike":
			if is_startup:
				p["pelvisYaw"] = -0.25 * startup_t; p["spineYaw"] = -0.22 * startup_t
				p["armDownL"] = 1.05; p["armFwdL"] = 0.45 + 0.35 * startup_t; p["elbowBendL"] = 1.35 * (1.0 - 0.3 * startup_t)
				p["armDownR"] = 1.05; p["armFwdR"] = 0.58; p["armCrossR"] = 0.52; p["elbowBendR"] = 1.52
				p["hipPitchL"] = 0.35 * startup_t; p["kneeBendL"] = 0.45 * startup_t
			elif is_active:
				var second_hit_start: int = atk.second_hit_frame if atk.second_hit_frame > 0 else int(s + ceil(a * 0.5))
				if attack_frame < second_hit_start:
					p["pelvisYaw"] = -0.38; p["spineYaw"] = -0.34; p["spinePitch"] = 0.16; p["headYaw"] = 0.52; p["pelvisOffsetZ"] = 0.06
					p["armDownL"] = 1.15; p["armFwdL"] = 1.28; p["armCrossL"] = 0.18; p["armRollL"] = -0.35; p["elbowBendL"] = 0.12
					p["armDownR"] = 1.05; p["armFwdR"] = 0.62; p["armCrossR"] = 0.58; p["armRollR"] = -0.58; p["elbowBendR"] = 1.58
					p["hipPitchL"] = 0.42; p["kneeBendL"] = 0.52; p["hipPitchR"] = -0.32; p["kneeBendR"] = 0.22
				else:
					p["pelvisYaw"] = 0.58; p["spineYaw"] = 0.52; p["spinePitch"] = 0.24; p["headYaw"] = -0.68; p["pelvisOffsetZ"] = 0.12
					p["armDownR"] = 1.16; p["armFwdR"] = 1.44; p["armCrossR"] = 0.22; p["armRollR"] = -0.35; p["elbowBendR"] = 0.08
					p["armDownL"] = 0.72; p["armFwdL"] = -0.48; p["armCrossL"] = -0.18; p["elbowBendL"] = 1.38
					p["hipPitchL"] = 0.46; p["kneeBendL"] = 0.56; p["hipPitchR"] = -0.38; p["kneeBendR"] = 0.18
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisYaw"] = 0.58 * w + 0.42 * (1.0 - w); p["spineYaw"] = 0.52 * w - 0.18 * (1.0 - w); p["spinePitch"] = 0.24 * w + 0.14 * (1.0 - w)
				p["armDownR"] = 1.16 * w + 0.88 * (1.0 - w); p["armFwdR"] = 1.44 * w + 0.78 * (1.0 - w); p["elbowBendR"] = 0.08 * w + 1.48 * (1.0 - w)

		"jab_gut_upper":
			p["pelvisOffsetY"] = -0.06 * (coil + extend)
			p["hipPitchL"] = 0.44 * (coil + extend) + 0.15 * (1.0 - extend - coil); p["kneeBendL"] = 0.54 * (coil + extend) + 0.25 * (1.0 - extend - coil)
			p["hipPitchR"] = -0.34 * (coil + extend) + 0.20 * (1.0 - extend - coil); p["kneeBendR"] = 0.26
			p["armDownR"] = 1.12; p["armFwdR"] = 0.28; p["armCrossR"] = 0.42; p["armRollR"] = -0.52; p["elbowBendR"] = 1.48
			if is_startup:
				p["pelvisYaw"] = 0.28 * startup_t; p["spinePitch"] = 0.18 * startup_t
				p["armDownL"] = 1.26; p["armFwdL"] = -0.18 * startup_t; p["armCrossL"] = 0.15; p["elbowBendL"] = 1.32
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				var rise: float = _smoothstep(0.0, 0.7, active_t) if is_active else 1.0
				p["pelvisYaw"] = -0.28 * w + 0.42 * (1.0 - w); p["spineYaw"] = -0.32 * w - 0.18 * (1.0 - w)
				p["spinePitch"] = -0.08 * w + 0.14 * (1.0 - w); p["headYaw"] = 0.45 * w - 0.24 * (1.0 - w)
				p["armDownL"] = (1.18 - 0.36 * rise) * w + 1.06 * (1.0 - w); p["armFwdL"] = (0.72 + 0.50 * rise) * w + 0.16 * (1.0 - w)
				p["armCrossL"] = 0.28 * w + 0.52 * (1.0 - w); p["armRollL"] = -0.65 * w - 0.55 * (1.0 - w); p["elbowBendL"] = 1.38 * w + 1.58 * (1.0 - w)

		"jab_axe_vault":
			if is_startup:
				p["pelvisOffsetY"] = 0.14 * startup_t; p["pelvisYaw"] = 0.08; p["spinePitch"] = -0.28 * startup_t; p["headPitch"] = 0.18 * startup_t
				p["armDownR"] = 0.88 - 0.58 * startup_t; p["armDownL"] = 0.88 - 0.58 * startup_t
				p["armFwdR"] = 0.78 + 0.96 * startup_t; p["armFwdL"] = 0.78 + 0.96 * startup_t
				p["armCrossR"] = 0.52 * startup_t; p["armCrossL"] = 0.52 * startup_t; p["elbowBendR"] = 1.12; p["elbowBendL"] = 1.12
				p["hipPitchL"] = 0.88 * startup_t; p["kneeBendL"] = 1.18 * startup_t; p["hipPitchR"] = -0.28 * startup_t; p["kneeBendR"] = 0.35 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = 0.18; p["pelvisPitch"] = 0.34; p["pelvisYaw"] = 0.0; p["spinePitch"] = 0.52; p["headPitch"] = 0.24
				p["armDownR"] = 1.24; p["armDownL"] = 1.24; p["armFwdR"] = 0.88; p["armFwdL"] = 0.88
				p["armCrossR"] = 0.54; p["armCrossL"] = 0.54; p["elbowBendR"] = 0.22; p["elbowBendL"] = 0.22
				p["hipPitchR"] = 0.82; p["kneeBendR"] = 1.12; p["hipSplayR"] = 0.22
				p["hipPitchL"] = 0.82; p["kneeBendL"] = 1.12; p["hipSplayL"] = 0.22
			else:
				var flip_t: float = _smoothstep(0.0, 0.88, recovery_t)
				var tuck: float = 1.0 - _smoothstep(0.75, 1.0, recovery_t)
				p["pelvisOffsetY"] = sin(flip_t * PI) * 0.28; p["pelvisPitch"] = flip_t * PI * 2.0; p["pelvisYaw"] = 0.0
				p["spinePitch"] = 0.45 * tuck; p["headPitch"] = 0.35 * tuck
				p["armDownR"] = 1.05; p["armDownL"] = 1.05; p["armFwdR"] = 0.65 * tuck + 0.78 * (1.0 - tuck); p["armFwdL"] = 0.65 * tuck + 0.16 * (1.0 - tuck)
				p["armCrossR"] = 0.48; p["armCrossL"] = 0.48; p["elbowBendR"] = 1.52; p["elbowBendL"] = 1.52
				p["hipPitchR"] = 1.15 * tuck + 0.36 * (1.0 - tuck); p["kneeBendR"] = 1.45 * tuck + 0.48 * (1.0 - tuck)
				p["hipPitchL"] = 1.15 * tuck - 0.22 * (1.0 - tuck); p["kneeBendL"] = 1.45 * tuck + 0.32 * (1.0 - tuck)

		"rekka_knee_dash":
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			p["pelvisOffsetY"] = 0.14 * w - 0.05 * (1.0 - w); p["pelvisOffsetZ"] = 0.15 * w
			p["pelvisPitch"] = 0.34 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = 0.22 * w + 0.42 * (1.0 - w)
			p["spinePitch"] = 0.26 * w + 0.14 * (1.0 - w); p["spineYaw"] = 0.18 * w - 0.18 * (1.0 - w)
			p["headPitch"] = -0.34 * w + 0.06 * (1.0 - w); p["headYaw"] = -0.30 * w - 0.24 * (1.0 - w)
			p["hipPitchR"] = 1.32 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 1.58 * w + 0.48 * (1.0 - w); p["hipSplayR"] = -0.04
			p["hipPitchL"] = -0.46 * w - 0.22 * (1.0 - w); p["kneeBendL"] = 1.18 * w + 0.32 * (1.0 - w); p["hipSplayL"] = -0.04
			p["armDownR"] = 0.38 * w + 0.88 * (1.0 - w); p["armFwdR"] = -0.65 * w + 0.78 * (1.0 - w); p["armCrossR"] = -0.15 * w + 0.34 * (1.0 - w); p["armRollR"] = -0.35; p["elbowBendR"] = 0.62 * w + 1.48 * (1.0 - w)
			p["armDownL"] = 1.12 * w + 1.06 * (1.0 - w); p["armFwdL"] = 0.32 * w + 0.16 * (1.0 - w); p["armCrossL"] = 0.48 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.48 * w + 1.58 * (1.0 - w)

		"rekka_knee_rising":
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			p["pelvisOffsetY"] = 0.20 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = -0.24 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = -0.26 * w + 0.42 * (1.0 - w)
			p["spinePitch"] = 0.18 * w + 0.14 * (1.0 - w); p["spineYaw"] = -0.18 * w - 0.18 * (1.0 - w)
			p["headPitch"] = -0.22 * w + 0.06 * (1.0 - w); p["headYaw"] = 0.28 * w - 0.24 * (1.0 - w)
			p["hipPitchL"] = 1.52 * w - 0.22 * (1.0 - w); p["kneeBendL"] = 1.56 * w + 0.32 * (1.0 - w); p["hipSplayL"] = -0.05
			p["hipPitchR"] = -0.38 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 0.16 * w + 0.48 * (1.0 - w); p["hipSplayR"] = -0.05
			p["armDownR"] = 0.84 * w + 0.88 * (1.0 - w); p["armFwdR"] = -0.38 * w + 0.78 * (1.0 - w); p["armCrossR"] = 0.24 * w + 0.34 * (1.0 - w); p["elbowBendR"] = 1.32 * w + 1.48 * (1.0 - w)
			p["armDownL"] = 0.86 * w + 1.06 * (1.0 - w); p["armFwdL"] = -0.32 * w + 0.16 * (1.0 - w); p["armCrossL"] = 0.28 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.35 * w + 1.58 * (1.0 - w)

		"rekka_axe_kick":
			if is_startup:
				p["pelvisOffsetY"] = 0.22 * startup_t; p["pelvisPitch"] = -0.24 * startup_t; p["pelvisYaw"] = 0.32 * startup_t
				p["spinePitch"] = -0.18 * startup_t; p["headPitch"] = 0.16 * startup_t
				p["hipPitchR"] = 0.36 + 1.42 * startup_t; p["kneeBendR"] = 0.48 * (1.0 - startup_t) + 0.05 * startup_t; p["hipSplayR"] = 0.10 * startup_t
				p["hipPitchL"] = 0.32 * startup_t; p["kneeBendL"] = 1.28 * startup_t
				p["armDownR"] = 0.88 - 0.52 * startup_t; p["armFwdR"] = 0.78 + 0.62 * startup_t; p["armCrossR"] = 0.38; p["elbowBendR"] = 1.25
				p["armDownL"] = 1.18; p["armFwdL"] = -0.32 * startup_t; p["elbowBendL"] = 0.42
			elif is_active:
				var slash_p: float = _smoothstep(0.0, 0.85, active_t)
				p["pelvisOffsetY"] = 0.18 * (1.0 - slash_p * 0.5); p["pelvisPitch"] = -0.18 + 0.38 * slash_p; p["pelvisYaw"] = 0.36
				p["spinePitch"] = 0.26 * slash_p; p["spineYaw"] = 0.24; p["headPitch"] = 0.18; p["headYaw"] = -0.28
				p["hipPitchR"] = 1.78 - 0.96 * slash_p; p["kneeBendR"] = 0.05; p["hipSplayR"] = 0.08
				p["hipPitchL"] = 0.28; p["kneeBendL"] = 1.35; p["hipSplayL"] = 0.12
				p["armDownR"] = 0.36; p["armFwdR"] = 1.38; p["armCrossR"] = 0.38; p["elbowBendR"] = 1.22
				p["armDownL"] = 1.22; p["armFwdL"] = -0.38; p["armCrossL"] = -0.12; p["elbowBendL"] = 0.35
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = 0.08 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = 0.20 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = 0.36 * w + 0.42 * (1.0 - w)
				p["spinePitch"] = 0.26 * w + 0.14 * (1.0 - w); p["hipPitchR"] = 0.82 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 0.05 * w + 0.48 * (1.0 - w)

		"jab_combo":
			p["pelvisYaw"] = -0.35 * coil + 0.45 * extend; p["spineYaw"] = -0.28 * coil + 0.42 * extend
			p["spinePitch"] = -0.08 * coil + 0.22 * extend; p["pelvisOffsetZ"] = 0.08 * extend
			p["armDownR"] = 1.12 - 0.18 * extend; p["armFwdR"] = -0.35 * coil + 1.38 * extend + 0.35 * (1.0 - extend - coil)
			p["armCrossR"] = 0.25 * extend; p["elbowBendR"] = 1.45 * coil + 0.12 * extend + 1.25 * (1.0 - extend - coil)
			p["armDownL"] = 1.15; p["armFwdL"] = 0.25 - 0.35 * extend; p["elbowBendL"] = 1.5
			p["hipPitchR"] = 0.32 * extend; p["kneeBendR"] = 0.42 * extend; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.15

		"side_roundhouse":
			if is_sans:
				p["pelvisYaw"] = -0.2 * coil + 0.35 * extend; p["spinePitch"] = -0.18 * extend
				p["armDownR"] = 0.85; p["armFwdR"] = 1.05 * extend + 0.4 * coil; p["armCrossR"] = 0.3; p["elbowBendR"] = 0.95 - 0.5 * extend
				p["armDownL"] = 0.92; p["armFwdL"] = 0.85 * extend + 0.35 * coil; p["armCrossL"] = 0.45; p["elbowBendL"] = 1.15
			else:
				p["pelvisYaw"] = -0.45 * coil + 0.65 * extend; p["pelvisRoll"] = 0.28 * extend; p["spinePitch"] = -0.24 * extend; p["spineYaw"] = 0.35 * extend
				p["hipPitchR"] = -0.35 * coil + 1.35 * extend; p["hipSplayR"] = 0.35 * extend; p["kneeBendR"] = 0.95 * coil + 0.08 * extend
				p["hipPitchL"] = -0.15 * extend; p["kneeBendL"] = 0.25; p["armDownR"] = 0.85; p["armFwdR"] = -0.25 * extend; p["elbowBendR"] = 0.85

		"uppercut_rising":
			p["pelvisOffsetY"] = -0.12 * coil + 0.16 * extend; p["pelvisYaw"] = -0.35 * coil + 0.48 * extend
			p["spinePitch"] = 0.25 * coil - 0.28 * extend; p["spineYaw"] = 0.42 * extend; p["headPitch"] = -0.32 * extend
			p["armDownR"] = 1.25 * coil + 0.35 * extend + 1.08 * (1.0 - extend - coil)
			p["armFwdR"] = -0.25 * coil + 1.75 * extend; p["armCrossR"] = 0.22 * extend
			p["elbowBendR"] = 1.45 * coil + 0.35 * extend + 1.2 * (1.0 - extend - coil)
			p["hipPitchR"] = 0.45 * coil + 0.55 * extend; p["kneeBendR"] = 0.65 * coil + 0.72 * extend
			p["hipPitchL"] = 0.45 * coil - 0.15 * extend; p["kneeBendL"] = 0.65 * coil + 0.15 * extend

		"spiral_kick_low":
			if is_startup:
				p["pelvisOffsetY"] = -0.22 * startup_t; p["pelvisPitch"] = -PI * 0.48 * startup_t; p["pelvisYaw"] = 0.0
				p["spinePitch"] = 0.0; p["spineYaw"] = 0.0; p["headPitch"] = 0.0; p["headYaw"] = 0.0
				p["armDownR"] = 0.88 - 2.23 * startup_t; p["armDownL"] = 1.06 - 2.41 * startup_t
				p["armFwdR"] = 0.78 * (1.0 - startup_t); p["armFwdL"] = 0.16 * (1.0 - startup_t)
				p["armCrossR"] = 0.34 * (1.0 - startup_t) + 0.08 * startup_t; p["armCrossL"] = 0.52 * (1.0 - startup_t) + 0.08 * startup_t
				p["elbowBendR"] = 1.48 * (1.0 - startup_t) + 0.08 * startup_t; p["elbowBendL"] = 1.58 * (1.0 - startup_t) + 0.08 * startup_t
				p["hipPitchR"] = 0.36 * (1.0 - startup_t); p["kneeBendR"] = 0.48 * (1.0 - startup_t); p["hipSplayR"] = -0.22 * startup_t
				p["hipPitchL"] = -0.22 * (1.0 - startup_t); p["kneeBendL"] = 0.32 * (1.0 - startup_t); p["hipSplayL"] = -0.22 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = -0.26; p["pelvisOffsetZ"] = 0.18; p["pelvisPitch"] = -PI * 0.48; p["pelvisYaw"] = active_t * PI * 4.0
				p["pelvisRoll"] = 0.0; p["spinePitch"] = 0.0; p["spineYaw"] = 0.0; p["headPitch"] = 0.0; p["headYaw"] = 0.0
				p["armDownR"] = -1.35; p["armDownL"] = -1.35; p["armFwdR"] = 0.0; p["armFwdL"] = 0.0
				p["armCrossR"] = 0.08; p["armCrossL"] = 0.08; p["armRollR"] = 0.0; p["armRollL"] = 0.0; p["elbowBendR"] = 0.08; p["elbowBendL"] = 0.08
				p["hipPitchR"] = 0.0; p["kneeBendR"] = 0.0; p["hipSplayR"] = -0.22; p["hipPitchL"] = 0.0; p["kneeBendL"] = 0.0; p["hipSplayL"] = -0.22
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = -0.26 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = -PI * 0.48 * w + 0.08 * (1.0 - w)

		"low_sweep":
			p["pelvisOffsetY"] = -0.18 * (coil + extend); p["pelvisPitch"] = 0.22 * extend
			p["pelvisYaw"] = -0.3 * coil + 0.55 * extend; p["spinePitch"] = 0.25 * extend
			p["hipPitchR"] = -0.25 * coil + 1.12 * extend; p["hipSplayR"] = 0.25 * extend; p["kneeBendR"] = 0.75 * coil + 0.08 * extend
			p["hipPitchL"] = 0.65 * (coil + extend); p["kneeBendL"] = 1.15 * (coil + extend)
			p["armDownR"] = 0.95; p["armFwdR"] = -0.35 * extend; p["armDownL"] = 0.85; p["armFwdL"] = 0.65 * extend

		"nair_spin":
			var spin_angle: float = (-0.3 * startup_t) if is_startup else ((active_t * PI * 2.0) if is_active else ((1.0 - recovery_t) * 0.4))
			p["pelvisYaw"] = spin_angle; p["armDownR"] = 0.55; p["armDownL"] = 0.55; p["elbowBendR"] = 0.45; p["elbowBendL"] = 0.45
			p["hipPitchR"] = 0.68 * extend; p["kneeBendR"] = 0.18; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.65

		"fair_cleave", "dair_meteor":
			var is_dair: bool = (atk.pose_style == "dair_meteor")
			p["spinePitch"] = -0.32 * coil + (0.52 if is_dair else 0.35) * extend
			p["headPitch"] = -0.25 * coil + 0.28 * extend
			p["armDownR"] = 0.45 * coil + (1.25 if is_dair else 0.95) * extend + 1.0 * (1.0 - extend - coil); p["armDownL"] = p["armDownR"]
			p["armFwdR"] = 1.65 * coil + (0.65 if is_dair else 1.15) * extend; p["armFwdL"] = p["armFwdR"]
			p["armCrossR"] = 0.45 * (coil + extend); p["armCrossL"] = 0.45 * (coil + extend)
			p["elbowBendR"] = 0.55 * coil + 0.22 * extend + 1.1 * (1.0 - extend - coil); p["elbowBendL"] = p["elbowBendR"]
			p["hipPitchR"] = 0.55 * extend; p["kneeBendR"] = 0.85 * extend; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.45 * extend

		"fair_downward_punch":
			if is_startup:
				p["pelvisPitch"] = -0.15 * startup_t; p["pelvisYaw"] = -0.38 * startup_t; p["spinePitch"] = -0.22 * startup_t; p["spineYaw"] = -0.28 * startup_t
				p["headPitch"] = 0.22 * startup_t; p["headYaw"] = 0.18 * startup_t
				p["armDownR"] = 0.55 + 0.15 * startup_t; p["armFwdR"] = -0.55 * startup_t; p["armCrossR"] = -0.12 * startup_t; p["elbowBendR"] = 1.62 * startup_t + 0.45 * (1.0 - startup_t)
				p["armDownL"] = 0.85; p["armFwdL"] = 0.65 * startup_t; p["armCrossL"] = 0.18 * startup_t; p["elbowBendL"] = 0.72
				p["hipPitchR"] = 0.35 * startup_t; p["kneeBendR"] = 0.75 * startup_t; p["hipPitchL"] = -0.25 * startup_t; p["kneeBendL"] = 0.45 * startup_t
			elif is_active:
				p["pelvisOffsetY"] = 0.04; p["pelvisPitch"] = 0.38; p["pelvisYaw"] = 0.42; p["pelvisRoll"] = -0.06
				p["spinePitch"] = 0.46; p["spineYaw"] = 0.35; p["headPitch"] = 0.38; p["headYaw"] = -0.15
				p["armDownR"] = 1.05; p["armFwdR"] = 1.25; p["armCrossR"] = 0.18; p["armRollR"] = -0.38; p["elbowBendR"] = 0.06
				p["armDownL"] = 1.15; p["armFwdL"] = -0.32; p["armCrossL"] = 0.22; p["elbowBendL"] = 1.45
				p["hipPitchR"] = 0.48; p["kneeBendR"] = 0.65; p["hipPitchL"] = -0.42; p["kneeBendL"] = 0.38
			else:
				var rt: float = recovery_t
				p["pelvisPitch"] = 0.38 * (1.0 - rt); p["pelvisYaw"] = 0.42 * (1.0 - rt); p["spinePitch"] = 0.46 * (1.0 - rt)
				p["armDownR"] = 1.05 * (1.0 - rt) + 0.85 * rt; p["armFwdR"] = 1.25 * (1.0 - rt) + 0.35 * rt; p["elbowBendR"] = 0.06 * (1.0 - rt) + 1.15 * rt

		"divekick_down_air":
			if is_startup:
				p["pelvisOffsetY"] = 0.08 * startup_t; p["pelvisPitch"] = 0.28 * startup_t; p["spinePitch"] = 0.22 * startup_t; p["headPitch"] = 0.18 * startup_t
				p["hipPitchR"] = -0.12 * startup_t; p["kneeBendR"] = 0.58 * startup_t; p["hipPitchL"] = 0.95 * startup_t; p["kneeBendL"] = 1.25 * startup_t
				p["armDownR"] = 0.85 - 1.35 * startup_t; p["armFwdR"] = 0.45 * startup_t; p["armCrossR"] = 0.18; p["elbowBendR"] = 1.38
				p["armDownL"] = 1.12; p["armFwdL"] = 0.25; p["armCrossL"] = 0.58; p["elbowBendL"] = 1.48
			elif is_active:
				p["pelvisOffsetY"] = 0.14; p["pelvisPitch"] = 0.62; p["pelvisYaw"] = 0.18; p["pelvisRoll"] = 0.04
				p["spinePitch"] = 0.38; p["spineYaw"] = 0.12; p["headPitch"] = 0.36; p["headYaw"] = -0.16
				p["hipPitchR"] = 0.92; p["kneeBendR"] = 0.03; p["hipSplayR"] = 0.04
				p["hipPitchL"] = 1.52; p["kneeBendL"] = 1.64; p["hipSplayL"] = -0.06
				p["armDownR"] = -0.58; p["armFwdR"] = 0.72; p["armCrossR"] = 0.24; p["armRollR"] = -0.42; p["elbowBendR"] = 1.48
				p["armDownL"] = 1.14; p["armFwdL"] = 0.34; p["armCrossL"] = 0.68; p["armRollL"] = -0.32; p["elbowBendL"] = 1.55
			else:
				p["pelvisOffsetY"] = -0.32 * (1.0 - recovery_t); p["pelvisPitch"] = 0.42 * (1.0 - recovery_t); p["spinePitch"] = 0.36 * (1.0 - recovery_t)
				p["hipPitchR"] = 1.15 * (1.0 - recovery_t); p["kneeBendR"] = 1.35 * (1.0 - recovery_t); p["hipPitchL"] = 0.92 * (1.0 - recovery_t); p["kneeBendL"] = 1.25 * (1.0 - recovery_t)

		"bair_backkick":
			p["pelvisYaw"] = 0.35 * coil - 0.85 * extend; p["spinePitch"] = 0.28 * extend; p["headYaw"] = -0.65 * extend
			p["hipPitchL"] = 0.45 * coil - 1.05 * extend; p["kneeBendL"] = 0.85 * coil + 0.08 * extend
			p["hipPitchR"] = 0.35 * extend; p["kneeBendR"] = 0.55 * extend
			p["armDownR"] = 0.78; p["armFwdR"] = 0.55 * extend; p["armDownL"] = 0.78; p["armFwdL"] = -0.45 * extend

		"uair_flipkick":
			p["pelvisPitch"] = 0.25 * coil - 0.65 * extend; p["spinePitch"] = -0.25 * extend
			p["hipPitchR"] = -0.35 * coil + 1.55 * extend; p["kneeBendR"] = 0.85 * coil + 0.10 * extend
			p["hipPitchL"] = -0.35 * extend; p["kneeBendL"] = 0.75 * extend; p["armDownR"] = 0.65; p["armDownL"] = 0.65

		"beam_charge_thrust":
			if is_startup:
				p["pelvisYaw"] = -0.48 * startup_t; p["spineYaw"] = -0.35 * startup_t; p["spinePitch"] = 0.14 * startup_t; p["pelvisOffsetY"] = -0.06 * startup_t
				p["armDownR"] = 1.15; p["armFwdR"] = -0.28 * startup_t; p["armCrossR"] = -0.25 * startup_t; p["elbowBendR"] = 1.25
				p["armDownL"] = 1.10; p["armFwdL"] = 0.25 * startup_t; p["armCrossL"] = 0.75 * startup_t; p["elbowBendL"] = 1.35
				p["hipPitchR"] = -0.18 * startup_t; p["kneeBendR"] = 0.35 * startup_t; p["hipPitchL"] = 0.28 * startup_t; p["kneeBendL"] = 0.42 * startup_t
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisYaw"] = 0.12 * w; p["spineYaw"] = 0.08 * w; p["spinePitch"] = 0.24 * w; p["pelvisOffsetZ"] = 0.10 * w
				p["armDownR"] = 1.12; p["armFwdR"] = 1.38 * w + 0.35 * (1.0 - w); p["armCrossR"] = 0.42 * w + 0.35 * (1.0 - w); p["elbowBendR"] = 0.14 * w + 1.25 * (1.0 - w)
				p["armDownL"] = 1.12; p["armFwdL"] = 1.38 * w + 0.35 * (1.0 - w); p["armCrossL"] = 0.42 * w + 0.35 * (1.0 - w); p["elbowBendL"] = 0.14 * w + 1.25 * (1.0 - w)
				p["hipPitchR"] = 0.35 * w; p["kneeBendR"] = 0.48 * w; p["hipPitchL"] = -0.28 * w; p["kneeBendL"] = 0.18 * w

		"lunge_burst":
			p["pelvisPitch"] = 0.18 * extend; p["pelvisYaw"] = -0.35 * coil + 0.45 * extend; p["spinePitch"] = 0.28 * extend; p["spineYaw"] = 0.32 * extend
			p["armDownR"] = 1.05; p["armFwdR"] = -0.4 * coil + 1.42 * extend; p["armCrossR"] = 0.28 * extend; p["elbowBendR"] = 1.35 * coil + 0.15 * extend
			p["armDownL"] = 0.95; p["armFwdL"] = -0.35 * extend; p["elbowBendL"] = 0.95
			p["hipPitchR"] = 0.65 * extend; p["kneeBendR"] = 0.75 * extend; p["hipPitchL"] = -0.45 * extend; p["kneeBendL"] = 0.20

		"up_somersault_vortex":
			if is_startup:
				p["pelvisOffsetY"] = -0.14 * startup_t; p["pelvisPitch"] = 0.28 * startup_t; p["pelvisYaw"] = 0.15 * (1.0 - startup_t)
				p["spinePitch"] = 0.36 * startup_t; p["headPitch"] = 0.22 * startup_t
				p["hipPitchR"] = 0.36 + 1.12 * startup_t; p["kneeBendR"] = 0.48 + 1.18 * startup_t; p["hipSplayR"] = -0.15 * startup_t
				p["hipPitchL"] = -0.22 + 1.70 * startup_t; p["kneeBendL"] = 0.32 + 1.34 * startup_t; p["hipSplayL"] = -0.15 * startup_t
				p["armDownR"] = 1.08; p["armFwdR"] = 0.52 * startup_t; p["armCrossR"] = 0.22; p["elbowBendR"] = 1.48
				p["armDownL"] = 1.08; p["armFwdL"] = 0.52 * startup_t; p["armCrossL"] = 0.22; p["elbowBendL"] = 1.48
			elif is_active:
				p["pelvisOffsetY"] = 0.16; p["pelvisPitch"] = active_t * PI * 2.0; p["pelvisYaw"] = 0.08
				p["spinePitch"] = 0.54; p["headPitch"] = 0.26; p["headYaw"] = -0.08
				p["hipPitchR"] = 1.54; p["kneeBendR"] = 1.66; p["hipSplayR"] = -0.18
				p["hipPitchL"] = 1.54; p["kneeBendL"] = 1.66; p["hipSplayL"] = -0.18
				p["armDownR"] = 1.08; p["armFwdR"] = 0.52; p["armCrossR"] = 0.22; p["armRollR"] = -0.48; p["elbowBendR"] = 1.48
				p["armDownL"] = 1.08; p["armFwdL"] = 0.52; p["armCrossL"] = 0.22; p["armRollL"] = -0.48; p["elbowBendL"] = 1.48
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = 0.16 * w - 0.05 * (1.0 - w); p["pelvisPitch"] = 0.12 * w + 0.08 * (1.0 - w)

		"up_special_followup_punch":
			if is_startup:
				p["pelvisOffsetY"] = 0.14; p["pelvisYaw"] = -0.54 * startup_t; p["spineYaw"] = -0.46 * startup_t; p["spinePitch"] = -0.12 * startup_t; p["headYaw"] = 0.52 * startup_t
				p["armDownR"] = 1.04; p["armFwdR"] = -0.58 * startup_t; p["armCrossR"] = -0.22 * startup_t; p["elbowBendR"] = 1.52
				p["armDownL"] = 1.02; p["armFwdL"] = 1.15 * startup_t; p["armCrossL"] = 0.25; p["elbowBendL"] = 0.35
				p["hipPitchL"] = 0.72 * startup_t; p["kneeBendL"] = 1.12 * startup_t; p["hipPitchR"] = -0.35 * startup_t; p["kneeBendR"] = 0.45
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisOffsetY"] = 0.14 * w - 0.05 * (1.0 - w); p["pelvisOffsetZ"] = 0.16 * w
				p["pelvisYaw"] = 0.64 * w + 0.42 * (1.0 - w); p["spineYaw"] = 0.58 * w - 0.18 * (1.0 - w); p["spinePitch"] = 0.28 * w + 0.14 * (1.0 - w); p["headYaw"] = -0.72 * w - 0.24 * (1.0 - w)
				p["armDownR"] = 1.12 * w + 0.88 * (1.0 - w); p["armFwdR"] = 1.48 * w + 0.78 * (1.0 - w); p["armCrossR"] = 0.24 * w + 0.34 * (1.0 - w); p["armRollR"] = -0.35; p["elbowBendR"] = 0.06 * w + 1.48 * (1.0 - w)
				p["armDownL"] = 0.78 * w + 1.06 * (1.0 - w); p["armFwdL"] = -0.52 * w + 0.16 * (1.0 - w); p["armCrossL"] = -0.18 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.42 * w + 1.58 * (1.0 - w)

		"down_special_elbow_lift":
			if is_startup:
				p["pelvisOffsetY"] = -0.18 * startup_t; p["pelvisOffsetZ"] = 0.12 * startup_t; p["pelvisYaw"] = 0.42 + 0.44 * startup_t
				p["spineYaw"] = -0.18 + 0.56 * startup_t; p["spinePitch"] = 0.14 + 0.12 * startup_t; p["headYaw"] = -0.24 - 0.38 * startup_t
				p["hipPitchR"] = 0.36 + 0.36 * startup_t; p["kneeBendR"] = 0.48 + 0.48 * startup_t; p["hipPitchL"] = -0.22 - 0.36 * startup_t; p["kneeBendL"] = 0.24
				p["armDownR"] = 0.88 - 0.44 * startup_t; p["armFwdR"] = 0.78 + 0.64 * startup_t; p["armCrossR"] = 0.34 + 0.06 * startup_t; p["elbowBendR"] = 1.48 + 0.22 * startup_t
				p["armDownL"] = 1.05; p["armFwdL"] = 0.16 - 0.62 * startup_t; p["armCrossL"] = 0.52 - 0.74 * startup_t; p["elbowBendL"] = 1.48
			elif is_active:
				var lift_t: float = _smoothstep(0.58, 1.0, active_t)
				p["pelvisOffsetY"] = -0.18 + 0.08 * lift_t; p["pelvisOffsetZ"] = 0.18 - 0.06 * lift_t
				p["pelvisYaw"] = 0.86 - 0.24 * lift_t; p["spineYaw"] = 0.38 - 0.16 * lift_t; p["spinePitch"] = 0.26 - 0.12 * lift_t; p["spineRoll"] = 0.14 * (1.0 - lift_t)
				p["headYaw"] = -0.62 + 0.22 * lift_t; p["headPitch"] = -0.14
				p["hipPitchR"] = 0.72 - 0.14 * lift_t; p["kneeBendR"] = 0.96 - 0.12 * lift_t; p["hipSplayR"] = -0.12
				p["hipPitchL"] = -0.58 + 0.25 * lift_t; p["kneeBendL"] = 0.22 + 0.28 * lift_t; p["hipSplayL"] = -0.12
				p["armDownR"] = 0.44 - 0.14 * lift_t; p["armFwdR"] = 1.42 + 0.12 * lift_t; p["armCrossR"] = 0.40 - 0.18 * lift_t; p["armRollR"] = 0.32; p["elbowBendR"] = 1.70 - 0.15 * lift_t
				p["armDownL"] = 1.05; p["armFwdL"] = -0.46 + 0.22 * lift_t; p["armCrossL"] = -0.22 + 0.18 * lift_t; p["elbowBendL"] = 1.48
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = -0.10 * w - 0.05 * (1.0 - w); p["pelvisYaw"] = 0.62 * w + 0.42 * (1.0 - w)

		"down_special_turn_kick":
			if is_startup:
				var turn_ease: float = _smoothstep(0.0, 1.0, startup_t)
				var knee_chamber: float = sin(startup_t * PI * 0.75)
				p["pelvisOffsetY"] = -0.08 * (1.0 - turn_ease) - 0.06 * turn_ease; p["pelvisOffsetZ"] = 0.12 * turn_ease
				p["pelvisPitch"] = -0.38 * turn_ease; p["pelvisYaw"] = 0.76 * turn_ease; p["pelvisRoll"] = -0.52 * turn_ease
				p["spinePitch"] = -0.28 * turn_ease; p["spineYaw"] = 0.36 * turn_ease; p["spineRoll"] = -0.38 * turn_ease
				p["headPitch"] = 0.22 * turn_ease; p["headYaw"] = -0.48 * turn_ease
				p["hipPitchL"] = 1.38 * turn_ease; p["kneeBendL"] = 1.15 * knee_chamber * (1.0 - 0.65 * turn_ease) + 0.12 * turn_ease; p["hipSplayL"] = 0.38 * turn_ease
				p["hipPitchR"] = 0.58; p["kneeBendR"] = 0.84 + 0.42 * turn_ease; p["hipSplayR"] = -0.20 * turn_ease
				p["armDownR"] = 0.32 * (1.0 - turn_ease) + 0.72 * turn_ease; p["armFwdR"] = 1.35 * (1.0 - turn_ease) - 0.28 * turn_ease; p["armCrossR"] = 0.22 * (1.0 - turn_ease) - 0.52 * turn_ease; p["elbowBendR"] = 1.55 * (1.0 - turn_ease) + 0.22 * turn_ease
				p["armDownL"] = 1.02 * (1.0 - turn_ease) + 0.82 * turn_ease; p["armFwdL"] = -0.24 * (1.0 - turn_ease) + 0.95 * turn_ease; p["armCrossL"] = 0.38 * turn_ease; p["elbowBendL"] = 1.45 * (1.0 - turn_ease) + 1.18 * turn_ease
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				p["pelvisOffsetY"] = -0.06 * w - 0.05 * (1.0 - w); p["pelvisOffsetZ"] = 0.14 * w
				p["pelvisPitch"] = -0.38 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = 0.76 * w + 0.42 * (1.0 - w); p["pelvisRoll"] = -0.52 * w
				p["spinePitch"] = -0.28 * w + 0.14 * (1.0 - w); p["spineYaw"] = 0.36 * w - 0.18 * (1.0 - w); p["spineRoll"] = -0.38 * w
				p["headPitch"] = 0.22 * w + 0.06 * (1.0 - w); p["headYaw"] = -0.48 * w - 0.24 * (1.0 - w)
				p["hipPitchL"] = 1.52 * w - 0.22 * (1.0 - w); p["kneeBendL"] = 0.06 * w + 0.32 * (1.0 - w); p["hipSplayL"] = 0.42 * w - 0.05 * (1.0 - w)
				p["hipPitchR"] = 0.58 * w + 0.36 * (1.0 - w); p["kneeBendR"] = 1.26 * w + 0.48 * (1.0 - w); p["hipSplayR"] = -0.22 * w - 0.05 * (1.0 - w)
				p["armDownR"] = 0.72 * w + 0.88 * (1.0 - w); p["armFwdR"] = -0.28 * w + 0.78 * (1.0 - w); p["armCrossR"] = -0.52 * w + 0.34 * (1.0 - w); p["elbowBendR"] = 0.22 * w + 1.48 * (1.0 - w)
				p["armDownL"] = 0.82 * w + 1.06 * (1.0 - w); p["armFwdL"] = 0.95 * w + 0.16 * (1.0 - w); p["armCrossL"] = 0.38 * w + 0.52 * (1.0 - w); p["elbowBendL"] = 1.18 * w + 1.58 * (1.0 - w)

		"warp_ascend":
			p["pelvisOffsetY"] = -0.10 * coil + 0.14 * extend; p["spinePitch"] = -0.15 * extend
			p["armDownR"] = 1.05 * coil + 0.45 * extend; p["armFwdR"] = 0.95 * coil + 1.65 * extend; p["armCrossR"] = 0.55 * coil + 0.15 * extend; p["elbowBendR"] = 1.65 * coil + 0.25 * extend
			p["armDownL"] = 0.85; p["armFwdL"] = 0.45 * extend; p["elbowBendL"] = 1.05
			p["hipPitchR"] = 0.55 * extend; p["kneeBendR"] = 0.85 * extend; p["hipPitchL"] = 0.20 * extend; p["kneeBendL"] = 0.35 * extend

		"counter_stance", _:
			p["pelvisOffsetY"] = -0.08 * (coil + extend); p["spinePitch"] = -0.15 * coil + 0.22 * extend
			p["armDownR"] = 0.75 * coil + 0.95 * extend + 1.1 * (1.0 - extend - coil); p["armDownL"] = p["armDownR"]
			p["armFwdR"] = 1.35 * coil + 0.85 * extend; p["armFwdL"] = p["armFwdR"]
			p["armCrossR"] = 0.55 * coil - 0.25 * extend; p["armCrossL"] = p["armCrossR"]
			p["elbowBendR"] = 1.25 * coil + 0.35 * extend + 1.2 * (1.0 - extend - coil); p["elbowBendL"] = p["elbowBendR"]
			p["hipPitchR"] = 0.28 * extend; p["kneeBendR"] = 0.42 * extend; p["hipPitchL"] = 0.22 * extend; p["kneeBendL"] = 0.38 * extend
#endregion

#region Aplicación de Cuaterniones a Skeleton3D
static func apply_gogeta_pose(skeleton: Skeleton3D, bones: Dictionary, p: Dictionary, t: float, is_hover_dash: bool) -> void:
	if skeleton == null:
		return
	var b_pelvis: int = bones.get("Pelvis", -1)
	if b_pelvis != -1:
		skeleton.set_bone_pose_position(b_pelvis, Vector3(0.0, 0.90 + float(p["pelvisOffsetY"]), float(p["pelvisOffsetZ"])))
		skeleton.set_bone_pose_rotation(b_pelvis, _quat_euler_xyz(p["pelvisPitch"], p["pelvisYaw"], p["pelvisRoll"]))
	var b_spine: int = bones.get("Spine", -1)
	if b_spine != -1:
		skeleton.set_bone_pose_rotation(b_spine, _quat_euler_yxz(p["spinePitch"], p["spineYaw"], p["spineRoll"]))
	var b_head: int = bones.get("Head", -1)
	if b_head != -1:
		skeleton.set_bone_pose_rotation(b_head, _quat_euler_yxz(p["headPitch"], p["headYaw"], p["headRoll"]))
	var b_sh_r: int = bones.get("ShoulderR", -1)
	if b_sh_r != -1:
		skeleton.set_bone_pose_rotation(b_sh_r, _build_shoulder_char_quat(-1.0, p["armDownR"], p["armFwdR"], p["armCrossR"], p["armRollR"]))
	var b_el_r: int = bones.get("ElbowR", -1)
	if b_el_r != -1:
		skeleton.set_bone_pose_rotation(b_el_r, Quaternion(Vector3.UP, float(p["elbowBendR"])))
	var b_sh_l: int = bones.get("ShoulderL", -1)
	if b_sh_l != -1:
		skeleton.set_bone_pose_rotation(b_sh_l, _build_shoulder_char_quat(1.0, p["armDownL"], p["armFwdL"], p["armCrossL"], p["armRollL"]))
	var b_el_l: int = bones.get("ElbowL", -1)
	if b_el_l != -1:
		skeleton.set_bone_pose_rotation(b_el_l, Quaternion(Vector3.UP, -float(p["elbowBendL"])))
	var b_hip_r: int = bones.get("HipR", -1)
	if b_hip_r != -1:
		skeleton.set_bone_pose_rotation(b_hip_r, _quat_euler_xyz(-float(p["hipPitchR"]), 0.0, -float(p["hipSplayR"])))
	var b_knee_r: int = bones.get("KneeR", -1)
	if b_knee_r != -1:
		skeleton.set_bone_pose_rotation(b_knee_r, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendR"]))))
	var b_hip_l: int = bones.get("HipL", -1)
	if b_hip_l != -1:
		skeleton.set_bone_pose_rotation(b_hip_l, _quat_euler_xyz(-float(p["hipPitchL"]), 0.0, float(p["hipSplayL"])))
	var b_knee_l: int = bones.get("KneeL", -1)
	if b_knee_l != -1:
		skeleton.set_bone_pose_rotation(b_knee_l, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendL"]))))
	var b_sash: int = bones.get("Sash", -1)
	if b_sash != -1:
		var sash_wave_z: float = (sin(t * 11.5) * 0.14 + 0.12) if is_hover_dash else (sin(t * 5.2) * 0.08 + 0.06)
		var sash_pitch: float = (0.42 + cos(t * 11.0) * 0.10) if is_hover_dash else (-float(p["hipPitchR"]) * 0.55 + cos(t * 4.5) * 0.06)
		skeleton.set_bone_pose_rotation(b_sash, _quat_euler_xyz(sash_pitch, 0.0, -sash_wave_z))

static func apply_sans_pose(skeleton: Skeleton3D, bindings: Dictionary, model_root: Node3D, base_offset: Vector3, p: Dictionary) -> void:
	if skeleton == null:
		return
	for b_name in bindings.keys():
		var bd: Dictionary = bindings[b_name]
		skeleton.set_bone_pose_rotation(bd["idx"], bd["local_rest"])

	_set_sans_bone_char_quat(skeleton, bindings, "Root", _quat_euler_yxz(p["pelvisPitch"], p["pelvisYaw"], p["pelvisRoll"]))
	var q_spine := _quat_euler_yxz(float(p["spinePitch"]) * 0.5, float(p["spineYaw"]) * 0.5, float(p["spineRoll"]) * 0.5)
	_set_sans_bone_char_quat(skeleton, bindings, "Spine", q_spine)
	_set_sans_bone_char_quat(skeleton, bindings, "Spine_1", q_spine)
	_set_sans_bone_char_quat(skeleton, bindings, "Head", _quat_euler_yxz(p["headPitch"], p["headYaw"], p["headRoll"]))

	_set_sans_bone_char_quat(skeleton, bindings, "UpperarmR", _build_shoulder_char_quat(-1.0, p["armDownR"], p["armFwdR"], p["armCrossR"], p["armRollR"]))
	_set_sans_bone_char_quat(skeleton, bindings, "ForearmR", Quaternion(Vector3.UP, float(p["elbowBendR"])))

	_set_sans_bone_char_quat(skeleton, bindings, "UpperarmL", _build_shoulder_char_quat(1.0, p["armDownL"], p["armFwdL"], p["armCrossL"], p["armRollL"]))
	_set_sans_bone_char_quat(skeleton, bindings, "ForearmL", Quaternion(Vector3.UP, -float(p["elbowBendL"])))

	_set_sans_bone_char_quat(skeleton, bindings, "ThighR", _quat_euler_xyz(-float(p["hipPitchR"]), 0.0, -float(p["hipSplayR"])))
	_set_sans_bone_char_quat(skeleton, bindings, "CalfR", Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendR"]))))
	_set_sans_bone_char_quat(skeleton, bindings, "FootR", Quaternion(Vector3.RIGHT, (float(p["hipPitchR"]) - float(p["kneeBendR"])) * 0.45))

	_set_sans_bone_char_quat(skeleton, bindings, "ThighL", _quat_euler_xyz(-float(p["hipPitchL"]), 0.0, float(p["hipSplayL"])))
	_set_sans_bone_char_quat(skeleton, bindings, "CalfL", Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendL"]))))
	_set_sans_bone_char_quat(skeleton, bindings, "FootL", Quaternion(Vector3.RIGHT, (float(p["hipPitchL"]) - float(p["kneeBendL"])) * 0.45))

	if model_root != null:
		model_root.position = base_offset + Vector3(0.0, float(p["pelvisOffsetY"]), float(p["pelvisOffsetZ"]))

static func _set_sans_bone_char_quat(skeleton: Skeleton3D, bindings: Dictionary, bone_name: String, q_char: Quaternion) -> void:
	if not bindings.has(bone_name):
		return
	var bd: Dictionary = bindings[bone_name]
	var local_delta: Quaternion = bd["inv_char_rest"] * q_char * bd["char_rest"]
	skeleton.set_bone_pose_rotation(bd["idx"], (bd["local_rest"] * local_delta).normalized())
#endregion

#region Helpers Matemáticos de Cuaterniones
static func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t: float = clampf((x - edge0) / maxf(0.0001, edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

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
#endregion

