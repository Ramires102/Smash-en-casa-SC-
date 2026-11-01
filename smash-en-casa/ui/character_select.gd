# ==============================================================================
# CharacterSelect (Pantalla 3D de Selección de Personajes y Escenario — 2 a 4P)
# ==============================================================================
# Pantalla estilo Dragon Ball FighterZ / Smash Bros para armar la partida:
#   1. Hasta 4 jugadores simultáneos (`P1`..`P4`), con entrada dinámica ("Drop-In")
#      para P3 y P4 presionando su mando o teclado.
#   2. Cursores 3D flotantes con separación automática cuando coinciden en una carta.
#   3. Selector superior de escenario (`[Q / E]` o clic) sincronizado con `GameManager`.
#   4. Delega la generación 3D de cartas, retratos y escenografía a `CharacterSelect3DBuilder`.
# ==============================================================================
class_name CharacterSelect
extends Node3D

const MENU_FONT: Font = preload("res://ui/Fondos de texto/kamikaze_condensed.tres")
const MAX_PLAYERS: int = 4

const PLAYER_COLORS: Dictionary = {
	1: Color(0.25, 0.70, 1.00), # Azul
	2: Color(1.00, 0.28, 0.20), # Rojo
	3: Color(0.20, 0.90, 0.35), # Verde
	4: Color(1.00, 0.85, 0.20)  # Amarillo
}

