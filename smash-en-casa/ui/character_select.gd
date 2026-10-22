class_name CharacterSelect
extends Node3D

# ==============================================================================
# DBFZ Character Select Screen (Dragon Ball FighterZ Style)
# - Curved 3D fan/arc of roster cards
# - P1 (Blue) and P2 (Red) floating cursor tokens
# - Live 3D character models standing on pedestals playing Idle animations
# - Random (?) card on elevated top pedestal
# - Audio feedback with arcade sound effects
# - Controller, Keyboard, and Mouse support
# ==============================================================================

@export var lego_batman_data: CharacterData = preload("res://resources/instances/lego_batman_data.tres")
@export var sakuya_data: CharacterData = preload("res://resources/instances/sakuya_data.tres")
@export var gogeta_data: CharacterData = preload("res://resources/instances/gogeta_data.tres")
@export var john_data: CharacterData = preload("res://resources/instances/john_placeholder_data.tres")
<<<<<<< HEAD
=======
@export var nekomiya_data: CharacterData = preload("res://resources/instances/nekomiya_data.tres")
@export var sans_data: CharacterData = preload("res://resources/instances/sans_data.tres")
>>>>>>> 2c9b02c86124e4a6e6792e563c1f11ad358e3728

# Roster definition
var roster_slots: Array[Dictionary] = []

# Player states
var p1_slot_index: int = 1 # Default: Lego Batman
var p2_slot_index: int = 2 # Default: Sakuya
var p1_locked: bool = false
var p2_locked: bool = false
var p1_selected: CharacterData = null
var p2_selected: CharacterData = null

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var card_arc_root: Node3D = $CardArc
@onready var p1_stage_model: Node3D = $StageP1/ModelContainer
@onready var p2_stage_model: Node3D = $StageP2/ModelContainer
@onready var p1_token: Node3D = $Tokens/P1Token
@onready var p2_token: Node3D = $Tokens/P2Token
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# UI Overlay references
@onready var p1_name_label: Label = $CanvasLayer/UI/P1Info/NameLabel
@onready var p1_status_label: Label = $CanvasLayer/UI/P1Info/StatusLabel
@onready var p2_name_label: Label = $CanvasLayer/UI/P2Info/NameLabel
@onready var p2_status_label: Label = $CanvasLayer/UI/P2Info/StatusLabel
@onready var center_vs_panel: Control = $CanvasLayer/UI/CenterVS
@onready var start_battle_button: Button = $CanvasLayer/UI/CenterVS/StartBattleButton
@onready var countdown_label: Label = $CanvasLayer/UI/CenterVS/CountdownLabel
@onready var bottom_prompt: Label = $CanvasLayer/UI/BottomBar/HBox/PromptLabel

# Card visual meshes dictionary: slot_index -> Node3D (card root)
var card_nodes: Dictionary = {}

# Tweens
var p1_token_tween: Tween = null
var p2_token_tween: Tween = null
var start_countdown_timer: float = -1.0

# Procedural SFX cache
var sfx_move: AudioStreamWAV
var sfx_select: AudioStreamWAV
var sfx_cancel: AudioStreamWAV
var sfx_ready: AudioStreamWAV

func _ready() -> void:
	_init_sfx()
	_init_roster()
	_build_3d_card_arc()
	_update_p1_selection(p1_slot_index, false)
	_update_p2_selection(p2_slot_index, false)
	
	if start_battle_button:
		start_battle_button.pressed.connect(_on_start_battle_pressed)
		start_battle_button.visible = false
	if countdown_label:
		countdown_label.visible = false
	_build_stage_preview()
	_sync_initial_tokens()

func _sync_initial_tokens() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_update_token_position(1, false)
	_update_token_position(2, false)

