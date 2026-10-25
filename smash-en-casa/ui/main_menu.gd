class_name MainMenu
extends Control

# ==============================================================================
# DBFZ / Smash Ultimate Style Main Menu
# - Animated 3D background stage
# - Character showcase carousel
# - Press Start entry screen
# - Full menu navigation with keyboard/controller
# ==============================================================================

# Node references
@onready var background_stage: Node3D = $BackgroundStage
@onready var camera: Camera3D = $BackgroundStage/Camera3D
@onready var world_env: WorldEnvironment = $BackgroundStage/WorldEnvironment
@onready var character_showcase: Node3D = $BackgroundStage/CharacterShowcase
@onready var press_start_overlay: Control = $PressStartOverlay
@onready var press_start_label: Label = $PressStartOverlay/PressStartLabel
@onready var main_menu_container: Control = $MainMenuContainer
@onready var menu_buttons: VBoxContainer = $MainMenuContainer/MenuButtons
@onready var version_label: Label = $MainMenuContainer/VersionLabel
@onready var character_name_label: Label = $BackgroundStage/CharacterShowcase/CharacterNameLabel
@onready var character_sub_label: Label = $BackgroundStage/CharacterShowcase/CharacterSubLabel
@onready var logo_texture_rect: TextureRect = $MainMenuContainer/LogoRect
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# Data
var roster_data: Array[Dictionary] = []
var current_showcase_index: int = 0
var showcase_model: Node3D = null
var showcase_tween: Tween = null
var press_start_visible: bool = true
var menu_selected_index: int = 0
var menu_animation_phase: float = 0.0

# Menu options (DBFZ style)
var menu_options: Array[Dictionary] = [
	{ "id": "vs_mode", "text": "MODO VS", "icon": "⚔", "action": "_on_vs_mode" },
	{ "id": "training", "text": "ENTRENAMIENTO", "icon": "🥋", "action": "_on_training" },
	{ "id": "online", "text": "EN LÍNEA", "icon": "🌐", "action": "_on_online" },
	{ "id": "options", "text": "OPCIONES", "icon": "⚙", "action": "_on_options" },
	{ "id": "quit", "text": "SALIR", "icon": "✕", "action": "_on_quit" }
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
	_setup_input()
	_setup_sfx()
	
	# Start with press start screen
	_show_press_start_screen()
	
	# Set initial focus
	call_deferred("_grab_focus_safe")

func _grab_focus_safe() -> void:
	if press_start_overlay and press_start_overlay.visible:
		press_start_overlay.grab_focus()
	else:
		menu_buttons.grab_focus()

func _init_roster_data() -> void:
	roster_data = [
		{
			"id": "lego_batman",
			"name": "LEGO BATMAN",
			"sub": "EL CABALLERO OSCURO",
			"model_path": "res://characters/lego_batman/lego_batman.glb",
			"color": Color(0.95, 0.82, 0.15),
			"logo": "res://assets/logos/logo_batman.png"
		},
		{
			"id": "sakuya",
			"name": "SAKUYA IZAYOI",
			"sub": "SIRVIENTA DEL TIEMPO",
			"model_path": "res://characters/sakuya/sakuya.glb",
			"color": Color(0.45, 0.75, 1.0),
			"logo": "res://assets/logos/logo_sakuya.png"
		},
		{
			"id": "gogeta",
			"name": "GOGETA",
			"sub": "GUERRERO DE FUSIÓN",
			"model_path": "res://characters/gogeta/gogeta.glb",
			"color": Color(0.25, 0.65, 1.0),
			"logo": "res://assets/logos/logo_gogeta.png"
		},
		{
			"id": "miyabi",
			"name": "MIYABI HOSHIMI",
			"sub": "MAESTRA DE LA ESPADA",
			"model_path": "res://characters/miyabi/miyabi.glb",
			"color": Color(0.85, 0.2, 0.35),
			"logo": "res://assets/logos/logo_miyabi.png"
		},
		{
			"id": "sans",
			"name": "SANS",
			"sub": "JUEZ DEL INFRAMUNDO",
			"model_path": "res://characters/sans/sans.glb",
			"color": Color(0.55, 0.9, 0.4),
			"logo": "res://assets/logos/logo_sans.png"
		}
	]

func _setup_3d_background() -> void:
	if not background_stage:
		return
	
	# Clear existing
	for child in background_stage.get_children():
		if child != camera and child != world_env and child != character_showcase:
			child.queue_free()
	
	# Sky environment (matching Astral stage)
	if world_env and world_env.environment:
		var env = world_env.environment
		env.background_mode = Environment.BG_SKY
		var sky_mat = ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.14, 0.18, 0.38)
		sky_mat.sky_horizon_color = Color(0.88, 0.58, 0.65)
		sky_mat.sky_curve = 0.15
		sky_mat.ground_bottom_color = Color(0.08, 0.10, 0.18)
		sky_mat.ground_horizon_color = Color(0.88, 0.58, 0.65)
		sky_mat.ground_curve = 0.15
		sky_mat.sun_angle_max = 35.0
		sky_mat.use_debanding = true
		
		var new_sky = Sky.new()
		new_sky.sky_material = sky_mat
		env.sky = new_sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.75
	
	# Camera setup
	if camera:
		camera.position = Vector3(0, 2.5, 6.0)
		camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)
		camera.fov = 55.0
		camera.near = 0.1
		camera.far = 100.0
	
	# Add decorative elements (rings, pillars like character select)
	_add_background_decor()

