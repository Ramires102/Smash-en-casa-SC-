class_name CharacterSelect
extends Node3D

# ==============================================================================
# DBFZ Character Select Screen (Dragon Ball FighterZ Style)
# - Curved 3D fan/arc of roster cards
# - Up to 4 Simultaneous Players (P1, P2, P3, P4)
# - Floating cursor tokens per active player with automatic multi-token spacing
# - Live 3D character models standing on pedestals playing Idle animations
# - Real-time Profile and Leaderboard integration
# - Random (?) card on elevated top pedestal
# - Audio feedback with arcade sound effects
# - Controller, Keyboard, and Mouse support
# ==============================================================================

@export var lego_batman_data: CharacterData = preload("res://resources/instances/lego_batman_data.tres")
@export var sakuya_data: CharacterData = preload("res://resources/instances/sakuya_data.tres")
@export var gogeta_data: CharacterData = preload("res://resources/instances/gogeta_data.tres")
@export var john_data: CharacterData = preload("res://resources/instances/john_placeholder_data.tres")
@export var miyabi_data: CharacterData = preload("res://resources/instances/miyabi_data.tres")
@export var hornet_data: CharacterData = preload("res://resources/instances/hornet_data.tres")

const MAX_PLAYERS: int = 4
const PLAYER_COLORS: Dictionary = {
	1: Color(0.25, 0.70, 1.0),   # Blue
	2: Color(1.0, 0.28, 0.20),   # Red
	3: Color(0.20, 0.90, 0.35),  # Green
	4: Color(1.0, 0.85, 0.20)    # Yellow
}

# Roster definition
var roster_slots: Array[Dictionary] = []

# Player states (1 a 4)
var players_state: Dictionary = {
	1: {
		"active": true,
		"slot_index": 1,
		"locked": false,
		"selected_data": null,
		"token": null,
		"token_tween": null,
		"stage_root": null,
		"stage_model": null,
		"stage_light": null,
		"info_panel": null,
		"badge_label": null,
		"name_label": null,
		"status_label": null,
		"profile_label": null
	},
	2: {
		"active": true,
		"slot_index": 2,
		"locked": false,
		"selected_data": null,
		"token": null,
		"token_tween": null,
		"stage_root": null,
		"stage_model": null,
		"stage_light": null,
		"info_panel": null,
		"badge_label": null,
		"name_label": null,
		"status_label": null,
		"profile_label": null
	},
	3: {
		"active": false,
		"slot_index": 3,
		"locked": false,
		"selected_data": null,
		"token": null,
		"token_tween": null,
		"stage_root": null,
		"stage_model": null,
		"stage_light": null,
		"info_panel": null,
		"badge_label": null,
		"name_label": null,
		"status_label": null,
		"profile_label": null
	},
	4: {
		"active": false,
		"slot_index": 4,
		"locked": false,
		"selected_data": null,
		"token": null,
		"token_tween": null,
		"stage_root": null,
		"stage_model": null,
		"stage_light": null,
		"info_panel": null,
		"badge_label": null,
		"name_label": null,
		"status_label": null,
		"profile_label": null
	}
}

# Retrocompatibilidad con propiedades anteriores
var p1_slot_index: int:
	get: return players_state[1]["slot_index"]
	set(val): players_state[1]["slot_index"] = val
var p2_slot_index: int:
	get: return players_state[2]["slot_index"]
	set(val): players_state[2]["slot_index"] = val
var p1_locked: bool:
	get: return players_state[1]["locked"]
	set(val): players_state[1]["locked"] = val
var p2_locked: bool:
	get: return players_state[2]["locked"]
	set(val): players_state[2]["locked"] = val
var p1_selected: CharacterData:
	get: return players_state[1]["selected_data"]
	set(val): players_state[1]["selected_data"] = val
var p2_selected: CharacterData:
	get: return players_state[2]["selected_data"]
	set(val): players_state[2]["selected_data"] = val

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var card_arc_root: Node3D = $CardArc
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# UI Overlay references
@onready var center_vs_panel: Control = $CanvasLayer/UI/CenterVS
@onready var start_battle_button: Button = $CanvasLayer/UI/CenterVS/StartBattleButton
@onready var countdown_label: Label = $CanvasLayer/UI/CenterVS/CountdownLabel
@onready var bottom_prompt: Label = $CanvasLayer/UI/BottomBar/HBox/PromptLabel

# Card visual meshes dictionary: slot_index -> Node3D (card root)
var card_nodes: Dictionary = {}
var portrait_viewports: Array[SubViewport] = []
var start_countdown_timer: float = -1.0

# 3D Stage Background and Selector
var stage_bg_deco: Node3D = null
var stage_preview_rect: TextureRect = null
var stage_name_label: Label = null
@onready var world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment
var _preview_time: float = 0.0

# Procedural SFX cache
var sfx_move: AudioStreamWAV
var sfx_select: AudioStreamWAV
var sfx_cancel: AudioStreamWAV
var sfx_ready: AudioStreamWAV

func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_menu_theme"):
		am.play_menu_theme()

	_init_sfx()
	_init_roster()
	_build_3d_card_arc()
	_setup_3d_stage_background()
	_setup_nodes_for_4_players()
	_build_stage_preview()
	
	# Restaurar jugadores activos previos de GameManager si existen
	var gm = _get_game_manager()
	var gm_active: Array = gm.active_player_ids if (gm and "active_player_ids" in gm) else [1, 2]
	for pid in [3, 4]:
		if gm_active.has(pid):
			players_state[pid]["active"] = true

	# Inicializar selección y UI para los 4 jugadores
	_update_pedestal_positions()
	for pid in [1, 2, 3, 4]:
		_refresh_player_ui(pid)
		_update_stage_preview(pid, roster_slots[players_state[pid]["slot_index"]])

	_refresh_card_highlights()
	_sync_initial_tokens()

	if start_battle_button:
		start_battle_button.pressed.connect(_on_start_battle_pressed)
		start_battle_button.visible = false
	if countdown_label:
		countdown_label.visible = false