func _build_stage_preview() -> void:
	var preview_path := "res://ui/character_select/stage_preview.png"
	var tex: Texture2D = null
	if ResourceLoader.exists(preview_path):
		tex = load(preview_path)
	elif FileAccess.file_exists(preview_path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(preview_path))
		if img:
			tex = ImageTexture.create_from_image(img)
	if tex == null:
		return
	
	var ui_root: Control = get_node_or_null("CanvasLayer/UI")
	if not ui_root:
		return
	
	# Compact frame under title banner
	var panel := PanelContainer.new()
	panel.name = "StagePreviewPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -75
	panel.offset_right = 75
	panel.offset_top = 54
	panel.offset_bottom = 138
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.1, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.68, 0.22, 0.9)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tex_rect := TextureRect.new()
	tex_rect.texture = tex
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.custom_minimum_size = Vector2(146, 62)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(tex_rect)
	
	var stage_name := Label.new()
	stage_name.text = "MAPA: SANTUARIO ASTRAL"
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres")
	stage_name.add_theme_font_override("font", font_res)
	stage_name.add_theme_font_size_override("font_size", 10)
	stage_name.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	stage_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stage_name)
	
	panel.add_child(vbox)
	ui_root.add_child(panel)

func _process(delta: float) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	
	# Continuous subtle floating bob on tokens
	if p1_token:
		p1_token.position.y += sin(now * 5.0) * (0.015 * delta)
	if p2_token:
		p2_token.position.y += cos(now * 5.0) * (0.015 * delta)
		
	# Continuous 360-degree rotation of preview models as requested
	if p1_stage_model and p1_stage_model.get_child_count() > 0:
		var c1 = p1_stage_model.get_child(0)
		c1.rotation.y += delta * 0.85
	if p2_stage_model and p2_stage_model.get_child_count() > 0:
		var c2 = p2_stage_model.get_child(0)
		c2.rotation.y += delta * 0.85
		
	# Auto-start countdown when both locked
	if start_countdown_timer > 0.0:
		start_countdown_timer -= delta
		if countdown_label:
			countdown_label.text = "BATALLA EN %d..." % int(ceil(start_countdown_timer))
		if start_countdown_timer <= 0.0:
			_launch_battle()

func _init_roster() -> void:
	roster_slots = [
		# Slot 0: Top Center (Elevated Random Box)
		{
			"id": "random",
			"name": "ALEATORIO",
			"sub": "Â¿QUIÃ‰N SERÃ?",
			"data": null,
			"row": 0,
			"col": 0,
			"tex_path": "res://ui/character_select/portraits/random.png",
			"color": Color(1.0, 0.85, 0.25)
		},
		# Slot 1: Row 1 Left - Lego Batman
		{
			"id": "lego_batman",
			"name": "LEGO\nBATMAN",
			"sub": "EL CABALLERO OSCURO",
			"data": lego_batman_data,
			"row": 1,
			"col": 0,
			"tex_path": "res://ui/character_select/portraits/lego_batman.png",
			"color": Color(0.95, 0.82, 0.15)
		},
		# Slot 2: Row 1 Right - Sakuya
		{
			"id": "sakuya",
			"name": "SAKUYA\nIZAYOI",
			"sub": "SIRVIENTA DEL TIEMPO",
			"data": sakuya_data,
			"row": 1,
			"col": 1,
			"tex_path": "res://ui/character_select/portraits/sakuya.png",
			"color": Color(0.45, 0.75, 1.0)
		},
		# Slot 3: Row 2 Left - Gogeta
		{
			"id": "gogeta",
			"name": "GOGETA",
			"sub": "GUERRERO DE FUSIÃ“N",
			"data": gogeta_data,
			"row": 2,
			"col": 0,
			"tex_path": "res://ui/character_select/portraits/gogeta.png",
			"color": Color(0.25, 0.65, 1.0)
		},
		# Slot 4: Row 2 Right - John Placeholder
		{
			"id": "john",
			"name": "JOHN\nPLACEHOLDER",
			"sub": "MANIQUÃ DE ENTRENAMIENTO",
			"data": john_data,
			"row": 2,
			"col": 1,
			"tex_path": "res://ui/character_select/portraits/john.png",
			"color": Color(0.4, 0.85, 0.95)
		}
	]

