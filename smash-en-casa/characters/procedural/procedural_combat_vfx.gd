class_name ProceduralCombatVfx
extends RefCounted

var vfx_group: Node3D = null
var slash_arc_mesh: MeshInstance3D
var beam_group: Node3D
var bone_pillar_group: Node3D
var stardust_orb_mesh: MeshInstance3D
var charge_ring_mesh: MeshInstance3D
var spiral_vortex_group: Node3D
var ki_knee_cone_group: Node3D
var somersault_vortex_group: Node3D
var elbow_slash_beam_group: Node3D
var kick_crescent_arc_group: Node3D
var divekick_vfx_group: Node3D
var telekinesis_box_group: Node3D
var telekinesis_box_mats: Array[StandardMaterial3D] = []

var gb_armature: Node3D = null
var gb_skeleton: Skeleton3D = null
var gb_mesh: MeshInstance3D = null
var gb_bindings: Dictionary = {}
var sans_bone_mesh: MeshInstance3D = null
var sans_hand_bone_mesh: MeshInstance3D = null

func build_nodes(character: Node) -> Node3D:
	if character == null:
		return null
	var humanoid: Node3D = character.get_node_or_null("Humanoid") as Node3D
	if humanoid == null:
		return null
	var old_vfx: Node = humanoid.get_node_or_null("CombatVfxGroup")
	if old_vfx:
		if gb_armature and gb_armature.get_parent() == old_vfx:
			old_vfx.remove_child(gb_armature)
		if sans_bone_mesh and sans_bone_mesh.get_parent() == old_vfx:
			old_vfx.remove_child(sans_bone_mesh)
		old_vfx.name = "OldCombatVfxGroup"
		humanoid.remove_child(old_vfx)
		old_vfx.queue_free()

	vfx_group = Node3D.new()
	vfx_group.name = "CombatVfxGroup"
	vfx_group.position = Vector3(0.0, -0.9, 0.0)
	humanoid.add_child(vfx_group)

	slash_arc_mesh = ProceduralVfxMeshes.create_torus_mesh(0.68, 0.08, Color(0.98, 0.75, 0.14, 0.88))
	charge_ring_mesh = ProceduralVfxMeshes.create_torus_mesh(0.45, 0.025, Color(0.98, 0.75, 0.14, 0.75))
	stardust_orb_mesh = ProceduralVfxMeshes.create_sphere_mesh(0.65, Color(0.98, 0.75, 0.14, 0.82))
	beam_group = ProceduralVfxMeshes.create_beam_group()
	bone_pillar_group = ProceduralVfxMeshes.create_bone_pillar_group()
	spiral_vortex_group = ProceduralVfxMeshes.create_spiral_vortex_group()
	ki_knee_cone_group = ProceduralVfxMeshes.create_ki_knee_cone_group()
	somersault_vortex_group = ProceduralVfxMeshes.create_somersault_vortex_group()
	elbow_slash_beam_group = ProceduralVfxMeshes.create_elbow_slash_beam_group()
	kick_crescent_arc_group = ProceduralVfxMeshes.create_kick_crescent_arc_group()
	divekick_vfx_group = ProceduralVfxMeshes.create_divekick_vfx_group()
	telekinesis_box_group = ProceduralVfxMeshes.create_telekinesis_box_group(telekinesis_box_mats)

	for node in [
		slash_arc_mesh, charge_ring_mesh, stardust_orb_mesh, beam_group, bone_pillar_group,
		spiral_vortex_group, ki_knee_cone_group, somersault_vortex_group,
		elbow_slash_beam_group, kick_crescent_arc_group, divekick_vfx_group, telekinesis_box_group
	]:
		node.visible = false
		vfx_group.add_child(node)

	if gb_armature and is_instance_valid(gb_armature):
		if gb_armature.get_parent():
			gb_armature.get_parent().remove_child(gb_armature)
		gb_armature.visible = false
		vfx_group.add_child(gb_armature)

	if sans_bone_mesh and is_instance_valid(sans_bone_mesh):
		if sans_bone_mesh.get_parent():
			sans_bone_mesh.get_parent().remove_child(sans_bone_mesh)
		sans_bone_mesh.visible = false
		vfx_group.add_child(sans_bone_mesh)

	return vfx_group