func _setup_nodes_for_4_players() -> void:
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null

	# 1. P1 & P2 Existentes en Escena
	var p1_stage = get_node_or_null("StageP1")
	var p2_stage = get_node_or_null("StageP2")
	players_state[1]["stage_root"] = p1_stage
	players_state[1]["stage_model"] = p1_stage.get_node_or_null("ModelContainer") if p1_stage else null
	players_state[1]["stage_light"] = get_node_or_null("Lights/StageLightP1")
	players_state[1]["token"] = get_node_or_null("Tokens/P1Token")

	players_state[2]["stage_root"] = p2_stage
	players_state[2]["stage_model"] = p2_stage.get_node_or_null("ModelContainer") if p2_stage else null
	players_state[2]["stage_light"] = get_node_or_null("Lights/StageLightP2")
	players_state[2]["token"] = get_node_or_null("Tokens/P2Token")

	# 2. Configurar Pedestales para P3 y P4 duplicando P1/P2 si no existen
	var tokens_parent: Node = get_node_or_null("Tokens")
	var lights_parent: Node = get_node_or_null("Lights")

	# P3 Stage Pedestal
	var p3_stage = get_node_or_null("StageP3")
	if not p3_stage and p1_stage:
		p3_stage = p1_stage.duplicate()
		p3_stage.name = "StageP3"
		add_child(p3_stage)
		var p3_ped = p3_stage.get_node_or_null("PedestalP1")
		if p3_ped:
			p3_ped.name = "PedestalP3"
			var mat3 = StandardMaterial3D.new()
			mat3.albedo_color = Color(0.08, 0.18, 0.10, 1)
			mat3.metallic = 0.7
			mat3.roughness = 0.3
			mat3.emission_enabled = true
			mat3.emission = PLAYER_COLORS[3]
			mat3.emission_energy_multiplier = 1.2
			p3_ped.material_override = mat3
	players_state[3]["stage_root"] = p3_stage
	players_state[3]["stage_model"] = p3_stage.get_node_or_null("ModelContainer") if p3_stage else null

	# P4 Stage Pedestal
	var p4_stage = get_node_or_null("StageP4")
	if not p4_stage and p2_stage:
		p4_stage = p2_stage.duplicate()
		p4_stage.name = "StageP4"
		add_child(p4_stage)
		var p4_ped = p4_stage.get_node_or_null("PedestalP2")
		if p4_ped:
			p4_ped.name = "PedestalP4"
			var mat4 = StandardMaterial3D.new()
			mat4.albedo_color = Color(0.18, 0.16, 0.06, 1)
			mat4.metallic = 0.7
			mat4.roughness = 0.3
			mat4.emission_enabled = true
			mat4.emission = PLAYER_COLORS[4]
			mat4.emission_energy_multiplier = 1.2
			p4_ped.material_override = mat4
	players_state[4]["stage_root"] = p4_stage
	players_state[4]["stage_model"] = p4_stage.get_node_or_null("ModelContainer") if p4_stage else null

	# P3 & P4 Spotlights
	if lights_parent:
		var l1 = lights_parent.get_node_or_null("StageLightP1")
		var l3 = lights_parent.get_node_or_null("StageLightP3")
		if not l3 and l1:
			l3 = l1.duplicate()
			l3.name = "StageLightP3"
			l3.light_color = PLAYER_COLORS[3]
			l3.position = Vector3(-1.45, 3.0, 1.0)
			lights_parent.add_child(l3)
		players_state[3]["stage_light"] = l3

		var l2 = lights_parent.get_node_or_null("StageLightP2")
		var l4 = lights_parent.get_node_or_null("StageLightP4")
		if not l4 and l2:
			l4 = l2.duplicate()
			l4.name = "StageLightP4"
			l4.light_color = PLAYER_COLORS[4]
			l4.position = Vector3(2.6, 3.0, 1.0)
			lights_parent.add_child(l4)
		players_state[4]["stage_light"] = l4

	# 3. P3 & P4 3D Tokens
	if tokens_parent:
		var tok1 = tokens_parent.get_node_or_null("P1Token")
		var tok3 = tokens_parent.get_node_or_null("P3Token")
		if not tok3 and tok1:
			tok3 = tok1.duplicate()
			tok3.name = "P3Token"
			var mat_tok3 = StandardMaterial3D.new()
			mat_tok3.albedo_color = PLAYER_COLORS[3]
			mat_tok3.metallic = 0.8
			mat_tok3.roughness = 0.2
			mat_tok3.emission_enabled = true
			mat_tok3.emission = PLAYER_COLORS[3]
			mat_tok3.emission_energy_multiplier = 0.5
			var d3 = tok3.get_node_or_null("Disc") as MeshInstance3D
			if d3: d3.material_override = mat_tok3
			var a3 = tok3.get_node_or_null("Arrow") as MeshInstance3D
			if a3: a3.material_override = mat_tok3
			var lbl3 = tok3.get_node_or_null("Label3D") as Label3D
			if lbl3: lbl3.text = "3"
			tokens_parent.add_child(tok3)
		players_state[3]["token"] = tok3

		var tok2 = tokens_parent.get_node_or_null("P2Token")
		var tok4 = tokens_parent.get_node_or_null("P4Token")
		if not tok4 and tok2:
			tok4 = tok2.duplicate()
			tok4.name = "P4Token"
			var mat_tok4 = StandardMaterial3D.new()
			mat_tok4.albedo_color = PLAYER_COLORS[4]
			mat_tok4.metallic = 0.8
			mat_tok4.roughness = 0.2
			mat_tok4.emission_enabled = true
			mat_tok4.emission = PLAYER_COLORS[4]
			mat_tok4.emission_energy_multiplier = 0.5
			var d4 = tok4.get_node_or_null("Disc") as MeshInstance3D
			if d4: d4.material_override = mat_tok4
			var a4 = tok4.get_node_or_null("Arrow") as MeshInstance3D
			if a4: a4.material_override = mat_tok4
			var lbl4 = tok4.get_node_or_null("Label3D") as Label3D
			if lbl4: lbl4.text = "4"
			tokens_parent.add_child(tok4)
		players_state[4]["token"] = tok4

	# 4. Configurar UI Overlay para 4 Jugadores (P1, P2, P3, P4)
	var ui_root: Control = get_node_or_null("CanvasLayer/UI")
	var p1_info: VBoxContainer = get_node_or_null("CanvasLayer/UI/P1Info") as VBoxContainer
	var p2_info: VBoxContainer = get_node_or_null("CanvasLayer/UI/P2Info") as VBoxContainer

	# Ajustar estilo compacto para P1
	if p1_info:
		p1_info.offset_top = 10
		p1_info.offset_bottom = 90
		p1_info.add_theme_constant_override("separation", 1)
		var p1_name = p1_info.get_node_or_null("NameLabel") as Label
		if p1_name: p1_name.add_theme_font_size_override("font_size", 17)
		var p1_stat = p1_info.get_node_or_null("StatusLabel") as Label
		if p1_stat: p1_stat.add_theme_font_size_override("font_size", 11)
		var p1_badge = p1_info.get_node_or_null("Badge") as Label
		if p1_badge: p1_badge.add_theme_font_size_override("font_size", 12)

		players_state[1]["info_panel"] = p1_info
		players_state[1]["badge_label"] = p1_badge
		players_state[1]["name_label"] = p1_name
		players_state[1]["status_label"] = p1_stat
		var p1_prof = p1_info.get_node_or_null("ProfileLabel")
		if not p1_prof:
			p1_prof = Label.new()
			p1_prof.name = "ProfileLabel"
			if font_res: p1_prof.add_theme_font_override("font", font_res)
			p1_prof.add_theme_font_size_override("font_size", 10)
			p1_info.add_child(p1_prof)
		players_state[1]["profile_label"] = p1_prof

	# Ajustar estilo compacto para P2
	if p2_info:
		p2_info.offset_top = 10
		p2_info.offset_bottom = 90
		p2_info.add_theme_constant_override("separation", 1)
		var p2_name = p2_info.get_node_or_null("NameLabel") as Label
		if p2_name: p2_name.add_theme_font_size_override("font_size", 17)
		var p2_stat = p2_info.get_node_or_null("StatusLabel") as Label
		if p2_stat: p2_stat.add_theme_font_size_override("font_size", 11)
		var p2_badge = p2_info.get_node_or_null("Badge") as Label
		if p2_badge: p2_badge.add_theme_font_size_override("font_size", 12)

		players_state[2]["info_panel"] = p2_info
		players_state[2]["badge_label"] = p2_badge
		players_state[2]["name_label"] = p2_name
		players_state[2]["status_label"] = p2_stat
		var p2_prof = p2_info.get_node_or_null("ProfileLabel")
		if not p2_prof:
			p2_prof = Label.new()
			p2_prof.name = "ProfileLabel"
			if font_res: p2_prof.add_theme_font_override("font", font_res)
			p2_prof.add_theme_font_size_override("font_size", 10)
			p2_prof.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			p2_info.add_child(p2_prof)
		players_state[2]["profile_label"] = p2_prof

	# P3 Info (Ubicado limpiamente debajo de P1)
	var p3_info = get_node_or_null("CanvasLayer/UI/P3Info")
	if not p3_info and ui_root and p1_info:
		p3_info = p1_info.duplicate()
		p3_info.name = "P3Info"
		p3_info.offset_top = 98
		p3_info.offset_bottom = 178
		p3_info.add_theme_constant_override("separation", 1)
		ui_root.add_child(p3_info)
	if p3_info:
		p3_info.offset_top = 98
		p3_info.offset_bottom = 178
		players_state[3]["info_panel"] = p3_info
		players_state[3]["badge_label"] = p3_info.get_node_or_null("Badge")
		players_state[3]["name_label"] = p3_info.get_node_or_null("NameLabel")
		players_state[3]["status_label"] = p3_info.get_node_or_null("StatusLabel")
		players_state[3]["profile_label"] = p3_info.get_node_or_null("ProfileLabel")
		if players_state[3]["badge_label"]:
			players_state[3]["badge_label"].text = "◄ JUGADOR 3"

	# P4 Info (Ubicado limpiamente debajo de P2)
	var p4_info = get_node_or_null("CanvasLayer/UI/P4Info")
	if not p4_info and ui_root and p2_info:
		p4_info = p2_info.duplicate()
		p4_info.name = "P4Info"
		p4_info.offset_top = 98
		p4_info.offset_bottom = 178
		p4_info.add_theme_constant_override("separation", 1)
		ui_root.add_child(p4_info)
	if p4_info:
		p4_info.offset_top = 98
		p4_info.offset_bottom = 178
		players_state[4]["info_panel"] = p4_info
		players_state[4]["badge_label"] = p4_info.get_node_or_null("Badge")
		players_state[4]["name_label"] = p4_info.get_node_or_null("NameLabel")
		players_state[4]["status_label"] = p4_info.get_node_or_null("StatusLabel")
		players_state[4]["profile_label"] = p4_info.get_node_or_null("ProfileLabel")
		if players_state[4]["badge_label"]:
			players_state[4]["badge_label"].text = "JUGADOR 4 ►"

