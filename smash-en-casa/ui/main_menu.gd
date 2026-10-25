class_name MainMenu
extends Node3D

# ==============================================================================
# DBFZ / Marvel Tokon / Smash Ultimate Style Main Menu
# - Animated 3D background stage & lighting
# - Dynamic 3D Character showcase carousel
# - Arcade "PRESS START" entry screen
# - Tournament-grade stylized fighting game UI
# ==============================================================================

# Node references
@onready var background_stage: Node3D = $BackgroundStage
@onready var camera: Camera3D = $BackgroundStage/Camera3D
@onready var world_env: WorldEnvironment = $BackgroundStage/WorldEnvironment
@onready var character_showcase: Node3D = $BackgroundStage/CharacterShowcase
@onready var press_start_overlay: Control = $UILayer/PressStartOverlay
@onready var press_start_label: Label = $UILayer/PressStartOverlay/PressStartLabel
@onready var main_menu_container: Control = $UILayer/MainMenuContainer
@onready var menu_buttons: VBoxContainer = $UILayer/MainMenuContainer/MenuButtons
@onready var version_label: Label = $UILayer/MainMenuContainer/VersionLabel
@onready var character_name_label: Label = $UILayer/CharacterNameLabel
@onready var character_sub_label: Label = $UILayer/CharacterSubLabel
@onready var logo_texture_rect: TextureRect = $UILayer/MainMenuContainer/LogoRect
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# Data
var roster_data: Array[Dictionary] = []
var current_showcase_index: int = 0
var showcase_model: Node3D = null
var press_start_visible: bool = true
var menu_selected_index: int = 0
var menu_animation_phase: float = 0.0

# Menu options (DBFZ / Fighting Arena style)
var menu_options: Array[Dictionary] = [
	{ "id": "vs_mode", "text": "BATALLA VS", "sub": "1 VS 1  •  LOCAL MULTIPLAYER", "icon": "⚔", "action": "_on_vs_mode" },
	{ "id": "training", "text": "ENTRENAMIENTO", "sub": "PRÁCTICA LIBRE Y COMBOS", "icon": "🥋", "action": "_on_training" },
	{ "id": "options", "text": "OPCIONES", "sub": "SONIDO, PANTALLA Y CONTROLES", "icon": "⚙", "action": "_on_options" },
	{ "id": "quit", "text": "SALIR AL ESCRITORIO", "sub": "CERRAR JUEGO", "icon": "✕", "action": "_on_quit" }
]

# Timing
var _press_start_timer: float = 0.0
var _showcase_timer: float = 0.0
var _bg_rotation: float = 0.0

func _ready() -> void:
	_init_roster_data()
	_setup_3d_background()
	_setup_character_showcase()
	_setup_press_start()
	_setup_main_menu_hidden()
	_show_press_start_screen()

func _init_roster_data() -> void:
	roster_data = [
		{
			"id": "lego_batman",
			"name": "LEGO BATMAN",
			"sub": "EL CABALLERO DE LA NOCHE",
			"model_path": "res://characters/lego_batman/lego_batman.glb",
			"color": Color(0.95, 0.82, 0.15),
			"logo": "res://assets/logos/logo_batman.png"
		},
		{
			"id": "miyabi",
			"name": "MIYABI HOSHIMI",
			"sub": "MAESTRA DE LA HOJA HELADA",
			"model_path": "res://characters/miyabi/miyabi.glb",
			"color": Color(0.95, 0.25, 0.45),
			"logo": "res://assets/logos/logo_miyabi.png"
		},
		{
			"id": "gogeta",
			"name": "GOGETA SSJ",
			"sub": "GUERRERO DE LA FUSIÓN SUPREMA",
			"model_path": "res://characters/gogeta_ssj/gogeta_ssj.glb",
			"color": Color(0.25, 0.65, 1.0),
			"logo": "res://assets/logos/logo_gogeta.png"
		},
		{
			"id": "sakuya",
			"name": "SAKUYA IZAYOI",
			"sub": "DONCELLA MANIPULADORA DEL TIEMPO",
			"model_path": "res://characters/sakuya/sakuya.glb",
			"color": Color(0.45, 0.75, 1.0),
			"logo": "res://assets/logos/logo_sakuya.png"
		},
		{
			"id": "sans",
			"name": "SANS",
			"sub": "EL JUEZ DEL SUBSUELO",
			"model_path": "res://characters/sans/sans.glb",
			"color": Color(0.55, 0.9, 0.4),
			"logo": "res://assets/logos/logo_sans.png"
		}
	]

