# ==============================================================================
# CombatVfxController — Generador y Animador de Efectos Visuales 3D de Combate
# ==============================================================================
# Construye mallas geométricas 3D sin iluminación (arcos de corte, conos de Ki,
# pilares de hueso y estelas de seda de Hornet) dentro de Humanoid/CombatVfxGroup
# y las muestra/oculta dinámicamente según el vfx_type del ataque activo.
# ==============================================================================
class_name CombatVfxController
extends RefCounted

var vfx_group: Node3D = null

var _slash_arc_mesh: MeshInstance3D
var _beam_group: Node3D
var _bone_pillar_group: Node3D
var _stardust_orb_mesh: MeshInstance3D
var _charge_ring_mesh: MeshInstance3D
var _spiral_vortex_group: Node3D
var _ki_knee_cone_group: Node3D
var _somersault_vortex_group: Node3D
var _elbow_slash_beam_group: Node3D
var _kick_crescent_arc_group: Node3D
var _divekick_vfx_group: Node3D

var _silk_thrust_starburst_group: Node3D
var _silk_buzzsaw_group: Node3D
var _silk_dair_drill_group: Node3D
var _silk_spear_beam_group: Node3D
var _silk_dome_eruption_group: Node3D
var _silk_nair_surround_group: Node3D

#region Construcción e Inicialización del Grupo VFX
func build_for_character(character: Node) -> void:
	if character == null:
		return
	var humanoid: Node3D = character.get_node_or_null("Humanoid") as Node3D
	if humanoid == null:
		return
	var old_vfx: Node = humanoid.get_node_or_null("CombatVfxGroup")
	if old_vfx:
		old_vfx.queue_free()

	vfx_group = Node3D.new()
	vfx_group.name = "CombatVfxGroup"
	humanoid.add_child(vfx_group)

	_slash_arc_mesh = _create_torus_mesh(0.68, 0.08, Color(0.98, 0.75, 0.14, 0.88))
	_charge_ring_mesh = _create_torus_mesh(0.45, 0.025, Color(0.98, 0.75, 0.14, 0.75))
	_stardust_orb_mesh = _create_sphere_mesh(0.65, Color(0.98, 0.75, 0.14, 0.82))
	_beam_group = _create_beam_group()
	_bone_pillar_group = _create_bone_pillar_group()
	_spiral_vortex_group = _create_spiral_vortex_group()
	_ki_knee_cone_group = _create_ki_knee_cone_group()
	_somersault_vortex_group = _create_somersault_vortex_group()
	_elbow_slash_beam_group = _create_elbow_slash_beam_group()
	_kick_crescent_arc_group = _create_kick_crescent_arc_group()
	_divekick_vfx_group = _create_divekick_vfx_group()

	_silk_thrust_starburst_group = _create_silk_thrust_starburst_group()
	_silk_buzzsaw_group = _create_silk_buzzsaw_group()
	_silk_dair_drill_group = _create_silk_dair_drill_group()
	_silk_spear_beam_group = _create_silk_spear_beam_group()
	_silk_dome_eruption_group = _create_silk_dome_eruption_group()
	_silk_nair_surround_group = _create_silk_nair_surround_group()

	for node in [
		_slash_arc_mesh, _charge_ring_mesh, _stardust_orb_mesh, _beam_group, _bone_pillar_group,
		_spiral_vortex_group, _ki_knee_cone_group, _somersault_vortex_group,
		_elbow_slash_beam_group, _kick_crescent_arc_group, _divekick_vfx_group,
		_silk_thrust_starburst_group, _silk_buzzsaw_group, _silk_dair_drill_group,
		_silk_spear_beam_group, _silk_dome_eruption_group, _silk_nair_surround_group
	]:
		node.visible = false
		vfx_group.add_child(node)

func hide_all() -> void:
	if vfx_group == null or not is_instance_valid(vfx_group):
		return
	for child in vfx_group.get_children():
		if child is Node3D:
			child.visible = false
#endregion

