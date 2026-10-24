class_name CharacterSelect
extends Node3D

@export var lego_batman_data: CharacterData = preload("res://resources/instances/lego_batman_data.tres")
@export var sakuya_data: CharacterData = preload("res://resources/instances/sakuya_data.tres")
@export var gogeta_data: CharacterData = preload("res://resources/instances/gogeta_data.tres")
@export var sans_data: CharacterData = preload("res://resources/instances/sans_data.tres")
@export var john_data: CharacterData = preload("res://resources/instances/john_placeholder_data.tres")
@export var extra_characters: Array[CharacterData] = []

var roster_slots: Array[Dictionary] = []
var playable_characters: Array[CharacterData] = []

var p1_slot_index: int = 1
var p2_slot_index: int = 2
var p1_locked: bool = false
var p2_locked: bool = false
var p1_selected: CharacterData = null
var p2_selected: CharacterData = null

@onready var camera: Camera3D = $Camera3D
@onready var card_arc_root: Node3D = $CardArc
@onready var p1_stage_model: Node3D = $StageP1/ModelContainer
@onready var p2_stage_model: Node3D = $StageP2/ModelContainer
@onready var p1_token: Node3D = $Tokens/P1Token
@onready var p2_token: Node3D = $Tokens/P2Token
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

@onready var p1_name_label: Label = $CanvasLayer/UI/P1Info/NameLabel
@onready var p1_status_label: Label = $CanvasLayer/UI/P1Info/StatusLabel
@onready var p2_name_label: Label = $CanvasLayer/UI/P2Info/NameLabel
@onready var p2_status_label: Label = $CanvasLayer/UI/P2Info/StatusLabel
@onready var center_vs_panel: Control = $CanvasLayer/UI/CenterVS
@onready var start_battle_button: Button = $CanvasLayer/UI/CenterVS/StartBattleButton
@onready var countdown_label: Label = $CanvasLayer/UI/CenterVS/CountdownLabel
@onready var bottom_prompt: Label = $CanvasLayer/UI/BottomBar/HBox/PromptLabel

var card_nodes: Dictionary = {}
var portrait_viewports: Array[SubViewport] = []

var p1_token_tween: Tween = null
var p2_token_tween: Tween = null
var start_countdown_timer: float = -1.0

var sfx_move: AudioStreamWAV
var sfx_select: AudioStreamWAV
var sfx_cancel: AudioStreamWAV
var sfx_ready: AudioStreamWAV

func _ready() -> void:
	var bank: Dictionary = CSAudioSynth.create_sfx_bank()
	sfx_move = bank["move"]
	sfx_select = bank["select"]
	sfx_cancel = bank["cancel"]
	sfx_ready = bank["ready"]

	var seeds: Array[CharacterData] = [lego_batman_data, sakuya_data, gogeta_data, sans_data, john_data]
	playable_characters = CSRosterLoader.discover_playable_characters(seeds, extra_characters)
	roster_slots = CSRosterLoader.build_roster_slots(playable_characters)
	CSRosterLoader.build_3d_card_arc(self, card_arc_root, roster_slots, card_nodes, portrait_viewports, _on_card_input_event)

	p1_slot_index = clampi(p1_slot_index, 0, maxi(0, roster_slots.size() - 1))
	p2_slot_index = clampi(p2_slot_index, 0, maxi(0, roster_slots.size() - 1))
	_update_p1_selection(p1_slot_index, false)
	_update_p2_selection(p2_slot_index, false)

	if start_battle_button:
		start_battle_button.pressed.connect(_on_start_battle_pressed)
		start_battle_button.visible = false
	if countdown_label:
		countdown_label.visible = false
	_build_stage_preview()
	_sync_initial_tokens()

func _frame_portrait_camera(holder: Node3D, cam: Camera3D, bg_plate: MeshInstance3D, data: CharacterData) -> void:
	CSPortraitRenderer.frame_portrait_camera(holder, cam, bg_plate, data)

func _sync_initial_tokens() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_update_token_position(1, false)
	_update_token_position(2, false)