func hide_all() -> void:
	if gb_mesh and is_instance_valid(gb_mesh):
		gb_mesh.visible = false
	if gb_armature and is_instance_valid(gb_armature):
		gb_armature.visible = false
	if sans_bone_mesh and is_instance_valid(sans_bone_mesh):
		sans_bone_mesh.visible = false
	if sans_hand_bone_mesh and is_instance_valid(sans_hand_bone_mesh):
		sans_hand_bone_mesh.visible = false
	if vfx_group == null:
		return
	for child in vfx_group.get_children():
		if child is Node3D:
			child.visible = false

func update_vfx(
	elapsed: float,
	is_gogeta: bool,
	is_sans: bool,
	active_state_name: String,
	active_attack: AttackData,
	attack_frame: int,
	attack_phase: String
) -> void:
	if vfx_group == null:
		return
	hide_all()

	if is_gogeta and active_state_name == "Run":
		charge_ring_mesh.visible = true
		charge_ring_mesh.position = Vector3(0.0, 0.95, -0.22)
		var pulse: float = 0.65 + sin(elapsed * 18.0) * 0.12
		charge_ring_mesh.scale = Vector3.ONE * pulse
		charge_ring_mesh.rotation = Vector3(0.35, 0.0, elapsed * 12.0)
		return

	if active_state_name != "Attack" or active_attack == null:
		return

	var off_x: float = active_attack.hitbox_offset.x
	var off_y: float = active_attack.hitbox_offset.y + 0.95
	var rad: float = active_attack.hitbox_radius if active_attack.hitbox_radius > 0.0 else 0.75

	if is_sans:
		if active_attack.pose_style in ["sans_jab_bone_1", "sans_jab_bone_2", "sans_jab_bone_3"]:
			_update_sans_handheld_bone(elapsed, active_attack, attack_frame, attack_phase)
			return
		if active_attack.vfx_type == "diagonal_ground_bone":
			_update_sans_diagonal_ground_bone(active_attack, attack_frame, attack_phase)
			return
		if active_attack.vfx_type == "gaster_beam" and gb_armature and gb_skeleton and gb_mesh:
			_update_sans_gaster_blaster(elapsed, off_y, active_attack, attack_frame, attack_phase)
			return
		if active_attack.vfx_type == "telekinesis_warning_box" or active_attack.is_telekinesis_hold or active_attack.is_telekinesis_throw:
			_update_sans_telekinesis_vfx(elapsed, active_attack, attack_frame, attack_phase)
			return
		if active_attack.vfx_type == "parry_shrug_aura" or active_attack.vfx_type == "parry_counter_bone":
			_update_sans_parry_vfx(elapsed, active_attack, attack_frame, attack_phase)
			return

	if attack_phase == "startup":
		charge_ring_mesh.visible = true
		charge_ring_mesh.position = Vector3(0.0, off_y, 0.25)
		var s: float = 0.35 + sin(elapsed * 25.0) * 0.12
		charge_ring_mesh.scale = Vector3.ONE * s
		charge_ring_mesh.rotation = Vector3(0.0, 0.0, elapsed * 10.0)
		return

	if attack_phase != "active":
		return

	match active_attack.vfx_type:
		"spiral_vortex":
			spiral_vortex_group.visible = true
			spiral_vortex_group.position = Vector3(0.0, 0.68, 0.12)
			spiral_vortex_group.rotation = Vector3(0.0, 0.0, elapsed * 32.0)
		"somersault_vortex_blue":
			somersault_vortex_group.visible = true
			somersault_vortex_group.position = Vector3(0.0, 1.08, 0.08)
			somersault_vortex_group.rotation = Vector3(0.0, PI * 0.5, -elapsed * 26.0)
			somersault_vortex_group.scale = Vector3.ONE * (1.0 + sin(elapsed * 38.0) * 0.06)
		"diagonal_elbow_slash_blue":
			elbow_slash_beam_group.visible = true
			elbow_slash_beam_group.position = Vector3(-0.08, 0.96, 0.16)
			elbow_slash_beam_group.rotation = Vector3(-0.82, 0.0, 0.10)
			var p: float = 1.0 + sin(elapsed * 36.0) * 0.12
			elbow_slash_beam_group.scale = Vector3(p, 1.05, p)
		"crescent_kick_arc_blue":
			kick_crescent_arc_group.visible = true
			kick_crescent_arc_group.position = Vector3(0.0, 1.18, 0.24)
			kick_crescent_arc_group.rotation = Vector3(0.12, PI * 0.5, 0.35 - elapsed * 6.5)
			var p: float = 1.0 + sin(elapsed * 30.0) * 0.06
			kick_crescent_arc_group.scale = Vector3(p, p, 1.15)
		"ki_divekick_trail":
			divekick_vfx_group.visible = true
			divekick_vfx_group.position = Vector3(-0.16, 0.32, 0.52)
			divekick_vfx_group.rotation = Vector3(0.72, 0.0, -0.06)
			var p: float = 1.0 + sin(elapsed * 38.0) * 0.08
			divekick_vfx_group.scale = Vector3(p, p, 1.18)
		"ki_knee_cone":
			ki_knee_cone_group.visible = true
			ki_knee_cone_group.position = Vector3(0.0, 1.12, 0.55)
			ki_knee_cone_group.rotation = Vector3(0.0, 0.0, elapsed * 26.0)
			var p: float = 1.0 + sin(elapsed * 40.0) * 0.10
			ki_knee_cone_group.scale = Vector3(p, p, 1.15)
		"ki_knee_rising":
			ki_knee_cone_group.visible = true
			ki_knee_cone_group.position = Vector3(0.0, 1.38, 0.42)
			ki_knee_cone_group.rotation = Vector3(-0.85, 0.0, elapsed * 28.0)
			var p: float = 1.0 + sin(elapsed * 42.0) * 0.12
			ki_knee_cone_group.scale = Vector3(p, p, 1.25)
		"axe_crescent_blue":
			slash_arc_mesh.visible = true
			ProceduralVfxMeshes.set_mesh_color(slash_arc_mesh, Color(0.22, 0.74, 0.97, 0.90))
			slash_arc_mesh.position = Vector3(0.0, 1.25, 0.78)
			slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, -0.35 - elapsed * 14.0)
			slash_arc_mesh.scale = Vector3(1.48, 1.48, 1.85)
		"downward_punch_arc":
			slash_arc_mesh.visible = true
			ProceduralVfxMeshes.set_mesh_color(slash_arc_mesh, Color(0.98, 0.75, 0.14, 0.90))
			slash_arc_mesh.position = Vector3(0.0, off_y, off_x * 0.85)
			slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, -1.05 - elapsed * 6.0)
			slash_arc_mesh.scale = Vector3(rad * 1.35, rad * 1.35, rad * 1.45)
		"ki_beam", "gaster_beam":
			beam_group.visible = true
			beam_group.position = Vector3(0.0, off_y, 0.65)
			beam_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
			var p: float = 1.0 + sin(elapsed * 45.0) * 0.18
			beam_group.scale = Vector3(1.0, p, p)
		"bone_spike":
			bone_pillar_group.visible = true
			bone_pillar_group.position = Vector3(0.0, maxf(0.2, off_y - 0.35), off_x)
			bone_pillar_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
		"stardust_orb", "gravity_slam", "teleport_burst":
			stardust_orb_mesh.visible = true
			stardust_orb_mesh.position = Vector3(0.0, off_y, off_x)
			stardust_orb_mesh.scale = Vector3.ONE * (rad * (0.85 + sin(elapsed * 30.0) * 0.15))
			ProceduralVfxMeshes.set_mesh_color(stardust_orb_mesh, Color(0.15, 0.39, 0.92, 0.82) if active_attack.vfx_type == "gravity_slam" else Color(0.98, 0.75, 0.14, 0.82))
		_:
			slash_arc_mesh.visible = true
			ProceduralVfxMeshes.set_mesh_color(slash_arc_mesh, Color(0.98, 0.75, 0.14, 0.88) if active_attack.vfx_type == "slash_gold" else Color(0.22, 0.74, 0.97, 0.88))
			slash_arc_mesh.position = Vector3(0.0, off_y, off_x * 0.75)
			slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, deg_to_rad(active_attack.angle_degrees - 45.0) + elapsed * 8.0)
			slash_arc_mesh.scale = Vector3.ONE * (rad * 1.15)

