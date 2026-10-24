class_name CSRosterLoader
extends RefCounted

const INSTANCES_DIR: String = "res://resources/instances"
const EXCLUDED_CHARACTER_FILES: Array[String] = [
	"miyabi_data.tres",
	"nekomiya_data.tres"
]

static func discover_playable_characters(seed_list: Array[CharacterData], extra_characters: Array[CharacterData]) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	var seen_keys: Dictionary = {}

	var combined: Array[CharacterData] = seed_list.duplicate()
	for extra in extra_characters:
		if extra != null:
			combined.append(extra)

	for ch in combined:
		if ch == null:
			continue
		var key: String = ch.resource_path if ch.resource_path != "" else ch.character_name.to_lower()
		if not seen_keys.has(key):
			seen_keys[key] = true
			seen_keys[ch.character_name.to_lower()] = true
			result.append(ch)

	var dir := DirAccess.open(INSTANCES_DIR)
	if dir:
		var discovered_files: Array[String] = []
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if not dir.current_is_dir():
				var clean_name: String = fname.trim_suffix(".remap")
				if clean_name.ends_with("_data.tres") and not (clean_name in EXCLUDED_CHARACTER_FILES):
					if not (clean_name in discovered_files):
						discovered_files.append(clean_name)
			fname = dir.get_next()
		dir.list_dir_end()
		discovered_files.sort()

		for f in discovered_files:
			var full_path: String = INSTANCES_DIR + "/" + f
			if seen_keys.has(full_path) or not is_valid_character_tres(full_path):
				continue
			var loaded = ResourceLoader.load(full_path)
			if loaded is CharacterData:
				var cdata := loaded as CharacterData
				var name_key: String = cdata.character_name.to_lower()
				if not seen_keys.has(name_key):
					seen_keys[full_path] = true
					seen_keys[name_key] = true
					result.append(cdata)

	return result

static func is_valid_character_tres(res_path: String) -> bool:
	if not FileAccess.file_exists(res_path):
		return ResourceLoader.exists(res_path)
	var txt: String = FileAccess.get_file_as_string(res_path)
	if txt == "":
		return false
	for line in txt.split("\n"):
		if line.begins_with("[ext_resource"):
			var p_idx: int = line.find("path=\"")
			if p_idx != -1:
				var start_idx: int = p_idx + 6
				var end_idx: int = line.find("\"", start_idx)
				if end_idx != -1:
					var dep_path: String = line.substr(start_idx, end_idx - start_idx)
					if not ResourceLoader.exists(dep_path) and not FileAccess.file_exists(dep_path):
						return false
	return true

static func build_roster_slots(playable_characters: Array[CharacterData]) -> Array[Dictionary]:
	var slots: Array[Dictionary] = [{
		"id": "random",
		"name": "ALEATORIO",
		"data": null,
		"row": 0,
		"col": 0,
		"tex_path": "res://ui/character_select/portraits/random.png",
		"color": Color(1.0, 0.85, 0.25)
	}]

	var count: int = playable_characters.size()
	var cols_per_row: int = 3 if (count >= 5 and count <= 9) else (4 if count >= 10 else 2)

	for idx in range(count):
		var cdata: CharacterData = playable_characters[idx]
		slots.append({
			"id": cdata.character_name.to_lower().replace(" ", "_"),
			"name": format_card_display_name(cdata),
			"data": cdata,
			"row": 1 + int(float(idx) / float(cols_per_row)),
			"col": idx % cols_per_row,
			"tex_path": "",
			"color": get_character_accent_color(cdata)
		})
	return slots

static func format_card_display_name(data: CharacterData) -> String:
	var raw_name: String = data.display_name if data.display_name != "" else data.character_name
	var upper: String = raw_name.strip_edges().to_upper()
	if upper == "SAKUYA":
		return "SAKUYA\nIZAYOI"
	if upper == "GOGETA SSJ":
		return "GOGETA\nSSJ"
	if upper.contains(" ") and not upper.contains("\n"):
		var parts: PackedStringArray = upper.split(" ", false)
		if parts.size() == 2:
			return parts[0] + "\n" + parts[1]
	return upper

static func get_character_accent_color(data: CharacterData) -> Color:
	var cname: String = data.character_name.to_lower()
	if cname.contains("batman"):
		return Color(0.95, 0.82, 0.15)
	if cname.contains("sakuya"):
		return Color(0.45, 0.75, 1.0)
	if cname.contains("gogeta"):
		return Color(0.98, 0.68, 0.12)
	if cname.contains("sans"):
		return Color(0.22, 0.78, 1.0)
	if data.character_color != Color.WHITE and data.character_color.v > 0.25:
		return data.character_color
	return Color(0.4, 0.85, 0.95)