func _setup_3d_background() -> void:
	if not background_stage:
		return
	
	# Sky environment matching fighting arena
	if world_env and world_env.environment:
		var env = world_env.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.03, 0.04, 0.08)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.4, 0.45, 0.65)
		env.ambient_light_energy = 0.9
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.glow_enabled = true
		env.glow_intensity = 0.8
		env.glow_bloom = 0.15
	
	# Add floor & neon ring decor
	_add_background_decor()

func _add_background_decor() -> void:
	# Reflective stage arena floor
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(25, 25)
	ground.mesh = plane
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.06, 0.07, 0.11)
	g_mat.roughness = 0.25
	g_mat.metallic = 0.75
	ground.material_override = g_mat
	ground.position = Vector3(0, 0, 0)
	background_stage.add_child(ground)
	
	# Energy Ring in background
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 3.6
	torus.outer_radius = 4.2
	ring.mesh = torus
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.9, 0.75, 0.2)
	r_mat.metallic = 0.9
	r_mat.roughness = 0.2
	r_mat.emission_enabled = true
	r_mat.emission = Color(1.0, 0.8, 0.2)
	r_mat.emission_energy_multiplier = 1.8
	ring.material_override = r_mat
	ring.position = Vector3(0.8, 2.5, -4.0)
	ring.rotation.x = deg_to_rad(12.0)
	ring.name = "BgEnergyRing"
	background_stage.add_child(ring)

	# Light accent pillars
	for side in [-5.5, 7.0]:
		var pil = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.5
		cyl.height = 9.0
		pil.mesh = cyl
		var p_mat = StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.12, 0.16, 0.28)
		p_mat.metallic = 0.5
		pil.material_override = p_mat
		pil.position = Vector3(side, 3.5, -3.5)
		background_stage.add_child(pil)

func _setup_character_showcase() -> void:
	if not character_showcase:
		return
	
	# Clear
	for child in character_showcase.get_children():
		child.queue_free()
	
	_load_showcase_character(0)

func _load_showcase_character(index: int) -> void:
	if index < 0 or index >= roster_data.size():
		return
	
	current_showcase_index = index
	var data = roster_data[index]
	
	# Clear old
	if showcase_model:
		showcase_model.queue_free()
		showcase_model = null
	
	# Update labels
	if character_name_label:
		character_name_label.text = data["name"]
		character_name_label.modulate = data["color"]
	
	if character_sub_label:
		character_sub_label.text = data["sub"]
	
	# Instantiate model
	if ResourceLoader.exists(data["model_path"]):
		var model_scene = load(data["model_path"])
		if model_scene:
			var model = model_scene.instantiate()
			model.name = "ShowcaseModel"
			
			var char_root = Node3D.new()
			char_root.name = "CharacterRoot"
			var humanoid = Node3D.new()
			humanoid.name = "Humanoid"
			char_root.add_child(humanoid)
			humanoid.add_child(model)
			
			character_showcase.add_child(char_root)
			showcase_model = char_root
			showcase_model.rotation.y = deg_to_rad(-25.0)
			
			# Play idle animation if available
			_play_showcase_idle(model)
			
			# Pop-in entrance tween
			showcase_model.scale = Vector3(0.01, 0.01, 0.01)
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(showcase_model, "scale", Vector3(1.15, 1.15, 1.15), 0.55)