# Atajos de teclado de respaldo por jugador para navegar sin configurar mandos.
const FALLBACK_DIR_KEYS: Dictionary = {
	1: {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S},
	2: {"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN},
	3: {"left": KEY_J, "right": KEY_L, "up": KEY_I, "down": KEY_K},
	4: {"left": KEY_KP_4, "right": KEY_KP_6, "up": KEY_KP_8, "down": KEY_KP_5}
}
const FALLBACK_CONFIRM_KEYS: Dictionary = {
	1: [KEY_SPACE, KEY_J, KEY_ENTER],
	2: [KEY_N, KEY_B, KEY_KP_1, KEY_KP_0],
	3: [KEY_U, KEY_O],
	4: [KEY_KP_1, KEY_KP_0]
}
const FALLBACK_CANCEL_KEYS: Dictionary = {
	1: [],
	2: [],
	3: [KEY_P],
	4: [KEY_KP_2]
}
const FALLBACK_UNLOCK_KEYS: Dictionary = {
	1: [KEY_K],
	2: [KEY_M, KEY_KP_2],
	3: [KEY_P],
	4: [KEY_KP_2]
}

#region Recursos Exportados del Roster (Contrato con character_select.tscn)
@export var lego_batman_data: CharacterData = preload("res://resources/instances/lego_batman_data.tres")
@export var sakuya_data: CharacterData = preload("res://resources/instances/sakuya_data.tres")
@export var gogeta_data: CharacterData = preload("res://resources/instances/gogeta_data.tres")
@export var john_data: CharacterData = preload("res://resources/instances/john_placeholder_data.tres")
@export var miyabi_data: CharacterData = preload("res://resources/instances/miyabi_data.tres")
@export var hornet_data: CharacterData = preload("res://resources/instances/hornet_data.tres")
#endregion

#region Referencias de Escena y Estado de los 4 Jugadores
@onready var camera: Camera3D = $Camera3D
@onready var card_arc_root: Node3D = $CardArc
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var start_battle_button: Button = $CanvasLayer/UI/CenterVS/StartBattleButton
@onready var countdown_label: Label = $CanvasLayer/UI/CenterVS/CountdownLabel
@onready var bottom_prompt: Label = $CanvasLayer/UI/BottomBar/HBox/PromptLabel
@onready var world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment

var roster_slots: Array[Dictionary] = []
var players_state: Dictionary = {}
var card_nodes: Dictionary = {}
var portrait_viewports: Array[SubViewport] = []

var stage_bg_deco: Node3D = null
var stage_preview_rect: TextureRect = null
var stage_name_label: Label = null

var start_countdown_timer: float = -1.0
var _preview_time: float = 0.0

var sfx_move: AudioStreamWAV
var sfx_select: AudioStreamWAV
var sfx_cancel: AudioStreamWAV
var sfx_ready: AudioStreamWAV
#endregion

#region Ciclo de Vida
func _ready() -> void:
	AudioManager.play_menu_theme()
	_init_players_state()
	_init_sfx()
	_init_roster()

	card_nodes = CharacterSelect3DBuilder.build_card_arc(
		card_arc_root, self, roster_slots, MENU_FONT, Callable(self, "_on_card_input_event"), portrait_viewports
	)
	_setup_3d_stage_background()
	_setup_nodes_for_4_players()
	_build_stage_preview()

	for pid in [3, 4]:
		if GameManager.active_player_ids.has(pid):
			players_state[pid]["active"] = true

	_update_pedestal_positions()
	for pid in range(1, MAX_PLAYERS + 1):
		_refresh_player_ui(pid)
		_update_stage_preview(pid, roster_slots[players_state[pid]["slot_index"]])

	_refresh_card_highlights()
	_sync_initial_tokens()

	if start_battle_button:
		start_battle_button.pressed.connect(_on_start_battle_pressed)
		start_battle_button.visible = false
	if countdown_label:
		countdown_label.visible = false

func _init_players_state() -> void:
	players_state.clear()
	for pid in range(1, MAX_PLAYERS + 1):
		players_state[pid] = {
			"active": (pid <= 2),
			"slot_index": pid,
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

func _init_sfx() -> void:
	sfx_move = UIThemeUtils.synth_tone(780.0, 0.045, 0.30)
	sfx_select = UIThemeUtils.synth_dual_tone(600.0, 1100.0, 0.12, 0.40)
	sfx_cancel = UIThemeUtils.synth_sweep(400.0, 180.0, 0.08, 0.35)
	sfx_ready = UIThemeUtils.synth_chord([440.0, 554.37, 659.25], 0.35, 0.45)

func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if is_inside_tree() and sfx_player and stream:
		sfx_player.stream = stream
		sfx_player.pitch_scale = pitch
		sfx_player.play()

func _process(delta: float) -> void:
	_preview_time += delta

	for pid in range(1, MAX_PLAYERS + 1):
		var tok: Node3D = players_state[pid]["token"]
		if tok and tok.visible:
			tok.position.y += sin(_preview_time * 5.0 + float(pid)) * (0.015 * delta)

		var st_model: Node3D = players_state[pid]["stage_model"]
		if st_model and st_model.visible:
			st_model.position.y = 0.08 + sin(_preview_time * 2.2 + float(pid) * 0.9) * 0.015
			if st_model.get_child_count() > 0 and st_model.get_child(0) is Node3D:
				var c: Node3D = st_model.get_child(0) as Node3D
				var base_yaw: float = deg_to_rad(22.0) if pid in [1, 3] else deg_to_rad(-22.0)
				c.rotation.y = base_yaw + sin(_preview_time * 1.5 + float(pid)) * 0.03

	if stage_bg_deco:
		for child in stage_bg_deco.get_children():
			if "Ring" in child.name:
				child.rotation.z += delta * 0.15

	if start_countdown_timer > 0.0:
		start_countdown_timer -= delta
		if countdown_label:
			countdown_label.text = "BATALLA EN %d..." % int(ceil(start_countdown_timer))
		if start_countdown_timer <= 0.0:
			_launch_battle()
#endregion

#region Definición del Roster y Selector de Escenarios
func _init_roster() -> void:
	roster_slots = [
		{
			"id": "random", "name": "ALEATORIO", "sub": "¿QUIÉN SERÁ?", "data": null,
			"row": 0, "col": 0, "tex_path": "res://ui/character_select/portraits/random.png",
			"color": Color(1.0, 0.85, 0.25)
		},
		{
			"id": "lego_batman", "name": "LEGO\nBATMAN", "sub": "EL CABALLERO OSCURO", "data": lego_batman_data,
			"row": 1, "col": 0, "tex_path": "res://ui/character_select/portraits/lego_batman.png",
			"color": Color(0.95, 0.82, 0.15)
		},
		{
			"id": "sakuya", "name": "SAKUYA\nIZAYOI", "sub": "SIRVIENTA DEL TIEMPO", "data": sakuya_data,
			"row": 1, "col": 1, "tex_path": "res://ui/character_select/portraits/sakuya.png",
			"color": Color(0.45, 0.75, 1.0)
		},
		{
			"id": "gogeta", "name": "GOGETA", "sub": "GUERRERO DE FUSIÓN", "data": gogeta_data,
			"row": 2, "col": 0, "tex_path": "res://ui/character_select/portraits/gogeta.png",
			"color": Color(0.25, 0.65, 1.0)
		},
		{
			"id": "john", "name": "JOHN\nPLACEHOLDER", "sub": "MANIQUÍ DE ENTRENAMIENTO", "data": john_data,
			"row": 2, "col": 1, "tex_path": "res://ui/character_select/portraits/john.png",
			"color": Color(0.4, 0.85, 0.95)
		},
		{
			"id": "miyabi", "name": "MIYABI\nHOSHIMI", "sub": "MAESTRA DE LA ESPADA", "data": miyabi_data,
			"row": 3, "col": 1, "tex_path": "res://ui/character_select/portraits/miyabi.png",
			"color": Color(0.85, 0.2, 0.35)
		},
		{
			"id": "hornet", "name": "HORNET", "sub": "PROTECTORA DE HALLOWNEST", "data": hornet_data,
			"row": 3, "col": 0, "tex_path": "res://ui/character_select/portraits/hornet.png",
			"color": Color(0.9, 0.15, 0.22)
		}
	]

func _setup_3d_stage_background() -> void:
	if stage_bg_deco == null:
		stage_bg_deco = Node3D.new()
		stage_bg_deco.name = "StageBackgroundDeco"
		stage_bg_deco.position = Vector3(0, 0, -3.2)
		add_child(stage_bg_deco)
	CharacterSelect3DBuilder.update_stage_background(stage_bg_deco, world_environment, GameManager.get_selected_stage())

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

	var style: StyleBoxFlat = UIThemeUtils.make_stylebox(
		Color(0.04, 0.06, 0.10, 0.88), Color(0.85, 0.68, 0.22, 0.90), 2, 6
	)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	var header_label := Label.new()
	header_label.text = "ESCENARIO [Q / E]"
	if MENU_FONT:
		header_label.add_theme_font_override("font", MENU_FONT)
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
	btn_left.pressed.connect(func() -> void: _cycle_stage(-1))
	row.add_child(btn_left)

	stage_preview_rect = TextureRect.new()
	stage_preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage_preview_rect.custom_minimum_size = Vector2(136, 56)
	stage_preview_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_preview_rect.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_cycle_stage(1)
	)
	row.add_child(stage_preview_rect)

	var btn_right := Button.new()
	btn_right.text = "►"
	btn_right.custom_minimum_size = Vector2(24, 52)
	btn_right.focus_mode = Control.FOCUS_NONE
	btn_right.pressed.connect(func() -> void: _cycle_stage(1))
	row.add_child(btn_right)
	vbox.add_child(row)

	stage_name_label = Label.new()
	if MENU_FONT:
		stage_name_label.add_theme_font_override("font", MENU_FONT)
	stage_name_label.add_theme_font_size_override("font_size", 11)
	stage_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35, 1.0))
	stage_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stage_name_label)

	panel.add_child(vbox)
	ui_root.add_child(panel)
	_update_stage_display()

