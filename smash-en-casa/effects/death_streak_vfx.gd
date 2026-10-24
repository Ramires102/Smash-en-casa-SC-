class_name DeathStreakVFX
extends Node3D

## Visual effect inspired by Super Smash Con / Smash Ultimate death streaks:
## Shoots an intense luminous energy ray + spark trail from the death blast zone towards stage center.

var from_pos: Vector3 = Vector3.ZERO
var to_pos: Vector3 = Vector3(0.0, 1.5, 0.0)
var elapsed: float = 0.0
const LIFETIME: float = 0.55

var _core_mesh: MeshInstance3D
var _glow_mesh: MeshInstance3D
var _spark_nodes: Array[MeshInstance3D] = []
var _target_ring: MeshInstance3D

func _ready() -> void:
	_build_beam()

func setup(start_pos: Vector3, center_pos: Vector3 = Vector3(0.0, 1.5, 0.0)) -> void:
	from_pos = start_pos
	to_pos = center_pos
	# Ensure the beam is visually oriented
	if _core_mesh:
		_align_beam()

func _build_beam() -> void:
	var dir = to_pos - from_pos
	var length = dir.length()
	if length < 0.1:
		length = 1.0
		
	# 1. Outer Glow Sheath Cylinder
	_glow_mesh = MeshInstance3D.new()
	var glow_cyl = CylinderMesh.new()
	glow_cyl.top_radius = 0.75
	glow_cyl.bottom_radius = 1.35
	glow_cyl.height = length
	_glow_mesh.mesh = glow_cyl
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.albedo_color = Color(0.2, 0.75, 1.0, 0.75)
	_glow_mesh.material_override = glow_mat
	add_child(_glow_mesh)
	
	# 2. Intense White Core Cylinder
	_core_mesh = MeshInstance3D.new()
	var core_cyl = CylinderMesh.new()
	core_cyl.top_radius = 0.28
	core_cyl.bottom_radius = 0.55
	core_cyl.height = length
	_core_mesh.mesh = core_cyl
	
	var core_mat = StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	core_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.95)
	_core_mesh.material_override = core_mat
	add_child(_core_mesh)
	
	# 3. Energy sparks / particle streak along the beam
	for i in range(16):
		var spark = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.18, randf_range(0.6, 1.4), 0.18)
		spark.mesh = s_mesh
		
		var s_mat = StandardMaterial3D.new()
		s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		# Rainbow / electric spark colors (cyan, magenta, gold, lime)
		var spark_colors = [
			Color(0.2, 0.8, 1.0),
			Color(1.0, 0.85, 0.2),
			Color(1.0, 0.35, 0.9),
			Color(0.3, 1.0, 0.6),
			Color(1.0, 1.0, 1.0)
		]
		s_mat.albedo_color = spark_colors[i % spark_colors.size()]
		spark.material_override = s_mat
		
		var t = randf()
		spark.position = from_pos.lerp(to_pos, t) + Vector3(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8), randf_range(-0.8, 0.8))
		spark.set_meta("speed_t", randf_range(1.5, 3.5))
		spark.set_meta("base_t", t)
		add_child(spark)
		_spark_nodes.append(spark)
		
	# 4. Impact Torus / Ring at center
	_target_ring = MeshInstance3D.new()
	var ring = TorusMesh.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.3
	_target_ring.mesh = ring
	var r_mat = StandardMaterial3D.new()
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	r_mat.albedo_color = Color(0.4, 0.85, 1.0, 0.8)
	_target_ring.material_override = r_mat
	_target_ring.position = to_pos
	_target_ring.rotation.x = PI / 2.0
	add_child(_target_ring)
	
	_align_beam()

func _align_beam() -> void:
	var dir = to_pos - from_pos
	var length = dir.length()
	if length < 0.01:
		return
		
	var mid = (from_pos + to_pos) * 0.5
	for mesh_node in [_glow_mesh, _core_mesh]:
		if mesh_node:
			mesh_node.position = mid
			# Cylinder in Godot is aligned with Y axis. Orient Y along `dir`
			var up = dir.normalized()
			var right = Vector3.UP.cross(up)
			if right.length_squared() < 0.001:
				right = Vector3.RIGHT.cross(up)
			right = right.normalized()
			var forward = up.cross(right).normalized()
			mesh_node.basis = Basis(right, up, forward)

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / LIFETIME
	if progress >= 1.0:
		queue_free()
		return
		
	# Expand width initially then collapse
	var width_factor: float
	if progress < 0.2:
		width_factor = ease(progress / 0.2, 0.5) * 1.4
	else:
		width_factor = (1.0 - (progress - 0.2) / 0.8) * 1.4
		
	var alpha_factor = (1.0 - progress)
	
	if _core_mesh and _core_mesh.material_override is StandardMaterial3D:
		_core_mesh.scale.x = width_factor
		_core_mesh.scale.z = width_factor
		var m = _core_mesh.material_override as StandardMaterial3D
		m.albedo_color.a = 0.95 * alpha_factor
		
	if _glow_mesh and _glow_mesh.material_override is StandardMaterial3D:
		_glow_mesh.scale.x = width_factor * 1.3
		_glow_mesh.scale.z = width_factor * 1.3
		var m = _glow_mesh.material_override as StandardMaterial3D
		m.albedo_color.a = 0.75 * alpha_factor
		
	# Animate sparks rushing towards center
	for spark in _spark_nodes:
		if is_instance_valid(spark):
			var base_t = spark.get_meta("base_t")
			var spd = spark.get_meta("speed_t")
			var cur_t = fmod(base_t + progress * spd, 1.0)
			spark.position = from_pos.lerp(to_pos, cur_t)
			if spark.material_override is StandardMaterial3D:
				spark.material_override.albedo_color.a = alpha_factor
				
	# Animate impact ring expanding
	if _target_ring:
		var ring_scale = 1.0 + progress * 2.5
		_target_ring.scale = Vector3(ring_scale, ring_scale, ring_scale)
		if _target_ring.material_override is StandardMaterial3D:
			_target_ring.material_override.albedo_color.a = alpha_factor * 0.8
