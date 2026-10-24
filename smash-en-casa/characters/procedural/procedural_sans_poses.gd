class_name ProceduralSansPoses
extends RefCounted

static func compute_attack_pose(atk: AttackData, p: Dictionary, attack_frame: int, attack_phase: String, character: Node) -> void:
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
		"sans_jab_bone_1":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			if is_startup:
				p["pelvisYaw"] = 0.22 * startup_t; p["spineYaw"] = 0.26 * startup_t; p["spinePitch"] = 0.06 * startup_t
				p["headYaw"] = -0.22 * startup_t
				p["armDownL"] = 0.92; p["armFwdL"] = 0.72 * startup_t; p["armCrossL"] = 0.58 * startup_t
				p["armRollL"] = 0.15; p["elbowBendL"] = 0.72 * (1.0 - 0.4 * startup_t)
				p["hipPitchL"] = 0.18 * startup_t; p["kneeBendL"] = 0.25 * startup_t
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				var swing: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.72, active_t) if is_active else 1.0
				p["pelvisOffsetZ"] = 0.08 * w
				p["pelvisYaw"] = (0.22 - 0.64 * swing) * w + 0.16 * (1.0 - w)
				p["spineYaw"] = (0.26 - 0.68 * swing) * w - 0.06 * (1.0 - w)
				p["spinePitch"] = 0.14 * w - 0.06 * (1.0 - w)
				p["headYaw"] = 0.32 * swing * w - 0.12 * (1.0 - w)
				p["armDownL"] = 0.92 * w + 1.08 * (1.0 - w)
				p["armFwdL"] = (1.12 + 0.16 * swing) * w + 0.56 * (1.0 - w)
				p["armCrossL"] = (0.58 - 0.96 * swing) * w + 0.28 * (1.0 - w)
				p["armRollL"] = (-0.35 * swing) * w + 1.38 * (1.0 - w)
				p["elbowBendL"] = 0.12 * w + 1.02 * (1.0 - w)
				p["hipPitchL"] = 0.28 * w - 0.04 * (1.0 - w); p["kneeBendL"] = 0.34 * w + 0.14 * (1.0 - w)
				p["hipPitchR"] = -0.14 * w + 0.12 * (1.0 - w); p["kneeBendR"] = 0.18

		"sans_jab_bone_2":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			if is_startup:
				p["pelvisYaw"] = -0.32 * startup_t; p["spineYaw"] = -0.36 * startup_t; p["spinePitch"] = 0.12 * startup_t
				p["armDownL"] = 0.96; p["armFwdL"] = 0.68; p["armCrossL"] = -0.42 * startup_t
				p["armRollL"] = -0.45 * startup_t; p["elbowBendL"] = 0.38
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				var swing: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.72, active_t) if is_active else 1.0
				p["pelvisOffsetZ"] = 0.10 * w
				p["pelvisYaw"] = (-0.32 + 0.68 * swing) * w + 0.16 * (1.0 - w)
				p["spineYaw"] = (-0.36 + 0.72 * swing) * w - 0.06 * (1.0 - w)
				p["spinePitch"] = (0.12 - 0.18 * swing) * w - 0.06 * (1.0 - w)
				p["headYaw"] = -0.34 * swing * w - 0.12 * (1.0 - w)
				p["armDownL"] = (0.96 - 0.24 * swing) * w + 1.08 * (1.0 - w)
				p["armFwdL"] = (1.16 + 0.22 * swing) * w + 0.56 * (1.0 - w)
				p["armCrossL"] = (-0.42 + 0.96 * swing) * w + 0.28 * (1.0 - w)
				p["armRollL"] = 0.45 * w + 1.38 * (1.0 - w)
				p["elbowBendL"] = 0.14 * w + 1.02 * (1.0 - w)
				p["hipPitchL"] = 0.32 * w - 0.04 * (1.0 - w); p["kneeBendL"] = 0.38 * w + 0.14 * (1.0 - w)

		"sans_jab_bone_3":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			if is_startup:
				p["pelvisOffsetY"] = 0.04 * startup_t
				p["pelvisPitch"] = -0.18 * startup_t; p["spinePitch"] = -0.26 * startup_t
				p["pelvisYaw"] = -0.24 * startup_t; p["spineYaw"] = -0.28 * startup_t
				p["headPitch"] = -0.18 * startup_t
				p["armDownL"] = 1.08 - 0.86 * startup_t; p["armFwdL"] = 0.56 + 1.18 * startup_t
				p["armCrossL"] = 0.18 * startup_t; p["armRollL"] = 0.0; p["elbowBendL"] = 0.28
				p["hipPitchL"] = 0.36 * startup_t; p["kneeBendL"] = 0.48 * startup_t
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				var slam: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.65, active_t) if is_active else 1.0
				p["pelvisOffsetY"] = -0.10 * slam * w; p["pelvisOffsetZ"] = 0.14 * slam * w
				p["pelvisPitch"] = (-0.18 + 0.44 * slam) * w - 0.10 * (1.0 - w)
				p["spinePitch"] = (-0.26 + 0.58 * slam) * w - 0.06 * (1.0 - w)
				p["pelvisYaw"] = (-0.24 + 0.52 * slam) * w + 0.16 * (1.0 - w)
				p["spineYaw"] = (-0.28 + 0.56 * slam) * w - 0.06 * (1.0 - w)
				p["headPitch"] = 0.22 * slam * w + 0.08 * (1.0 - w)
				p["armDownL"] = (0.22 + 1.06 * slam) * w + 1.08 * (1.0 - w)
				p["armFwdL"] = (1.74 - 0.68 * slam) * w + 0.56 * (1.0 - w)
				p["armCrossL"] = 0.24 * w + 0.28 * (1.0 - w)
				p["armRollL"] = 0.0 * w + 1.38 * (1.0 - w); p["elbowBendL"] = 0.10 * w + 1.02 * (1.0 - w)
				p["hipPitchL"] = 0.48 * w - 0.04 * (1.0 - w); p["kneeBendL"] = 0.58 * w + 0.14 * (1.0 - w)
				p["hipPitchR"] = -0.26 * w + 0.12 * (1.0 - w); p["kneeBendR"] = 0.22

		"sans_stomp_bone":
			if is_startup:
				var lift: float = ProceduralPoseLibrary.smoothstep_val(0.0, 1.0, startup_t)
				p["pelvisOffsetY"] = 0.04 * lift; p["pelvisPitch"] = -0.16 * lift; p["pelvisYaw"] = 0.20 * lift; p["pelvisRoll"] = -0.10 * lift
				p["spinePitch"] = -0.14 * lift; p["headPitch"] = 0.16 * lift
				p["hipPitchL"] = 1.24 * lift; p["kneeBendL"] = 1.38 * lift; p["hipSplayL"] = 0.14 * lift
				p["hipPitchR"] = 0.08; p["kneeBendR"] = 0.22
				ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			elif is_active:
				var stomp_down: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.28, active_t)
				p["pelvisOffsetY"] = 0.04 * (1.0 - stomp_down) - 0.11 * stomp_down; p["pelvisOffsetZ"] = 0.10 * stomp_down
				p["pelvisPitch"] = -0.16 * (1.0 - stomp_down) + 0.08 * stomp_down; p["pelvisYaw"] = 0.20 - 0.12 * stomp_down
				p["pelvisRoll"] = -0.10 * (1.0 - stomp_down); p["spinePitch"] = -0.14 * (1.0 - stomp_down) + 0.12 * stomp_down
				p["headPitch"] = 0.18
				p["hipPitchL"] = 1.24 * (1.0 - stomp_down) + 0.44 * stomp_down; p["kneeBendL"] = 1.38 * (1.0 - stomp_down) + 0.46 * stomp_down; p["hipSplayL"] = 0.10
				p["hipPitchR"] = 0.08 * (1.0 - stomp_down) - 0.22 * stomp_down; p["kneeBendR"] = 0.28
				ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisOffsetY"] = -0.11 * w; p["pelvisOffsetZ"] = 0.10 * w
				p["pelvisPitch"] = 0.08 * w - 0.10 * (1.0 - w); p["spinePitch"] = 0.12 * w - 0.06 * (1.0 - w)
				p["hipPitchL"] = 0.44 * w - 0.04 * (1.0 - w); p["kneeBendL"] = 0.46 * w + 0.14 * (1.0 - w)
				p["hipPitchR"] = -0.22 * w + 0.12 * (1.0 - w); p["kneeBendR"] = 0.28 * w + 0.18 * (1.0 - w)
				ProceduralPoseLibrary.apply_sans_pocket_arms(p)

		"sans_telekinesis_warning":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			if is_startup:
				var prep: float = ProceduralPoseLibrary.smoothstep_val(0.68, 1.0, startup_t)
				p["pelvisPitch"] = -0.12 - 0.04 * prep; p["pelvisYaw"] = 0.18 + 0.14 * prep
				p["spinePitch"] = -0.08; p["headPitch"] = 0.10; p["headYaw"] = -0.16 - 0.14 * prep
				p["armDownL"] = 1.08 - 0.26 * prep; p["armFwdL"] = 0.56 + 0.62 * prep
				p["armCrossL"] = 0.28 * (1.0 - prep) + 0.08 * prep; p["armRollL"] = 1.38 * (1.0 - prep)
				p["elbowBendL"] = 1.02 * (1.0 - prep) + 0.22 * prep
			elif is_active:
				p["pelvisPitch"] = -0.06; p["pelvisYaw"] = 0.28; p["spinePitch"] = 0.08; p["spineYaw"] = 0.22
				p["headPitch"] = 0.06; p["headYaw"] = -0.34
				p["armDownL"] = 0.78; p["armFwdL"] = 1.48; p["armCrossL"] = 0.08; p["armRollL"] = 0.0; p["elbowBendL"] = 0.08
			else:
				var w: float = 1.0 - recovery_t
				p["pelvisYaw"] = 0.28 * w + 0.16 * (1.0 - w)
				p["armDownL"] = 0.78 * w + 1.08 * (1.0 - w); p["armFwdL"] = 1.48 * w + 0.56 * (1.0 - w)
				p["armCrossL"] = 0.08 * w + 0.28 * (1.0 - w); p["armRollL"] = 1.38 * (1.0 - w); p["elbowBendL"] = 0.08 * w + 1.02 * (1.0 - w)

		"sans_telekinesis_hold":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			var hover_pulse: float = sin(f * 0.20) * 0.05
			p["pelvisPitch"] = -0.08; p["pelvisYaw"] = 0.26; p["spinePitch"] = 0.06; p["spineYaw"] = 0.20
			p["headPitch"] = 0.06; p["headYaw"] = -0.32
			p["armDownL"] = 0.74 + hover_pulse; p["armFwdL"] = 1.46; p["armCrossL"] = 0.10; p["armRollL"] = 0.0; p["elbowBendL"] = 0.12

		"sans_telekinesis_throw":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			var facing: float = character.get_facing_direction() if (character and character.has_method("get_facing_direction")) else 1.0
			var raw_dir: Vector2 = character.telekinesis_throw_dir if (character and "telekinesis_throw_dir" in character) else Vector2(facing, 0.0)
			var local_fwd: float = raw_dir.x * facing
			var up_y: float = raw_dir.y
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			var whip: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.45, active_t) if is_active else (0.0 if is_startup else 1.0)
			var target_down: float = clampf(0.76 - up_y * 0.68, 0.12, 1.42)
			var target_fwd: float = 0.92 if local_fwd < -0.25 else (1.52 if local_fwd > 0.25 else (1.58 if up_y > 0.25 else 1.18))
			var target_cross: float = 0.82 if local_fwd < -0.25 else (-0.28 if local_fwd > 0.25 else 0.05)
			p["pelvisYaw"] = (0.26 + (-0.38 if local_fwd < -0.25 else 0.24) * whip) * w + 0.16 * (1.0 - w)
			p["spineYaw"] = (0.20 + (-0.42 if local_fwd < -0.25 else 0.26) * whip) * w - 0.06 * (1.0 - w)
			p["spinePitch"] = (-up_y * 0.24 * whip) * w - 0.06 * (1.0 - w)
			p["headPitch"] = (-up_y * 0.20 * whip) * w + 0.08 * (1.0 - w)
			p["headYaw"] = -float(p["spineYaw"]) * 0.85
			p["armDownL"] = (0.74 * (1.0 - whip) + target_down * whip) * w + 1.08 * (1.0 - w)
			p["armFwdL"] = (1.46 * (1.0 - whip) + target_fwd * whip) * w + 0.56 * (1.0 - w)
			p["armCrossL"] = (0.10 * (1.0 - whip) + target_cross * whip) * w + 0.28 * (1.0 - w)
			p["armRollL"] = 0.0 * w + 1.38 * (1.0 - w)
			p["elbowBendL"] = (0.14 * (1.0 - whip) + 0.06 * whip) * w + 1.02 * (1.0 - w)

		"sans_parry_shrug":
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			p["pelvisOffsetY"] = -0.05 * w; p["pelvisPitch"] = -0.14 * w - 0.10 * (1.0 - w); p["pelvisYaw"] = 0.16 * (1.0 - w)
			p["spinePitch"] = -0.12 * w - 0.06 * (1.0 - w); p["spineYaw"] = -0.06 * (1.0 - w)
			p["headPitch"] = 0.10 * w + 0.08 * (1.0 - w); p["headYaw"] = -0.12 * (1.0 - w); p["headRoll"] = 0.20 * w
			p["armDownR"] = 0.92 * w + 1.08 * (1.0 - w); p["armFwdR"] = 0.18 * w + 0.56 * (1.0 - w); p["armCrossR"] = -0.32 * w + 0.28 * (1.0 - w); p["armRollR"] = -0.68 * w + 1.38 * (1.0 - w); p["elbowBendR"] = 1.42 * w + 1.02 * (1.0 - w)
			p["armDownL"] = 0.92 * w + 1.08 * (1.0 - w); p["armFwdL"] = 0.18 * w + 0.56 * (1.0 - w); p["armCrossL"] = -0.32 * w + 0.28 * (1.0 - w); p["armRollL"] = -0.68 * w + 1.38 * (1.0 - w); p["elbowBendL"] = 1.42 * w + 1.02 * (1.0 - w)
			p["hipPitchR"] = 0.16 * w + 0.12 * (1.0 - w); p["hipSplayR"] = 0.14 * w + 0.08 * (1.0 - w); p["kneeBendR"] = 0.24 * w + 0.18 * (1.0 - w)
			p["hipPitchL"] = 0.16 * w - 0.04 * (1.0 - w); p["hipSplayL"] = 0.14 * w + 0.08 * (1.0 - w); p["kneeBendL"] = 0.24 * w + 0.14 * (1.0 - w)

		"sans_parry_counter_impale":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			var w: float = startup_t if is_startup else (1.0 if is_active else (1.0 - recovery_t))
			var slam: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.25, active_t) if is_active else (0.0 if is_startup else 1.0)
			p["pelvisOffsetY"] = -0.06 * w; p["pelvisPitch"] = (-0.12 + 0.24 * slam) * w - 0.10 * (1.0 - w); p["pelvisYaw"] = 0.30 * w + 0.16 * (1.0 - w)
			p["spinePitch"] = (-0.14 + 0.32 * slam) * w - 0.06 * (1.0 - w); p["spineYaw"] = 0.24 * w - 0.06 * (1.0 - w)
			p["headPitch"] = (0.14 * slam) * w + 0.08 * (1.0 - w); p["headYaw"] = -0.36 * w - 0.12 * (1.0 - w)
			p["armDownL"] = (0.35 + 0.72 * slam) * w + 1.08 * (1.0 - w); p["armFwdL"] = (1.62 - 0.32 * slam) * w + 0.56 * (1.0 - w)
			p["armCrossL"] = 0.12 * w + 0.28 * (1.0 - w); p["armRollL"] = 1.38 * (1.0 - w); p["elbowBendL"] = 0.10 * w + 1.02 * (1.0 - w)
			p["hipPitchL"] = 0.34 * w - 0.04 * (1.0 - w); p["kneeBendL"] = 0.42 * w + 0.14 * (1.0 - w)

		"side_roundhouse":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			p["pelvisYaw"] = -0.2 * coil + 0.35 * extend; p["spinePitch"] = -0.18 * extend
			p["armDownL"] = 0.92; p["armFwdL"] = 1.15 * extend + 0.35 * coil; p["armCrossL"] = 0.18; p["armRollL"] = 0.0; p["elbowBendL"] = 0.25

		"uppercut_rising":
			p["pelvisOffsetY"] = -0.12 * coil + 0.16 * extend; p["pelvisYaw"] = -0.35 * coil + 0.48 * extend
			p["spinePitch"] = 0.25 * coil - 0.28 * extend; p["spineYaw"] = 0.42 * extend; p["headPitch"] = -0.32 * extend
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			p["armDownL"] = 1.15 * coil + 0.32 * extend + 1.08 * (1.0 - extend - coil)
			p["armFwdL"] = -0.15 * coil + 1.72 * extend + 0.56 * (1.0 - extend - coil)
			p["armCrossL"] = 0.18 * extend; p["armRollL"] = 0.0; p["elbowBendL"] = 0.25 * extend + 0.95 * (1.0 - extend)
			p["hipPitchR"] = 0.45 * coil + 0.55 * extend; p["kneeBendR"] = 0.65 * coil + 0.72 * extend
			p["hipPitchL"] = 0.45 * coil - 0.15 * extend; p["kneeBendL"] = 0.65 * coil + 0.15 * extend

		"nair_spin":
			p["pelvisYaw"] = (-0.3 * startup_t) if is_startup else ((active_t * PI * 2.0) if is_active else ((1.0 - recovery_t) * 0.4))
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			p["hipPitchR"] = 0.68 * extend; p["kneeBendR"] = 0.18; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.65

		"fair_cleave", "dair_meteor":
			var is_dair: bool = (atk.pose_style == "dair_meteor")
			p["spinePitch"] = -0.32 * coil + (0.52 if is_dair else 0.35) * extend; p["headPitch"] = -0.25 * coil + 0.28 * extend
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			p["armDownL"] = 0.45 * coil + (1.25 if is_dair else 0.95) * extend + 1.08 * (1.0 - extend - coil)
			p["armFwdL"] = 1.65 * coil + (0.65 if is_dair else 1.15) * extend + 0.56 * (1.0 - extend - coil)
			p["armCrossL"] = 0.35 * (coil + extend); p["armRollL"] = 0.0; p["elbowBendL"] = 0.55 * coil + 0.22 * extend + 1.02 * (1.0 - extend - coil)
			p["hipPitchR"] = 0.55 * extend; p["kneeBendR"] = 0.85 * extend; p["hipPitchL"] = -0.25 * extend; p["kneeBendL"] = 0.45 * extend

		"bair_backkick":
			p["pelvisYaw"] = 0.35 * coil - 0.85 * extend; p["spinePitch"] = 0.28 * extend; p["headYaw"] = -0.65 * extend
			p["hipPitchL"] = 0.45 * coil - 1.05 * extend; p["kneeBendL"] = 0.85 * coil + 0.08 * extend
			p["hipPitchR"] = 0.35 * extend; p["kneeBendR"] = 0.55 * extend
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)

		"uair_flipkick":
			p["pelvisPitch"] = 0.25 * coil - 0.65 * extend; p["spinePitch"] = -0.25 * extend
			p["hipPitchR"] = -0.35 * coil + 1.55 * extend; p["kneeBendR"] = 0.85 * coil + 0.10 * extend
			p["hipPitchL"] = -0.35 * extend; p["kneeBendL"] = 0.75 * extend
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)

		"beam_charge_thrust":
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			if is_startup:
				var summon_t: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.75, startup_t)
				p["pelvisPitch"] = -0.12 - 0.06 * summon_t; p["pelvisYaw"] = 0.22 + 0.16 * summon_t
				p["spinePitch"] = -0.08 - 0.08 * summon_t; p["spineYaw"] = 0.14 * summon_t
				p["headPitch"] = 0.12 * summon_t; p["headYaw"] = -0.32 * summon_t
				p["armDownL"] = 1.08 - 0.32 * summon_t; p["armFwdL"] = 0.56 + 0.78 * summon_t
				p["armCrossL"] = 0.28 * (1.0 - summon_t) + 0.12 * summon_t; p["armRollL"] = 1.38 * (1.0 - summon_t); p["elbowBendL"] = 1.02 * (1.0 - summon_t) + 0.18 * summon_t
			else:
				var w: float = 1.0 if is_active else (1.0 - recovery_t)
				var recoil: float = sin(active_t * PI * 4.0) * 0.04 if is_active else 0.0
				p["pelvisOffsetZ"] = -0.06 * w; p["pelvisPitch"] = -0.16 * w - 0.10 * (1.0 - w); p["pelvisYaw"] = 0.38 * w + 0.16 * (1.0 - w)
				p["spinePitch"] = -0.14 * w - 0.06 * (1.0 - w); p["spineYaw"] = 0.26 * w - 0.06 * (1.0 - w)
				p["headPitch"] = 0.14 * w + 0.08 * (1.0 - w); p["headYaw"] = -0.44 * w - 0.12 * (1.0 - w)
				p["armDownL"] = (0.72 + recoil) * w + 1.08 * (1.0 - w); p["armFwdL"] = (1.46 + recoil) * w + 0.56 * (1.0 - w)
				p["armCrossL"] = 0.10 * w + 0.28 * (1.0 - w); p["armRollL"] = 1.38 * (1.0 - w); p["elbowBendL"] = 0.08 * w + 1.02 * (1.0 - w)

		"warp_ascend", _:
			p["pelvisOffsetY"] = -0.10 * coil + 0.14 * extend; p["spinePitch"] = -0.15 * extend
			ProceduralPoseLibrary.apply_sans_pocket_arms(p)
			p["hipPitchR"] = 0.55 * extend; p["kneeBendR"] = 0.85 * extend; p["hipPitchL"] = 0.20 * extend; p["kneeBendL"] = 0.35 * extend

