# ==============================================================================
# CharacterSelect3DBuilder (Constructor 3D para Selección de Personajes)
# ==============================================================================
# Separa la generación procedural 3D de la lógica de cursores y reglas de
# `CharacterSelect`:
#   1. Abanico 3D de cartas del roster con detección de clic (`Area3D`).
#   2. Retratos faciales 3D en vivo (`SubViewport`) encuadrando automáticamente
#      el hueso de la cabeza (`Head`) o el `AABB` visual de cada luchador.
#   3. Escenografía 3D dinámica según el escenario elegido (Astral, Cyber, Volcano).
#   4. Instanciación de modelos 3D sobre los pedestales de vista previa.
# ==============================================================================
class_name CharacterSelect3DBuilder
extends RefCounted

#region Abanico 3D de Cartas y Retratos en Vivo (SubViewport)
## Construye todas las cartas 3D del roster y devuelve el diccionario `slot_idx -> Node3D`.
static func build_card_arc(
	card_arc_root: Node3D,
	vp_parent: Node,
	roster_slots: Array[Dictionary],
	font_res: Font,
	on_card_input: Callable,
	portrait_viewports_out: Array[SubViewport]
) -> Dictionary:
	for vp in portrait_viewports_out:
		if is_instance_valid(vp):
			vp.queue_free()
	portrait_viewports_out.clear()

	var card_nodes: Dictionary = {}
	var col_spacing: float = 0.36
	var row_spacing_y: float = 0.25
	var row_spacing_z: float = 0.04

	for i in range(roster_slots.size()):
		var slot: Dictionary = roster_slots[i]
		var row: int = slot["row"]
		var col: int = slot["col"]

		var card_root := Node3D.new()
		card_root.name = "Card_" + str(slot["id"])

		var px: float = 0.0
		var py: float = (2 - row) * row_spacing_y
		var pz: float = (row - 1) * row_spacing_z
		var yaw: float = 0.0

		if row == 0:
			py += 0.06
			pz -= 0.02
		else:
			var side: float = -1.0 if col == 0 else 1.0
			px = side * (col_spacing * 0.5)
			yaw = -side * 0.035
			pz -= 0.008

		card_root.position = Vector3(px, py, pz)
		card_root.rotation.y = yaw
		card_root.set_meta("base_pos", card_root.position)

		# Halo luminoso trasero cuando algún cursor apunta a la carta.
		var glow_mesh := MeshInstance3D.new()
		glow_mesh.name = "Glow"
		var glow_quad := QuadMesh.new()
		glow_quad.size = Vector2(0.324, 0.224)
		glow_mesh.mesh = glow_quad
		var glow_mat := StandardMaterial3D.new()
		glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow_mat.albedo_color = Color(1.0, 0.85, 0.2)
		glow_mesh.material_override = glow_mat
		glow_mesh.position = Vector3(0.0, 0.0, -0.003)
		glow_mesh.visible = false
		card_root.add_child(glow_mesh)

		# Placa frontal con textura en vivo (SubViewport) o imagen estática.
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "CardMesh"
		var quad := QuadMesh.new()
		quad.size = Vector2(0.30, 0.20)
		mesh_inst.mesh = quad

		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if slot["data"] != null:
			var vp: SubViewport = create_face_portrait_viewport(slot, vp_parent)
			portrait_viewports_out.append(vp)
			mat.albedo_texture = vp.get_texture()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		else:
			var tex: Texture2D = _load_texture_safe(str(slot.get("tex_path", "")))
			if tex:
				mat.albedo_texture = tex
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.alpha_scissor_threshold = 0.5
		mat.albedo_color = Color(0.85, 0.85, 0.88)
		mesh_inst.material_override = mat
		card_root.add_child(mesh_inst)

		# Nombre 3D al pie de la carta.
		var label := Label3D.new()
		label.text = slot["name"]
		label.font = font_res
		label.font_size = 8
		label.outline_size = 3
		label.outline_modulate = Color.BLACK
		label.modulate = Color.WHITE
		label.line_spacing = 0.0
		label.position = Vector3(0.0, -0.072, 0.010)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card_root.add_child(label)

		# Colisión 3D para permitir selección con clic izquierdo del ratón.
		var area := Area3D.new()
		var col_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.30, 0.20, 0.05)
		col_shape.shape = box
		area.add_child(col_shape)
		if on_card_input.is_valid():
			area.input_event.connect(on_card_input.bind(i))
		card_root.add_child(area)

		card_arc_root.add_child(card_root)
		card_nodes[i] = card_root

	return card_nodes

## Crea un `SubViewport` aislado con iluminación propia para retratar el rostro del personaje.
static func create_face_portrait_viewport(slot: Dictionary, vp_parent: Node) -> SubViewport:
	var data: CharacterData = slot["data"]
	var accent: Color = slot.get("color", Color(0.35, 0.7, 1.0))

	var vp := SubViewport.new()
	vp.name = "PortraitVP_" + str(slot["id"])
	vp.size = Vector2i(256, 170)
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

	var model: Node3D = _instantiate_character_preview_node(data, deg_to_rad(10.0))
	holder.add_child(model)

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

	vp_parent.add_child(vp)
	CharacterSelect3DBuilder.frame_portrait_camera.call_deferred(holder, cam, bg_plate, data)
	return vp