func _update_sans_handheld_bone(elapsed: float, active_attack: AttackData, attack_frame: int, attack_phase: String) -> void:
	var s: float = float(maxi(1, active_attack.startup_frames))
	var a: float = float(maxi(1, active_attack.active_frames))
	var r: float = float(maxi(1, active_attack.recovery_frames))
	var f: float = float(attack_frame)

	if sans_hand_bone_mesh != null and is_instance_valid(sans_hand_bone_mesh):
		sans_hand_bone_mesh.visible = true
		var pop: float = 1.0
		if attack_phase == "startup" and active_attack.pose_style == "sans_jab_bone_1":
			pop = ProceduralPoseLibrary.smoothstep_val(0.0, 0.65, f / s)
		elif attack_phase == "recovery":
			pop = 1.0 - ProceduralPoseLibrary.smoothstep_val(0.35, 1.0, (f - s - a) / r)
		sans_hand_bone_mesh.scale = Vector3.ONE * (0.60 * maxf(0.01, pop))
		if active_attack.pose_style == "sans_jab_bone_3":
			sans_hand_bone_mesh.position = Vector3(0.015, 0.045, 0.01)
			sans_hand_bone_mesh.rotation = Vector3(0.35, 0.20, 0.15)
		else:
			sans_hand_bone_mesh.position = Vector3(0.015, 0.042, 0.0)
			sans_hand_bone_mesh.rotation = Vector3(0.15, 0.0, PI * 0.5)

	if attack_phase == "active":
		slash_arc_mesh.visible = true
		ProceduralVfxMeshes.set_mesh_color(slash_arc_mesh, Color("#38bdf8") if active_attack.pose_style == "sans_jab_bone_3" else Color("#bae6fd"))
		if active_attack.pose_style == "sans_jab_bone_1":
			slash_arc_mesh.position = Vector3(0.0, 1.08, 0.82)
			slash_arc_mesh.rotation = Vector3(1.38, 0.15, elapsed * 14.0)
			slash_arc_mesh.scale = Vector3(1.12, 1.12, 1.25)
		elif active_attack.pose_style == "sans_jab_bone_2":
			slash_arc_mesh.position = Vector3(0.0, 1.12, 0.86)
			slash_arc_mesh.rotation = Vector3(-1.32, -0.18, -elapsed * 14.0)
			slash_arc_mesh.scale = Vector3(1.18, 1.18, 1.32)
		else:
			slash_arc_mesh.position = Vector3(0.0, 1.06, 0.92)
			slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, -0.45 - elapsed * 16.0)
			slash_arc_mesh.scale = Vector3(1.36, 1.36, 1.62)