func _cycle_stage(direction: int) -> void:
	GameManager.set_selected_stage_index(GameManager.selected_stage_index + direction)
	_update_stage_display()
	CharacterSelect3DBuilder.update_stage_background(stage_bg_deco, world_environment, GameManager.get_selected_stage())
	_play_sfx(sfx_move, 1.25)

func _update_stage_display() -> void:
	var stage_data: Dictionary = GameManager.get_selected_stage()
	if stage_name_label:
		stage_name_label.text = str(stage_data.get("name", "ESCENARIO")).to_upper()
		stage_name_label.add_theme_color_override("font_color", stage_data.get("theme_color", Color(1.0, 0.9, 0.4)))
	if stage_preview_rect:
		var preview_path: String = str(stage_data.get("preview_path", ""))
		if ResourceLoader.exists(preview_path):
			stage_preview_rect.texture = load(preview_path)
		elif FileAccess.file_exists(preview_path):
			var img: Image = Image.load_from_file(ProjectSettings.globalize_path(preview_path))
			if img:
				stage_preview_rect.texture = ImageTexture.create_from_image(img)
#endregion

#region Configuración de Nodos 3D y UI para 4 Jugadores
func _setup_nodes_for_4_players() -> void:
	var p1_stage: Node3D = get_node_or_null("StageP1")
	var p2_stage: Node3D = get_node_or_null("StageP2")
	var lights_parent: Node = get_node_or_null("Lights")
	var tokens_parent: Node = get_node_or_null("Tokens")

	players_state[1]["stage_root"] = p1_stage
	players_state[1]["stage_model"] = p1_stage.get_node_or_null("ModelContainer") if p1_stage else null
	players_state[1]["stage_light"] = get_node_or_null("Lights/StageLightP1")
	players_state[1]["token"] = get_node_or_null("Tokens/P1Token")

	players_state[2]["stage_root"] = p2_stage
	players_state[2]["stage_model"] = p2_stage.get_node_or_null("ModelContainer") if p2_stage else null
	players_state[2]["stage_light"] = get_node_or_null("Lights/StageLightP2")
	players_state[2]["token"] = get_node_or_null("Tokens/P2Token")

	# Pedestales, focos y fichas 3D de P3 y P4 clonados a partir de P1/P2.
	var p3_stage: Node3D = _ensure_extra_pedestal(3, p1_stage, "PedestalP1", Color(0.08, 0.18, 0.10, 1.0))
	players_state[3]["stage_root"] = p3_stage
	players_state[3]["stage_model"] = p3_stage.get_node_or_null("ModelContainer") if p3_stage else null

	var p4_stage: Node3D = _ensure_extra_pedestal(4, p2_stage, "PedestalP2", Color(0.18, 0.16, 0.06, 1.0))
	players_state[4]["stage_root"] = p4_stage
	players_state[4]["stage_model"] = p4_stage.get_node_or_null("ModelContainer") if p4_stage else null

	if lights_parent:
		players_state[3]["stage_light"] = _ensure_extra_spotlight(3, lights_parent, "StageLightP1", Vector3(-1.45, 3.0, 1.0))
		players_state[4]["stage_light"] = _ensure_extra_spotlight(4, lights_parent, "StageLightP2", Vector3(2.6, 3.0, 1.0))

	if tokens_parent:
		players_state[3]["token"] = _ensure_extra_token(3, tokens_parent, "P1Token")
		players_state[4]["token"] = _ensure_extra_token(4, tokens_parent, "P2Token")

	# Tarjetas de información 2D en las esquinas para P1..P4.
	var ui_root: Control = get_node_or_null("CanvasLayer/UI")
	var p1_info: VBoxContainer = get_node_or_null("CanvasLayer/UI/P1Info") as VBoxContainer
	var p2_info: VBoxContainer = get_node_or_null("CanvasLayer/UI/P2Info") as VBoxContainer

	_configure_player_info_panel(1, p1_info, false, 10.0, 90.0)
	_configure_player_info_panel(2, p2_info, true, 10.0, 90.0)

	var p3_info: VBoxContainer = get_node_or_null("CanvasLayer/UI/P3Info") as VBoxContainer
	if not p3_info and ui_root and p1_info:
		p3_info = p1_info.duplicate()
		p3_info.name = "P3Info"
		ui_root.add_child(p3_info)
	_configure_player_info_panel(3, p3_info, false, 98.0, 178.0, "◄ JUGADOR 3")

	var p4_info: VBoxContainer = get_node_or_null("CanvasLayer/UI/P4Info") as VBoxContainer
	if not p4_info and ui_root and p2_info:
		p4_info = p2_info.duplicate()
		p4_info.name = "P4Info"
		ui_root.add_child(p4_info)
	_configure_player_info_panel(4, p4_info, true, 98.0, 178.0, "JUGADOR 4 ►")