#region Actualización por Frame según Fase de Ataque
func update(
	elapsed: float,
	is_gogeta: bool,
	active_state_name: String,
	active_attack: AttackData,
	attack_phase: String
) -> void:
	if vfx_group == null or not is_instance_valid(vfx_group):
		return
	hide_all()

	if is_gogeta and active_state_name == "Run":
		_charge_ring_mesh.visible = true
		_charge_ring_mesh.position = Vector3(0.0, 0.95, -0.22)
		_charge_ring_mesh.scale = Vector3.ONE * (0.65 + sin(elapsed * 18.0) * 0.12)
		_charge_ring_mesh.rotation = Vector3(0.35, 0.0, elapsed * 12.0)
		return

	if active_state_name != "Attack" or active_attack == null:
		return
	if active_attack.vfx_type.is_empty() or active_attack.vfx_type == "none":
		return

	var off_x: float = active_attack.hitbox_offset.x
	var off_y: float = active_attack.hitbox_offset.y
	var rad: float = active_attack.hitbox_radius if active_attack.hitbox_radius > 0.0 else 0.75

	if attack_phase == "startup":
		_charge_ring_mesh.visible = true
		_charge_ring_mesh.position = Vector3(0.0, off_y, 0.25)
		_charge_ring_mesh.scale = Vector3.ONE * (0.35 + sin(elapsed * 25.0) * 0.12)
		_charge_ring_mesh.rotation = Vector3(0.0, 0.0, elapsed * 10.0)
		return

	if attack_phase != "active":
		return

	match active_attack.vfx_type:
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
		"ki_beam", "gaster_beam":
			_beam_group.visible = true
			_beam_group.position = Vector3(0.0, off_y, 0.65)
			_beam_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
			var p: float = 1.0 + sin(elapsed * 45.0) * 0.18
			_beam_group.scale = Vector3(1.0, p, p)
		"bone_spike":
			_bone_pillar_group.visible = true
			_bone_pillar_group.position = Vector3(0.0, maxf(0.2, off_y - 0.35), off_x)
			_bone_pillar_group.rotation = Vector3(0.0, -PI * 0.5, 0.0)
		"stardust_orb", "gravity_slam", "teleport_burst":
			_stardust_orb_mesh.visible = true
			_stardust_orb_mesh.position = Vector3(0.0, off_y, off_x)
			_stardust_orb_mesh.scale = Vector3.ONE * (rad * (0.85 + sin(elapsed * 30.0) * 0.15))
			_set_mesh_color(_stardust_orb_mesh, Color(0.15, 0.39, 0.92, 0.82) if active_attack.vfx_type == "gravity_slam" else Color(0.98, 0.75, 0.14, 0.82))
		"silk_thrust_starburst":
			_silk_thrust_starburst_group.visible = true
			_silk_thrust_starburst_group.position = Vector3(off_x, off_y, 0.05)
			var p: float = 1.0 + sin(elapsed * 45.0) * 0.12
			_silk_thrust_starburst_group.scale = Vector3(p, p, 1.0)
		"silk_buzzsaw":
			_silk_buzzsaw_group.visible = true
			_silk_buzzsaw_group.position = Vector3(0.0, 0.75, 0.05)
			_silk_buzzsaw_group.rotation.z = elapsed * 42.0
			var p: float = 1.0 + sin(elapsed * 35.0) * 0.08
			_silk_buzzsaw_group.scale = Vector3(p, p, 1.0)
		"silk_dair_drill":
			_silk_dair_drill_group.visible = true
			_silk_dair_drill_group.position = Vector3(off_x, off_y, 0.05)
			_silk_dair_drill_group.rotation = Vector3(0.0, 0.0, -PI * 0.35)
			var p: float = 1.0 + sin(elapsed * 40.0) * 0.10
			_silk_dair_drill_group.scale = Vector3(p, p, 1.15)
		"silk_spear_beam":
			_silk_spear_beam_group.visible = true
			_silk_spear_beam_group.position = Vector3(0.2, off_y, 0.05)
			var p: float = 1.0 + sin(elapsed * 30.0) * 0.05
			_silk_spear_beam_group.scale = Vector3(1.0, p, p)
		"silk_dome_eruption":
			_silk_dome_eruption_group.visible = true
			_silk_dome_eruption_group.position = Vector3(0.0, -0.80, 0.05)
			var p: float = clampf(elapsed * 12.0, 0.2, 1.25)
			_silk_dome_eruption_group.scale = Vector3(p, p, p)
		"silk_nair_surround":
			_silk_nair_surround_group.visible = true
			_silk_nair_surround_group.position = Vector3(0.0, 0.0, 0.05)
			_silk_nair_surround_group.rotation = Vector3(elapsed * 25.0, elapsed * 32.0, elapsed * 18.0)
		"silk_slash_whip", "silk_slash_up", "silk_slash_low", "silk_bair_whip", "silk_fsmash", "silk_needle_lunge":
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(1.0, 1.0, 1.0, 0.96))
			var rot_z: float = deg_to_rad(active_attack.angle_degrees - 45.0) if active_attack.angle_degrees != 0.0 else 0.0
			_slash_arc_mesh.position = Vector3(off_x * 0.85, off_y, 0.05)
			_slash_arc_mesh.rotation = Vector3(0.0, 0.0, rot_z - elapsed * 12.0)
			_slash_arc_mesh.scale = Vector3.ONE * (rad * 1.35)
		_:
			_slash_arc_mesh.visible = true
			_set_mesh_color(_slash_arc_mesh, Color(0.98, 0.75, 0.14, 0.88) if active_attack.vfx_type == "slash_gold" else Color(0.22, 0.74, 0.97, 0.88))
			_slash_arc_mesh.position = Vector3(0.0, off_y, off_x * 0.75)
			_slash_arc_mesh.rotation = Vector3(0.0, PI * 0.5, deg_to_rad(active_attack.angle_degrees - 45.0) + elapsed * 8.0)
			_slash_arc_mesh.scale = Vector3.ONE * (rad * 1.15)