func _update_sans_diagonal_ground_bone(active_attack: AttackData, attack_frame: int, attack_phase: String) -> void:
	if sans_bone_mesh == null or not is_instance_valid(sans_bone_mesh) or attack_phase == "startup":
		return
	var s: float = float(maxi(1, active_attack.startup_frames))
	var a: float = float(maxi(1, active_attack.active_frames))
	var r: float = float(maxi(1, active_attack.recovery_frames))
	var f: float = float(attack_frame)
	var emerge: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.35, (f - s) / a) if attack_phase == "active" else (1.0 - ProceduralPoseLibrary.smoothstep_val(0.0, 0.85, (f - s - a) / r))
	if emerge <= 0.02:
		return
	sans_bone_mesh.visible = true
	var tilt_pitch: float = 0.62
	var slide: float = (1.0 - emerge) * 0.62
	sans_bone_mesh.position = Vector3(0.0, 0.50 - slide * cos(tilt_pitch), 1.06 - slide * sin(tilt_pitch))
	sans_bone_mesh.rotation = Vector3(-PI * 0.5 + tilt_pitch, 0.0, 0.0)
	sans_bone_mesh.scale = Vector3(3.0, 3.0, 3.3 * emerge)

	if attack_phase == "active" and f <= s + 5.0:
		charge_ring_mesh.visible = true
		ProceduralVfxMeshes.set_mesh_color(charge_ring_mesh, Color("#38bdf8"))
		charge_ring_mesh.position = Vector3(0.0, 0.05, 0.72)
		charge_ring_mesh.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		charge_ring_mesh.scale = Vector3.ONE * (0.45 + ((f - s) / 5.0) * 0.55)