func _ensure_extra_pedestal(pid: int, template_stage: Node3D, old_ped_name: String, base_albedo: Color) -> Node3D:
	var stage_name: String = "StageP%d" % pid
	var existing: Node3D = get_node_or_null(stage_name)
	if existing or not template_stage:
		return existing

	var cloned: Node3D = template_stage.duplicate()
	cloned.name = stage_name
	add_child(cloned)
	var ped: MeshInstance3D = cloned.get_node_or_null(old_ped_name) as MeshInstance3D
	if ped:
		ped.name = "PedestalP%d" % pid
		var mat := StandardMaterial3D.new()
		mat.albedo_color = base_albedo
		mat.metallic = 0.7
		mat.roughness = 0.3
		mat.emission_enabled = true
		mat.emission = PLAYER_COLORS[pid]
		mat.emission_energy_multiplier = 1.2
		ped.material_override = mat
	return cloned

func _ensure_extra_spotlight(pid: int, lights_parent: Node, src_name: String, pos: Vector3) -> Light3D:
	var dst_name: String = "StageLightP%d" % pid
	var existing: Light3D = lights_parent.get_node_or_null(dst_name) as Light3D
	var src: Light3D = lights_parent.get_node_or_null(src_name) as Light3D
	if existing or not src:
		return existing

	var cloned: Light3D = src.duplicate()
	cloned.name = dst_name
	cloned.light_color = PLAYER_COLORS[pid]
	cloned.position = pos
	lights_parent.add_child(cloned)
	return cloned