func _add_background_decor() -> void:
	# Celestial ring (Astral stage style)
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 4.0
	torus.outer_radius = 4.8
	ring.mesh = torus
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(1.0, 0.85, 0.3)
	r_mat.metallic = 0.95
	r_mat.roughness = 0.15
	r_mat.emission_enabled = true
	r_mat.emission = Color(1.0, 0.8, 0.25)
	r_mat.emission_energy_multiplier = 1.5
	ring.material_override = r_mat
	ring.position = Vector3(0, 4.0, -5.0)
	ring.rotation.x = deg_to_rad(15.0)
	ring.name = "BgCelestialRing"
	background_stage.add_child(ring)
	
	# Side pillars
	for side in [-7.0, 7.0]:
		var pil = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.7
		cyl.height = 10.0
		pil.mesh = cyl
		var p_mat = StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.18, 0.22, 0.35)
		p_mat.metallic = 0.4
		pil.material_override = p_mat
		pil.position = Vector3(side, 2.5, -3.0)
		pil.name = "BgPillar"
		background_stage.add_child(pil)
	
	# Ground plane with subtle glow
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.1, 0.12, 0.2)
	g_mat.roughness = 0.7
	g_mat.metallic = 0.2
	ground.material_override = g_mat
	ground.position = Vector3(0, -0.1, 0)
	ground.rotation.x = deg_to_rad(-90)
	background_stage.add_child(ground)

func _setup_character_showcase() -> void:
	if not character_showcase:
		return
	
	# Clear existing
	for child in character_showcase.get_children():
		if child != character_name_label and child != character_sub_label:
			child.queue_free()
	
	# Setup labels
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
	if font_res and character_name_label:
		character_name_label.add_theme_font_override("font", font_res)
		character_name_label.add_theme_font_size_override("font_size", 28)
		character_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		character_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		character_name_label.add_theme_constant_override("outline_size", 4)
	
	if font_res and character_sub_label:
		character_sub_label.add_theme_font_override("font", font_res)
		character_sub_label.add_theme_font_size_override("font_size", 14)
		character_sub_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.9))
	
	# Load first character
	_load_showcase_character(0)

func _load_showcase_character(index: int) -> void:
	if index < 0 or index >= roster_data.size():
		return
	
	current_showcase_index = index
	var data = roster_data[index]
	
	# Clear previous model
	if showcase_model:
		showcase_model.queue_free()
		showcase_model = null
	
	# Update labels with animation
	if character_name_label:
		character_name_label.text = data["name"]
		character_name_label.modulate = data["color"]
	
	if character_sub_label:
		character_sub_label.text = data["sub"]
	
	# Instantiate model
	var model_scene = load(data["model_path"])
	if model_scene:
		var model = model_scene.instantiate()
		model.name = "ShowcaseModel"
		model.position = Vector3(0, 0.5, 0)
		model.scale = Vector3(1.2, 1.2, 1.2)
		
		# Standard hierarchy for animation
		var char_root = Node3D.new()
		char_root.name = "CharacterRoot"
		
		var humanoid = Node3D.new()
		humanoid.name = "Humanoid"
		char_root.add_child(humanoid)
		humanoid.add_child(model)
		
		character_showcase.add_child(char_root)
		showcase_model = char_root
		
		# Face camera slightly
		showcase_model.rotation.y = deg_to_rad(-15.0)
		
		# Play idle animation
		_play_showcase_idle(model)
	
	# Entrance animation
	if showcase_model:
		showcase_model.scale = Vector3(0.01, 0.01, 0.01)
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(showcase_model, "scale", Vector3(1.2, 1.2, 1.2), 0.6)

