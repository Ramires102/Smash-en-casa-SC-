class_name VisualController
extends Node

@export var character: Character = null
@export var visual_root_3d: Node3D = null

var timestop_shiver_timer: float = 0.0
var hitlag_shake_offset: Vector3 = Vector3.ZERO


func _ready() -> void:
	if character == null and get_parent() is Character:
		character = get_parent() as Character
	if visual_root_3d == null and character and character.has_node("Humanoid"):
		visual_root_3d = character.get_node("Humanoid") as Node3D

func setup(char_node: Character, data: CharacterData) -> void:
	character = char_node
	if visual_root_3d == null:
		if character and character.has_node("Humanoid"):
			visual_root_3d = character.get_node("Humanoid") as Node3D
	if visual_root_3d == null or data == null:
		return

	if data.model_scene:
		for child in visual_root_3d.get_children():
			if child.name.begins_with("Debug") or child.name in ["ShieldMesh", "DazeStars", "MenacingAura", "ModelRoot"]:
				continue
			if child is CanvasItem or child is Node3D:
				child.visible = false

		var old_model: Node = visual_root_3d.get_node_or_null("ModelRoot")
		if old_model:
			old_model.queue_free()

		var model_instance: Node3D = data.model_scene.instantiate()
		model_instance.name = "ModelRoot"
		model_instance.position = data.model_offset
		var s: float = data.model_scale
		model_instance.scale = Vector3(s, s, s)
		visual_root_3d.add_child(model_instance)
	else:
		_apply_color_recursive(visual_root_3d, data.character_color)

func _apply_color_recursive(node: Node, color: Color) -> void:
	for child in node.get_children():
		if child.name.begins_with("Debug") or child.name in ["ShieldMesh", "DazeStars", "MenacingAura"]:
			continue
		if child is MeshInstance3D:
			var mesh_inst: MeshInstance3D = child as MeshInstance3D
			var mat: StandardMaterial3D = mesh_inst.get_surface_override_material(0) as StandardMaterial3D
			if mat:
				mat.albedo_color = color
			mesh_inst.visible = true
		_apply_color_recursive(child, color)


func sync_3d_visuals(delta: float) -> void:
	if visual_root_3d == null or character == null:
		return

	var target_3d_pos := Vector3(
		character.global_position.x / Constants.UNIT_SIZE,
		-character.global_position.y / Constants.UNIT_SIZE,
		0.0
	)

	if timestop_shiver_timer > 0.0:
		timestop_shiver_timer -= delta
		target_3d_pos.x += randf_range(-0.06, 0.06)

	visual_root_3d.global_position = target_3d_pos + hitlag_shake_offset


func update_rotation(dir: float) -> void:
	if visual_root_3d:
		visual_root_3d.rotation_degrees.y = 90.0 if dir > 0.0 else -90.0
	if character and character.anim_controller and character.anim_controller.has_method("on_facing_direction_changed"):
		character.anim_controller.on_facing_direction_changed(dir)

func set_menacing_aura_enabled(enabled: bool) -> void:
	if visual_root_3d:
		var aura_node: Node3D = visual_root_3d.get_node_or_null("MenacingAura")
		if aura_node:
			aura_node.visible = enabled

func update_menacing_aura(delta: float) -> void:
	if visual_root_3d:
		var aura_node: Node3D = visual_root_3d.get_node_or_null("MenacingAura")
		if aura_node and aura_node.visible:
			aura_node.rotate_y(delta * 1.2)

func set_daze_effects_enabled(enabled: bool) -> void:
	if visual_root_3d:
		var stars: Node3D = visual_root_3d.get_node_or_null("DazeStars")
		if stars:
			stars.visible = enabled

func update_daze_effects(delta: float, _timer: float = 0.0) -> void:
	if visual_root_3d:
		var stars: Node3D = visual_root_3d.get_node_or_null("DazeStars")
		if stars and stars.visible:
			stars.rotate_y(delta * 4.0)

func get_shield_mesh() -> Node3D:
	if visual_root_3d and visual_root_3d.has_node("ShieldMesh"):
		return visual_root_3d.get_node("ShieldMesh") as Node3D
	return null