func _ensure_extra_token(pid: int, tokens_parent: Node, src_name: String) -> Node3D:
	var dst_name: String = "P%dToken" % pid
	var existing: Node3D = tokens_parent.get_node_or_null(dst_name) as Node3D
	var src: Node3D = tokens_parent.get_node_or_null(src_name) as Node3D
	if existing or not src:
		return existing

	var cloned: Node3D = src.duplicate()
	cloned.name = dst_name
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PLAYER_COLORS[pid]
	mat.metallic = 0.8
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = PLAYER_COLORS[pid]
	mat.emission_energy_multiplier = 0.5
	var disc: MeshInstance3D = cloned.get_node_or_null("Disc") as MeshInstance3D
	if disc: disc.material_override = mat
	var arrow: MeshInstance3D = cloned.get_node_or_null("Arrow") as MeshInstance3D
	if arrow: arrow.material_override = mat
	var lbl: Label3D = cloned.get_node_or_null("Label3D") as Label3D
	if lbl: lbl.text = str(pid)
	tokens_parent.add_child(cloned)
	return cloned

func _configure_player_info_panel(
	pid: int,
	panel: VBoxContainer,
	align_right: bool,
	top_px: float,
	bottom_px: float,
	badge_override: String = ""
) -> void:
	if not panel:
		return
	panel.offset_top = top_px
	panel.offset_bottom = bottom_px
	panel.add_theme_constant_override("separation", 1)

	var name_lbl: Label = panel.get_node_or_null("NameLabel") as Label
	if name_lbl: name_lbl.add_theme_font_size_override("font_size", 17)
	var stat_lbl: Label = panel.get_node_or_null("StatusLabel") as Label
	if stat_lbl: stat_lbl.add_theme_font_size_override("font_size", 11)
	var badge_lbl: Label = panel.get_node_or_null("Badge") as Label
	if badge_lbl:
		badge_lbl.add_theme_font_size_override("font_size", 12)
		if badge_override != "":
			badge_lbl.text = badge_override

	var prof_lbl: Label = panel.get_node_or_null("ProfileLabel") as Label
	if not prof_lbl:
		prof_lbl = Label.new()
		prof_lbl.name = "ProfileLabel"
		if MENU_FONT: prof_lbl.add_theme_font_override("font", MENU_FONT)
		prof_lbl.add_theme_font_size_override("font_size", 10)
		if align_right:
			prof_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(prof_lbl)

	players_state[pid]["info_panel"] = panel
	players_state[pid]["badge_label"] = badge_lbl
	players_state[pid]["name_label"] = name_lbl
	players_state[pid]["status_label"] = stat_lbl
	players_state[pid]["profile_label"] = prof_lbl

func _sync_initial_tokens() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_refresh_all_token_positions(false)
#endregion

#region Entrada y Navegación Multijugador (1 a 4 Jugadores)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_Q, KEY_BRACKETLEFT]:
			_cycle_stage(-1)
			return
		elif event.keycode in [KEY_E, KEY_BRACKETRIGHT]:
			_cycle_stage(1)
			return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_handle_cancel(1)
		return

	# Entrada dinámica ("Drop-In") para P3 y P4.
	for extra_pid in [3, 4]:
		if not players_state[extra_pid]["active"] and _is_join_event_for_player(extra_pid, event):
			_activate_player(extra_pid)
			return

	for pid in range(1, MAX_PLAYERS + 1):
		if players_state[pid]["active"]:
			_handle_player_input(pid, event)