func _update_sans_gaster_blaster(elapsed: float, off_y: float, active_attack: AttackData, attack_frame: int, attack_phase: String) -> void:
	var s: float = float(maxi(1, active_attack.startup_frames))
	var a: float = float(maxi(1, active_attack.active_frames))
	var r: float = float(maxi(1, active_attack.recovery_frames))
	var f: float = float(attack_frame)

	for b_name in gb_bindings.keys():
		var bd: Dictionary = gb_bindings[b_name]
		gb_skeleton.set_bone_pose_rotation(bd["idx"], bd["local_rest"])

	gb_armature.visible = true
	gb_mesh.visible = true

	var pop_scale: float = 1.0
	var jaw_open: float = 0.0
	var head_pitch: float = 0.0
	var blaster_y: float = off_y + 0.16
	var blaster_z: float = 0.86

	if attack_phase == "startup":
		var st: float = clampf(f / s, 0.0, 1.0)
		pop_scale = ProceduralPoseLibrary.smoothstep_val(0.0, 0.42, st)
		var anticipate: float = sin(ProceduralPoseLibrary.smoothstep_val(0.15, 0.65, st) * PI)
		var open_t: float = ProceduralPoseLibrary.smoothstep_val(0.42, 1.0, st)
		jaw_open = open_t * 0.88
		head_pitch = -0.24 * anticipate - 0.14 * open_t
		blaster_y += (1.0 - pop_scale) * 0.45 + anticipate * 0.08
		blaster_z -= (1.0 - pop_scale) * 0.35

		charge_ring_mesh.visible = true
		ProceduralVfxMeshes.set_mesh_color(charge_ring_mesh, Color("#38bdf8"))
		charge_ring_mesh.position = Vector3(0.0, blaster_y - 0.08, blaster_z + 0.42)
		charge_ring_mesh.scale = Vector3.ONE * (0.22 + open_t * 0.48 + sin(elapsed * 38.0) * 0.06)
		charge_ring_mesh.rotation = Vector3(0.0, 0.0, elapsed * 18.0)
	elif attack_phase == "active":
		var ro: float = sin(elapsed * 55.0) * 0.05
		pop_scale = 1.08 + ro * 0.4
		jaw_open = 1.05 + ro
		head_pitch = -0.18 + ro * 0.5
		blaster_z = 0.80 + ro * 0.3

		beam_group.visible = true
		beam_group.position = Vector3(0.0, blaster_y - 0.10, blaster_z + 0.44)
		beam_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
		var p: float = 1.18 + sin(elapsed * 50.0) * 0.22
		beam_group.scale = Vector3(1.35, p, p)
	else:
		var rt: float = clampf((f - s - a) / r, 0.0, 1.0)
		pop_scale = maxf(0.01, 1.0 - ProceduralPoseLibrary.smoothstep_val(0.15, 1.0, rt))
		jaw_open = (1.0 - ProceduralPoseLibrary.smoothstep_val(0.0, 0.65, rt)) * 0.85
		head_pitch = 0.25 * rt
		blaster_y += rt * 0.35
		blaster_z -= rt * 0.28

	gb_armature.position = Vector3(0.0, blaster_y, blaster_z)
	gb_armature.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	gb_armature.scale = Vector3.ONE * (2.65 * pop_scale)

	ProceduralRigSolver.set_bone_char_quat(gb_skeleton, gb_bindings, "Root", ProceduralRigSolver.quat_euler_yxz(head_pitch, 0.0, 0.0))
	ProceduralRigSolver.set_bone_char_quat(gb_skeleton, gb_bindings, "Jaw", ProceduralRigSolver.quat_euler_xyz(jaw_open * 0.72, 0.0, 0.0))
	ProceduralRigSolver.set_bone_char_quat(gb_skeleton, gb_bindings, "JawR", ProceduralRigSolver.quat_euler_xyz(jaw_open * 0.28, -jaw_open * 0.42, -jaw_open * 0.32))
	ProceduralRigSolver.set_bone_char_quat(gb_skeleton, gb_bindings, "JawL", ProceduralRigSolver.quat_euler_xyz(jaw_open * 0.28, jaw_open * 0.42, jaw_open * 0.32))