func _sync_initial_tokens() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_refresh_all_token_positions(false)

func _setup_3d_stage_background() -> void:
	if stage_bg_deco != null:
		return
	stage_bg_deco = Node3D.new()
	stage_bg_deco.name = "StageBackgroundDeco"
	stage_bg_deco.position = Vector3(0, 0, -3.2)
	add_child(stage_bg_deco)
	_update_3d_stage_background()

func _update_3d_stage_background() -> void:
	if stage_bg_deco == null:
		return
		
	for c in stage_bg_deco.get_children():
		c.queue_free()
		
	var gm = _get_game_manager()
	var stage_data = gm.get_selected_stage() if (gm and gm.has_method("get_selected_stage")) else {}
	var stage_id: String = stage_data.get("id", "astral")
	
	# Update Sky Environment
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.background_mode = Environment.BG_SKY
		var sky_mat = ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = stage_data.get("sky_top_color", Color(0.14, 0.18, 0.38))
		sky_mat.sky_horizon_color = stage_data.get("sky_horizon_color", Color(0.88, 0.58, 0.65))
		sky_mat.sky_curve = 0.15
		sky_mat.ground_bottom_color = stage_data.get("ground_bottom_color", Color(0.08, 0.10, 0.18))
		sky_mat.ground_horizon_color = stage_data.get("ground_horizon_color", Color(0.88, 0.58, 0.65))
		sky_mat.ground_curve = 0.15
		sky_mat.sun_angle_max = 35.0
		sky_mat.use_debanding = true
		
		var new_sky = Sky.new()
		new_sky.sky_material = sky_mat
		env.sky = new_sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.75
		
	# 3D Decorative visual elements matching each stage
	match stage_id:
		"astral":
			var ring_mesh = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 2.4
			torus.outer_radius = 2.8
			ring_mesh.mesh = torus
			var r_mat = StandardMaterial3D.new()
			r_mat.albedo_color = Color(1.0, 0.85, 0.3)
			r_mat.metallic = 0.95
			r_mat.roughness = 0.15
			r_mat.emission_enabled = true
			r_mat.emission = Color(1.0, 0.8, 0.25)
			r_mat.emission_energy_multiplier = 1.2
			ring_mesh.material_override = r_mat
			ring_mesh.position = Vector3(0, 2.5, -2.0)
			ring_mesh.rotation.x = deg_to_rad(15.0)
			ring_mesh.name = "CelestialRing"
			stage_bg_deco.add_child(ring_mesh)
			
			for side in [-4.5, 4.5]:
				var pil = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.35
				cyl.bottom_radius = 0.45
				cyl.height = 6.0
				pil.mesh = cyl
				var p_mat = StandardMaterial3D.new()
				p_mat.albedo_color = Color(0.18, 0.22, 0.35)
				p_mat.metallic = 0.4
				pil.material_override = p_mat
				pil.position = Vector3(side, 1.0, -1.5)
				stage_bg_deco.add_child(pil)
				
		"cyber":
			var c_ring1 = MeshInstance3D.new()
			var torus1 = TorusMesh.new()
			torus1.inner_radius = 2.0
			torus1.outer_radius = 2.2
			c_ring1.mesh = torus1
			var cr_mat1 = StandardMaterial3D.new()
			cr_mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cr_mat1.albedo_color = Color(0.1, 0.85, 1.0)
			c_ring1.material_override = cr_mat1
			c_ring1.position = Vector3(-1.5, 2.2, -1.8)
			c_ring1.name = "CyberRing1"
			stage_bg_deco.add_child(c_ring1)
			
			var c_ring2 = MeshInstance3D.new()
			var torus2 = TorusMesh.new()
			torus2.inner_radius = 1.5
			torus2.outer_radius = 1.68
			c_ring2.mesh = torus2
			var cr_mat2 = StandardMaterial3D.new()
			cr_mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cr_mat2.albedo_color = Color(1.0, 0.15, 0.85)
			c_ring2.material_override = cr_mat2
			c_ring2.position = Vector3(1.5, 2.0, -1.5)
			c_ring2.rotation.y = deg_to_rad(30.0)
			c_ring2.name = "CyberRing2"
			stage_bg_deco.add_child(c_ring2)
			
			for side in [-3.5, -1.8, 1.8, 3.5]:
				var beam = MeshInstance3D.new()
				var box = BoxMesh.new()
				box.size = Vector3(0.08, 7.0, 0.08)
				beam.mesh = box
				var b_mat = StandardMaterial3D.new()
				b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				b_mat.albedo_color = Color(0.2, 0.8, 1.0, 0.6)
				beam.material_override = b_mat
				beam.position = Vector3(side, 1.5, -2.0)
				stage_bg_deco.add_child(beam)
				
		"volcano":
			for side in [-4.2, -2.2, 2.2, 4.2]:
				var pil = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.4
				cyl.bottom_radius = 0.6
				cyl.height = 5.5
				pil.mesh = cyl
				var p_mat = StandardMaterial3D.new()
				p_mat.albedo_color = Color(0.1, 0.08, 0.09)
				p_mat.roughness = 0.9
				p_mat.emission_enabled = true
				p_mat.emission = Color(1.0, 0.35, 0.05)
				p_mat.emission_energy_multiplier = 0.4
				pil.material_override = p_mat
				pil.position = Vector3(side, 1.0, -1.8)
				stage_bg_deco.add_child(pil)
				
			var lava = MeshInstance3D.new()
			var l_mesh = BoxMesh.new()
			l_mesh.size = Vector3(12.0, 0.3, 2.0)
			lava.mesh = l_mesh
			var l_mat = StandardMaterial3D.new()
			l_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			l_mat.albedo_color = Color(1.0, 0.4, 0.05)
			lava.material_override = l_mat
			lava.position = Vector3(0, -0.2, -2.0)
			stage_bg_deco.add_child(lava)

