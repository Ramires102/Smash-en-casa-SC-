class_name ProceduralPoseLibrary
extends RefCounted

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

static func apply_sans_pocket_arms(p: Dictionary) -> void:
	var sp_pitch: float = float(p["spinePitch"])
	var sp_yaw: float = float(p["spineYaw"])
	p["armDownR"] = 1.08 - sp_pitch * 0.20
	p["armFwdR"] = 0.56 + sp_pitch * 0.48 - sp_yaw * 0.35
	p["armCrossR"] = 0.28
	p["armRollR"] = 1.38
	p["elbowBendR"] = 1.02 + sp_pitch * 0.18
	p["armDownL"] = 1.08 - sp_pitch * 0.20
	p["armFwdL"] = 0.56 + sp_pitch * 0.48 + sp_yaw * 0.35
	p["armCrossL"] = 0.28
	p["armRollL"] = 1.38
	p["elbowBendL"] = 1.02 + sp_pitch * 0.18

static func smoothstep_val(edge0: float, edge1: float, x: float) -> float:
	var t: float = clampf((x - edge0) / maxf(0.0001, edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

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
	attack_phase: String,
	character: Node
) -> void:
	var breath_speed: float = 2.6 if is_gogeta else 2.1
	var breath_freq: float = breath_speed * 1.25
	var breath: float = sin(t * breath_freq)
	var breath2: float = cos(t * breath_freq * 2.0)

	p["pelvisOffsetY"] = -0.05 if is_gogeta else 0.0
	p["pelvisOffsetZ"] = 0.0
	p["pelvisPitch"] = 0.08 if is_gogeta else -0.10
	p["pelvisYaw"] = 0.42 if is_gogeta else 0.16
	p["pelvisRoll"] = 0.0
	p["spinePitch"] = 0.14 if is_gogeta else -0.06
	p["spineYaw"] = -0.18 if is_gogeta else -0.06
	p["spineRoll"] = 0.0
	p["headPitch"] = 0.06 if is_gogeta else 0.08
	p["headYaw"] = -0.24 if is_gogeta else -0.12
	p["headRoll"] = 0.0

	if is_gogeta:
		p["armDownR"] = 0.88; p["armFwdR"] = 0.78; p["armCrossR"] = 0.34; p["armRollR"] = -0.62; p["elbowBendR"] = 1.48
		p["armDownL"] = 1.06; p["armFwdL"] = 0.16; p["armCrossL"] = 0.52; p["armRollL"] = -0.55; p["elbowBendL"] = 1.58
		p["hipPitchR"] = 0.36; p["hipSplayR"] = -0.05; p["kneeBendR"] = 0.48
		p["hipPitchL"] = -0.22; p["hipSplayL"] = -0.05; p["kneeBendL"] = 0.32
	else:
		p["hipPitchR"] = 0.12; p["hipSplayR"] = 0.08; p["kneeBendR"] = 0.18
		p["hipPitchL"] = -0.04; p["hipSplayL"] = 0.08; p["kneeBendL"] = 0.14
		apply_sans_pocket_arms(p)

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
		p["hipPitchR"] = 0.72; p["kneeBendR"] = 0.95; p["hipPitchL"] = 0.28; p["kneeBendL"] = 0.45
		if is_sans:
			apply_sans_pocket_arms(p)
		else:
			p["armDownR"] = 0.78; p["armFwdR"] = 0.25; p["armCrossR"] = 0.20; p["elbowBendR"] = 1.15
			p["armDownL"] = 0.78; p["armFwdL"] = 0.25; p["armCrossL"] = 0.20; p["elbowBendL"] = 1.15
		if is_double_jumping:
			p["pelvisPitch"] = minf(PI * 2.0, t * 13.5)
			p["hipPitchL"] = 0.75; p["kneeBendL"] = 1.05
		return

	if active_state_name == "Fall":
		var sway: float = sin(t * 6.0) * 0.06
		p["pelvisYaw"] = 0.1; p["spinePitch"] = 0.14; p["headPitch"] = 0.15
		p["hipPitchR"] = 0.38; p["kneeBendR"] = 0.62; p["hipPitchL"] = 0.12; p["kneeBendL"] = 0.35
		if is_sans:
			apply_sans_pocket_arms(p)
		else:
			p["armDownR"] = 0.68 + sway; p["armFwdR"] = 0.15; p["armCrossR"] = 0.12; p["elbowBendR"] = 0.92
			p["armDownL"] = 0.68 - sway; p["armFwdL"] = 0.15; p["armCrossL"] = 0.12; p["elbowBendL"] = 0.92
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
		p["pelvisPitch"] = 0.08
		p["pelvisYaw"] = -sin_p * 0.18
		p["pelvisRoll"] = cos_p * 0.04
		p["spinePitch"] = 0.22 * 0.65
		p["spineYaw"] = sin_p * 0.24
		p["headPitch"] = -float(p["spinePitch"]) * 0.55
		p["headYaw"] = -sin_p * 0.08
		p["hipPitchR"] = sin_p * 0.78 + 0.08
		p["kneeBendR"] = maxf(0.08, (-cos_p * 0.5 + 0.5) * 0.95)
		p["hipSplayR"] = 0.0
		p["hipPitchL"] = -sin_p * 0.78 + 0.08
		p["kneeBendL"] = maxf(0.08, (cos_p * 0.5 + 0.5) * 0.95)
		p["hipSplayL"] = 0.0
		apply_sans_pocket_arms(p)
		return

	if active_state_name == "Attack" and active_attack != null:
		if is_sans:
			ProceduralSansPoses.compute_attack_pose(active_attack, p, attack_frame, attack_phase, character)
		else:
			ProceduralGogetaPoses.compute_attack_pose(active_attack, p, attack_frame, attack_phase)
		return

	var bounce: float = breath * 0.024
	p["pelvisOffsetY"] += bounce
	p["spinePitch"] += breath * 0.032
	p["headPitch"] -= breath * 0.025
	var knee_flex: float = maxf(0.0, -breath) * 0.065
	p["hipPitchR"] += knee_flex * 0.65
	p["kneeBendR"] += knee_flex
	p["hipPitchL"] += knee_flex * 0.55
	p["kneeBendL"] += knee_flex * 0.85
	if is_sans:
		apply_sans_pocket_arms(p)
	else:
		p["armDownR"] += breath * 0.035
		p["armFwdR"] += breath * 0.04
		p["armDownL"] += breath * 0.03
		p["elbowBendR"] += breath2 * 0.035
		p["elbowBendL"] -= breath2 * 0.035