#endregion

#region Fábricas de Mallas Primitivas 3D
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
	grp.add_child(_create_sphere_mesh(0.42, Color(0.95, 0.98, 1.0, 0.95)))
	var cyl := _create_cyl_mesh(0.28, 0.36, 2.6, Color(0.22, 0.74, 0.97, 0.88))
	cyl.rotation.z = -PI * 0.5
	cyl.position.x = 1.35
	grp.add_child(cyl)
	return grp

func _create_bone_pillar_group() -> Node3D:
	var grp := Node3D.new()
	var col := Color(0.95, 0.98, 1.0, 0.95)
	for i in [-1, 0, 1]:
		var single := Node3D.new()
		single.add_child(_create_cyl_mesh(0.06, 0.06, 0.85, col))
		var knob_l := _create_sphere_mesh(0.09, col)
		knob_l.position = Vector3(-0.05, 0.42, 0.0)
		var knob_r := _create_sphere_mesh(0.09, col)
		knob_r.position = Vector3(0.05, 0.42, 0.0)
		single.add_child(knob_l)
		single.add_child(knob_r)
		single.position = Vector3(float(i) * 0.26, 0.35, 0.0)
		single.rotation.z = float(i) * -0.15
		grp.add_child(single)
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
	grp.add_child(_create_torus_mesh(0.96, 0.068, Color(0.15, 0.39, 0.92, 0.88)))
	var b2 := _create_torus_mesh(0.92, 0.052, Color(0.22, 0.74, 0.97, 0.84))
	b2.position.z = 0.04
	grp.add_child(b2)
	var w1 := _create_torus_mesh(0.76, 0.024, Color(0.97, 0.98, 1.0, 0.82))
	w1.position.z = -0.05
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

func _create_silk_thrust_starburst_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_sphere_mesh(0.22, Color(1.0, 1.0, 1.0, 0.98)))
	grp.add_child(_create_torus_mesh(0.48, 0.022, Color(1.0, 1.0, 1.0, 0.85)))
	var angles := [-60.0, -45.0, -30.0, -15.0, 0.0, 15.0, 30.0, 45.0, 60.0, 180.0]
	var lengths := [0.85, 1.15, 1.35, 1.45, 1.55, 1.45, 1.35, 1.15, 0.85, 0.65]
	for i in range(angles.size()):
		var spike := _create_cyl_mesh(0.005, 0.045, lengths[i], Color(1.0, 1.0, 1.0, 0.95))
		var ang: float = deg_to_rad(angles[i])
		spike.position = Vector3(cos(ang) * (lengths[i] * 0.45), sin(ang) * (lengths[i] * 0.45), 0.0)
		spike.rotation.z = ang - PI * 0.5
		grp.add_child(spike)
	return grp