static func build_3d_card_arc(
	owner_node: Node3D,
	card_arc_root: Node3D,
	roster_slots: Array[Dictionary],
	card_nodes: Dictionary,
	portrait_viewports: Array[SubViewport],
	on_card_input: Callable
) -> void:
	for child in card_arc_root.get_children():
		child.queue_free()
	card_nodes.clear()
	for vp in portrait_viewports:
		if is_instance_valid(vp):
			vp.queue_free()
	portrait_viewports.clear()

	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres")
	var row_counts: Dictionary = {}
	var max_row: int = 1
	for slot in roster_slots:
		var r: int = slot["row"]
		row_counts[r] = int(row_counts.get(r, 0)) + 1
		if r > max_row:
			max_row = r

	var card_size: float = 0.19 if max_row >= 3 else 0.22
	var col_spacing: float = 0.225 if max_row >= 3 else 0.255
	var row_spacing_y: float = 0.21 if max_row >= 3 else 0.245
	var row_spacing_z: float = 0.035

	for i in range(roster_slots.size()):
		var slot: Dictionary = roster_slots[i]
		var row: int = slot["row"]
		var col: int = slot["col"]

		var card_root := Node3D.new()
		card_root.name = "Card_" + slot["id"]

		var px: float = 0.0
		var py: float = (max_row - row) * row_spacing_y
		var pz: float = (row - 1) * row_spacing_z
		var yaw: float = 0.0

		if row == 0:
			py += 0.03
			pz -= 0.02
		else:
			var cols_in_row: int = int(row_counts.get(row, 1))
			var offset_col: float = float(col) - float(cols_in_row - 1) * 0.5
			px = offset_col * col_spacing
			yaw = -offset_col * 0.035
			pz -= absf(offset_col) * 0.008

		card_root.position = Vector3(px, py, pz)
		card_root.rotation.y = yaw
		card_root.set_meta("grid_x", px)
		card_root.set_meta("grid_row", row)
		card_root.set_meta("grid_col", col)
		card_root.set_meta("base_pos", card_root.position)

		var is_random_card: bool = (row == 0)
		var quad_w: float = 0.26 if is_random_card else card_size
		var quad_h: float = 0.16 if is_random_card else card_size

		var glow_mesh := _make_quad_mesh("Glow", Vector2(quad_w + 0.026, quad_h + 0.026), Color(1.0, 0.85, 0.2), Vector3(0.0, 0.0, -0.004))
		glow_mesh.visible = false
		card_root.add_child(glow_mesh)

		var accent_col: Color = slot.get("color", Color(0.85, 0.68, 0.22))
		card_root.add_child(_make_quad_mesh("Frame", Vector2(quad_w + 0.010, quad_h + 0.010), accent_col.darkened(0.25), Vector3(0.0, 0.0, -0.002)))

		var mesh_inst := _make_quad_mesh("CardMesh", Vector2(quad_w, quad_h), Color(0.88, 0.88, 0.90), Vector3.ZERO)
		var mat := mesh_inst.material_override as StandardMaterial3D
		if slot["data"] != null:
			var vp: SubViewport = CSPortraitRenderer.create_face_portrait_viewport(owner_node, slot)
			owner_node.add_child(vp)
			portrait_viewports.append(vp)
			mat.albedo_texture = vp.get_texture()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		else:
			mat.albedo_texture = _load_texture_safe(slot["tex_path"])
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.alpha_scissor_threshold = 0.5
		card_root.add_child(mesh_inst)

		var banner_h: float = 0.044 if is_random_card else 0.056
		var banner_mesh := _make_quad_mesh("NameBanner", Vector2(quad_w, banner_h), Color(0.03, 0.04, 0.07, 0.78), Vector3(0.0, -quad_h * 0.5 + banner_h * 0.5, 0.004))
		(banner_mesh.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		card_root.add_child(banner_mesh)

		var label := Label3D.new()
		label.text = slot["name"]
		label.font = font_res
		label.font_size = 8 if is_random_card else 7
		label.outline_size = 3
		label.outline_modulate = Color.BLACK
		label.modulate = Color(1.0, 0.96, 0.82, 1.0)
		label.line_spacing = -1.0
		label.position = Vector3(0.0, -quad_h * 0.5 + banner_h * 0.5, 0.010)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card_root.add_child(label)

		var area := Area3D.new()
		var col_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(quad_w, quad_h, 0.05)
		col_shape.shape = box
		area.add_child(col_shape)
		area.input_event.connect(on_card_input.bind(i))
		card_root.add_child(area)

		card_arc_root.add_child(card_root)
		card_nodes[i] = card_root

static func _make_quad_mesh(node_name: String, sz: Vector2, col: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var q := QuadMesh.new()
	q.size = sz
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mi.material_override = m
	mi.position = pos
	return mi

static func _load_texture_safe(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img:
			return ImageTexture.create_from_image(img)
	return null