func _is_join_event_for_player(pid: int, event: InputEvent) -> bool:
	var prefix: String = "p%d_" % pid
	for act in ["attack", "jump", "special", "left", "right", "up", "down", "pause"]:
		if event.is_action_pressed(prefix + act):
			return true

	if event is InputEventKey and event.pressed:
		if pid == 3 and event.keycode in [KEY_U, KEY_I, KEY_O, KEY_P, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON]:
			return true
		elif pid == 4 and event.keycode in [KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_8]:
			return true

	if event is InputEventJoypadButton and event.pressed:
		return event.device == InputManager.get_device_id_for_player(pid)

	return false

func _handle_player_input(pid: int, event: InputEvent) -> void:
	var state: Dictionary = players_state[pid]
	var prefix: String = "p%d_" % pid
	var is_key_down: bool = (event is InputEventKey and event.pressed)
	var keycode: int = (event as InputEventKey).keycode if is_key_down else 0

	if not state["locked"]:
		var fb_dirs: Dictionary = FALLBACK_DIR_KEYS[pid]
		var dir := Vector2i.ZERO
		if event.is_action_pressed(prefix + "left") or (is_key_down and keycode == fb_dirs["left"]):
			dir = Vector2i(-1, 0)
		elif event.is_action_pressed(prefix + "right") or (is_key_down and keycode == fb_dirs["right"]):
			dir = Vector2i(1, 0)
		elif event.is_action_pressed(prefix + "up") or (is_key_down and keycode == fb_dirs["up"]):
			dir = Vector2i(0, -1)
		elif event.is_action_pressed(prefix + "down") or (is_key_down and keycode == fb_dirs["down"]):
			dir = Vector2i(0, 1)

		if dir != Vector2i.ZERO:
			_navigate_player(pid, dir)
			return

		var confirm_pressed: bool = event.is_action_pressed(prefix + "attack") \
			or event.is_action_pressed(prefix + "jump") \
			or (is_key_down and keycode in FALLBACK_CONFIRM_KEYS[pid])
		if confirm_pressed:
			_lock_player(pid)
			return

		var cancel_pressed: bool = event.is_action_pressed(prefix + "special") \
			or (is_key_down and keycode in FALLBACK_CANCEL_KEYS[pid])
		if cancel_pressed:
			_handle_cancel(pid)
	else:
		var unlock_pressed: bool = event.is_action_pressed(prefix + "special") \
			or (is_key_down and keycode in FALLBACK_UNLOCK_KEYS[pid])
		if unlock_pressed:
			_unlock_player(pid)

func _navigate_player(player_id: int, dir: Vector2i) -> void:
	if not players_state[player_id]["active"] or players_state[player_id]["locked"]:
		return
	var current_idx: int = players_state[player_id]["slot_index"]
	var next_idx: int = _calc_grid_step(current_idx, dir)
	if next_idx != current_idx:
		_play_sfx(sfx_move, 1.0 + (player_id - 1) * 0.08)
		_update_player_selection(player_id, next_idx)

func _calc_grid_step(curr_idx: int, dir: Vector2i) -> int:
	match curr_idx:
		0: # Aleatorio (fila 0, centro)
			if dir.y > 0: return 1
		1: # Lego Batman (fila 1, izq)
			if dir.x > 0: return 2
			elif dir.y < 0: return 0
			elif dir.y > 0: return 3
		2: # Sakuya (fila 1, der)
			if dir.x < 0: return 1
			elif dir.y < 0: return 0
			elif dir.y > 0: return 4
		3: # Gogeta (fila 2, izq)
			if dir.x > 0: return 4
			elif dir.y < 0: return 1
			elif dir.y > 0: return 6
		4: # John (fila 2, der)
			if dir.x < 0: return 3
			elif dir.y < 0: return 2
			elif dir.y > 0: return 5
		5: # Miyabi (fila 3, der)
			if dir.y < 0: return 4
			elif dir.x < 0: return 6
		6: # Hornet (fila 3, izq)
			if dir.y < 0: return 3
			elif dir.x > 0: return 5
	return curr_idx

func _on_card_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, slot_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for pid in range(1, MAX_PLAYERS + 1):
			if players_state[pid]["active"] and not players_state[pid]["locked"]:
				_play_sfx(sfx_select, 1.0 + (pid - 1) * 0.1)
				_update_player_selection(pid, slot_idx)
				_lock_player(pid)
				return
#endregion