func _build_stage_preview() -> void:
	var ui_root: Control = get_node_or_null("CanvasLayer/UI")
	if not ui_root:
		return
	
	var panel := PanelContainer.new()
	panel.name = "StagePreviewPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -110
	panel.offset_right = 110
	panel.offset_top = 46
	panel.offset_bottom = 142
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 0.88)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.68, 0.22, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	
	var header_label := Label.new()
	header_label.text = "ESCENARIO [Q / E]"
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
	if font_res:
		header_label.add_theme_font_override("font", font_res)
	header_label.add_theme_font_size_override("font_size", 9)
	header_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.85))
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header_label)
	
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	
	var btn_left := Button.new()
	btn_left.text = "◄"
	btn_left.custom_minimum_size = Vector2(24, 52)
	btn_left.focus_mode = Control.FOCUS_NONE
	btn_left.pressed.connect(func(): _cycle_stage(-1))
	row.add_child(btn_left)
	
	stage_preview_rect = TextureRect.new()
	stage_preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage_preview_rect.custom_minimum_size = Vector2(136, 56)
	stage_preview_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_preview_rect.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_cycle_stage(1)
	)
	row.add_child(stage_preview_rect)
	
	var btn_right := Button.new()
	btn_right.text = "►"
	btn_right.custom_minimum_size = Vector2(24, 52)
	btn_right.focus_mode = Control.FOCUS_NONE
	btn_right.pressed.connect(func(): _cycle_stage(1))
	row.add_child(btn_right)
	
	vbox.add_child(row)
	
	stage_name_label = Label.new()
	if font_res:
		stage_name_label.add_theme_font_override("font", font_res)
	stage_name_label.add_theme_font_size_override("font_size", 11)
	stage_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35, 1.0))
	stage_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stage_name_label)
	
	panel.add_child(vbox)
	ui_root.add_child(panel)
	
	_update_stage_display()

func _cycle_stage(direction: int) -> void:
	var gm = _get_game_manager()
	if gm and gm.has_method("set_selected_stage_index"):
		gm.set_selected_stage_index(gm.selected_stage_index + direction)
	_update_stage_display()
	_update_3d_stage_background()
	_play_sfx(sfx_move, 1.25)
	
func _update_stage_display() -> void:
	var gm = _get_game_manager()
	var stage_data = gm.get_selected_stage() if (gm and gm.has_method("get_selected_stage")) else {}
	if stage_name_label:
		stage_name_label.text = stage_data.get("name", "ESCENARIO").to_upper()
		stage_name_label.add_theme_color_override("font_color", stage_data.get("theme_color", Color(1.0, 0.9, 0.4)))
	if stage_preview_rect:
		var preview_path = stage_data.get("preview_path", "")
		if ResourceLoader.exists(preview_path):
			stage_preview_rect.texture = load(preview_path)
		elif FileAccess.file_exists(preview_path):
			var img = Image.load_from_file(ProjectSettings.globalize_path(preview_path))
			if img:
				stage_preview_rect.texture = ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	_preview_time += delta
	var now = _preview_time
	
	# Continuous subtle floating bob on active tokens
	for pid in [1, 2, 3, 4]:
		var tok: Node3D = players_state[pid]["token"]
		if tok and tok.visible:
			tok.position.y += sin(now * 5.0 + float(pid)) * (0.015 * delta)
		
	# Continuous living breathing bob on preview model pedestals
	for pid in [1, 2, 3, 4]:
		var st_model: Node3D = players_state[pid]["stage_model"]
		if st_model and st_model.visible:
			var bob = sin(now * 2.2 + float(pid) * 0.9) * 0.015
			st_model.position.y = 0.08 + bob
			if st_model.get_child_count() > 0:
				var c = st_model.get_child(0)
				if c is Node3D:
					var base_yaw = deg_to_rad(22.0) if pid in [1, 3] else deg_to_rad(-22.0)
					c.rotation.y = base_yaw + sin(now * 1.5 + float(pid)) * 0.03
		
	# Slow background deco rotation
	if stage_bg_deco:
		for child in stage_bg_deco.get_children():
			if "Ring" in child.name:
				child.rotation.z += delta * 0.15
		
	# Auto-start countdown when all active players are locked
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
			"sub": "¿QUIÉN SERÁ?",
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
			"sub": "GUERRERO DE FUSIÓN",
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
			"sub": "MANIQUÍ DE ENTRENAMIENTO",
			"data": john_data,
			"row": 2,
			"col": 1,
			"tex_path": "res://ui/character_select/portraits/john.png",
			"color": Color(0.4, 0.85, 0.95)
		},
		# Slot 5: Row 3 Right - Miyabi
		{
			"id": "miyabi",
			"name": "MIYABI\nHOSHIMI",
			"sub": "MAESTRA DE LA ESPADA",
			"data": miyabi_data,
			"row": 3,
			"col": 1,
			"tex_path": "res://ui/character_select/portraits/miyabi.png",
			"color": Color(0.85, 0.2, 0.35)
		},
		# Slot 6: Row 3 Left - Hornet
		{
			"id": "hornet",
			"name": "HORNET",
			"sub": "PROTECTORA DE HALLOWNEST",
			"data": hornet_data,
			"row": 3,
			"col": 0,
			"tex_path": "res://ui/character_select/portraits/hornet.png",
			"color": Color(0.9, 0.15, 0.22)
		}
	]

func _build_3d_card_arc() -> void:
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres")
	
	var col_spacing: float = 0.36
	var row_spacing_y: float = 0.25
	var row_spacing_z: float = 0.04
	
	for vp in portrait_viewports:
		if is_instance_valid(vp):
			vp.queue_free()
	portrait_viewports.clear()

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
			px = 0.0
			py += 0.06
			pz -= 0.02
			yaw = 0.0
		else:
			var side: float = -1.0 if col == 0 else 1.0
			px = side * (col_spacing * 0.5)
			yaw = -side * 0.035
			pz -= 0.008
			
		card_root.position = Vector3(px, py, pz)
		card_root.rotation.y = yaw
		
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

		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "CardMesh"
		var quad := QuadMesh.new()
		quad.size = Vector2(0.30, 0.20)
		mesh_inst.mesh = quad
		
		var mat := StandardMaterial3D.new()
		if slot["data"] != null:
			var vp: SubViewport = _create_face_portrait_viewport(slot)
			add_child(vp)
			portrait_viewports.append(vp)
			mat.albedo_texture = vp.get_texture()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		else:
			var tex: Texture2D = null
			if ResourceLoader.exists(slot["tex_path"]):
				tex = load(slot["tex_path"])
			elif FileAccess.file_exists(slot["tex_path"]):
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
	# Stage cycle hotkeys (Q / E)
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_Q, KEY_BRACKETLEFT]:
			_cycle_stage(-1)
			return
		elif event.keycode in [KEY_E, KEY_BRACKETRIGHT]:
			_cycle_stage(1)
			return

	# Global Back / Cancel
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_handle_cancel(1)
		return

	# Detección de Entrada / Unirse para Jugadores 3 y 4
	if not players_state[3]["active"] and _is_join_event_for_player(3, event):
		_activate_player(3)
		return
	if not players_state[4]["active"] and _is_join_event_for_player(4, event):
		_activate_player(4)
		return

	# Procesar Entrada para cada Jugador Activo (1 a 4)
	for pid in [1, 2, 3, 4]:
		if not players_state[pid]["active"]:
			continue
		_handle_player_input(pid, event)

