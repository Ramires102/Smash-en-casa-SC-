class_name CSPortraitRenderer
extends RefCounted

static func create_face_portrait_viewport(owner_node: Node, slot: Dictionary) -> SubViewport:
	var data: CharacterData = slot["data"]
	var accent: Color = slot.get("color", Color(0.35, 0.7, 1.0))

	var vp := SubViewport.new()
	vp.name = "PortraitVP_" + str(slot["id"])
	vp.size = Vector2i(192, 192)
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(
		clampf(accent.r * 0.18 + 0.05, 0.0, 1.0),
		clampf(accent.g * 0.18 + 0.06, 0.0, 1.0),
		clampf(accent.b * 0.22 + 0.10, 0.0, 1.0),
		1.0
	)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.90, 0.96, 1.0)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.97, 0.92)
	key_light.light_energy = 1.15
	key_light.rotation_degrees = Vector3(-20.0, 24.0, 0.0)
	vp.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.light_color = Color(0.65, 0.78, 1.0)
	fill_light.light_energy = 0.55
	fill_light.rotation_degrees = Vector3(-10.0, -38.0, 0.0)
	vp.add_child(fill_light)

	var holder := Node3D.new()
	holder.name = "PortraitModelHolder"
	vp.add_child(holder)

	var model: Node3D = instantiate_character_model(data, deg_to_rad(10.0))
	holder.add_child(model)
	setup_character_idle_pose(owner_node, model, data)

	var bg_plate := MeshInstance3D.new()
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(0.55, 0.55)
	bg_plate.mesh = bg_quad
	var bg_mat := StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.albedo_color = accent.lightened(0.15)
	bg_plate.material_override = bg_mat
	bg_plate.rotation.z = deg_to_rad(45.0)
	vp.add_child(bg_plate)

	var cam := Camera3D.new()
	cam.name = "PortraitCamera"
	cam.fov = 30.0
	cam.near = 0.05
	cam.far = 20.0
	vp.add_child(cam)

	owner_node.call_deferred("_frame_portrait_camera", holder, cam, bg_plate, data)
	return vp

static func frame_portrait_camera(holder: Node3D, cam: Camera3D, bg_plate: MeshInstance3D, data: CharacterData) -> void:
	if not is_instance_valid(holder) or not is_instance_valid(cam):
		return
	var aabb: AABB = _compute_visual_aabb(holder)
	var head_bone: Vector3 = _find_head_bone_pos(holder)

	var focus_pt := Vector3(0.0, 1.45, 0.0)
	var cam_dist: float = 1.05
	var cname: String = data.character_name.to_lower() if data != null else ""

	if head_bone != Vector3.ZERO:
		var span_above: float = clampf((aabb.end.y - head_bone.y) * 0.32, 0.11, 0.21)
		if cname.contains("sans"):
			span_above = 0.14; cam_dist = 0.92
		elif cname.contains("batman"):
			span_above = 0.18; cam_dist = 1.02
		elif cname.contains("sakuya"):
			span_above = 0.10; cam_dist = 0.88
		elif cname.contains("gogeta"):
			span_above = 0.13; cam_dist = 0.98
		focus_pt = Vector3(head_bone.x, head_bone.y + span_above, head_bone.z)
	elif aabb.size.y > 0.05:
		focus_pt = Vector3(
			aabb.position.x + aabb.size.x * 0.5,
			aabb.position.y + aabb.size.y * 0.83,
			aabb.position.z + aabb.size.z * 0.5
		)
		cam_dist = clampf(aabb.size.y * 0.58, 0.75, 1.35)

	if is_instance_valid(bg_plate):
		bg_plate.position = focus_pt + Vector3(0.0, 0.0, -0.45)

	cam.position = focus_pt + Vector3(0.0, 0.02, cam_dist)
	cam.look_at(focus_pt, Vector3.UP)

