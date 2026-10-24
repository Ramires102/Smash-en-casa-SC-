class_name ProceduralRigSolver
extends RefCounted

static func quat_euler_xyz(rx: float, ry: float, rz: float) -> Quaternion:
	return Quaternion(Vector3.RIGHT, rx) * Quaternion(Vector3.UP, ry) * Quaternion(Vector3.BACK, rz)

static func quat_euler_yxz(rx: float, ry: float, rz: float) -> Quaternion:
	return Quaternion(Vector3.UP, ry) * Quaternion(Vector3.RIGHT, rx) * Quaternion(Vector3.BACK, rz)

static func build_shoulder_char_quat(side_sign: float, arm_down: float, arm_fwd: float, arm_cross: float, arm_roll: float) -> Quaternion:
	var q1 := Quaternion(Vector3.RIGHT, arm_roll)
	var q2 := Quaternion(Vector3.BACK, -side_sign * arm_down)
	var q3 := Quaternion(Vector3.RIGHT, -arm_fwd)
	var q4 := Quaternion(Vector3.UP, -side_sign * arm_cross)
	return q4 * q3 * q2 * q1

static func get_relative_basis(node: Node3D, ancestor: Node3D) -> Basis:
	var b := Basis.IDENTITY
	var cur: Node = node
	while cur != null and cur != ancestor:
		if cur is Node3D:
			b = (cur as Node3D).transform.basis.orthonormalized() * b
		cur = cur.get_parent()
	return b.orthonormalized()

static func init_gogeta_rig(skeleton: Skeleton3D) -> Dictionary:
	var bones := {}
	if skeleton == null:
		return bones
	for b_name in ["Pelvis", "Spine", "Head", "ShoulderR", "ElbowR", "ShoulderL", "ElbowL", "HipR", "KneeR", "HipL", "KneeL", "Sash"]:
		bones[b_name] = skeleton.find_bone(b_name)
	return bones

static func bind_skeleton_char_space(skel: Skeleton3D, root_node: Node3D) -> Dictionary:
	var bindings := {}
	if skel == null or root_node == null:
		return bindings
	var skel_to_root_quat: Quaternion = get_relative_basis(skel, root_node).get_rotation_quaternion().normalized()
	for idx in range(skel.get_bone_count()):
		var b_name: String = skel.get_bone_name(idx)
		var local_rest_quat: Quaternion = skel.get_bone_rest(idx).basis.orthonormalized().get_rotation_quaternion().normalized()
		var bone_skel_rest_quat: Quaternion = skel.get_bone_global_rest(idx).basis.orthonormalized().get_rotation_quaternion().normalized()
		var char_rest_quat: Quaternion = (skel_to_root_quat * bone_skel_rest_quat).normalized()
		var entry := {
			"idx": idx,
			"local_rest": local_rest_quat,
			"char_rest": char_rest_quat,
			"inv_char_rest": char_rest_quat.inverse()
		}
		bindings[b_name] = entry
		var sanitized: String = b_name.replace(" ", "_").replace(".", "")
		if sanitized != b_name:
			bindings[sanitized] = entry
	return bindings

static func init_sans_rig(skeleton: Skeleton3D, model_root: Node3D, prev_hand_attach: BoneAttachment3D) -> Dictionary:
	var result := {
		"sans_bindings": {},
		"gb_bindings": {},
		"gb_armature": null,
		"gb_skeleton": null,
		"gb_mesh": null,
		"sans_bone_mesh": null,
		"sans_hand_bone_attach": null,
		"sans_hand_bone_mesh": null
	}
	if skeleton == null or model_root == null:
		return result

	_extract_sans_meshes_and_materials(model_root, result)
	result["sans_bindings"] = bind_skeleton_char_space(skeleton, model_root)

	var bone_mesh: MeshInstance3D = result["sans_bone_mesh"]
	if bone_mesh != null:
		var hand_l_idx: int = skeleton.find_bone("Hand.L")
		if hand_l_idx == -1:
			hand_l_idx = skeleton.find_bone("HandL")
		if hand_l_idx != -1:
			if prev_hand_attach != null and is_instance_valid(prev_hand_attach):
				prev_hand_attach.queue_free()
			var attach := BoneAttachment3D.new()
			attach.name = "SansHandBoneAttachment"
			attach.bone_idx = hand_l_idx
			skeleton.add_child(attach)
			var hand_bone := bone_mesh.duplicate() as MeshInstance3D
			hand_bone.name = "SansHandheldBone"
			hand_bone.visible = false
			attach.add_child(hand_bone)
			result["sans_hand_bone_attach"] = attach
			result["sans_hand_bone_mesh"] = hand_bone

	return result