func _create_silk_buzzsaw_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_torus_mesh(1.05, 0.038, Color(1.0, 1.0, 1.0, 0.96)))
	grp.add_child(_create_torus_mesh(0.72, 0.025, Color(1.0, 1.0, 1.0, 0.88)))
	grp.add_child(_create_sphere_mesh(0.24, Color(1.0, 1.0, 1.0, 0.98)))
	for i in range(8):
		var blade := _create_cyl_mesh(0.01, 0.05, 1.0, Color(1.0, 1.0, 1.0, 0.92))
		blade.rotation.z = float(i) * (PI * 0.25)
		grp.add_child(blade)
	return grp

func _create_silk_dair_drill_group() -> Node3D:
	var grp := Node3D.new()
	var cone_out := _create_cyl_mesh(0.02, 0.68, 2.45, Color(1.0, 1.0, 1.0, 0.75))
	cone_out.rotation.z = PI * 0.5
	grp.add_child(cone_out)
	var cone_in := _create_cyl_mesh(0.01, 0.42, 2.25, Color(1.0, 1.0, 1.0, 0.95))
	cone_in.rotation.z = PI * 0.5
	grp.add_child(cone_in)
	var ring1 := _create_torus_mesh(0.55, 0.028, Color(1.0, 1.0, 1.0, 0.90))
	ring1.position.x = 0.5
	ring1.rotation.y = PI * 0.5
	grp.add_child(ring1)
	var ring2 := _create_torus_mesh(0.40, 0.022, Color(1.0, 1.0, 1.0, 0.85))
	ring2.position.x = -0.3
	ring2.rotation.y = PI * 0.5
	grp.add_child(ring2)
	return grp

func _create_silk_spear_beam_group() -> Node3D:
	var grp := Node3D.new()
	var beam := _create_cyl_mesh(0.032, 0.032, 4.2, Color(1.0, 1.0, 1.0, 0.98))
	beam.rotation.z = PI * 0.5
	beam.position.x = 2.1
	grp.add_child(beam)
	var glow := _create_cyl_mesh(0.065, 0.065, 4.0, Color(1.0, 1.0, 1.0, 0.60))
	glow.rotation.z = PI * 0.5
	glow.position.x = 2.1
	grp.add_child(glow)
	var impact_burst := _create_sphere_mesh(0.24, Color(1.0, 1.0, 1.0, 0.98))
	impact_burst.position.x = 4.2
	grp.add_child(impact_burst)
	return grp

func _create_silk_dome_eruption_group() -> Node3D:
	var grp := Node3D.new()
	var shock_ring := _create_torus_mesh(1.65, 0.045, Color(1.0, 1.0, 1.0, 0.90))
	shock_ring.rotation.x = PI * 0.5
	grp.add_child(shock_ring)
	var spike_angles := [-75.0, -65.0, -55.0, -45.0, -35.0, -25.0, -15.0, -5.0, 5.0, 15.0, 25.0, 35.0, 45.0, 55.0, 65.0, 75.0]
	var heights := [1.4, 1.7, 1.9, 2.2, 2.5, 2.7, 2.8, 2.9, 2.9, 2.8, 2.7, 2.5, 2.2, 1.9, 1.7, 1.4]
	for i in range(spike_angles.size()):
		var h: float = heights[i]
		var ang: float = deg_to_rad(spike_angles[i])
		var spike := _create_cyl_mesh(0.008, 0.075, h, Color(1.0, 1.0, 1.0, 0.95))
		spike.position = Vector3(sin(ang) * (h * 0.45), cos(ang) * (h * 0.45), 0.0)
		spike.rotation.z = -ang
		grp.add_child(spike)
	return grp

func _create_silk_nair_surround_group() -> Node3D:
	var grp := Node3D.new()
	grp.add_child(_create_torus_mesh(1.15, 0.035, Color(1.0, 1.0, 1.0, 0.92)))
	var r2 := _create_torus_mesh(1.08, 0.028, Color(1.0, 1.0, 1.0, 0.85))
	r2.rotation.x = PI * 0.5
	grp.add_child(r2)
	var r3 := _create_torus_mesh(1.02, 0.025, Color(1.0, 1.0, 1.0, 0.78))
	r3.rotation.y = PI * 0.5
	grp.add_child(r3)
	return grp
#endregion