func _update_sans_telekinesis_vfx(elapsed: float, active_attack: AttackData, attack_frame: int, attack_phase: String) -> void:
	if telekinesis_box_group == null:
		return
	var s: float = float(maxi(1, active_attack.startup_frames))
	var f: float = float(attack_frame)
	var box_z: float = 1.65
	var box_y: float = 1.05
	var excl_stem: Node3D = telekinesis_box_group.get_node_or_null("ExclStem") as Node3D
	var excl_dot: Node3D = telekinesis_box_group.get_node_or_null("ExclDot") as Node3D

	if active_attack.vfx_type == "telekinesis_warning_box":
		if attack_phase == "startup":
			telekinesis_box_group.visible = true
			telekinesis_box_group.position = Vector3(0.0, box_y, box_z)
			telekinesis_box_group.rotation = Vector3(0.0, PI * 0.5, 0.0)
			var pop: float = ProceduralPoseLibrary.smoothstep_val(0.0, 0.12, f / s)
			telekinesis_box_group.scale = Vector3.ONE * (0.85 + 0.15 * pop)
			var is_yellow: bool = (int(floor(elapsed * 22.0)) % 2) == 0
			var col := Color("#facc15") if is_yellow else Color("#ff2a2a")
			for mat in telekinesis_box_mats:
				mat.albedo_color = col
			if excl_stem:
				excl_stem.visible = true
			if excl_dot:
				excl_dot.visible = true
		elif attack_phase == "active":
			telekinesis_box_group.visible = true
			telekinesis_box_group.position = Vector3(0.0, box_y, box_z)
			telekinesis_box_group.rotation = Vector3(0.0, PI * 0.5, 0.0)
			var pulse: float = 1.0 + sin(elapsed * 35.0) * 0.08
			telekinesis_box_group.scale = Vector3.ONE * pulse
			for mat in telekinesis_box_mats:
				mat.albedo_color = Color("#38bdf8")
			if excl_stem:
				excl_stem.visible = false
			if excl_dot:
				excl_dot.visible = false
			stardust_orb_mesh.visible = true
			ProceduralVfxMeshes.set_mesh_color(stardust_orb_mesh, Color(0.22, 0.74, 0.97, 0.75))
			stardust_orb_mesh.position = Vector3(0.0, box_y, box_z)
			stardust_orb_mesh.scale = Vector3.ONE * (0.68 * pulse)
	elif active_attack.is_telekinesis_hold:
		telekinesis_box_group.visible = true
		var hover_bob: float = sin(elapsed * 12.0) * 0.06
		telekinesis_box_group.position = Vector3(0.0, box_y + hover_bob, box_z)
		telekinesis_box_group.rotation = Vector3(0.0, PI * 0.5, 0.0)
		telekinesis_box_group.scale = Vector3.ONE * (0.92 + sin(elapsed * 24.0) * 0.04)
		for mat in telekinesis_box_mats:
			mat.albedo_color = Color("#38bdf8")
		if excl_stem:
			excl_stem.visible = false
		if excl_dot:
			excl_dot.visible = false
		charge_ring_mesh.visible = true
		ProceduralVfxMeshes.set_mesh_color(charge_ring_mesh, Color("#38bdf8"))
		charge_ring_mesh.position = Vector3(0.0, box_y + hover_bob, box_z)
		charge_ring_mesh.rotation = Vector3(0.0, PI * 0.5, elapsed * 14.0)
		charge_ring_mesh.scale = Vector3.ONE * 0.82
	elif active_attack.is_telekinesis_throw and attack_phase == "active":
		slash_arc_mesh.visible = true
		ProceduralVfxMeshes.set_mesh_color(slash_arc_mesh, Color("#38bdf8"))
		slash_arc_mesh.position = Vector3(0.0, box_y, box_z)
		slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, elapsed * 20.0)
		slash_arc_mesh.scale = Vector3.ONE * 1.35