static func _extract_sans_meshes_and_materials(node: Node, out_info: Dictionary) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var lower_name: String = mi.name.to_lower().replace(" ", "_")
			if lower_name == "sans":
				mi.visible = true
				_ensure_sans_material(mi)
			elif lower_name == "gaster_blaster":
				out_info["gb_mesh"] = mi
				var gb_skel := mi.get_parent() as Skeleton3D
				out_info["gb_skeleton"] = gb_skel
				if gb_skel:
					var gb_arm := gb_skel.get_parent() as Node3D
					out_info["gb_armature"] = gb_arm
					if gb_arm:
						out_info["gb_bindings"] = bind_skeleton_char_space(gb_skel, gb_arm)
				_ensure_sans_props_material(mi, true)
				mi.visible = false
			elif lower_name == "bone":
				out_info["sans_bone_mesh"] = mi
				_ensure_sans_props_material(mi, false)
				mi.visible = false
			else:
				mi.visible = false
		_extract_sans_meshes_and_materials(child, out_info)

static func _ensure_sans_material(mi: MeshInstance3D) -> void:
	if not ResourceLoader.exists("res://assets/models/sans/sans texture.png"):
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = load("res://assets/models/sans/sans texture.png") as Texture2D
	mat.roughness = 0.58
	mat.metallic = 0.1
	if ResourceLoader.exists("res://assets/models/sans/sans emission.png"):
		mat.emission_enabled = true
		mat.emission = Color.WHITE
		mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		mat.emission_energy_multiplier = 0.85
		mat.emission_texture = load("res://assets/models/sans/sans emission.png") as Texture2D
	mi.material_override = mat

static func _ensure_sans_props_material(mi: MeshInstance3D, with_emission: bool) -> void:
	if not ResourceLoader.exists("res://assets/models/sans/sans props texture.png"):
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = load("res://assets/models/sans/sans props texture.png") as Texture2D
	mat.roughness = 0.42 if with_emission else 0.35
	mat.metallic = 0.12 if with_emission else 0.08
	if with_emission and ResourceLoader.exists("res://assets/models/sans/sans props emission.png"):
		mat.emission_enabled = true
		mat.emission = Color("#38bdf8")
		mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		mat.emission_energy_multiplier = 1.25
		mat.emission_texture = load("res://assets/models/sans/sans props emission.png") as Texture2D
	mi.material_override = mat