static func instantiate_character_model(data: CharacterData, facing_yaw: float) -> Node3D:
	if data != null and data.model_scene != null:
		var wrapper := Node3D.new()
		wrapper.name = "CharacterPreviewRoot"
		wrapper.rotation.y = facing_yaw
		var humanoid := Node3D.new()
		humanoid.name = "Humanoid"
		wrapper.add_child(humanoid)
		var model: Node3D = data.model_scene.instantiate()
		model.name = "ModelRoot"
		model.position = Vector3(data.model_offset.x, 0.0, data.model_offset.z)
		var s: float = data.model_scale
		model.scale = Vector3(s, s, s)
		humanoid.add_child(model)
		return wrapper
	var color: Color = data.character_color if data != null else Color(0.4, 0.85, 0.95)
	var dummy := _create_procedural_dummy(color)
	dummy.rotation.y = facing_yaw
	return dummy

static func setup_character_idle_pose(owner_node: Node, preview_root: Node3D, data: CharacterData) -> void:
	if preview_root == null or data == null:
		return

	var target_model: Node3D = preview_root
	var mr: Node3D = preview_root.get_node_or_null("Humanoid/ModelRoot") as Node3D
	if mr != null:
		target_model = mr

	var cname: String = data.character_name.to_lower()
	if cname.contains("gogeta") or cname.contains("sans"):
		var anim_ctrl := AnimationController.new()
		anim_ctrl.name = "PreviewAnimationController"
		target_model.add_child(anim_ctrl)
		anim_ctrl.setup_preview_on_model(target_model, data.character_name)
		return

	var played_idle := false
	var ap: AnimationPlayer = _find_animation_player(target_model)
	if ap:
		var anim_name: String = _find_idle_anim(ap)
		if anim_name != "":
			var anim_res: Animation = ap.get_animation(anim_name)
			if anim_res:
				anim_res.loop_mode = Animation.LOOP_LINEAR
			ap.play(anim_name)
			ap.advance(0.0)
			played_idle = true

	if not played_idle and data.animation_library:
		var new_ap := AnimationPlayer.new()
		new_ap.add_animation_library("", data.animation_library)
		preview_root.add_child(new_ap)
		var anim_name: String = _find_idle_anim(new_ap)
		if anim_name != "":
			var anim_res: Animation = new_ap.get_animation(anim_name)
			if anim_res:
				anim_res.loop_mode = Animation.LOOP_LINEAR
			new_ap.play(anim_name)
			new_ap.advance(0.0)
			played_idle = true

	if not played_idle:
		_apply_procedural_idle(target_model)

static func update_stage_preview(owner_node: Node, container: Node3D, player_id: int, slot: Dictionary) -> void:
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

	var facing_yaw: float = deg_to_rad(65.0) if player_id == 1 else deg_to_rad(-65.0)
	var data: CharacterData = slot["data"]

	if slot["id"] == "random":
		var q_root := Node3D.new()
		var q_mesh := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.6, 0.8, 0.2)
		q_mesh.mesh = prism
		var q_mat := StandardMaterial3D.new()
		q_mat.albedo_color = Color(1.0, 0.85, 0.2)
		q_mat.metallic = 0.9
		q_mat.roughness = 0.2
		q_mat.emission_enabled = true
		q_mat.emission = Color(1.0, 0.8, 0.2)
		q_mat.emission_energy_multiplier = 1.5
		q_mesh.material_override = q_mat
		q_mesh.position = Vector3(0, 0.8, 0)
		q_root.add_child(q_mesh)
		q_root.rotation.y = facing_yaw
		container.add_child(q_root)
		return

	if data == null:
		return

	var model: Node3D = instantiate_character_model(data, facing_yaw)
	container.add_child(model)
	setup_character_idle_pose(owner_node, model, data)

	container.scale = Vector3(0.85, 0.85, 0.85)
	var tw: Tween = container.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).bind_node(container)
	tw.tween_property(container, "scale", Vector3.ONE, 0.2)