func _is_join_event_for_player(pid: int, event: InputEvent) -> bool:
	var prefix = "p%d_" % pid
	for act in ["attack", "jump", "special", "left", "right", "up", "down", "pause"]:
		if event.is_action_pressed(prefix + act):
			return true

	if event is InputEventKey and event.pressed:
		if pid == 3 and event.keycode in [KEY_U, KEY_I, KEY_O, KEY_P, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON]:
			return true
		elif pid == 4 and event.keycode in [KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_8]:
			return true

	if event is InputEventJoypadButton and event.pressed:
		var im = get_node_or_null("/root/InputManager")
		var target_dev = im.get_device_id_for_player(pid) if (im and im.has_method("get_device_id_for_player")) else (pid - 1)
		if event.device == target_dev:
			return true

	return false

func _handle_player_input(pid: int, event: InputEvent) -> void:
	var state = players_state[pid]
	var prefix = "p%d_" % pid

	if not state["locked"]:
		# Navegación
		var moved := false
		var dir := Vector2i.ZERO

		match pid:
			1:
				if event.is_action_pressed(prefix + "left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
					dir = Vector2i(-1, 0); moved = true
				elif event.is_action_pressed(prefix + "right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
					dir = Vector2i(1, 0); moved = true
				elif event.is_action_pressed(prefix + "up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
					dir = Vector2i(0, -1); moved = true
				elif event.is_action_pressed(prefix + "down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
					dir = Vector2i(0, 1); moved = true
			2:
				if event.is_action_pressed(prefix + "left") or (event is InputEventKey and event.pressed and event.keycode == KEY_LEFT):
					dir = Vector2i(-1, 0); moved = true
				elif event.is_action_pressed(prefix + "right") or (event is InputEventKey and event.pressed and event.keycode == KEY_RIGHT):
					dir = Vector2i(1, 0); moved = true
				elif event.is_action_pressed(prefix + "up") or (event is InputEventKey and event.pressed and event.keycode == KEY_UP):
					dir = Vector2i(0, -1); moved = true
				elif event.is_action_pressed(prefix + "down") or (event is InputEventKey and event.pressed and event.keycode == KEY_DOWN):
					dir = Vector2i(0, 1); moved = true
			3:
				if event.is_action_pressed(prefix + "left") or (event is InputEventKey and event.pressed and event.keycode == KEY_J):
					dir = Vector2i(-1, 0); moved = true
				elif event.is_action_pressed(prefix + "right") or (event is InputEventKey and event.pressed and event.keycode == KEY_L):
					dir = Vector2i(1, 0); moved = true
				elif event.is_action_pressed(prefix + "up") or (event is InputEventKey and event.pressed and event.keycode == KEY_I):
					dir = Vector2i(0, -1); moved = true
				elif event.is_action_pressed(prefix + "down") or (event is InputEventKey and event.pressed and event.keycode == KEY_K):
					dir = Vector2i(0, 1); moved = true
			4:
				if event.is_action_pressed(prefix + "left") or (event is InputEventKey and event.pressed and event.keycode == KEY_KP_4):
					dir = Vector2i(-1, 0); moved = true
				elif event.is_action_pressed(prefix + "right") or (event is InputEventKey and event.pressed and event.keycode == KEY_KP_6):
					dir = Vector2i(1, 0); moved = true
				elif event.is_action_pressed(prefix + "up") or (event is InputEventKey and event.pressed and event.keycode == KEY_KP_8):
					dir = Vector2i(0, -1); moved = true
				elif event.is_action_pressed(prefix + "down") or (event is InputEventKey and event.pressed and event.keycode == KEY_KP_5):
					dir = Vector2i(0, 1); moved = true

		if moved:
			_navigate_player(pid, dir)
			return

		# Confirmar / Bloquear Selección
		var confirm_pressed := false
		match pid:
			1:
				confirm_pressed = event.is_action_pressed(prefix + "attack") or event.is_action_pressed(prefix + "jump") or (event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_J, KEY_ENTER])
			2:
				confirm_pressed = event.is_action_pressed(prefix + "attack") or event.is_action_pressed(prefix + "jump") or (event is InputEventKey and event.pressed and event.keycode in [KEY_N, KEY_B, KEY_KP_1, KEY_KP_0])
			3:
				confirm_pressed = event.is_action_pressed(prefix + "attack") or event.is_action_pressed(prefix + "jump") or (event is InputEventKey and event.pressed and event.keycode in [KEY_U, KEY_O])
			4:
				confirm_pressed = event.is_action_pressed(prefix + "attack") or event.is_action_pressed(prefix + "jump") or (event is InputEventKey and event.pressed and event.keycode in [KEY_KP_1, KEY_KP_0])

		if confirm_pressed:
			_lock_player(pid)
			return

		# Cancelar / Salir (Para P3/P4 permite desunirse)
		var cancel_pressed := false
		match pid:
			1: cancel_pressed = event.is_action_pressed(prefix + "special")
			2: cancel_pressed = event.is_action_pressed(prefix + "special")
			3: cancel_pressed = event.is_action_pressed(prefix + "special") or (event is InputEventKey and event.pressed and event.keycode == KEY_P)
			4: cancel_pressed = event.is_action_pressed(prefix + "special") or (event is InputEventKey and event.pressed and event.keycode == KEY_KP_2)

		if cancel_pressed:
			_handle_cancel(pid)
			return

	else:
		# Jugador bloqueado: tecla de desbloquear
		var unlock_pressed := false
		match pid:
			1: unlock_pressed = event.is_action_pressed(prefix + "special") or (event is InputEventKey and event.pressed and event.keycode == KEY_K)
			2: unlock_pressed = event.is_action_pressed(prefix + "special") or (event is InputEventKey and event.pressed and event.keycode in [KEY_M, KEY_KP_2])
			3: unlock_pressed = event.is_action_pressed(prefix + "special") or (event is InputEventKey and event.pressed and event.keycode == KEY_P)
			4: unlock_pressed = event.is_action_pressed(prefix + "special") or (event is InputEventKey and event.pressed and event.keycode == KEY_KP_2)

		if unlock_pressed:
			_unlock_player(pid)

func _activate_player(pid: int) -> void:
	if not players_state.has(pid) or players_state[pid]["active"]:
		return
	players_state[pid]["active"] = true
	players_state[pid]["locked"] = false
	_play_sfx(sfx_select, 1.0 + pid * 0.1)
	_update_pedestal_positions()
	_update_player_selection(pid, players_state[pid]["slot_index"], false)
	_refresh_all_token_positions(true)
	_refresh_player_ui(pid)
	_check_all_ready()

func _deactivate_player(pid: int) -> void:
	if not players_state.has(pid) or not players_state[pid]["active"]:
		return
	if pid <= 2 and _get_active_player_count() <= 2:
		return
	players_state[pid]["active"] = false
	players_state[pid]["locked"] = false
	players_state[pid]["selected_data"] = null
	if players_state[pid]["token"]:
		players_state[pid]["token"].visible = false
	if players_state[pid]["stage_root"]:
		players_state[pid]["stage_root"].visible = false
	if players_state[pid]["stage_light"]:
		players_state[pid]["stage_light"].visible = false
	_play_sfx(sfx_cancel, 0.95)
	_update_pedestal_positions()
	_refresh_all_token_positions(true)
	_refresh_player_ui(pid)
	_refresh_card_highlights()
	_check_all_ready()

func _get_active_player_count() -> int:
	var count: int = 0
	for pid in [1, 2, 3, 4]:
		if players_state[pid]["active"]:
			count += 1
	return count

func _update_pedestal_positions() -> void:
	var count: int = _get_active_player_count()
	var crowded: bool = (count > 2)

	if crowded:
		_set_stage_pos_rot(1, Vector3(-2.6, 0.05, -0.5), deg_to_rad(28.0))
		_set_stage_pos_rot(3, Vector3(-1.45, 0.05, 0.0), deg_to_rad(15.0))
		_set_stage_pos_rot(2, Vector3(1.45, 0.05, 0.0), deg_to_rad(-15.0))
		_set_stage_pos_rot(4, Vector3(2.6, 0.05, -0.5), deg_to_rad(-28.0))
		if camera:
			camera.position = Vector3(0.0, 1.25, 4.35)
	else:
		_set_stage_pos_rot(1, Vector3(-1.85, 0.05, -0.4), deg_to_rad(22.0))
		_set_stage_pos_rot(2, Vector3(1.85, 0.05, -0.4), deg_to_rad(-22.0))
		_set_stage_pos_rot(3, Vector3(-1.45, 0.05, 0.0), deg_to_rad(15.0))
		_set_stage_pos_rot(4, Vector3(2.6, 0.05, -0.5), deg_to_rad(-28.0))
		if camera:
			camera.position = Vector3(0.0, 1.20, 4.0)

	for pid in [1, 2, 3, 4]:
		var st_root: Node3D = players_state[pid]["stage_root"]
		var st_light: Light3D = players_state[pid]["stage_light"]
		var is_act: bool = players_state[pid]["active"]
		if st_root:
			st_root.visible = is_act
		if st_light:
			st_light.visible = is_act

func _set_stage_pos_rot(pid: int, pos: Vector3, rot_y: float) -> void:
	var st_root: Node3D = players_state[pid]["stage_root"]
	if st_root:
		st_root.position = pos
		var model_cont: Node3D = players_state[pid]["stage_model"]
		if model_cont and model_cont.get_child_count() > 0:
			var c = model_cont.get_child(0)
			if c is Node3D:
				c.rotation.y = rot_y

func _navigate_player(player_id: int, dir: Vector2i) -> void:
	if not players_state[player_id]["active"] or players_state[player_id]["locked"]:
		return
	var current_idx = players_state[player_id]["slot_index"]
	var next_idx = _calc_grid_step(current_idx, dir)
	if next_idx != current_idx:
		_play_sfx(sfx_move, 1.0 + (player_id - 1) * 0.08)
		_update_player_selection(player_id, next_idx)

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
			elif dir.y > 0:
				return 6 # Down to Hornet
		4: # John (row 2, right)
			if dir.x < 0:
				return 3 # Left to Gogeta
			elif dir.y < 0:
				return 2 # Up to Sakuya
			elif dir.y > 0:
				return 5 # Down to Miyabi
		5: # Miyabi (row 3, right)
			if dir.y < 0:
				return 4 # Up to John
			elif dir.x < 0:
				return 6 # Left to Hornet
		6: # Hornet (row 3, left)
			if dir.y < 0:
				return 3 # Up to Gogeta
			elif dir.x > 0:
				return 5 # Right to Miyabi
	return curr_idx

func _on_card_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, slot_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for pid in [1, 2, 3, 4]:
			if players_state[pid]["active"] and not players_state[pid]["locked"]:
				_play_sfx(sfx_select, 1.0 + (pid - 1) * 0.1)
				_update_player_selection(pid, slot_idx)
				_lock_player(pid)
				return

# ==============================================================================
# Player Selection Updates
# ==============================================================================
func _update_player_selection(player_id: int, slot_idx: int, animate_token: bool = true) -> void:
	players_state[player_id]["slot_index"] = slot_idx
	var slot = roster_slots[slot_idx]
	_refresh_player_ui(player_id)
	_refresh_card_highlights()
	_refresh_all_token_positions(animate_token)
	_update_stage_preview(player_id, slot)

func _update_p1_selection(slot_idx: int, animate_token: bool = true) -> void:
	_update_player_selection(1, slot_idx, animate_token)

func _update_p2_selection(slot_idx: int, animate_token: bool = true) -> void:
	_update_player_selection(2, slot_idx, animate_token)

func _refresh_player_ui(pid: int) -> void:
	var state = players_state[pid]
	var is_act: bool = state["active"]
	var n_lbl: Label = state["name_label"]
	var s_lbl: Label = state["status_label"]
	var b_lbl: Label = state["badge_label"]
	var p_lbl: Label = state["profile_label"]
	var p_color: Color = PLAYER_COLORS[pid]

	var prof_name: String = "Default"
	var im = get_node_or_null("/root/InputManager")
	if im and im.has_method("get_player_profile_name"):
		prof_name = im.get_player_profile_name(pid)

	if not is_act:
		if b_lbl:
			b_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
		if n_lbl:
			n_lbl.text = "+ UNIRSE"
			n_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
		if s_lbl:
			var join_key: String = "[U / JOYPAD]" if pid == 3 else "[NUMPAD / JOYPAD]"
			s_lbl.text = join_key + " PARA JUGAR"
			s_lbl.modulate = Color(0.5, 0.5, 0.5, 0.8)
		if p_lbl:
			p_lbl.text = "Perfil: " + prof_name
			p_lbl.modulate = Color(0.4, 0.4, 0.4, 0.6)
		return

	if b_lbl:
		b_lbl.add_theme_color_override("font_color", p_color)
	if p_lbl:
		p_lbl.text = "Perfil: " + prof_name
		p_lbl.modulate = Color(0.85, 0.9, 1.0, 0.8)

	var slot = roster_slots[state["slot_index"]]
	if n_lbl:
		n_lbl.text = slot["name"]
		n_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))

	if s_lbl:
		if state["locked"]:
			s_lbl.text = "¡LISTO!"
			s_lbl.modulate = Color(1.0, 0.88, 0.2)
		else:
			s_lbl.text = "ELIGE LUCHADOR"
			s_lbl.modulate = p_color

func _refresh_card_highlights() -> void:
	for i in card_nodes.keys():
		var node: Node3D = card_nodes[i]
		var glow_mesh: MeshInstance3D = node.get_node_or_null("Glow") as MeshInstance3D
		var mesh_inst: MeshInstance3D = node.get_node_or_null("CardMesh") as MeshInstance3D
		var base_pos: Vector3 = node.get_meta("base_pos") if node.has_meta("base_pos") else node.position

		var hovering_players: Array[int] = []
		for pid in [1, 2, 3, 4]:
			if players_state[pid]["active"] and players_state[pid]["slot_index"] == i:
				hovering_players.append(pid)

		if mesh_inst and mesh_inst.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mesh_inst.material_override
			if not hovering_players.is_empty():
				mat.albedo_color = Color(1.08, 1.08, 1.08)
				node.scale = Vector3(1.10, 1.10, 1.10)
				node.position = base_pos + Vector3(0.0, 0.0, 0.02)
				if glow_mesh and glow_mesh.material_override is StandardMaterial3D:
					glow_mesh.visible = true
					var g_mat: StandardMaterial3D = glow_mesh.material_override
					if hovering_players.size() > 1:
						g_mat.albedo_color = Color(1.0, 0.90, 0.25)
					else:
						g_mat.albedo_color = PLAYER_COLORS[hovering_players[0]]
			else:
				mat.albedo_color = Color(0.80, 0.80, 0.83)
				node.scale = Vector3(1.0, 1.0, 1.0)
				node.position = base_pos
				if glow_mesh:
					glow_mesh.visible = false

func _refresh_all_token_positions(animate: bool = true) -> void:
	var slot_to_players: Dictionary = {}
	for pid in [1, 2, 3, 4]:
		var state = players_state[pid]
		var tok: Node3D = state["token"]
		if not state["active"]:
			if tok:
				tok.visible = false
			continue
		if tok:
			tok.visible = true
		var s_idx: int = state["slot_index"]
		if not slot_to_players.has(s_idx):
			slot_to_players[s_idx] = []
		slot_to_players[s_idx].append(pid)

	for s_idx in slot_to_players.keys():
		var p_list: Array = slot_to_players[s_idx]
		var count: int = p_list.size()
		if not card_nodes.has(s_idx):
			continue
		var card_node: Node3D = card_nodes[s_idx]
		var up_vec: Vector3 = card_node.global_transform.basis.y
		var right_vec: Vector3 = card_node.global_transform.basis.x
		var base_pos: Vector3 = card_node.global_position + up_vec * 0.11 + Vector3(0.0, 0.01, 0.01)

		var spacing: float = 0.08 if count <= 2 else 0.065
		for j in range(count):
			var pid: int = p_list[j]
			var tok: Node3D = players_state[pid]["token"]
			if not tok:
				continue
			var offset_x: float = (float(j) - float(count - 1) * 0.5) * spacing
			var target_pos: Vector3 = base_pos + right_vec * offset_x

			if animate:
				var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(tok, "global_position", target_pos, 0.12)
				players_state[pid]["token_tween"] = tw
			else:
				tok.global_position = target_pos

func _update_token_position(player_id: int, animate: bool = true) -> void:
	_refresh_all_token_positions(animate)

# ==============================================================================
# 3D Stage Character Preview
# ==============================================================================
func _update_stage_preview(player_id: int, slot: Dictionary) -> void:
	var container: Node3D = players_state[player_id]["stage_model"]
	if not container:
		return
		
	for child in container.get_children():
		child.queue_free()
		
	var facing_yaw = deg_to_rad(22.0) if player_id in [1, 3] else deg_to_rad(-22.0)
	var data: CharacterData = slot["data"]
	
	if slot["id"] == "random":
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
		var char_root := Node3D.new()
		char_root.name = "CharacterRoot"
		char_root.rotation.y = facing_yaw
		
		var humanoid := Node3D.new()
		humanoid.name = "Humanoid"
		char_root.add_child(humanoid)
		
		var model = data.model_scene.instantiate()
		model.name = "ModelRoot"
		model.position = Vector3(data.model_offset.x, 0.0, data.model_offset.z)
		var s = data.model_scale if data.model_scale > 0.0 else 1.0
		model.scale = Vector3(s, s, s)
		humanoid.add_child(model)
		
		container.add_child(char_root)
		
		var played_idle := false
		var ap: AnimationPlayer = _find_animation_player(model)
		if ap:
			var anim_name = _find_idle_anim(ap)
			if anim_name != "":
				ap.play(anim_name)
				played_idle = true
		
		if not played_idle and data.animation_library:
			var new_ap := AnimationPlayer.new()
			new_ap.name = "AnimationPlayer"
			new_ap.root_node = NodePath("..")
			new_ap.add_animation_library("", data.animation_library)
			char_root.add_child(new_ap)
			var anim_name = _find_idle_anim(new_ap)
			if anim_name != "":
				new_ap.play(anim_name)
				played_idle = true
	else:
		var dummy := _create_procedural_dummy(data.character_color)
		dummy.rotation.y = facing_yaw
		dummy.position = Vector3(0, 0, 0)
		container.add_child(dummy)
		
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
	
	var torso := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.65, 0.28)
	torso.mesh = box
	torso.material_override = mat
	torso.position = Vector3(0, 0.95, 0)
	root.add_child(torso)
	
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.material_override = mat
	head.position = Vector3(0, 1.45, 0)
	root.add_child(head)
	
	for side in [-0.15, 0.15]:
		var leg := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.08
		cap.height = 0.65
		leg.mesh = cap
		leg.material_override = mat
		leg.position = Vector3(side, 0.35, 0)
		root.add_child(leg)
		
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
		if a.to_lower() == "idle":
			return a
	for a in ap.get_animation_list():
		if "idle" in a.to_lower():
			return a
	return ""

