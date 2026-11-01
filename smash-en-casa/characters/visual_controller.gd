# ==============================================================================
# VisualController — Puente Híbrido 2.5D (Física 2D -> Modelo 3D)
# ==============================================================================
# Instancia el modelo 3D del personaje bajo el nodo "Humanoid/ModelRoot" y
# sincroniza en cada frame su posición 3D con la posición física 2D del luchador,
# además de gestionar el giro suave de cámara o el modo espejo 2.5D (ej. Hornet).
# ==============================================================================
class_name VisualController
extends Node

@export var character: Character = null
@export var visual_root_3d: Node3D = null

var timestop_shiver_timer: float = 0.0
var hitlag_shake_offset: Vector3 = Vector3.ZERO
var target_rotation_y: float = PI * 0.42
var smooth_turn_active: bool = false

#region Inicialización e Instanciación del Modelo 3D
func _ready() -> void:
	if character == null and get_parent() is Character:
		character = get_parent() as Character
	if visual_root_3d == null and character and character.has_node("Humanoid"):
		visual_root_3d = character.get_node("Humanoid") as Node3D

func setup(char_node: Character, data: CharacterData) -> void:
	character = char_node
	if visual_root_3d == null and character and character.has_node("Humanoid"):
		visual_root_3d = character.get_node("Humanoid") as Node3D
	if visual_root_3d == null or data == null:
		return

	if data.model_scene:
		# Ocultar el maniquí de cápsulas por defecto cuando el personaje trae su propio GLB
		for child in visual_root_3d.get_children():
			if child.name.begins_with("Debug") or child.name in ["ShieldMesh", "ModelRoot"]:
				continue
			if child is CanvasItem or child is Node3D:
				child.visible = false

		var old_model: Node = visual_root_3d.get_node_or_null("ModelRoot")
		if old_model:
			old_model.queue_free()

		var model_instance: Node3D = data.model_scene.instantiate()
		model_instance.name = "ModelRoot"
		model_instance.position = data.model_offset
		var model_scale_val: float = data.model_scale if data.model_scale > 0.0 else 1.0
		model_instance.scale = Vector3.ONE * model_scale_val
		visual_root_3d.add_child(model_instance)
	else:
		_apply_color_recursive(visual_root_3d, data.character_color)

	var initial_dir: float = character.get_facing_direction() if character else 1.0
	update_rotation(initial_dir, false)

func _apply_color_recursive(node: Node, color: Color) -> void:
	for child in node.get_children():
		if child.name.begins_with("Debug") or child.name == "ShieldMesh":
			continue
		if child is MeshInstance3D:
			var mesh_inst: MeshInstance3D = child as MeshInstance3D
			var mat: StandardMaterial3D = mesh_inst.get_surface_override_material(0) as StandardMaterial3D
			if mat:
				mat.albedo_color = color
			mesh_inst.visible = true
		_apply_color_recursive(child, color)
#endregion

#region Sincronización de Posición y Rotación 2.5D
func sync_3d_visuals(delta: float) -> void:
	if visual_root_3d == null or character == null:
		return

	var target_3d_pos: Vector3 = Utils.pos_2d_to_3d(character.global_position)
	if timestop_shiver_timer > 0.0:
		timestop_shiver_timer -= delta
		target_3d_pos.x += randf_range(-0.06, 0.06)
	visual_root_3d.global_position = target_3d_pos + hitlag_shake_offset

	var damp_speed: float = 13.5 if smooth_turn_active else 22.0
	visual_root_3d.rotation.y = CharacterController.damp(
		visual_root_3d.rotation.y,
		target_rotation_y,
		damp_speed,
		minf(delta, 0.05)
	)
	if absf(visual_root_3d.rotation.y - target_rotation_y) < 0.02:
		smooth_turn_active = false

func update_rotation(dir: float, smooth_turn: bool = false) -> void:
	var sign_dir: float = 1.0 if dir >= 0.0 else -1.0
	var is_mirror: bool = false
	if character and character.character_data and character.character_data.use_mirror_facing:
		is_mirror = true
	elif character and character.is_hornet():
		is_mirror = true

	if is_mirror:
		# Modo espejo horizontal 2.5D: invierte scale.x para no mostrar nunca la espalda a la cámara
		var base_s: float = 1.0
		if character and character.character_data and character.character_data.model_scale > 0.0:
			base_s = character.character_data.model_scale

		var model_inst: Node3D = visual_root_3d.get_node_or_null("ModelRoot") as Node3D if visual_root_3d else null
		if model_inst:
			model_inst.scale.x = sign_dir * base_s
		elif visual_root_3d != null:
			visual_root_3d.scale.x = sign_dir * absf(visual_root_3d.scale.x)

		var vfx_node: Node3D = visual_root_3d.get_node_or_null("CombatVfxGroup") as Node3D if visual_root_3d else null
		if vfx_node:
			vfx_node.scale.x = sign_dir

		var angle_rad: float = 0.26
		if character and character.character_data and character.character_data.facing_angle_degrees > 0.0:
			angle_rad = deg_to_rad(character.character_data.facing_angle_degrees)
		target_rotation_y = angle_rad
		smooth_turn_active = false
		if visual_root_3d != null:
			visual_root_3d.rotation.y = target_rotation_y
	else:
		var angle_rad: float = PI * 0.42
		if character and character.character_data and character.character_data.facing_angle_degrees > 0.0:
			angle_rad = deg_to_rad(character.character_data.facing_angle_degrees)
		target_rotation_y = sign_dir * angle_rad
		smooth_turn_active = smooth_turn
		if not smooth_turn and visual_root_3d != null:
			visual_root_3d.rotation.y = target_rotation_y

	if character and character.anim_controller:
		character.anim_controller.on_facing_direction_changed(sign_dir)

func get_shield_mesh() -> Node3D:
	if visual_root_3d and visual_root_3d.has_node("ShieldMesh"):
		return visual_root_3d.get_node("ShieldMesh") as Node3D
	return null
#endregion