static func _apply_procedural_idle(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	if not node.is_inside_tree():
		node.tree_entered.connect(_apply_procedural_idle.bind(node), CONNECT_ONE_SHOT)
		return
	var tw: Tween = node.create_tween().set_loops().bind_node(node)
	var base_y: float = node.position.y
	tw.tween_property(node, "position:y", base_y + 0.025, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position:y", base_y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

static func _create_procedural_dummy(color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.4
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = color * 0.2

	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.65, 0.28)
	torso.mesh = box
	torso.material_override = mat
	torso.position = Vector3(0, 0.95, 0)
	root.add_child(torso)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.material_override = mat
	head.position = Vector3(0, 1.45, 0)
	root.add_child(head)

	var visor := MeshInstance3D.new()
	visor.name = "Visor"
	var visor_box := BoxMesh.new()
	visor_box.size = Vector3(0.28, 0.08, 0.12)
	visor.mesh = visor_box
	var v_mat := StandardMaterial3D.new()
	v_mat.albedo_color = Color(0.85, 0.96, 1.0)
	v_mat.emission_enabled = true
	v_mat.emission = Color(0.5, 0.9, 1.0)
	v_mat.emission_energy_multiplier = 1.6
	visor.material_override = v_mat
	visor.position = Vector3(0, 1.47, 0.18)
	root.add_child(visor)

	for side in [-0.15, 0.15]:
		var leg := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.08; cap.height = 0.65
		leg.mesh = cap; leg.material_override = mat
		leg.position = Vector3(side, 0.35, 0)
		root.add_child(leg)

	for side in [-0.35, 0.35]:
		var arm := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.07; cap.height = 0.55
		arm.mesh = cap; arm.material_override = mat
		arm.position = Vector3(side, 0.95, 0)
		arm.rotation.z = deg_to_rad(-15.0 if side < 0 else 15.0)
		root.add_child(arm)

	return root

static func _compute_visual_aabb(root: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_visible_meshes(root, meshes)
	var first := true
	var merged := AABB()
	var inv_root: Transform3D = root.global_transform.affine_inverse()
	for m in meshes:
		if m.mesh == null:
			continue
		var maabb: AABB = m.get_aabb()
		var rel_xf: Transform3D = inv_root * m.global_transform
		for ix in [0, 1]:
			for iy in [0, 1]:
				for iz in [0, 1]:
					var pt: Vector3 = rel_xf * Vector3(
						maabb.position.x if ix == 0 else maabb.end.x,
						maabb.position.y if iy == 0 else maabb.end.y,
						maabb.position.z if iz == 0 else maabb.end.z
					)
					merged = AABB(pt, Vector3.ZERO) if first else merged.expand(pt)
					first = false
	return merged

static func _collect_visible_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_visible_meshes(c, out)

static func _find_head_bone_pos(root: Node3D) -> Vector3:
	var skels: Array[Skeleton3D] = []
	_collect_skeletons(root, skels)
	var inv_root: Transform3D = root.global_transform.affine_inverse()
	for sk in skels:
		if not sk.is_visible_in_tree():
			continue
		for bname in ["Head", "head", "Bip01_Head", "mixamorig:Head", "head.x"]:
			var idx: int = sk.find_bone(bname)
			if idx != -1:
				return (inv_root * sk.global_transform) * sk.get_bone_global_pose(idx).origin
		for idx in range(sk.get_bone_count()):
			if "head" in sk.get_bone_name(idx).to_lower():
				return (inv_root * sk.global_transform) * sk.get_bone_global_pose(idx).origin
	var head_node: Node3D = root.find_child("Head", true, false) as Node3D
	return (inv_root * head_node.global_transform).origin if head_node != null else Vector3.ZERO

static func _collect_skeletons(n: Node, out: Array[Skeleton3D]) -> void:
	if n is Skeleton3D:
		out.append(n as Skeleton3D)
	for c in n.get_children():
		_collect_skeletons(c, out)

static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var found := _find_animation_player(c)
		if found:
			return found
	return null

static func _find_idle_anim(ap: AnimationPlayer) -> String:
	for a in ap.get_animation_list():
		if a.to_lower() == "idle":
			return a
	for a in ap.get_animation_list():
		if "idle" in a.to_lower():
			return a
	return ""