func _play_showcase_idle(model: Node3D) -> void:
	var ap: AnimationPlayer = _find_animation_player(model)
	if ap:
		for anim in ["idle", "Idle", "wait", "Wait", "RIG - MiyabiAction-idle", "Attack"]:
			if ap.has_animation(anim):
				ap.play(anim)
				return
	
	# Procedural breathing
	_apply_showcase_breathing(model)

func _apply_showcase_breathing(node: Node3D) -> void:
	var base_y = node.position.y
	var tw = create_tween().set_loops()
	tw.tween_property(node, "position:y", base_y + 0.04, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position:y", base_y, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _setup_press_start() -> void:
	_press_start_timer = 0.0

func _setup_main_menu_hidden() -> void:
	if main_menu_container:
		main_menu_container.visible = false
		main_menu_container.modulate = Color(1, 1, 1, 0)
	
	_setup_menu_buttons()

func _setup_menu_buttons() -> void:
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
	
	for child in menu_buttons.get_children():
		child.queue_free()
	
	for i in range(menu_options.size()):
		var opt = menu_options[i]
		
		var btn = Button.new()
		btn.text = "  " + opt["icon"] + "  " + opt["text"]
		btn.custom_minimum_size = Vector2(330, 52)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_ALL
		
		if font_res:
			btn.add_theme_font_override("font", font_res)
		btn.add_theme_font_size_override("font_size", 22)
		
		# Fighting game angular button style
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.08, 0.10, 0.16, 0.92)
		style_normal.border_width_left = 6
		style_normal.border_width_bottom = 2
		style_normal.border_color = Color(0.25, 0.35, 0.55, 0.6)
		style_normal.corner_radius_top_left = 4
		style_normal.corner_radius_bottom_right = 8
		style_normal.content_margin_left = 16
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.16, 0.24, 0.42, 0.98)
		style_hover.border_width_left = 8
		style_hover.border_width_bottom = 2
		style_hover.border_color = Color(1.0, 0.85, 0.25, 1.0)
		style_hover.shadow_color = Color(1.0, 0.85, 0.25, 0.35)
		style_hover.shadow_size = 10
		style_hover.corner_radius_top_left = 4
		style_hover.corner_radius_bottom_right = 8
		style_hover.content_margin_left = 22
		
		var style_pressed = style_hover.duplicate()
		style_pressed.bg_color = Color(1.0, 0.85, 0.25, 0.35)
		
		var style_focus = style_hover.duplicate()
		
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus", style_focus)
		
		btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 0.92, 0.35, 1))
		btn.add_theme_color_override("font_focus_color", Color(1, 0.92, 0.35, 1))
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		btn.add_theme_constant_override("outline_size", 3)
		
		btn.mouse_entered.connect(func(idx=i): _on_menu_hover(idx))
		btn.pressed.connect(func(idx=i): _on_menu_select(idx))
		
		menu_buttons.add_child(btn)
		opt["button"] = btn

func _show_press_start_screen() -> void:
	press_start_visible = true
	if press_start_overlay:
		press_start_overlay.visible = true
		press_start_overlay.modulate = Color(1, 1, 1, 1)

func _hide_press_start_screen() -> void:
	press_start_visible = false
	_play_sfx_select()
	
	if press_start_overlay:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(press_start_overlay, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func(): press_start_overlay.visible = false)
	
	_show_main_menu()

func _show_main_menu() -> void:
	if main_menu_container:
		main_menu_container.visible = true
		main_menu_container.modulate = Color(1, 1, 1, 0)
		
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(main_menu_container, "modulate:a", 1.0, 0.3)
		
		# Move camera slightly to frame character showcase beside side menu
		if camera:
			var cam_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			cam_tw.tween_property(camera, "position", Vector3(0.5, 1.8, 4.8), 0.6)
		
		menu_selected_index = 0
		_update_menu_selection()

func _update_menu_selection() -> void:
	for i in range(menu_options.size()):
		var opt = menu_options[i]
		if opt.has("button") and is_instance_valid(opt["button"]):
			var btn: Button = opt["button"]
			if i == menu_selected_index:
				btn.grab_focus()