func _play_showcase_idle(model: Node3D) -> void:
	# Try internal AnimationPlayer first
	var ap: AnimationPlayer = _find_animation_player(model)
	if ap:
		# Try common idle names
		for anim in ["idle", "Idle", "wait", "Wait", "RIG - MiyabiAction-idle"]:
			if ap.has_animation(anim):
				ap.play(anim)
				return
	
	# Fallback: procedural breathing idle
	_apply_showcase_breathing(model)

func _apply_showcase_breathing(node: Node3D) -> void:
	var base_y = node.position.y
	var tw = create_tween().set_loops()
	tw.tween_property(node, "position:y", base_y + 0.03, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position:y", base_y, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Subtle rotation sway
	var tw2 = create_tween().set_loops()
	tw2.tween_property(node, "rotation:y", deg_to_rad(-12.0), 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw2.tween_property(node, "rotation:y", deg_to_rad(-18.0), 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _setup_press_start() -> void:
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
	
	if press_start_label and font_res:
		press_start_label.add_theme_font_override("font", font_res)
		press_start_label.add_theme_font_size_override("font_size", 24)
		press_start_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8, 1))
		press_start_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		press_start_label.add_theme_constant_override("outline_size", 3)
		press_start_label.text = "PRESIONA CUALQUIER BOTÓN"
		press_start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Pulsing animation handled in _process

func _setup_main_menu_hidden() -> void:
	if main_menu_container:
		main_menu_container.visible = false
		main_menu_container.modulate = Color(1, 1, 1, 0)
	
	# Setup menu buttons with custom styling
	_setup_menu_buttons()
	
	# Version label
	if version_label:
		var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
		if font_res:
			version_label.add_theme_font_override("font", font_res)
			version_label.add_theme_font_size_override("font_size", 12)
			version_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.6))
		version_label.text = "v1.0.0  |  SMASH EN CASA"
		version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Logo
	if logo_texture_rect:
		var logo_tex = load("res://assets/images/jojo_menacing.png") if ResourceLoader.exists("res://assets/images/jojo_menacing.png") else null
		if logo_tex:
			logo_texture_rect.texture = logo_tex
			logo_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _setup_menu_buttons() -> void:
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
	
	# Clear existing buttons
	for child in menu_buttons.get_children():
		child.queue_free()
	
	# Add some spacing at top
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 40)
	menu_buttons.add_child(spacer_top)
	
	for i in range(menu_options.size()):
		var opt = menu_options[i]
		var btn_container = HBoxContainer.new()
		btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_container.add_theme_constant_override("separation", 16)
		
		# Icon
		var icon_label = Label.new()
		icon_label.text = opt["icon"]
		if font_res:
			icon_label.add_theme_font_override("font", font_res)
		icon_label.add_theme_font_size_override("font_size", 28)
		icon_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		icon_label.custom_minimum_size = Vector2(40, 0)
		btn_container.add_child(icon_label)
		
		# Text
		var btn = Button.new()
		btn.text = opt["text"]
		btn.custom_minimum_size = Vector2(280, 56)
		btn.focus_mode = Control.FOCUS_ALL
		btn.theme_type_variation = "MenuButton"
		
		if font_res:
			btn.add_theme_font_override("font", font_res)
		btn.add_theme_font_size_override("font_size", 22)
		
		# Custom style for menu buttons
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.08, 0.1, 0.18, 0.85)
		style_normal.border_width_left = 2
		style_normal.border_width_top = 2
		style_normal.border_width_right = 2
		style_normal.border_width_bottom = 2
		style_normal.border_color = Color(0.3, 0.4, 0.6, 0.5)
		style_normal.corner_radius_top_left = 8
		style_normal.corner_radius_top_right = 8
		style_normal.corner_radius_bottom_left = 8
		style_normal.corner_radius_bottom_right = 8
		
		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color(0.15, 0.2, 0.35, 0.95)
		style_hover.border_color = Color(1, 0.85, 0.3, 0.9)
		style_hover.shadow_color = Color(1, 0.85, 0.3, 0.3)
		style_hover.shadow_size = 12
		
		var style_pressed = style_hover.duplicate()
		style_pressed.bg_color = Color(1, 0.85, 0.3, 0.25)
		style_pressed.border_color = Color(1, 0.9, 0.4, 1)
		
		var style_focus = style_hover.duplicate()
		style_focus.border_width_left = 3
		style_focus.border_width_top = 3
		style_focus.border_width_right = 3
		style_focus.border_width_bottom = 3
		style_focus.border_color = Color(1, 0.9, 0.4, 1)
		
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus", style_focus)
		
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		
		btn.mouse_entered.connect(func(idx=i): _on_menu_hover(idx))
		btn.pressed.connect(func(idx=i): _on_menu_select(idx))
		
		btn_container.add_child(btn)
		menu_buttons.add_child(btn_container)
		
		# Store reference for navigation
		opt["button"] = btn
	
	# Bottom spacer
	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size = Vector2(0, 20)
	menu_buttons.add_child(spacer_bot)