func _build_3d_card_arc() -> void:
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres")
	
	# Layout tuning (matching DBFZ compact tilted curved plane)
	var col_spacing: float = 0.36
	var row_spacing_y: float = 0.25
	var row_spacing_z: float = 0.04
	
	for i in range(roster_slots.size()):
		var slot: Dictionary = roster_slots[i]
		var row: int = slot["row"]
		var col: int = slot["col"]
		
		var card_root := Node3D.new()
		card_root.name = "Card_" + slot["id"]
		
		var px: float = 0.0
		var py: float = (2 - row) * row_spacing_y
		var pz: float = (row - 1) * row_spacing_z
		var yaw: float = 0.0
		
		if row == 0:
			# Random card at top center
			px = 0.0
			py += 0.06
			pz -= 0.02
			yaw = 0.0
		else:
			# 2 columns: col 0 is left (-1), col 1 is right (+1)
			var side: float = -1.0 if col == 0 else 1.0
			px = side * (col_spacing * 0.5)
			yaw = -side * 0.035
			pz -= 0.008
			
		card_root.position = Vector3(px, py, pz)
		card_root.rotation.y = yaw
		
		# Glow Mesh (Behind Card for DBFZ outline effect)
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

		# Card Mesh
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "CardMesh"
		var quad := QuadMesh.new()
		quad.size = Vector2(0.30, 0.20)
		mesh_inst.mesh = quad
		
		# Material (Unshaded to keep 2D anime art crisp and vivid)
		var mat := StandardMaterial3D.new()
		var tex: Texture2D = null
		if ResourceLoader.exists(slot["tex_path"]):
			tex = load(slot["tex_path"])
		if tex == null and FileAccess.file_exists(slot["tex_path"]):
			var img := Image.load_from_file(ProjectSettings.globalize_path(slot["tex_path"]))
			if img:
				tex = ImageTexture.create_from_image(img)
		if tex:
			mat.albedo_texture = tex
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.5
		mat.albedo_color = Color(0.85, 0.85, 0.88)
		mesh_inst.material_override = mat
		card_root.add_child(mesh_inst)
		
		# Name Label in bottom banner
		var label := Label3D.new()
		label.text = slot["name"]
		label.font = font_res
		label.font_size = 8
		label.outline_size = 3
		label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		label.line_spacing = 0.0
		label.position = Vector3(0.0, -0.072, 0.010)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card_root.add_child(label)
		
		card_root.set_meta("base_pos", card_root.position)
		
		# Clickable Area3D for Mouse clicks
		var area := Area3D.new()
		var col_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.30, 0.20, 0.05)
		col_shape.shape = box
		area.add_child(col_shape)
		area.input_event.connect(_on_card_input_event.bind(i))
		card_root.add_child(area)
		
		card_arc_root.add_child(card_root)
		card_nodes[i] = card_root