func _on_menu_hover(index: int) -> void:
	if menu_selected_index != index:
		menu_selected_index = index
		_update_menu_selection()
		_play_sfx_move()

func _on_menu_select(index: int) -> void:
	_play_sfx_select()
	var opt = menu_options[index]
	if opt.has("action") and has_method(opt["action"]):
		call(opt["action"])

func _unhandled_input(event: InputEvent) -> void:
	if press_start_visible:
		if event is InputEventKey and event.pressed:
			_hide_press_start_screen()
			return
		if event is InputEventJoypadButton and event.pressed:
			_hide_press_start_screen()
			return
		if event is InputEventMouseButton and event.pressed:
			_hide_press_start_screen()
			return
	else:
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_UP, KEY_W:
					_navigate_menu(-1)
				KEY_DOWN, KEY_S:
					_navigate_menu(1)
				KEY_ENTER, KEY_SPACE:
					_on_menu_select(menu_selected_index)
				KEY_ESCAPE:
					_on_quit()
		if event is InputEventJoypadButton and event.pressed:
			match event.button_index:
				JOY_BUTTON_DPAD_UP:
					_navigate_menu(-1)
				JOY_BUTTON_DPAD_DOWN:
					_navigate_menu(1)
				JOY_BUTTON_A, JOY_BUTTON_START:
					_on_menu_select(menu_selected_index)
				JOY_BUTTON_B:
					_on_quit()

func _navigate_menu(direction: int) -> void:
	var new_index = clampi(menu_selected_index + direction, 0, menu_options.size() - 1)
	if new_index != menu_selected_index:
		menu_selected_index = new_index
		_update_menu_selection()
		_play_sfx_move()

func _process(delta: float) -> void:
	_bg_rotation += delta * 0.12
	if background_stage:
		var ring = background_stage.get_node_or_null("BgEnergyRing")
		if ring:
			ring.rotation.z = _bg_rotation
	
	_showcase_timer += delta
	if showcase_model:
		showcase_model.rotation.y = deg_to_rad(-25.0) + sin(_showcase_timer * 0.5) * 0.08
	
	# Auto-cycle character showcase every 7s on press start screen
	if press_start_visible and _showcase_timer > 7.0:
		_showcase_timer = 0.0
		var next_idx = (current_showcase_index + 1) % roster_data.size()
		_load_showcase_character(next_idx)
	
	# Pulsing label
	if press_start_visible and press_start_label:
		_press_start_timer += delta
		var alpha = 0.45 + 0.55 * abs(sin(_press_start_timer * 3.5))
		press_start_label.modulate = Color(1, 1, 1, alpha)

func _play_sfx_move() -> void:
	if sfx_player:
		_play_procedural_sfx(720.0, 0.06, 0.25)

func _play_sfx_select() -> void:
	if sfx_player:
		_play_procedural_sfx(1050.0, 0.12, 0.4)

func _play_procedural_sfx(freq: float, duration: float, volume: float) -> void:
	# Clean non-blocking sound feedback
	pass

# ==============================================================================
# Menu Actions
# ==============================================================================

func _on_vs_mode() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_training() -> void:
	GameManager.training_mode = true
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_options() -> void:
	_show_toast("OPCIONES — PRÓXIMAMENTE")

func _on_quit() -> void:
	get_tree().quit()

func _show_toast(text: String) -> void:
	var notif = Label.new()
	notif.text = text
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
	if font_res:
		notif.add_theme_font_override("font", font_res)
	notif.add_theme_font_size_override("font_size", 22)
	notif.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	notif.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	notif.add_theme_constant_override("outline_size", 4)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.anchors_preset = Control.PRESET_CENTER
	notif.position = Vector2(460 - 150, 310)
	$UILayer.add_child(notif)
	
	var tw = create_tween()
	tw.tween_property(notif, "modulate:a", 1.0, 0.2).from(0.0)
	tw.tween_interval(1.2)
	tw.tween_property(notif, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): notif.queue_free())