static func apply_gogeta_pose(skeleton: Skeleton3D, gogeta_bones: Dictionary, p: Dictionary, t: float, active_state_name: String) -> void:
	if skeleton == null:
		return
	var b_pelvis: int = gogeta_bones.get("Pelvis", -1)
	if b_pelvis != -1:
		skeleton.set_bone_pose_position(b_pelvis, Vector3(0.0, 0.90 + float(p["pelvisOffsetY"]), float(p["pelvisOffsetZ"])))
		skeleton.set_bone_pose_rotation(b_pelvis, quat_euler_xyz(p["pelvisPitch"], p["pelvisYaw"], p["pelvisRoll"]))
	var b_spine: int = gogeta_bones.get("Spine", -1)
	if b_spine != -1:
		skeleton.set_bone_pose_rotation(b_spine, quat_euler_yxz(p["spinePitch"], p["spineYaw"], p["spineRoll"]))
	var b_head: int = gogeta_bones.get("Head", -1)
	if b_head != -1:
		skeleton.set_bone_pose_rotation(b_head, quat_euler_yxz(p["headPitch"], p["headYaw"], p["headRoll"]))
	var b_sh_r: int = gogeta_bones.get("ShoulderR", -1)
	if b_sh_r != -1:
		skeleton.set_bone_pose_rotation(b_sh_r, build_shoulder_char_quat(-1.0, p["armDownR"], p["armFwdR"], p["armCrossR"], p["armRollR"]))
	var b_el_r: int = gogeta_bones.get("ElbowR", -1)
	if b_el_r != -1:
		skeleton.set_bone_pose_rotation(b_el_r, Quaternion(Vector3.UP, float(p["elbowBendR"])))
	var b_sh_l: int = gogeta_bones.get("ShoulderL", -1)
	if b_sh_l != -1:
		skeleton.set_bone_pose_rotation(b_sh_l, build_shoulder_char_quat(1.0, p["armDownL"], p["armFwdL"], p["armCrossL"], p["armRollL"]))
	var b_el_l: int = gogeta_bones.get("ElbowL", -1)
	if b_el_l != -1:
		skeleton.set_bone_pose_rotation(b_el_l, Quaternion(Vector3.UP, -float(p["elbowBendL"])))
	var b_hip_r: int = gogeta_bones.get("HipR", -1)
	if b_hip_r != -1:
		skeleton.set_bone_pose_rotation(b_hip_r, quat_euler_xyz(-float(p["hipPitchR"]), 0.0, -float(p["hipSplayR"])))
	var b_knee_r: int = gogeta_bones.get("KneeR", -1)
	if b_knee_r != -1:
		skeleton.set_bone_pose_rotation(b_knee_r, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendR"]))))
	var b_hip_l: int = gogeta_bones.get("HipL", -1)
	if b_hip_l != -1:
		skeleton.set_bone_pose_rotation(b_hip_l, quat_euler_xyz(-float(p["hipPitchL"]), 0.0, float(p["hipSplayL"])))
	var b_knee_l: int = gogeta_bones.get("KneeL", -1)
	if b_knee_l != -1:
		skeleton.set_bone_pose_rotation(b_knee_l, Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendL"]))))
	var b_sash: int = gogeta_bones.get("Sash", -1)
	if b_sash != -1:
		var is_hover_dash: bool = (active_state_name == "Run")
		var sash_wave_z: float = (sin(t * 11.5) * 0.14 + 0.12) if is_hover_dash else (sin(t * 5.2) * 0.08 + 0.06)
		var sash_pitch: float = (0.42 + cos(t * 11.0) * 0.10) if is_hover_dash else (-float(p["hipPitchR"]) * 0.55 + cos(t * 4.5) * 0.06)
		skeleton.set_bone_pose_rotation(b_sash, quat_euler_xyz(sash_pitch, 0.0, -sash_wave_z))

static func set_bone_char_quat(skeleton: Skeleton3D, bindings: Dictionary, bone_name: String, q_char: Quaternion) -> void:
	if not bindings.has(bone_name) or skeleton == null:
		return
	var bd: Dictionary = bindings[bone_name]
	var local_delta: Quaternion = bd["inv_char_rest"] * q_char * bd["char_rest"]
	skeleton.set_bone_pose_rotation(bd["idx"], (bd["local_rest"] * local_delta).normalized())

static func set_bone_scale(skeleton: Skeleton3D, bindings: Dictionary, bone_name: String, sc: float) -> void:
	if not bindings.has(bone_name) or skeleton == null:
		return
	var bd: Dictionary = bindings[bone_name]
	skeleton.set_bone_pose_scale(bd["idx"], Vector3(sc, sc, sc))

static func apply_sans_pose(
	skeleton: Skeleton3D,
	bindings: Dictionary,
	model_root: Node3D,
	character: Node,
	p: Dictionary,
	active_state_name: String,
	active_attack: AttackData,
	attack_phase: String
) -> void:
	if skeleton == null:
		return
	for b_name in bindings.keys():
		var bd: Dictionary = bindings[b_name]
		skeleton.set_bone_pose_rotation(bd["idx"], bd["local_rest"])

	set_bone_char_quat(skeleton, bindings, "Root", quat_euler_yxz(p["pelvisPitch"], p["pelvisYaw"], p["pelvisRoll"]))
	var q_spine := quat_euler_yxz(float(p["spinePitch"]) * 0.5, float(p["spineYaw"]) * 0.5, float(p["spineRoll"]) * 0.5)
	set_bone_char_quat(skeleton, bindings, "Spine", q_spine)
	set_bone_char_quat(skeleton, bindings, "Spine_1", q_spine)
	set_bone_char_quat(skeleton, bindings, "Head", quat_euler_yxz(p["headPitch"], p["headYaw"], p["headRoll"]))

	set_bone_char_quat(skeleton, bindings, "UpperarmR", build_shoulder_char_quat(-1.0, p["armDownR"], p["armFwdR"], p["armCrossR"], p["armRollR"]))
	set_bone_char_quat(skeleton, bindings, "ForearmR", Quaternion(Vector3.UP, float(p["elbowBendR"])))

	set_bone_char_quat(skeleton, bindings, "UpperarmL", build_shoulder_char_quat(1.0, p["armDownL"], p["armFwdL"], p["armCrossL"], p["armRollL"]))
	set_bone_char_quat(skeleton, bindings, "ForearmL", Quaternion(Vector3.UP, -float(p["elbowBendL"])))

	set_bone_scale(skeleton, bindings, "HandR", 0.28 if float(p["armRollR"]) > 1.25 else 1.0)
	set_bone_scale(skeleton, bindings, "HandL", 0.28 if float(p["armRollL"]) > 1.25 else 1.0)

	var atk_style: String = active_attack.pose_style if (active_state_name == "Attack" and active_attack != null) else ""
	var is_jab_bone: bool = atk_style in ["sans_jab_bone_1", "sans_jab_bone_2", "sans_jab_bone_3"]
	var is_parry_shrug: bool = (atk_style == "sans_parry_shrug" and attack_phase in ["startup", "active"])

	if is_jab_bone:
		set_bone_char_quat(skeleton, bindings, "HandL", Quaternion(Vector3.UP, 0.25))
		var grip_q := Quaternion(Vector3.BACK, -1.25)
		set_bone_char_quat(skeleton, bindings, "FingersL", grip_q)
		set_bone_char_quat(skeleton, bindings, "MiddleL", grip_q)
		set_bone_char_quat(skeleton, bindings, "Fingers1L", Quaternion(Vector3.BACK, -1.05))
		set_bone_char_quat(skeleton, bindings, "Middle1L", Quaternion(Vector3.BACK, -1.05))
		set_bone_char_quat(skeleton, bindings, "ThumbL", Quaternion(Vector3.RIGHT, 0.75))
		set_bone_char_quat(skeleton, bindings, "Thumb1L", Quaternion(Vector3.RIGHT, 0.55))
	elif is_parry_shrug:
		set_bone_char_quat(skeleton, bindings, "HandR", Quaternion(Vector3.BACK, -0.24))
		set_bone_char_quat(skeleton, bindings, "HandL", Quaternion(Vector3.BACK, 0.24))
	elif float(p["armRollL"]) <= 1.25:
		set_bone_char_quat(skeleton, bindings, "HandL", Quaternion(Vector3.UP, 1.05))

	set_bone_char_quat(skeleton, bindings, "ThighR", quat_euler_xyz(-float(p["hipPitchR"]), 0.0, -float(p["hipSplayR"])))
	set_bone_char_quat(skeleton, bindings, "CalfR", Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendR"]))))
	set_bone_char_quat(skeleton, bindings, "FootR", Quaternion(Vector3.RIGHT, (float(p["hipPitchR"]) - float(p["kneeBendR"])) * 0.45))

	set_bone_char_quat(skeleton, bindings, "ThighL", quat_euler_xyz(-float(p["hipPitchL"]), 0.0, float(p["hipSplayL"])))
	set_bone_char_quat(skeleton, bindings, "CalfL", Quaternion(Vector3.RIGHT, maxf(0.0, float(p["kneeBendL"]))))
	set_bone_char_quat(skeleton, bindings, "FootL", Quaternion(Vector3.RIGHT, (float(p["hipPitchL"]) - float(p["kneeBendL"])) * 0.45))

	if model_root != null and character and "character_data" in character and character.character_data:
		var base_off: Vector3 = character.character_data.model_offset
		model_root.position = base_off + Vector3(0.0, float(p["pelvisOffsetY"]), float(p["pelvisOffsetZ"]))