func _update_sans_parry_vfx(elapsed: float, active_attack: AttackData, attack_frame: int, attack_phase: String) -> void:
	var s: float = float(maxi(1, active_attack.startup_frames))
	var a: float = float(maxi(1, active_attack.active_frames))
	var r: float = float(maxi(1, active_attack.recovery_frames))
	var f: float = float(attack_frame)

	if active_attack.vfx_type == "parry_shrug_aura":
		if attack_phase in ["startup", "active"]:
			charge_ring_mesh.visible = true
			ProceduralVfxMeshes.set_mesh_color(charge_ring_mesh, Color("#38bdf8"))
			charge_ring_mesh.position = Vector3(0.0, 0.08, 0.0)
			charge_ring_mesh.rotation = Vector3(PI * 0.5, 0.0, elapsed * 10.0)
			charge_ring_mesh.scale = Vector3.ONE * (0.72 + sin(elapsed * 22.0) * 0.08)
		return

	if active_attack.vfx_type == "parry_counter_bone" and sans_bone_mesh and is_instance_valid(sans_bone_mesh):
		var emerge: float = ProceduralPoseLibrary.smoothstep_val(0.0, 1.0, f / s) if attack_phase == "startup" else (1.0 if attack_phase == "active" else (1.0 - ProceduralPoseLibrary.smoothstep_val(0.0, 0.85, (f - s - a) / r)))
		if emerge <= 0.02:
			return
		sans_bone_mesh.visible = true
		var tilt_pitch: float = 0.54
		var slide: float = (1.0 - emerge) * 0.85
		sans_bone_mesh.position = Vector3(0.0, 0.68 - slide * cos(tilt_pitch), 0.92 - slide * sin(tilt_pitch))
		sans_bone_mesh.rotation = Vector3(-PI * 0.5 + tilt_pitch, 0.0, 0.0)
		sans_bone_mesh.scale = Vector3(3.6, 3.6, 4.4 * emerge)

		if attack_phase == "active" and f <= s + 8.0:
			charge_ring_mesh.visible = true
			ProceduralVfxMeshes.set_mesh_color(charge_ring_mesh, Color("#38bdf8"))
			charge_ring_mesh.position = Vector3(0.0, 0.06, 0.65)
			charge_ring_mesh.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			charge_ring_mesh.scale = Vector3.ONE * (0.65 + ((f - s) / 8.0) * 0.65)

