class_name ProceduralVfxMeshes
extends RefCounted

static func make_unshaded_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	return m

static func set_mesh_color(mi: MeshInstance3D, col: Color) -> void:
	if mi and mi.material_override is StandardMaterial3D:
		(mi.material_override as StandardMaterial3D).albedo_color = col

static func create_torus_mesh(outer_r: float, thickness: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.01, outer_r - thickness)
	torus.outer_radius = outer_r + thickness
	mi.mesh = torus
	mi.rotation.x = PI * 0.5
	mi.material_override = make_unshaded_mat(col)
	return mi

static func create_sphere_mesh(rad: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = rad
	sp.height = rad * 2.0
	mi.mesh = sp
	mi.material_override = make_unshaded_mat(col)
	return mi

static func create_cyl_mesh(top_r: float, bot_r: float, h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = h
	mi.mesh = cyl
	mi.material_override = make_unshaded_mat(col)
	return mi

static func create_beam_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(create_sphere_mesh(0.42, Color(0.95, 0.98, 1.0, 0.95)))
	var cyl := create_cyl_mesh(0.28, 0.36, 2.6, Color(0.22, 0.74, 0.97, 0.88))
	cyl.rotation.z = -PI * 0.5
	cyl.position.x = 1.35
	grp.add_child(cyl)
	return grp

static func create_bone_pillar_group() -> Node3D:
	var grp := Node3D.new()
	var col := Color(0.95, 0.98, 1.0, 0.95)
	for i in [-1, 0, 1]:
		var single := Node3D.new()
		single.add_child(create_cyl_mesh(0.06, 0.06, 0.85, col))
		var knob_l := create_sphere_mesh(0.09, col)
		knob_l.position = Vector3(-0.05, 0.42, 0.0)
		var knob_r := create_sphere_mesh(0.09, col)
		knob_r.position = Vector3(0.05, 0.42, 0.0)
		single.add_child(knob_l)
		single.add_child(knob_r)
		single.position = Vector3(float(i) * 0.26, 0.35, 0.0)
		single.rotation.z = float(i) * -0.15
		grp.add_child(single)
	return grp

static func create_spiral_vortex_group() -> Node3D:
	var grp := Node3D.new()
	var z_list := [-0.58, 0.0, 0.58]
	var r_list := [0.56, 0.68, 0.52]
	for i in range(3):
		var ring := create_torus_mesh(r_list[i], 0.028, Color(0.97, 0.98, 1.0, 0.82) if i == 1 else Color(0.99, 0.90, 0.54, 0.65))
		ring.position = Vector3(0.0, 0.0, z_list[i])
		grp.add_child(ring)
	return grp

static func create_ki_knee_cone_group() -> Node3D:
	var grp := Node3D.new()
	var outer_cone := create_cyl_mesh(0.02, 0.62, 1.65, Color(0.22, 0.74, 0.97, 0.52))
	outer_cone.rotation.x = PI * 0.5
	grp.add_child(outer_cone)
	var inner_cone := create_cyl_mesh(0.01, 0.38, 1.45, Color(0.88, 0.95, 1.0, 0.78))
	inner_cone.rotation.x = PI * 0.5
	inner_cone.position.z = 0.12
	grp.add_child(inner_cone)
	var ring := create_torus_mesh(0.46, 0.032, Color(0.49, 0.83, 0.99, 0.88))
	ring.position.z = 0.35
	grp.add_child(ring)
	return grp

static func create_somersault_vortex_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(create_torus_mesh(0.96, 0.068, Color(0.15, 0.39, 0.92, 0.88)))
	var b2 := create_torus_mesh(0.92, 0.052, Color(0.22, 0.74, 0.97, 0.84))
	b2.position.z = 0.04
	grp.add_child(b2)
	var w1 := create_torus_mesh(0.76, 0.024, Color(0.97, 0.98, 1.0, 0.82))
	w1.position.z = -0.05
	grp.add_child(w1)
	return grp

static func create_elbow_slash_beam_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(create_cyl_mesh(0.22, 0.28, 2.45, Color(0.15, 0.39, 0.92, 0.72)))
	grp.add_child(create_cyl_mesh(0.13, 0.18, 2.52, Color(0.22, 0.74, 0.97, 0.88)))
	grp.add_child(create_cyl_mesh(0.06, 0.09, 2.58, Color(1.0, 1.0, 1.0, 0.98)))
	var flash := create_sphere_mesh(0.28, Color(1.0, 1.0, 1.0, 0.95))
	flash.position = Vector3(0.0, 1.15, 0.0)
	grp.add_child(flash)
	return grp

static func create_kick_crescent_arc_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(create_torus_mesh(1.32, 0.14, Color(0.11, 0.31, 0.85, 0.82)))
	var mid := create_torus_mesh(1.30, 0.09, Color(0.22, 0.74, 0.97, 0.90))
	mid.position.z = 0.02
	grp.add_child(mid)
	var core := create_torus_mesh(1.28, 0.045, Color(1.0, 1.0, 1.0, 0.96))
	core.position.z = 0.04
	grp.add_child(core)
	return grp

static func create_divekick_vfx_group() -> Node3D:
	var grp := Node3D.new()
	var outer_cone := create_cyl_mesh(0.02, 0.52, 2.35, Color(0.22, 0.74, 0.97, 0.65))
	outer_cone.rotation.x = PI * 0.5
	grp.add_child(outer_cone)
	var inner_cone := create_cyl_mesh(0.01, 0.32, 2.15, Color(1.0, 1.0, 1.0, 0.92))
	inner_cone.rotation.x = PI * 0.5
	inner_cone.position.z = 0.15
	grp.add_child(inner_cone)
	var tip_ring := create_torus_mesh(0.48, 0.038, Color(0.49, 0.83, 0.99, 0.92))
	tip_ring.position.z = 1.12
	grp.add_child(tip_ring)
	return grp

static func create_telekinesis_box_group(out_mats: Array[StandardMaterial3D]) -> Node3D:
	var grp := Node3D.new()
	grp.name = "TelekinesisBoxGroup"
	out_mats.clear()
	var w: float = 1.48
	var h: float = 1.62
	var t: float = 0.065

	var make_bar := func(bx: float, by: float, bz: float, px: float, py: float, node_name: String) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.name = node_name
		var bm := BoxMesh.new()
		bm.size = Vector3(bx, by, bz)
		mi.mesh = bm
		var mat := make_unshaded_mat(Color("#ff2a2a"))
		mi.material_override = mat
		out_mats.append(mat)
		mi.position = Vector3(px, py, 0.0)
		return mi

	grp.add_child(make_bar.call(w + t, t, t, 0.0, h * 0.5, "TopBar"))
	grp.add_child(make_bar.call(w + t, t, t, 0.0, -h * 0.5, "BottomBar"))
	grp.add_child(make_bar.call(t, h + t, t, -w * 0.5, 0.0, "LeftBar"))
	grp.add_child(make_bar.call(t, h + t, t, w * 0.5, 0.0, "RightBar"))
	grp.add_child(make_bar.call(0.11, 0.52, 0.05, 0.0, 0.16, "ExclStem"))
	grp.add_child(make_bar.call(0.11, 0.11, 0.05, 0.0, -0.26, "ExclDot"))
	return grp