func _build_stage_preview() -> void:
	var ui_root: Control = get_node_or_null("CanvasLayer/UI")
	if not ui_root or ui_root.has_node("StagePreviewPanel"):
		return
	var tex: Texture2D = CSRosterLoader._load_texture_safe("res://ui/character_select/stage_preview.png")
	if tex == null:
		return

	var panel := PanelContainer.new()
	panel.name = "StagePreviewPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -75; panel.offset_right = 75
	panel.offset_top = 54; panel.offset_bottom = 138
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.1, 0.85)
	style.set_border_width_all(2)
	style.border_color = Color(0.85, 0.68, 0.22, 0.9)
	style.set_corner_radius_all(4)
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
	stage_name.add_theme_font_override("font", preload("res://ui/Fondos de texto/kamikaze_condensed.tres"))
	stage_name.add_theme_font_size_override("font_size", 10)
	stage_name.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	stage_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stage_name)

	panel.add_child(vbox)
	ui_root.add_child(panel)

func _process(delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if p1_token:
		p1_token.position.y += sin(now * 5.0) * (0.015 * delta)
	if p2_token:
		p2_token.position.y += cos(now * 5.0) * (0.015 * delta)

	if p1_slot_index == 0 and p1_stage_model and p1_stage_model.get_child_count() > 0:
		p1_stage_model.get_child(0).rotation.y += delta * 1.2
	if p2_slot_index == 0 and p2_stage_model and p2_stage_model.get_child_count() > 0:
		p2_stage_model.get_child(0).rotation.y += delta * 1.2

	if start_countdown_timer > 0.0:
		start_countdown_timer -= delta
		if countdown_label:
			countdown_label.text = "BATALLA EN %d..." % int(ceil(start_countdown_timer))
		if start_countdown_timer <= 0.0:
			_launch_battle()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_handle_cancel(1)
		return

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
	elif event.is_action_pressed("p1_special") or (event is InputEventKey and event.pressed and event.keycode == KEY_K):
		_unlock_player(1)

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
	elif event.is_action_pressed("p2_special") or (event is InputEventKey and event.pressed and event.keycode in [KEY_M, KEY_KP_2]):
		_unlock_player(2)

func _navigate_player(player_id: int, dir: Vector2i) -> void:
	var current_idx: int = p1_slot_index if player_id == 1 else p2_slot_index
	var next_idx: int = _calc_grid_step(current_idx, dir)
	if next_idx != current_idx:
		_play_sfx(sfx_move, 1.0 + (0.1 if player_id == 2 else 0.0))
		if player_id == 1:
			_update_p1_selection(next_idx)
		else:
			_update_p2_selection(next_idx)

func _calc_grid_step(curr_idx: int, dir: Vector2i) -> int:
	if curr_idx < 0 or curr_idx >= roster_slots.size():
		return 0
	var curr_slot: Dictionary = roster_slots[curr_idx]
	var curr_row: int = int(curr_slot["row"])
	var curr_col: int = int(curr_slot["col"])
	var curr_x: float = float(card_nodes[curr_idx].get_meta("grid_x", 0.0)) if card_nodes.has(curr_idx) else 0.0

	if dir.x != 0:
		var target_col: int = curr_col + dir.x
		for i in range(roster_slots.size()):
			if int(roster_slots[i]["row"]) == curr_row and int(roster_slots[i]["col"]) == target_col:
				return i
		return curr_idx

	if dir.y != 0:
		var target_row: int = curr_row + dir.y
		if target_row < 0:
			return curr_idx
		var best_idx: int = curr_idx
		var best_dist: float = 99999.0
		for i in range(roster_slots.size()):
			if int(roster_slots[i]["row"]) == target_row:
				var cand_x: float = float(card_nodes[i].get_meta("grid_x", 0.0)) if card_nodes.has(i) else 0.0
				var d: float = absf(cand_x - curr_x)
				if d < best_dist:
					best_dist = d
					best_idx = i
		return best_idx

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

func _update_p1_selection(slot_idx: int, animate_token: bool = true) -> void:
	p1_slot_index = slot_idx
	var slot: Dictionary = roster_slots[slot_idx]
	if p1_name_label:
		p1_name_label.text = slot["name"]
	if p1_status_label:
		p1_status_label.text = "ELIGE LUCHADOR"
		p1_status_label.modulate = Color(0.3, 0.7, 1.0)
	_refresh_card_highlights()
	_update_token_position(1, animate_token)
	CSPortraitRenderer.update_stage_preview(self, p1_stage_model, 1, slot)

func _update_p2_selection(slot_idx: int, animate_token: bool = true) -> void:
	p2_slot_index = slot_idx
	var slot: Dictionary = roster_slots[slot_idx]
	if p2_name_label:
		p2_name_label.text = slot["name"]
	if p2_status_label:
		p2_status_label.text = "ELIGE LUCHADOR"
		p2_status_label.modulate = Color(1.0, 0.35, 0.3)
	_refresh_card_highlights()
	_update_token_position(2, animate_token)
	CSPortraitRenderer.update_stage_preview(self, p2_stage_model, 2, slot)

func _refresh_card_highlights() -> void:
	for i in card_nodes.keys():
		var node: Node3D = card_nodes[i]
		var glow_mesh: MeshInstance3D = node.get_node_or_null("Glow") as MeshInstance3D
		var mesh_inst: MeshInstance3D = node.get_node_or_null("CardMesh") as MeshInstance3D
		var base_pos: Vector3 = node.get_meta("base_pos") if node.has_meta("base_pos") else node.position
		var is_p1: bool = (i == p1_slot_index)
		var is_p2: bool = (i == p2_slot_index)

		if mesh_inst and mesh_inst.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mesh_inst.material_override
			if is_p1 or is_p2:
				mat.albedo_color = Color(1.06, 1.06, 1.06)
				node.scale = Vector3(1.08, 1.08, 1.08)
				node.position = base_pos + Vector3(0.0, 0.0, 0.02)
				if glow_mesh and glow_mesh.material_override is StandardMaterial3D:
					glow_mesh.visible = true
					var g_mat: StandardMaterial3D = glow_mesh.material_override
					g_mat.albedo_color = Color(1.0, 0.90, 0.25) if (is_p1 and is_p2) else (Color(0.25, 0.70, 1.0) if is_p1 else Color(1.0, 0.28, 0.20))
			else:
				mat.albedo_color = Color(0.82, 0.82, 0.85)
				node.scale = Vector3.ONE
				node.position = base_pos
				if glow_mesh:
					glow_mesh.visible = false

func _update_token_position(player_id: int, animate: bool = true) -> void:
	var slot_idx: int = p1_slot_index if player_id == 1 else p2_slot_index
	var token: Node3D = p1_token if player_id == 1 else p2_token
	if not token or not card_nodes.has(slot_idx):
		return

	var card_node: Node3D = card_nodes[slot_idx]
	var target_pos: Vector3 = card_node.global_position + card_node.global_transform.basis.y * 0.11 + Vector3(0, 0.01, 0.01)
	if p1_slot_index == p2_slot_index:
		var right_vec: Vector3 = card_node.global_transform.basis.x
		target_pos += (-right_vec if player_id == 1 else right_vec) * 0.08

	if animate:
		var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(token, "global_position", target_pos, 0.12)
		if player_id == 1:
			p1_token_tween = tw
		else:
			p2_token_tween = tw
	else:
		token.global_position = target_pos

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
	var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	token.scale = Vector3(1.35, 1.35, 1.35)
	tw.tween_property(token, "scale", Vector3.ONE, 0.18)

func _resolve_slot_selection(slot_idx: int) -> CharacterData:
	var slot: Dictionary = roster_slots[slot_idx]
	if slot["data"] != null:
		return slot["data"]
	var pool: Array[CharacterData] = playable_characters.duplicate()
	if pool.is_empty():
		pool = [lego_batman_data, sakuya_data, gogeta_data, sans_data, john_data]
	pool.shuffle()
	return pool[0]

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

func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if not is_inside_tree() or not sfx_player or not stream:
		return
	sfx_player.stream = stream
	sfx_player.pitch_scale = pitch
	sfx_player.play()