# ==============================================================================
# Lock & Ready Flow
# ==============================================================================
func _lock_player(player_id: int) -> void:
	if not players_state[player_id]["active"]:
		return
	players_state[player_id]["locked"] = true
	_play_sfx(sfx_select, 1.0 + (player_id - 1) * 0.12)
	players_state[player_id]["selected_data"] = _resolve_slot_selection(players_state[player_id]["slot_index"])
	_refresh_player_ui(player_id)
	_punch_token(players_state[player_id]["token"])
	_check_all_ready()

func _unlock_player(player_id: int) -> void:
	if not players_state[player_id]["active"]:
		return
	_play_sfx(sfx_cancel, 1.0)
	players_state[player_id]["locked"] = false
	players_state[player_id]["selected_data"] = null
	_refresh_player_ui(player_id)
			
	start_countdown_timer = -1.0
	if countdown_label:
		countdown_label.visible = false
	if start_battle_button:
		start_battle_button.visible = false
	_check_all_ready()

func _handle_cancel(player_id: int) -> void:
	if players_state[player_id]["locked"]:
		_unlock_player(player_id)
		return

	if player_id in [3, 4]:
		_deactivate_player(player_id)
	else:
		var any_locked = false
		for p in [1, 2, 3, 4]:
			if players_state[p]["active"] and players_state[p]["locked"]:
				any_locked = true
				break
		if not any_locked:
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
		
	var playable: Array[CharacterData] = [
		lego_batman_data,
		sakuya_data,
		gogeta_data,
		john_data,
		miyabi_data
	]
	playable.shuffle()
	return playable[0]