func _setup_input() -> void:
	pass

func _setup_sfx() -> void:
	pass

func _show_press_start_screen() -> void:
	press_start_visible = true
	if press_start_overlay:
		press_start_overlay.visible = true
		press_start_overlay.modulate = Color(1, 1, 1, 0)
		
		var tw = create_tween()
		tw.tween_property(press_start_overlay, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Start pulsing
		_press_start_timer = 0.0

func _hide_press_start_screen() -> void:
	press_start_visible = false
	if press_start_overlay:
		var tw = create_tween()
		tw.tween_property(press_start_overlay, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): press_start_overlay.visible = false)
	
	# Show main menu
	_show_main_menu()

func _show_main_menu() -> void:
	if main_menu_container:
		main_menu_container.visible = true
		main_menu_container.modulate = Color(1, 1, 1, 0)
		
		var tw = create_tween()
		tw.tween_property(main_menu_container, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(main_menu_container, "position:y", 0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).from_(30)
		
		# Animate buttons in sequence
		for i in range(menu_options.size()):
			var opt = menu_options[i]
			if opt.has("button") and opt["button"]:
				var btn = opt["button"]
				btn.modulate = Color(1, 1, 1, 0)
				btn.position = Vector2(0, 30)
				
				var btn_tw = create_tween()
				btn_tw.tween_interval(i * 0.06)
				btn_tw.tween_property(btn, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD)
				btn_tw.parallel().tween_property(btn, "position:y", 0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		menu_selected_index = 0
		_update_menu_selection()
		call_deferred("_grab_menu_focus")

func _update_menu_selection() -> void:
	for i in range(menu_options.size()):
		var opt = menu_options[i]
		if opt.has("button") and opt["button"]:
			var btn = opt["button"]
			if i == menu_selected_index:
				btn.grab_focus()
			else:
				btn.release_focus()

func _on_menu_hover(index: int) -> void:
	menu_selected_index = index
	_update_menu_selection()
	_play_sfx_move()

func _on_menu_select(index: int) -> void:
	_play_sfx_select()
	var opt = menu_options[index]
	if opt.has("action") and has_method(opt["action"]):
		call(opt["action"])

func _process(delta: float) -> void:
	# Background rotation
	_bg_rotation += delta * 0.08
	if background_stage:
		for child in background_stage.get_children():
			if "Ring" in child.name:
				child.rotation.z = _bg_rotation
	
	# Character showcase rotation & timer
	_showcase_timer += delta
	if showcase_model and not press_start_visible:
		# Slow idle rotation
		showcase_model.rotation.y = deg_to_rad(-15.0) + sin(_showcase_timer * 0.4) * 0.08
	
	# Auto-cycle showcase every 8 seconds (only on press start screen)
	if press_start_visible and _showcase_timer > 8.0:
		_showcase_timer = 0.0
		var next_idx = (current_showcase_index + 1) % roster_data.size()
		_transition_showcase_character(next_idx)
	
	# Press Start pulsing
	if press_start_visible and press_start_label:
		_press_start_timer += delta
		var alpha = 0.5 + 0.5 * sin(_press_start_timer * 3.5)
		press_start_label.modulate = Color(1, 0.95, 0.8, alpha)
	
	# Subtle background particles/sway for menu
	if not press_start_visible:
		menu_animation_phase += delta

func _transition_showcase_character(next_idx: int) -> void:
	if showcase_model:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(showcase_model, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
		tw.tween_callback(func(): _load_showcase_character(next_idx))
	
	_play_sfx_move()

func _unhandled_input(event: InputEvent) -> void:
	if press_start_visible:
		# Any button press dismisses press start screen
		if event is InputEventKey and event.pressed:
			_hide_press_start_screen()
			return
		if event is InputEventJoypadButton and event.pressed:
			_hide_press_start_screen()
			return
		if event is InputEventMouseButton and event.pressed:
			_hide_press_start_screen()
			return
		if event is InputEventScreenTouch and event.pressed:
			_hide_press_start_screen()
			return
	else:
		# Menu navigation
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_UP, KEY_W, KEY_GAMEPAD_DPAD_UP, KEY_GAMEPAD_LSTICK_UP:
					_navigate_menu(-1)
				KEY_DOWN, KEY_S, KEY_GAMEPAD_DPAD_DOWN, KEY_GAMEPAD_LSTICK_DOWN:
					_navigate_menu(1)
				KEY_ENTER, KEY_SPACE, KEY_GAMEPAD_A, KEY_GAMEPAD_START:
					_on_menu_select(menu_selected_index)
				KEY_ESCAPE, KEY_GAMEPAD_B:
					_on_quit()
		if event is InputEventJoypadButton and event.pressed:
			match event.button_index:
				JOY_DPAD_UP, JOY_LSTICK_UP:
					_navigate_menu(-1)
				JOY_DPAD_DOWN, JOY_LSTICK_DOWN:
					_navigate_menu(1)
				JOY_A, JOY_START:
					_on_menu_select(menu_selected_index)
				JOY_B:
					_on_quit()

func _navigate_menu(direction: int) -> void:
	var new_index = clampi(menu_selected_index + direction, 0, menu_options.size() - 1)
	if new_index != menu_selected_index:
		menu_selected_index = new_index
		_update_menu_selection()
		_play_sfx_move()

func _play_sfx_move() -> void:
	if sfx_player:
		# Generate procedural beep
		_play_procedural_sfx(880.0, 0.08, 0.3)

func _play_sfx_select() -> void:
	if sfx_player:
		_play_procedural_sfx(440.0, 0.15, 0.4)

func _play_procedural_sfx(freq: float, duration: float, volume: float) -> void:
	# Simple procedural tone via AudioStreamGenerator (Godot 4)
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100
	var length = int(gen.mix_rate * duration)
	var buffer = PackedVector2Array()
	buffer.resize(length)
	
	for i in range(length):
		var t = float(i) / gen.mix_rate
		var envelope = 1.0 - pow(t / duration, 2.0)
		var sample = sin(t * freq * TAU) * envelope * volume
		buffer[i] = Vector2(sample, sample)
	
	gen.buffer = buffer
	sfx_player.stream = gen
	sfx_player.play()

# ==============================================================================
# Menu Actions
# ==============================================================================

func _on_vs_mode() -> void:
	_transition_to_scene("res://ui/character_select.tscn")

func _on_training() -> void:
	# Quick jump to training - for now go to character select with a flag
	GameManager.training_mode = true
	_transition_to_scene("res://ui/character_select.tscn")

func _on_online() -> void:
	# Placeholder
	_show_notification("ONLINE - PRÓXIMAMENTE")

func _on_options() -> void:
	# Placeholder
	_show_notification("OPCIONES - PRÓXIMAMENTE")

func _on_quit() -> void:
	get_tree().quit()

func _transition_to_scene(target_path: String) -> void:
	# Fade out everything
	var tw = create_tween()
	tw.tween_property(press_start_overlay, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(main_menu_container, "modulate:a", 0.0, 0.25)
	if background_stage:
		tw.parallel().tween_property(background_stage, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): get_tree().change_scene_to_file(target_path))

func _show_notification(text: String) -> void:
	var notif = Label.new()
	notif.text = text
	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null
	if font_res:
		notif.add_theme_font_override("font", font_res)
	notif.add_theme_font_size_override("font_size", 24)
	notif.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	notif.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	notif.add_theme_constant_override("outline_size", 4)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notif.anchors_preset = Control.PRESET_CENTER
	notif.anchor_left = 0.5
	notif.anchor_top = 0.5
	notif.anchor_right = 0.5
	notif.anchor_bottom = 0.5
	notif.offset_left = -200
	notif.offset_top = -30
	notif.offset_right = 200
	notif.offset_bottom = 30
	notif.modulate = Color(1, 1, 1, 0)
	add_child(notif)
	
	var tw = create_tween()
	tw.tween_property(notif, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.5)
	tw.tween_property(notif, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): notif.queue_free())