#region Activación de Jugadores, Cursores 3D y Pedestales
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
	if players_state[pid]["token"]: players_state[pid]["token"].visible = false
	if players_state[pid]["stage_root"]: players_state[pid]["stage_root"].visible = false
	if players_state[pid]["stage_light"]: players_state[pid]["stage_light"].visible = false

	_play_sfx(sfx_cancel, 0.95)
	_update_pedestal_positions()
	_refresh_all_token_positions(true)
	_refresh_player_ui(pid)
	_refresh_card_highlights()
	_check_all_ready()

func _get_active_player_count() -> int:
	var count: int = 0
	for pid in range(1, MAX_PLAYERS + 1):
		if players_state[pid]["active"]:
			count += 1
	return count

func _update_pedestal_positions() -> void:
	var crowded: bool = (_get_active_player_count() > 2)
	if crowded:
		_set_stage_pos_rot(1, Vector3(-2.60, 0.05, -0.5), deg_to_rad(28.0))
		_set_stage_pos_rot(3, Vector3(-1.45, 0.05,  0.0), deg_to_rad(15.0))
		_set_stage_pos_rot(2, Vector3( 1.45, 0.05,  0.0), deg_to_rad(-15.0))
		_set_stage_pos_rot(4, Vector3( 2.60, 0.05, -0.5), deg_to_rad(-28.0))
		if camera: camera.position = Vector3(0.0, 1.25, 4.35)
	else:
		_set_stage_pos_rot(1, Vector3(-1.85, 0.05, -0.4), deg_to_rad(22.0))
		_set_stage_pos_rot(2, Vector3( 1.85, 0.05, -0.4), deg_to_rad(-22.0))
		_set_stage_pos_rot(3, Vector3(-1.45, 0.05,  0.0), deg_to_rad(15.0))
		_set_stage_pos_rot(4, Vector3( 2.60, 0.05, -0.5), deg_to_rad(-28.0))
		if camera: camera.position = Vector3(0.0, 1.20, 4.00)

	for pid in range(1, MAX_PLAYERS + 1):
		var is_act: bool = players_state[pid]["active"]
		if players_state[pid]["stage_root"]: players_state[pid]["stage_root"].visible = is_act
		if players_state[pid]["stage_light"]: players_state[pid]["stage_light"].visible = is_act

func _set_stage_pos_rot(pid: int, pos: Vector3, rot_y: float) -> void:
	var st_root: Node3D = players_state[pid]["stage_root"]
	if not st_root:
		return
	st_root.position = pos
	var model_cont: Node3D = players_state[pid]["stage_model"]
	if model_cont and model_cont.get_child_count() > 0 and model_cont.get_child(0) is Node3D:
		(model_cont.get_child(0) as Node3D).rotation.y = rot_y

func _update_player_selection(player_id: int, slot_idx: int, animate_token: bool = true) -> void:
	players_state[player_id]["slot_index"] = slot_idx
	_refresh_player_ui(player_id)
	_refresh_card_highlights()
	_refresh_all_token_positions(animate_token)
	_update_stage_preview(player_id, roster_slots[slot_idx])

func _refresh_player_ui(pid: int) -> void:
	var state: Dictionary = players_state[pid]
	var is_act: bool = state["active"]
	var n_lbl: Label = state["name_label"]
	var s_lbl: Label = state["status_label"]
	var b_lbl: Label = state["badge_label"]
	var p_lbl: Label = state["profile_label"]
	var p_color: Color = PLAYER_COLORS[pid]
	var prof_name: String = InputManager.get_player_profile_name(pid)

	if not is_act:
		if b_lbl: b_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
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

	if b_lbl: b_lbl.add_theme_color_override("font_color", p_color)
	if p_lbl:
		p_lbl.text = "Perfil: " + prof_name
		p_lbl.modulate = Color(0.85, 0.9, 1.0, 0.8)

	var slot: Dictionary = roster_slots[state["slot_index"]]
	if n_lbl:
		n_lbl.text = slot["name"]
		n_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))

	if s_lbl:
		s_lbl.text = "¡LISTO!" if state["locked"] else "ELIGE LUCHADOR"
		s_lbl.modulate = Color(1.0, 0.88, 0.2) if state["locked"] else p_color

