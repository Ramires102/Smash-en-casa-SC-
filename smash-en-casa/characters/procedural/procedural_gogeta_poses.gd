class_name ProceduralGogetaPoses
extends RefCounted

static func compute_attack_pose(atk: AttackData, p: Dictionary, attack_frame: int, attack_phase: String) -> void:
	var f: float = float(attack_frame)
	var s: float = float(maxi(1, atk.startup_frames))
	var a: float = float(maxi(1, atk.active_frames))
	var r: float = float(maxi(1, atk.recovery_frames))

	var is_startup: bool = (attack_phase == "startup")
	var is_active: bool = (attack_phase == "active")

	var startup_t: float = ProceduralPoseLibrary.smoothstep_val(0.0, 1.0, minf(1.0, f / s))
	var active_t: float = ProceduralPoseLibrary.smoothstep_val(0.0, 1.0, minf(1.0, (f - s) / a))
	var recovery_t: float = ProceduralPoseLibrary.smoothstep_val(0.0, 1.0, minf(1.0, (f - s - a) / r))

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
				var rise: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.7, active_t) if is_active else 1.0
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
				var flip_t: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.88, recovery_t)
				var tuck: float = 1.0 - ProceduralPoseLibrary.smoothstep_val(0.75, 1.0, recovery_t)
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
			p["pelvisOffsetY"] = 0.20 * w - 0.05 * (1.0 - w)
			p["pelvisPitch"] = -0.24 * w + 0.08 * (1.0 - w); p["pelvisYaw"] = -0.26 * w + 0.42 * (1.0 - w)
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
				var slash_p: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.85, active_t)
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

		"side_roundhouse":
			p["pelvisYaw"] = -0.45 * coil + 0.65 * extend; p["pelvisRoll"] = 0.28 * extend; p["spinePitch"] = -0.24 * extend; p["spineYaw"] = 0.35 * extend
			p["hipPitchR"] = -0.35 * coil + 1.35 * extend; p["hipSplayR"] = 0.35 * extend; p["kneeBendR"] = 0.95 * coil + 0.08 * extend
			p["hipPitchL"] = -0.15 * extend; p["kneeBendL"] = 0.25; p["armDownR"] = 0.85; p["armFwdR"] = -0.25 * extend; p["elbowBendR"] = 0.85

		"uppercut_rising":
			p["pelvisOffsetY"] = -0.12 * coil + 0.16 * extend
			p["pelvisYaw"] = -0.35 * coil + 0.48 * extend
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

		"nair_spin":
			var spin_angle: float = (-0.3 * startup_t) if is_startup else ((active_t * PI * 2.0) if is_active else ((1.0 - recovery_t) * 0.4))
			p["pelvisYaw"] = spin_angle
			p["armDownR"] = 0.55; p["armDownL"] = 0.55; p["elbowBendR"] = 0.45; p["elbowBendL"] = 0.45
			p["hipPitchR"] = 0.68 * extend; p["kneeBendR"] = 0.18; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.65

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
			p["hipPitchL"] = -0.35 * extend; p["kneeBendL"] = 0.75 * extend
			p["armDownR"] = 0.65; p["armDownL"] = 0.65

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
				var lift_t: float = ProceduralPoseLibrary.smoothstep_val(0.58, 1.0, active_t)
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
				var turn_ease: float = ProceduralPoseLibrary.smoothstep_val(0.0, 1.0, startup_t)
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

		_:
			p["pelvisYaw"] = -0.35 * coil + 0.45 * extend; p["spineYaw"] = -0.28 * coil + 0.42 * extend; p["spinePitch"] = -0.08 * coil + 0.22 * extend
			p["armDownR"] = 1.12 - 0.18 * extend; p["armFwdR"] = -0.35 * coil + 1.38 * extend + 0.35 * (1.0 - extend - coil)
			p["armCrossR"] = 0.25 * extend; p["elbowBendR"] = 1.45 * coil + 0.12 * extend + 1.25 * (1.0 - extend - coil)