func _check_all_ready() -> void:
	var active_count: int = 0
	var locked_count: int = 0
	for pid in [1, 2, 3, 4]:
		if players_state[pid]["active"]:
			active_count += 1
			if players_state[pid]["locked"]:
				locked_count += 1

	if active_count >= 2 and locked_count == active_count:
		_play_sfx(sfx_ready, 1.0)
		if start_battle_button:
			start_battle_button.visible = true
			if is_inside_tree():
				start_battle_button.grab_focus()
		if countdown_label:
			countdown_label.visible = true
		start_countdown_timer = 2.0
		if bottom_prompt:
			bottom_prompt.text = "¡TODOS LISTOS! INICIANDO COMBATE..."
	else:
		start_countdown_timer = -1.0
		if countdown_label:
			countdown_label.visible = false
		if start_battle_button:
			start_battle_button.visible = false
		if bottom_prompt:
			bottom_prompt.text = "P1: [W/A/S/D / Joy1] • P2: [Flechas / Joy2] • P3: [I/J/K/L / Joy3] • P4: [NumPad / Joy4] • [Esc] Salir"

func _check_both_ready() -> void:
	_check_all_ready()

func _launch_battle() -> void:
	var p_data_dict: Dictionary = {}
	var p_profiles_dict: Dictionary = {}
	var im = get_node_or_null("/root/InputManager")

	for pid in [1, 2, 3, 4]:
		if not players_state[pid]["active"]:
			continue
		var sel_data: CharacterData = players_state[pid]["selected_data"]
		if sel_data == null:
			sel_data = _resolve_slot_selection(players_state[pid]["slot_index"])
			players_state[pid]["selected_data"] = sel_data
		p_data_dict[pid] = sel_data

		var prof: String = "Default"
		if im and im.has_method("get_player_profile_name"):
			prof = im.get_player_profile_name(pid)
		p_profiles_dict[pid] = prof
		
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_match_multi(p_data_dict, 3, 480.0, p_profiles_dict)
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
		var v = (sin(t * freqs[0] * TAU) + sin(t * freqs[1] * TAU) + sin(t * freqs[2] * TAU)) * 0.33 * env * volume
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

