# ==============================================================================
# DeathStreakVFX — Haz Luminoso de Eliminación (Blast Zone KO)
# ==============================================================================
# Efecto visual procedural 3D inspirado en Super Smash Bros Ultimate: cuando un
# jugador cruza los límites del escenario, dispara un cilindro de energía con
# chispas y un anillo expansivo desde el punto de salida hacia el centro.
# ==============================================================================
class_name DeathStreakVFX
extends Node3D

const LIFETIME: float = 0.55
const SPARK_COLORS: Array[Color] = [
	Color(0.2, 0.8, 1.0),
	Color(1.0, 0.85, 0.2),
	Color(1.0, 0.35, 0.9),
	Color(0.3, 1.0, 0.6),
	Color(1.0, 1.0, 1.0)
]

var from_pos: Vector3 = Vector3.ZERO
var to_pos: Vector3 = Vector3(0.0, 1.5, 0.0)
var elapsed: float = 0.0

var _core_mesh: MeshInstance3D
var _glow_mesh: MeshInstance3D
var _spark_nodes: Array[MeshInstance3D] = []
var _target_ring: MeshInstance3D

func _ready() -> void:
	_build_beam()

func setup(start_pos: Vector3, center_pos: Vector3 = Vector3(0.0, 1.5, 0.0)) -> void:
	from_pos = start_pos
	to_pos = center_pos
	if _core_mesh:
		_align_beam()

func _build_beam() -> void:
	var length: float = maxf(1.0, (to_pos - from_pos).length())

	# 1. Cilindro exterior translúcido (resplandor azulado)
	_glow_mesh = _create_cylinder(0.75, 1.35, length, Color(0.2, 0.75, 1.0, 0.75))
	add_child(_glow_mesh)

	# 2. Núcleo interior blanco brillante
	_core_mesh = _create_cylinder(0.28, 0.55, length, Color(1.0, 1.0, 1.0, 0.95))
	add_child(_core_mesh)

	# 3. Chispas de energía viajando a lo largo del haz
	for i in range(16):
		var spark := MeshInstance3D.new()
		var s_mesh := BoxMesh.new()
		s_mesh.size = Vector3(0.18, randf_range(0.6, 1.4), 0.18)
		spark.mesh = s_mesh
		spark.material_override = _make_additive_material(SPARK_COLORS[i % SPARK_COLORS.size()])

		var t: float = randf()
		spark.position = from_pos.lerp(to_pos, t) + Vector3(
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8),
			randf_range(-0.8, 0.8)
		)
		spark.set_meta("speed_t", randf_range(1.5, 3.5))
		spark.set_meta("base_t", t)
		add_child(spark)
		_spark_nodes.append(spark)

	# 4. Anillo de onda expansiva en el centro
	_target_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.3
	_target_ring.mesh = ring
	_target_ring.material_override = _make_additive_material(Color(0.4, 0.85, 1.0, 0.8))
	_target_ring.position = to_pos
	_target_ring.rotation.x = PI * 0.5
	add_child(_target_ring)

	_align_beam()

func _create_cylinder(top_r: float, bottom_r: float, height_val: float, col: Color) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bottom_r
	cyl.height = height_val
	inst.mesh = cyl
	inst.material_override = _make_additive_material(col)
	return inst

func _make_additive_material(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = col
	return mat

func _align_beam() -> void:
	var dir: Vector3 = to_pos - from_pos
	var length: float = dir.length()
	if length < 0.01:
		return

	var mid: Vector3 = (from_pos + to_pos) * 0.5
	var up: Vector3 = dir.normalized()
	var right: Vector3 = Vector3.UP.cross(up)
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT.cross(up)
	right = right.normalized()
	var forward: Vector3 = up.cross(right).normalized()
	var beam_basis := Basis(right, up, forward)

	for mesh_node in [_glow_mesh, _core_mesh]:
		if mesh_node:
			mesh_node.position = mid
			mesh_node.basis = beam_basis
			var cyl := mesh_node.mesh as CylinderMesh
			if cyl:
				cyl.height = length

func _process(delta: float) -> void:
	elapsed += delta
	var progress: float = elapsed / LIFETIME
	if progress >= 1.0:
		queue_free()
		return

	var width_factor: float = (ease(progress / 0.2, 0.5) if progress < 0.2 else (1.0 - (progress - 0.2) / 0.8)) * 1.4
	var alpha_factor: float = 1.0 - progress

	if _core_mesh and _core_mesh.material_override is StandardMaterial3D:
		_core_mesh.scale.x = width_factor
		_core_mesh.scale.z = width_factor
		(_core_mesh.material_override as StandardMaterial3D).albedo_color.a = 0.95 * alpha_factor

	if _glow_mesh and _glow_mesh.material_override is StandardMaterial3D:
		_glow_mesh.scale.x = width_factor * 1.3
		_glow_mesh.scale.z = width_factor * 1.3
		(_glow_mesh.material_override as StandardMaterial3D).albedo_color.a = 0.75 * alpha_factor

	for spark in _spark_nodes:
		if is_instance_valid(spark):
			var cur_t: float = fmod(float(spark.get_meta("base_t")) + progress * float(spark.get_meta("speed_t")), 1.0)
			spark.position = from_pos.lerp(to_pos, cur_t)
			if spark.material_override is StandardMaterial3D:
				(spark.material_override as StandardMaterial3D).albedo_color.a = alpha_factor

	if _target_ring:
		var ring_scale: float = 1.0 + progress * 2.5
		_target_ring.scale = Vector3(ring_scale, ring_scale, ring_scale)
		if _target_ring.material_override is StandardMaterial3D:
			(_target_ring.material_override as StandardMaterial3D).albedo_color.a = alpha_factor * 0.8