## Ajusta la cámara del retrato apuntando automáticamente a la cabeza del modelo 3D.
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
		elif cname.contains("miyabi"):
			span_above = 0.12; cam_dist = 0.95
		elif cname.contains("hornet"):
			span_above = 0.12; cam_dist = 0.98
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
#endregion

#region Escenografía 3D de Fondo y Pedestales de Luchadores
## Reconstruye el cielo y los elementos decorativos 3D del escenario seleccionado.
static func update_stage_background(stage_bg_deco: Node3D, world_environment: WorldEnvironment, stage_data: Dictionary) -> void:
	if stage_bg_deco == null:
		return

	for child in stage_bg_deco.get_children():
		child.queue_free()

	var stage_id: String = str(stage_data.get("id", "astral"))

	if world_environment and world_environment.environment:
		var env: Environment = world_environment.environment
		env.background_mode = Environment.BG_SKY
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = stage_data.get("sky_top_color", Color(0.14, 0.18, 0.38))
		sky_mat.sky_horizon_color = stage_data.get("sky_horizon_color", Color(0.88, 0.58, 0.65))
		sky_mat.sky_curve = 0.15
		sky_mat.ground_bottom_color = stage_data.get("ground_bottom_color", Color(0.08, 0.10, 0.18))
		sky_mat.ground_horizon_color = stage_data.get("ground_horizon_color", Color(0.88, 0.58, 0.65))
		sky_mat.ground_curve = 0.15
		sky_mat.sun_angle_max = 35.0
		sky_mat.use_debanding = true

		var new_sky := Sky.new()
		new_sky.sky_material = sky_mat
		env.sky = new_sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.75

	match stage_id:
		"astral":
			var ring_mesh := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = 2.4
			torus.outer_radius = 2.8
			ring_mesh.mesh = torus
			var r_mat := StandardMaterial3D.new()
			r_mat.albedo_color = Color(1.0, 0.85, 0.3)
			r_mat.metallic = 0.95
			r_mat.roughness = 0.15
			r_mat.emission_enabled = true
			r_mat.emission = Color(1.0, 0.8, 0.25)
			r_mat.emission_energy_multiplier = 1.2
			ring_mesh.material_override = r_mat
			ring_mesh.position = Vector3(0, 2.5, -2.0)
			ring_mesh.rotation.x = deg_to_rad(15.0)
			ring_mesh.name = "CelestialRing"
			stage_bg_deco.add_child(ring_mesh)

			for side_x in [-4.5, 4.5]:
				var pil := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.35
				cyl.bottom_radius = 0.45
				cyl.height = 6.0
				pil.mesh = cyl
				var p_mat := StandardMaterial3D.new()
				p_mat.albedo_color = Color(0.18, 0.22, 0.35)
				p_mat.metallic = 0.4
				pil.material_override = p_mat
				pil.position = Vector3(side_x, 1.0, -1.5)
				stage_bg_deco.add_child(pil)

		"cyber":
			var c_ring1 := MeshInstance3D.new()
			var torus1 := TorusMesh.new()
			torus1.inner_radius = 2.0
			torus1.outer_radius = 2.2
			c_ring1.mesh = torus1
			var cr_mat1 := StandardMaterial3D.new()
			cr_mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cr_mat1.albedo_color = Color(0.1, 0.85, 1.0)
			c_ring1.material_override = cr_mat1
			c_ring1.position = Vector3(-1.5, 2.2, -1.8)
			c_ring1.name = "CyberRing1"
			stage_bg_deco.add_child(c_ring1)

			var c_ring2 := MeshInstance3D.new()
			var torus2 := TorusMesh.new()
			torus2.inner_radius = 1.5
			torus2.outer_radius = 1.68
			c_ring2.mesh = torus2
			var cr_mat2 := StandardMaterial3D.new()
			cr_mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cr_mat2.albedo_color = Color(1.0, 0.15, 0.85)
			c_ring2.material_override = cr_mat2
			c_ring2.position = Vector3(1.5, 2.0, -1.5)
			c_ring2.rotation.y = deg_to_rad(30.0)
			c_ring2.name = "CyberRing2"
			stage_bg_deco.add_child(c_ring2)

			for side_x in [-3.5, -1.8, 1.8, 3.5]:
				var beam := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(0.08, 7.0, 0.08)
				beam.mesh = box
				var b_mat := StandardMaterial3D.new()
				b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				b_mat.albedo_color = Color(0.2, 0.8, 1.0, 0.6)
				beam.material_override = b_mat
				beam.position = Vector3(side_x, 1.5, -2.0)
				stage_bg_deco.add_child(beam)

		"volcano":
			for side_x in [-4.2, -2.2, 2.2, 4.2]:
				var pil := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.4
				cyl.bottom_radius = 0.6
				cyl.height = 5.5
				pil.mesh = cyl
				var p_mat := StandardMaterial3D.new()
				p_mat.albedo_color = Color(0.1, 0.08, 0.09)
				p_mat.roughness = 0.9
				p_mat.emission_enabled = true
				p_mat.emission = Color(1.0, 0.35, 0.05)
				p_mat.emission_energy_multiplier = 0.4
				pil.material_override = p_mat
				pil.position = Vector3(side_x, 1.0, -1.8)
				stage_bg_deco.add_child(pil)

			var lava := MeshInstance3D.new()
			var l_mesh := BoxMesh.new()
			l_mesh.size = Vector3(12.0, 0.3, 2.0)
			lava.mesh = l_mesh
			var l_mat := StandardMaterial3D.new()
			l_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			l_mat.albedo_color = Color(1.0, 0.4, 0.05)
			lava.material_override = l_mat
			lava.position = Vector3(0, -0.2, -2.0)
			stage_bg_deco.add_child(lava)