func _unhandled_input(event: InputEvent) -> void:
	# Global Back / Cancel
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_handle_cancel(1)
		return

	# Player 1 Inputs
	if not p1_locked:
		if event.is_action_pressed("p1_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
			_navigate_player(1, Vector2i(-1, 0))
		elif event.is_action_pressed("p1_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
			_navigate_player(1, Vector2i(1, 0))
		elif event.is_action_pressed("p1_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
			_navigate_player(1, Vector2i(0, -1))
		elif event.is_action_pressed("p1_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
			_navigate_player(1, Vector2i(0, 1))
		elif event.is_action_pressed("p1_attack") or event.is_action_pressed("p1_jump") or (event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_J, KEY_ENTER]):
			_lock_player(1)
	else:
		if event.is_action_pressed("p1_special") or (event is InputEventKey and event.pressed and event.keycode == KEY_K):
			_unlock_player(1)

	# Player 2 Inputs
	if not p2_locked:
		if event.is_action_pressed("p2_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_LEFT):
			_navigate_player(2, Vector2i(-1, 0))
		elif event.is_action_pressed("p2_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_RIGHT):
			_navigate_player(2, Vector2i(1, 0))
		elif event.is_action_pressed("p2_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_UP):
			_navigate_player(2, Vector2i(0, -1))
		elif event.is_action_pressed("p2_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_DOWN):
			_navigate_player(2, Vector2i(0, 1))
		elif event.is_action_pressed("p2_attack") or event.is_action_pressed("p2_jump") or (event is InputEventKey and event.pressed and event.keycode in [KEY_N, KEY_B, KEY_KP_1, KEY_KP_0]):
			_lock_player(2)
	else:
		if event.is_action_pressed("p2_special") or (event is InputEventKey and event.pressed and event.keycode in [KEY_M, KEY_KP_2]):
			_unlock_player(2)

func _navigate_player(player_id: int, dir: Vector2i) -> void:
	var current_idx = p1_slot_index if player_id == 1 else p2_slot_index
	var next_idx = _calc_grid_step(current_idx, dir)
	if next_idx != current_idx:
		_play_sfx(sfx_move, 1.0 + (0.1 if player_id == 2 else 0.0))
		if player_id == 1:
			_update_p1_selection(next_idx)
		else:
			_update_p2_selection(next_idx)

func _calc_grid_step(curr_idx: int, dir: Vector2i) -> int:
	match curr_idx:
		0: # Random (row 0, center)
			if dir.y > 0:
				return 1 # Down to Lego Batman
		1: # Lego Batman (row 1, left)
			if dir.x > 0:
				return 2 # Right to Sakuya
			elif dir.y < 0:
				return 0 # Up to Random
			elif dir.y > 0:
				return 3 # Down to Gogeta
		2: # Sakuya (row 1, right)
			if dir.x < 0:
				return 1 # Left to Lego Batman
			elif dir.y < 0:
				return 0 # Up to Random
			elif dir.y > 0:
				return 4 # Down to John
		3: # Gogeta (row 2, left)
			if dir.x > 0:
				return 4 # Right to John
			elif dir.y < 0:
				return 1 # Up to Lego Batman
		4: # John (row 2, right)
			if dir.x < 0:
				return 3 # Left to Gogeta
			elif dir.y < 0:
				return 2 # Up to Sakuya
	return curr_idx

func _on_card_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, slot_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not p1_locked:
			_play_sfx(sfx_select, 1.0)
			_update_p1_selection(slot_idx)
			_lock_player(1)
		elif not p2_locked:
			_play_sfx(sfx_select, 1.1)
			_update_p2_selection(slot_idx)
			_lock_player(2)

# ==============================================================================
# Player Selection Updates
# ==============================================================================
func _update_p1_selection(slot_idx: int, animate_token: bool = true) -> void:
	p1_slot_index = slot_idx
	var slot = roster_slots[slot_idx]
	
	if p1_name_label:
		p1_name_label.text = slot["name"]
	if p1_status_label:
		p1_status_label.text = "ELIGE LUCHADOR"
		p1_status_label.modulate = Color(0.3, 0.7, 1.0)
		
	_refresh_card_highlights()
	_update_token_position(1, animate_token)
	_update_stage_preview(1, slot)

func _update_p2_selection(slot_idx: int, animate_token: bool = true) -> void:
	p2_slot_index = slot_idx
	var slot = roster_slots[slot_idx]
	
	if p2_name_label:
		p2_name_label.text = slot["name"]
	if p2_status_label:
		p2_status_label.text = "ELIGE LUCHADOR"
		p2_status_label.modulate = Color(1.0, 0.35, 0.3)
		
	_refresh_card_highlights()
	_update_token_position(2, animate_token)
	_update_stage_preview(2, slot)

<<<<<<< HEAD
func _refresh_card_highlights() -> void:
	for i in card_nodes.keys():
		var node: Node3D = card_nodes[i]
		var glow_mesh: MeshInstance3D = node.get_node_or_null("Glow") as MeshInstance3D
		var mesh_inst: MeshInstance3D = node.get_node_or_null("CardMesh") as MeshInstance3D
		var base_pos: Vector3 = node.get_meta("base_pos") if node.has_meta("base_pos") else node.position
		
		var is_p1 = (i == p1_slot_index)
		var is_p2 = (i == p2_slot_index)
		
		if mesh_inst and mesh_inst.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mesh_inst.material_override
			if is_p1 or is_p2:
				mat.albedo_color = Color(1.08, 1.08, 1.08)
				node.scale = Vector3(1.10, 1.10, 1.10)
				node.position = base_pos + Vector3(0.0, 0.0, 0.02)
				if glow_mesh and glow_mesh.material_override is StandardMaterial3D:
					glow_mesh.visible = true
					var g_mat: StandardMaterial3D = glow_mesh.material_override
					if is_p1 and is_p2:
						g_mat.albedo_color = Color(1.0, 0.90, 0.25) # Shared gold
					elif is_p1:
						g_mat.albedo_color = Color(0.25, 0.70, 1.0) # Blue
					else:
						g_mat.albedo_color = Color(1.0, 0.28, 0.20) # Red
			else:
				mat.albedo_color = Color(0.80, 0.80, 0.83)
				node.scale = Vector3(1.0, 1.0, 1.0)
				node.position = base_pos
				if glow_mesh:
					glow_mesh.visible = false
=======
func _on_p1_sans_pressed() -> void:
	p1_selected = sans_data
	p1_status.text = "P1 Seleccionó: Sans (Undertale)"
	_check_ready()

# --- Selección de P2 ---
>>>>>>> 2c9b02c86124e4a6e6792e563c1f11ad358e3728

func _update_token_position(player_id: int, animate: bool = true) -> void:
	var slot_idx = p1_slot_index if player_id == 1 else p2_slot_index
	var token = p1_token if player_id == 1 else p2_token
	if not token or not card_nodes.has(slot_idx):
		return
		
	var card_node: Node3D = card_nodes[slot_idx]
	var target_global_pos = card_node.global_position
	
	# Offset badge right above the card's top edge
	var up_vec = card_node.global_transform.basis.y
	var target_pos = target_global_pos + up_vec * 0.11 + Vector3(0, 0.01, 0.01)
	
	# If both on the same card, offset horizontally
	if p1_slot_index == p2_slot_index:
		var right_vec = card_node.global_transform.basis.x
		if player_id == 1:
			target_pos -= right_vec * 0.10
		else:
			target_pos += right_vec * 0.10
			
	if animate:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(token, "global_position", target_pos, 0.12)
		if player_id == 1:
			p1_token_tween = tw
		else:
			p2_token_tween = tw
	else:
		token.global_position = target_pos

# ==============================================================================
# 3D Stage Character Preview
# ==============================================================================
func _update_stage_preview(player_id: int, slot: Dictionary) -> void:
	var container = p1_stage_model if player_id == 1 else p2_stage_model
	if not container:
		return
		
	# Clear old preview
	for child in container.get_children():
		child.queue_free()
		
	var facing_yaw = deg_to_rad(22.0) if player_id == 1 else deg_to_rad(-22.0)
	var data: CharacterData = slot["data"]
	
	if slot["id"] == "random":
		# Golden rotating 3D Hologram question mark
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
		
	if data.model_scene:
		var model = data.model_scene.instantiate()
		model.position = Vector3(data.model_offset.x, 0.0, data.model_offset.z)
		var s = data.model_scale
		model.scale = Vector3(s, s, s)
		model.rotation.y = facing_yaw
		container.add_child(model)
		
		# Try to play built-in Idle animation
		var played_idle := false
		var ap: AnimationPlayer = _find_animation_player(model)
		if ap:
			var anim_name = _find_idle_anim(ap)
			if anim_name != "":
				ap.play(anim_name)
				played_idle = true
		
		if not played_idle and data.animation_library:
			var new_ap := AnimationPlayer.new()
			new_ap.add_animation_library("", data.animation_library)
			model.add_child(new_ap)
			var anim_name = _find_idle_anim(new_ap)
			if anim_name != "":
				new_ap.play(anim_name)
				played_idle = true
		
		# If no idle animation found, create a procedural breathing idle
		if not played_idle:
			_apply_procedural_idle(model)
	else:
		# Procedural stylized fighting dummy for Gogeta / John
		var dummy := _create_procedural_dummy(data.character_color)
		dummy.rotation.y = facing_yaw
		dummy.position = Vector3(0, 0, 0)
		container.add_child(dummy)
		_apply_procedural_idle(dummy)
		
	# Scale punch transition
	container.scale = Vector3(0.85, 0.85, 0.85)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(container, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

## Creates a subtle breathing/bobbing idle animation using tweens
func _apply_procedural_idle(node: Node3D) -> void:
	# Subtle vertical bob (breathing)
	var base_y = node.position.y
	var breath_tween = create_tween().set_loops()
	breath_tween.tween_property(node, "position:y", base_y + 0.025, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath_tween.tween_property(node, "position:y", base_y, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Subtle scale pulse (chest expanding with breath)
	var base_scale = node.scale
	var expand = base_scale * 1.008
	var scale_tween = create_tween().set_loops()
	scale_tween.tween_property(node, "scale", expand, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(node, "scale", base_scale, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _create_procedural_dummy(color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.4
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = color * 0.2
	
	# Torso
	var torso := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.65, 0.28)
	torso.mesh = box
	torso.material_override = mat
	torso.position = Vector3(0, 0.95, 0)
	root.add_child(torso)
	
	# Head
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.material_override = mat
	head.position = Vector3(0, 1.45, 0)
	root.add_child(head)
	
	# Legs
	for side in [-0.15, 0.15]:
		var leg := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.08
		cap.height = 0.65
		leg.mesh = cap
		leg.material_override = mat
		leg.position = Vector3(side, 0.35, 0)
		root.add_child(leg)
		
	# Arms
	for side in [-0.35, 0.35]:
		var arm := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.07
		cap.height = 0.55
		arm.mesh = cap
		arm.material_override = mat
		arm.position = Vector3(side, 0.95, 0)
		arm.rotation.z = deg_to_rad(-15.0 if side < 0 else 15.0)
		root.add_child(arm)
		
	return root

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var found = _find_animation_player(c)
		if found:
			return found
	return null

func _find_idle_anim(ap: AnimationPlayer) -> String:
	# First pass: exact "idle" match
	for a in ap.get_animation_list():
		if a.to_lower() == "idle":
			return a
	# Second pass: contains "idle" 
	for a in ap.get_animation_list():
		if "idle" in a.to_lower():
			return a
	return ""

<<<<<<< HEAD
# ==============================================================================
# Lock & Ready Flow
# ==============================================================================
func _lock_player(player_id: int) -> void:
	if player_id == 1:
		p1_locked = true
		_play_sfx(sfx_select, 1.0)
		p1_selected = _resolve_slot_selection(p1_slot_index)
		if p1_status_label:
			p1_status_label.text = "¡LISTO!"
			p1_status_label.modulate = Color(1.0, 0.88, 0.2)
		_punch_token(p1_token)
	else:
		p2_locked = true
		_play_sfx(sfx_select, 1.15)
		p2_selected = _resolve_slot_selection(p2_slot_index)
		if p2_status_label:
			p2_status_label.text = "¡LISTO!"
			p2_status_label.modulate = Color(1.0, 0.88, 0.2)
		_punch_token(p2_token)
		
	_check_both_ready()

func _unlock_player(player_id: int) -> void:
	_play_sfx(sfx_cancel, 1.0)
	if player_id == 1:
		p1_locked = false
		p1_selected = null
		if p1_status_label:
			p1_status_label.text = "ELIGE LUCHADOR"
			p1_status_label.modulate = Color(0.3, 0.7, 1.0)
	else:
		p2_locked = false
		p2_selected = null
		if p2_status_label:
			p2_status_label.text = "ELIGE LUCHADOR"
			p2_status_label.modulate = Color(1.0, 0.35, 0.3)
			
	start_countdown_timer = -1.0
	if countdown_label:
		countdown_label.visible = false
	_build_stage_preview()
	_sync_initial_tokens()
	if start_battle_button:
		start_battle_button.visible = false

func _handle_cancel(player_id: int) -> void:
	if player_id == 1 and p1_locked:
		_unlock_player(1)
	elif player_id == 2 and p2_locked:
		_unlock_player(2)
	else:
		_on_back_pressed()

func _punch_token(token: Node3D) -> void:
	if not token:
		return
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	token.scale = Vector3(1.35, 1.35, 1.35)
	tw.tween_property(token, "scale", Vector3(1.0, 1.0, 1.0), 0.18)

func _resolve_slot_selection(slot_idx: int) -> CharacterData:
	var slot = roster_slots[slot_idx]
	if slot["data"] != null:
		return slot["data"]
		
	# Random slot selected: pick a random character from available list
	var playable: Array[CharacterData] = [
		lego_batman_data,
		sakuya_data,
		gogeta_data,
		john_data
	]
	playable.shuffle()
	return playable[0]

func _check_both_ready() -> void:
	if p1_locked and p2_locked:
		_play_sfx(sfx_ready, 1.0)
=======
func _on_p2_sans_pressed() -> void:
	p2_selected = sans_data
	p2_status.text = "P2 Seleccionó: Sans (Undertale)"
	_check_ready()

# --- Verificación ---
func _check_ready() -> void:
	if p1_selected and p2_selected:
>>>>>>> 2c9b02c86124e4a6e6792e563c1f11ad358e3728
		if start_battle_button:
			start_battle_button.visible = true
			if is_inside_tree():
				start_battle_button.grab_focus()
		if countdown_label:
			countdown_label.visible = true
		start_countdown_timer = 2.0
		if bottom_prompt:
			bottom_prompt.text = "¡AMBOS LISTOS! INICIANDO COMBATE..."

func _launch_battle() -> void:
	if p1_selected == null:
		p1_selected = _resolve_slot_selection(p1_slot_index)
	if p2_selected == null:
		p2_selected = _resolve_slot_selection(p2_slot_index)
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_match(p1_selected, p2_selected)
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_start_battle_pressed() -> void:
	_launch_battle()

func _on_back_pressed() -> void:
	_play_sfx(sfx_cancel, 0.9)
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

# ==============================================================================
# Procedural Audio Synthesizer
# ==============================================================================
func _init_sfx() -> void:
	sfx_move = _synth_tone(780.0, 0.045, 0.3)
	sfx_select = _synth_dual_tone(600.0, 1100.0, 0.12, 0.4)
	sfx_cancel = _synth_sweep(400.0, 180.0, 0.08, 0.35)
	sfx_ready = _synth_chord([440.0, 554.37, 659.25], 0.35, 0.45)

func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if not is_inside_tree() or not sfx_player or not stream:
		return
	sfx_player.stream = stream
	sfx_player.pitch_scale = pitch
	sfx_player.play()

func _synth_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples = int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / 22050.0
		var env = 1.0 - (float(i) / float(samples))
		var v = sin(t * freq * TAU) * env * volume
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

func _synth_dual_tone(f1: float, f2: float, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples = int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / 22050.0
		var env = 1.0 - (float(i) / float(samples))
		var v = (sin(t * f1 * TAU) * 0.5 + sin(t * f2 * TAU) * 0.5) * env * volume
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

func _synth_sweep(f_start: float, f_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples = int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var norm = float(i) / float(samples)
		var freq = lerp(f_start, f_end, norm)
		var t = float(i) / 22050.0
		var env = 1.0 - norm
		var v = sin(t * freq * TAU) * env * volume
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

func _synth_chord(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples = int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / 22050.0
		var env = 1.0 - (float(i) / float(samples))
		var acc = 0.0
		for f in freqs:
			acc += sin(t * f * TAU)
		var v = (acc / float(freqs.size())) * env * volume
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav
