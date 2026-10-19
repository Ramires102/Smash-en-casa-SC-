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

@export var miyabi_data: CharacterData = preload("res://resources/instances/miyabi_data.tres")
@export var lego_batman_data: CharacterData = preload("res://resources/instances/lego_batman_data.tres")
@export var sakuya_data: CharacterData = preload("res://resources/instances/sakuya_data.tres")
@export var nekomiya_data: CharacterData = preload("res://resources/instances/nekomiya_data.tres")
@export var gogeta_data: CharacterData = preload("res://resources/instances/gogeta_data.tres")
@export var john_data: CharacterData = preload("res://resources/instances/john_placeholder_data.tres")

# Roster definition
var roster_slots: Array[Dictionary] = []

# Player states
var p1_slot_index: int = 2 # Default: Miyabi
var p2_slot_index: int = 1 # Default: Lego Batman
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

func _process(delta: float) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	
	# Continuous subtle floating bob on tokens
	if p1_token:
		p1_token.position.y += sin(now * 5.0) * (0.015 * delta)
	if p2_token:
		p2_token.position.y += cos(now * 5.0) * (0.015 * delta)
		
	# Subtle floating idle on preview models
	if p1_stage_model and p1_stage_model.get_child_count() > 0:
		var c1 = p1_stage_model.get_child(0)
		c1.rotation.y = deg_to_rad(22.0) + sin(now * 1.5) * 0.03
	if p2_stage_model and p2_stage_model.get_child_count() > 0:
		var c2 = p2_stage_model.get_child(0)
		c2.rotation.y = deg_to_rad(-22.0) - sin(now * 1.5) * 0.03
		
	# Auto-start countdown when both locked
	if start_countdown_timer > 0.0:
		start_countdown_timer -= delta
		if countdown_label:
			countdown_label.text = "BATALLA EN %d..." % int(ceil(start_countdown_timer))
		if start_countdown_timer <= 0.0:
			_launch_battle()

func _init_roster() -> void:
	roster_slots = [
		# Row 0: Top Center (Elevated Random Box)
		{
			"id": "random",
			"name": "ALEATORIO",
			"sub": "¿QUIÉN SERÁ?",
			"data": null,
			"row": 0,
			"col": 1,
			"tex_path": "res://ui/character_select/portraits/random.png",
			"color": Color(1.0, 0.85, 0.25)
		},
		# Row 1: Upper Arc
		{
			"id": "lego_batman",
			"name": "LEGO BATMAN",
			"sub": "EL CABALLERO OSCURO",
			"data": lego_batman_data,
			"row": 1,
			"col": 0,
			"tex_path": "res://ui/character_select/portraits/lego_batman.png",
			"color": Color(0.95, 0.82, 0.15)
		},
		{
			"id": "miyabi",
			"name": "MIYABI",
			"sub": "ESPADA DE SOMBRA",
			"data": miyabi_data,
			"row": 1,
			"col": 1,
			"tex_path": "res://ui/character_select/portraits/miyabi.png",
			"color": Color(0.95, 0.22, 0.35)
		},
		{
			"id": "sakuya",
			"name": "SAKUYA IZAYOI",
			"sub": "SIRVIENTA DEL TIEMPO",
			"data": sakuya_data,
			"row": 1,
			"col": 2,
			"tex_path": "res://ui/character_select/portraits/sakuya.png",
			"color": Color(0.45, 0.75, 1.0)
		},
		# Row 2: Lower Arc
		{
			"id": "gogeta",
			"name": "GOGETA",
			"sub": "GUERRERO DE FUSIÓN",
			"data": gogeta_data,
			"row": 2,
			"col": 0,
			"tex_path": "res://ui/character_select/portraits/gogeta.png",
			"color": Color(0.25, 0.65, 1.0)
		},
		{
			"id": "nekomiya",
			"name": "NEKOMIYA MANA",
			"sub": "GATA RÁPIDA",
			"data": nekomiya_data,
			"row": 2,
			"col": 1,
			"tex_path": "res://ui/character_select/portraits/nekomiya.png",
			"color": Color(1.0, 0.55, 0.85)
		},
		{
			"id": "john",
			"name": "JOHN PLACEHOLDER",
			"sub": "MANIQUÍ DE ENTRENAMIENTO",
			"data": john_data,
			"row": 2,
			"col": 2,
			"tex_path": "res://ui/character_select/portraits/john.png",
			"color": Color(0.4, 0.85, 0.95)
		}
	]

# ==============================================================================
# 3D Card Arc Construction
# ==============================================================================
func _build_3d_card_arc() -> void:
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres")
	
	# Layout tuning (matching DBFZ tilted curved plane)
	var col_spacing: float = 1.48
	var row_spacing_y: float = 0.54
	var row_spacing_z: float = 0.68
	var arc_depth_factor: float = 0.08
	var arc_yaw_factor: float = 0.07
	
	for i in range(roster_slots.size()):
		var slot: Dictionary = roster_slots[i]
		var row: int = slot["row"]
		var col: int = slot["col"]
		var dx: float = float(col - 1) # -1, 0, +1
		
		var card_root := Node3D.new()
		card_root.name = "Card_" + slot["id"]
		
		# Compute 3D position
		var px: float = dx * col_spacing
		var py: float = (2 - row) * row_spacing_y
		var pz: float = (row - 1) * row_spacing_z - (abs(dx) * arc_depth_factor)
		
		# Top random card elevation
		if row == 0:
			py += 0.18
			pz -= 0.12
			
		card_root.position = Vector3(px, py, pz)
		card_root.rotation.y = -dx * arc_yaw_factor
		
		# Card Mesh
		var mesh_inst := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.36, 0.92)
		mesh_inst.mesh = quad
		
		# Material
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
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.5
		mat.metallic = 0.55
		mat.roughness = 0.28
		mat.emission_enabled = false
		mat.emission = slot["color"]
		mat.emission_energy_multiplier = 0.9
		mesh_inst.material_override = mat
		card_root.add_child(mesh_inst)
		
		# Name Label in bottom banner
		var label := Label3D.new()
		label.text = slot["name"]
		label.font = font_res
		label.font_size = 26
		label.outline_size = 8
		label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		label.modulate = Color(1.0, 0.92, 0.5)
		label.position = Vector3(0.0, -0.31, 0.015)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		card_root.add_child(label)
		
		# Clickable Area3D for Mouse clicks
		var area := Area3D.new()
		var col_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.36, 0.92, 0.2)
		col_shape.shape = box
		area.add_child(col_shape)
		area.input_event.connect(_on_card_input_event.bind(i))
		card_root.add_child(area)
		
		card_arc_root.add_child(card_root)
		card_nodes[i] = card_root

# ==============================================================================
# Input & Navigation
# ==============================================================================
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
	var cur_slot = roster_slots[curr_idx]
	var r = cur_slot["row"]
	var c = cur_slot["col"]
	
	# Moving horizontally
	if dir.x != 0:
		if r == 0:
			# Only Random in Row 0
			return curr_idx
		else:
			var target_c = clamp(c + dir.x, 0, 2)
			for i in range(roster_slots.size()):
				if roster_slots[i]["row"] == r and roster_slots[i]["col"] == target_c:
					return i
					
	# Moving vertically
	elif dir.y != 0:
		if dir.y < 0: # UP
			if r == 2:
				for i in range(roster_slots.size()):
					if roster_slots[i]["row"] == 1 and roster_slots[i]["col"] == c:
						return i
			elif r == 1:
				# Go to Random (Row 0)
				return 0
		elif dir.y > 0: # DOWN
			if r == 0:
				# From Random down to center (Miyabi, row 1 col 1)
				return 2
			elif r == 1:
				for i in range(roster_slots.size()):
					if roster_slots[i]["row"] == 2 and roster_slots[i]["col"] == c:
						return i
						
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

func _refresh_card_highlights() -> void:
	for i in card_nodes.keys():
		var node: Node3D = card_nodes[i]
		var mesh_inst: MeshInstance3D = node.get_child(0) as MeshInstance3D
		if mesh_inst and mesh_inst.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mesh_inst.material_override
			var is_p1 = (i == p1_slot_index)
			var is_p2 = (i == p2_slot_index)
			
			if is_p1 or is_p2:
				mat.emission_enabled = true
				if is_p1 and is_p2:
					mat.emission = Color(1.0, 0.9, 0.4) # Shared gold
				elif is_p1:
					mat.emission = Color(0.2, 0.6, 1.0) # Blue
				else:
					mat.emission = Color(1.0, 0.25, 0.2) # Red
				node.scale = Vector3(1.08, 1.08, 1.08)
			else:
				mat.emission_enabled = false
				node.scale = Vector3(1.0, 1.0, 1.0)

func _update_token_position(player_id: int, animate: bool = true) -> void:
	var slot_idx = p1_slot_index if player_id == 1 else p2_slot_index
	var token = p1_token if player_id == 1 else p2_token
	if not token or not card_nodes.has(slot_idx):
		return
		
	var card_node: Node3D = card_nodes[slot_idx]
	var target_global_pos = card_node.global_position
	
	# Offset badge right above the card's top edge
	var up_vec = card_node.global_transform.basis.y
	var target_pos = target_global_pos + up_vec * 0.58 + Vector3(0, 0.05, 0.05)
	
	# If both on the same card, offset horizontally
	if p1_slot_index == p2_slot_index:
		var right_vec = card_node.global_transform.basis.x
		if player_id == 1:
			target_pos -= right_vec * 0.28
		else:
			target_pos += right_vec * 0.28
			
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
		model.position = data.model_offset
		var s = data.model_scale
		model.scale = Vector3(s, s, s)
		model.rotation.y = facing_yaw
		container.add_child(model)
		
		# Play Idle Animation
		var ap: AnimationPlayer = _find_animation_player(model)
		if ap:
			var anim_name = _find_idle_anim(ap)
			if anim_name != "":
				ap.play(anim_name)
		elif data.animation_library:
			var new_ap := AnimationPlayer.new()
			new_ap.add_animation_library("", data.animation_library)
			model.add_child(new_ap)
			var anim_name = _find_idle_anim(new_ap)
			if anim_name != "":
				new_ap.play(anim_name)
	else:
		# Procedural stylized fighting dummy for Gogeta / John
		var dummy := _create_procedural_dummy(data.character_color)
		dummy.rotation.y = facing_yaw
		dummy.position = Vector3(0, 0, 0)
		container.add_child(dummy)
		
	# Scale punch transition
	container.scale = Vector3(0.85, 0.85, 0.85)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(container, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

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
	for a in ap.get_animation_list():
		if "idle" in a.to_lower():
			return a
	var list = ap.get_animation_list()
	return list[0] if list.size() > 0 else ""

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
		miyabi_data,
		sakuya_data,
		nekomiya_data,
		gogeta_data,
		john_data
	]
	playable.shuffle()
	return playable[0]

func _check_both_ready() -> void:
	if p1_locked and p2_locked:
		_play_sfx(sfx_ready, 1.0)
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