func _refresh_card_highlights() -> void:
	for i in card_nodes.keys():
		var node: Node3D = card_nodes[i]
		var glow_mesh: MeshInstance3D = node.get_node_or_null("Glow") as MeshInstance3D
		var mesh_inst: MeshInstance3D = node.get_node_or_null("CardMesh") as MeshInstance3D
		var base_pos: Vector3 = node.get_meta("base_pos") if node.has_meta("base_pos") else node.position

		var hovering_players: Array[int] = []
		for pid in range(1, MAX_PLAYERS + 1):
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
					g_mat.albedo_color = Color(1.0, 0.90, 0.25) if hovering_players.size() > 1 else PLAYER_COLORS[hovering_players[0]]
			else:
				mat.albedo_color = Color(0.80, 0.80, 0.83)
				node.scale = Vector3.ONE
				node.position = base_pos
				if glow_mesh:
					glow_mesh.visible = false

func _refresh_all_token_positions(animate: bool = true) -> void:
	var slot_to_players: Dictionary = {}
	for pid in range(1, MAX_PLAYERS + 1):
		var state: Dictionary = players_state[pid]
		var tok: Node3D = state["token"]
		if not state["active"]:
			if tok: tok.visible = false
			continue
		if tok: tok.visible = true
		var s_idx: int = state["slot_index"]
		if not slot_to_players.has(s_idx):
			slot_to_players[s_idx] = []
		slot_to_players[s_idx].append(pid)

	for s_idx in slot_to_players.keys():
		if not card_nodes.has(s_idx):
			continue
		var p_list: Array = slot_to_players[s_idx]
		var count: int = p_list.size()
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

			var prev_tw: Tween = players_state[pid]["token_tween"]
			if prev_tw and prev_tw.is_valid():
				prev_tw.kill()

			if animate:
				var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(tok, "global_position", target_pos, 0.12)
				players_state[pid]["token_tween"] = tw
			else:
				tok.global_position = target_pos

func _update_stage_preview(player_id: int, slot: Dictionary) -> void:
	var container: Node3D = players_state[player_id]["stage_model"]
	var facing_yaw: float = deg_to_rad(22.0) if player_id in [1, 3] else deg_to_rad(-22.0)
	if CharacterSelect3DBuilder.populate_pedestal_model(container, slot, facing_yaw):
		container.scale = Vector3(0.85, 0.85, 0.85)
		var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(container, "scale", Vector3.ONE, 0.2)
#endregion

#region Confirmación de Luchadores e Inicio de Batalla
func _lock_player(player_id: int) -> void:
	if not players_state[player_id]["active"]:
		return
	players_state[player_id]["locked"] = true
	players_state[player_id]["selected_data"] = _resolve_slot_selection(players_state[player_id]["slot_index"])
	_play_sfx(sfx_select, 1.0 + (player_id - 1) * 0.12)
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
	_check_all_ready()

func _handle_cancel(player_id: int) -> void:
	if players_state[player_id]["locked"]:
		_unlock_player(player_id)
		return

	if player_id in [3, 4]:
		_deactivate_player(player_id)
	else:
		for p in range(1, MAX_PLAYERS + 1):
			if players_state[p]["active"] and players_state[p]["locked"]:
				return
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

	var playable: Array[CharacterData] = [
		lego_batman_data,
		sakuya_data,
		gogeta_data,
		john_data,
		miyabi_data,
		hornet_data
	]
	playable.shuffle()
	return playable[0]

func _check_all_ready() -> void:
	var active_count: int = 0
	var locked_count: int = 0
	for pid in range(1, MAX_PLAYERS + 1):
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

func _launch_battle() -> void:
	var p_data_dict: Dictionary = {}
	var p_profiles_dict: Dictionary = {}

	for pid in range(1, MAX_PLAYERS + 1):
		if not players_state[pid]["active"]:
			continue
		var sel_data: CharacterData = players_state[pid]["selected_data"]
		if sel_data == null:
			sel_data = _resolve_slot_selection(players_state[pid]["slot_index"])
			players_state[pid]["selected_data"] = sel_data
		p_data_dict[pid] = sel_data
		p_profiles_dict[pid] = InputManager.get_player_profile_name(pid)

	GameManager.start_match_multi(p_data_dict, 3, 480.0, p_profiles_dict)
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_start_battle_pressed() -> void:
	_launch_battle()

func _on_back_pressed() -> void:
	_play_sfx(sfx_cancel, 0.9)
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
#endregion