# ==============================================================================
# Live 3D Character Face Portrait Viewports
# ==============================================================================
func _create_face_portrait_viewport(slot: Dictionary) -> SubViewport:
	var data: CharacterData = slot["data"]
	var accent: Color = slot.get("color", Color(0.35, 0.7, 1.0))

	var vp := SubViewport.new()
	vp.name = "PortraitVP_" + str(slot["id"])
	vp.size = Vector2i(256, 170)
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(
		clampf(accent.r * 0.18 + 0.05, 0.0, 1.0),
		clampf(accent.g * 0.18 + 0.06, 0.0, 1.0),
		clampf(accent.b * 0.22 + 0.10, 0.0, 1.0),
		1.0
	)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.90, 0.96, 1.0)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.97, 0.92)
	key_light.light_energy = 1.15
	key_light.rotation_degrees = Vector3(-20.0, 24.0, 0.0)
	vp.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.light_color = Color(0.65, 0.78, 1.0)
	fill_light.light_energy = 0.55
	fill_light.rotation_degrees = Vector3(-10.0, -38.0, 0.0)
	vp.add_child(fill_light)

	var holder := Node3D.new()
	holder.name = "PortraitModelHolder"
	vp.add_child(holder)

	var model: Node3D = null
	if data != null and data.model_scene != null:
		var wrapper := Node3D.new()
		wrapper.rotation.y = deg_to_rad(10.0)
		var humanoid := Node3D.new()
		humanoid.name = "Humanoid"
		wrapper.add_child(humanoid)
		
		var m: Node3D = data.model_scene.instantiate()
		m.name = "ModelRoot"
		m.position = Vector3(data.model_offset.x, 0.0, data.model_offset.z)
		var s: float = data.model_scale if data.model_scale > 0.0 else 1.0
		m.scale = Vector3(s, s, s)
		humanoid.add_child(m)
		model = wrapper
		
		var ap: AnimationPlayer = _find_animation_player(m)
		if ap:
			var anim_name: String = _find_idle_anim(ap)
			if anim_name != "":
				ap.play(anim_name)
		elif data.animation_library:
			var new_ap := AnimationPlayer.new()
			new_ap.name = "AnimationPlayer"
			new_ap.root_node = NodePath("..")
			new_ap.add_animation_library("", data.animation_library)
			wrapper.add_child(new_ap)
			var anim_name: String = _find_idle_anim(new_ap)
			if anim_name != "":
				new_ap.play(anim_name)
	else:
		var color: Color = data.character_color if data != null else Color(0.4, 0.85, 0.95)
		model = _create_procedural_dummy(color)
		model.rotation.y = deg_to_rad(10.0)

	holder.add_child(model)

	var bg_plate := MeshInstance3D.new()
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(0.55, 0.55)
	bg_plate.mesh = bg_quad
	var bg_mat := StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.albedo_color = accent.lightened(0.15)
	bg_plate.material_override = bg_mat
	bg_plate.rotation.z = deg_to_rad(45.0)
	vp.add_child(bg_plate)

	var cam := Camera3D.new()
	cam.name = "PortraitCamera"
	cam.fov = 30.0
	cam.near = 0.05
	cam.far = 20.0
	vp.add_child(cam)

	call_deferred("_frame_portrait_camera", holder, cam, bg_plate, data)
	return vp

func _frame_portrait_camera(holder: Node3D, cam: Camera3D, bg_plate: MeshInstance3D, data: CharacterData) -> void:
	if not is_instance_valid(holder) or not is_instance_valid(cam):
		return
	var aabb: AABB = _compute_visual_aabb(holder)
	var head_bone: Vector3 = _find_head_bone_pos(holder)

	var focus_pt := Vector3(0.0, 1.45, 0.0)
	var cam_dist: float = 1.05
	var cname: String = data.character_name.to_lower() if data != null else ""

	if head_bone != Vector3.ZERO:
		var span_above: float = clampf((aabb.end.y - head_bone.y) * 0.32, 0.11, 0.21)
		if cname.contains("sans"):
			span_above = 0.14; cam_dist = 0.92
		elif cname.contains("batman"):
			span_above = 0.18; cam_dist = 1.02
		elif cname.contains("sakuya"):
			span_above = 0.10; cam_dist = 0.88
		elif cname.contains("gogeta"):
			span_above = 0.13; cam_dist = 0.98
		elif cname.contains("miyabi"):
			span_above = 0.12; cam_dist = 0.95
		elif cname.contains("hornet"):
			span_above = 0.12; cam_dist = 0.98
		focus_pt = Vector3(head_bone.x, head_bone.y + span_above, head_bone.z)
	elif aabb.size.y > 0.05:
		focus_pt = Vector3(
			aabb.position.x + aabb.size.x * 0.5,
			aabb.position.y + aabb.size.y * 0.83,
			aabb.position.z + aabb.size.z * 0.5
		)
		cam_dist = clampf(aabb.size.y * 0.58, 0.75, 1.35)

	if is_instance_valid(bg_plate):
		bg_plate.position = focus_pt + Vector3(0.0, 0.0, -0.45)

	cam.position = focus_pt + Vector3(0.0, 0.02, cam_dist)
	cam.look_at(focus_pt, Vector3.UP)

func _compute_visual_aabb(root: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_visible_meshes(root, meshes)
	var first := true
	var merged := AABB()
	var inv_root: Transform3D = root.global_transform.affine_inverse()
	for m in meshes:
		if m.mesh == null:
			continue
		var maabb: AABB = m.get_aabb()
		var rel_xf: Transform3D = inv_root * m.global_transform
		for ix in [0, 1]:
			for iy in [0, 1]:
				for iz in [0, 1]:
					var pt: Vector3 = rel_xf * Vector3(
						maabb.position.x if ix == 0 else maabb.end.x,
						maabb.position.y if iy == 0 else maabb.end.y,
						maabb.position.z if iz == 0 else maabb.end.z
					)
					merged = AABB(pt, Vector3.ZERO) if first else merged.expand(pt)
					first = false
	return merged

func _collect_visible_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_visible_meshes(c, out)

func _find_head_bone_pos(root: Node3D) -> Vector3:
	var skels: Array[Skeleton3D] = []
	_collect_skeletons(root, skels)
	var inv_root: Transform3D = root.global_transform.affine_inverse()
	for sk in skels:
		if not sk.is_visible_in_tree():
			continue
		for bname in ["Head", "head", "Bip01_Head", "mixamorig:Head", "head.x"]:
			var idx: int = sk.find_bone(bname)
			if idx != -1:
				return (inv_root * sk.global_transform) * sk.get_bone_global_pose(idx).origin
		for idx in range(sk.get_bone_count()):
			if "head" in sk.get_bone_name(idx).to_lower():
				return (inv_root * sk.global_transform) * sk.get_bone_global_pose(idx).origin
	var head_node: Node3D = root.find_child("Head", true, false) as Node3D
	return (inv_root * head_node.global_transform).origin if head_node != null else Vector3.ZERO

func _collect_skeletons(n: Node, out: Array[Skeleton3D]) -> void:
	if n is Skeleton3D:
		out.append(n as Skeleton3D)
	for c in n.get_children():
		_collect_skeletons(c, out)