## Instancia el modelo 3D (o prisma de Aleatorio) sobre el pedestal del jugador.
## Devuelve `true` si instanció un modelo de personaje (para animar su escala de entrada).
static func populate_pedestal_model(container: Node3D, slot: Dictionary, facing_yaw: float) -> bool:
	if not container:
		return false

	for child in container.get_children():
		child.queue_free()

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
		return false

	var data: CharacterData = slot["data"]
	if data == null:
		return false

	var preview_node: Node3D = _instantiate_character_preview_node(data, facing_yaw)
	container.add_child(preview_node)
	return true
#endregion

#region Utilidades Internas de Modelos, Animación y Geometría 3D
static func _instantiate_character_preview_node(data: CharacterData, yaw_rad: float) -> Node3D:
	if data != null and data.model_scene != null:
		var char_root := Node3D.new()
		char_root.name = "CharacterRoot"
		char_root.rotation.y = yaw_rad

		# Mantiene la jerarquía `CharacterRoot -> Humanoid -> ModelRoot` que usan las pistas de animación.
		var humanoid := Node3D.new()
		humanoid.name = "Humanoid"
		char_root.add_child(humanoid)

		var model: Node3D = data.model_scene.instantiate()
		model.name = "ModelRoot"
		model.position = Vector3(data.model_offset.x, 0.0, data.model_offset.z)
		var s: float = data.model_scale if data.model_scale > 0.0 else 1.0
		model.scale = Vector3(s, s, s)
		humanoid.add_child(model)

		var played_idle: bool = false
		var ap: AnimationPlayer = _find_animation_player(model)
		if ap:
			var anim_name: String = _find_idle_anim(ap)
			if anim_name != "":
				ap.play(anim_name)
				played_idle = true

		if not played_idle and data.animation_library:
			var new_ap := AnimationPlayer.new()
			new_ap.name = "AnimationPlayer"
			new_ap.root_node = NodePath("..")
			new_ap.add_animation_library("", data.animation_library)
			char_root.add_child(new_ap)
			var anim_name: String = _find_idle_anim(new_ap)
			if anim_name != "":
				new_ap.play(anim_name)

		return char_root

	var color: Color = data.character_color if data != null else Color(0.4, 0.85, 0.95)
	var dummy: Node3D = create_procedural_dummy(color)
	dummy.rotation.y = yaw_rad
	return dummy

static func create_procedural_dummy(color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.4
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = color * 0.2

	var torso := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.65, 0.28)
	torso.mesh = box
	torso.material_override = mat
	torso.position = Vector3(0, 0.95, 0)
	root.add_child(torso)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.material_override = mat
	head.position = Vector3(0, 1.45, 0)
	root.add_child(head)

	for side_x in [-0.15, 0.15]:
		var leg := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.08
		cap.height = 0.65
		leg.mesh = cap
		leg.material_override = mat
		leg.position = Vector3(side_x, 0.35, 0)
		root.add_child(leg)

	for side_x in [-0.35, 0.35]:
		var arm := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.07
		cap.height = 0.55
		arm.mesh = cap
		arm.material_override = mat
		arm.position = Vector3(side_x, 0.95, 0)
		arm.rotation.z = deg_to_rad(-15.0 if side_x < 0 else 15.0)
		root.add_child(arm)

	return root

static func _load_texture_safe(tex_path: String) -> Texture2D:
	if tex_path == "":
		return null
	if ResourceLoader.exists(tex_path):
		return load(tex_path)
	if FileAccess.file_exists(tex_path):
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(tex_path))
		if img:
			return ImageTexture.create_from_image(img)
	return null

static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found:
			return found
	return null

static func _find_idle_anim(ap: AnimationPlayer) -> String:
	for anim_name in ap.get_animation_list():
		if anim_name.to_lower() == "idle":
			return anim_name
	for anim_name in ap.get_animation_list():
		if "idle" in anim_name.to_lower():
			return anim_name
	return ""

static func _compute_visual_aabb(root: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_visible_meshes(root, meshes)
	var first: bool = true
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
	for child in n.get_children():
		_collect_visible_meshes(child, out)

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
	for child in n.get_children():
		_collect_skeletons(child, out)
#endregion

