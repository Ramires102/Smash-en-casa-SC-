# ==============================================================================
# MainMenu (Menú Principal Arcade 3D)
# ==============================================================================
# Pantalla de bienvenida del juego inspirada en Dragon Ball FighterZ y Smash:
#   1. Escenario 3D animado de fondo con iluminación dramática y anillo de energía.
#   2. Carrusel 3D automático de luchadores reproduciendo sus poses de reposo.
#   3. Pantalla inicial tipo arcade ("PULSA CUALQUIER BOTÓN") con transición de cámara.
#   4. Navegación accesible con teclado, mando o ratón hacia Batalla VS,
#      Entrenamiento, Clasificación (Leaderboard) y Opciones (Controles/Audio/Créditos).
# ==============================================================================
class_name MainMenu
extends Node3D

const MENU_FONT: Font = preload("res://ui/Fondos de texto/kamikaze_condensed.tres")
const LEADERBOARD_SCENE: PackedScene = preload("res://ui/leaderboard.tscn")
const CONTROLS_CONFIG_SCENE: PackedScene = preload("res://ui/controls_config.tscn")

#region Referencias de Escena
@onready var background_stage: Node3D = $BackgroundStage
@onready var camera: Camera3D = $BackgroundStage/Camera3D
@onready var world_env: WorldEnvironment = $BackgroundStage/WorldEnvironment
@onready var character_showcase: Node3D = $BackgroundStage/CharacterShowcase
@onready var press_start_overlay: Control = $UILayer/PressStartOverlay
@onready var press_start_label: Label = $UILayer/PressStartOverlay/PressStartLabel
@onready var main_menu_container: Control = $UILayer/MainMenuContainer
@onready var menu_buttons: VBoxContainer = $UILayer/MainMenuContainer/MenuButtons
@onready var character_name_label: Label = $UILayer/CharacterNameLabel
@onready var character_sub_label: Label = $UILayer/CharacterSubLabel
@onready var logo_texture_rect: TextureRect = $UILayer/MainMenuContainer/LogoRect
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
#endregion

#region Datos del Carrusel y Opciones del Menú
var roster_data: Array[Dictionary] = []
var current_showcase_index: int = 0
var showcase_model: Node3D = null

var press_start_visible: bool = true
var menu_selected_index: int = 0
var _last_stick_dir: int = 0

var _press_start_timer: float = 0.0
var _showcase_timer: float = 0.0
var _bg_rotation: float = 0.0

var _controls_config_instance: Control = null
var _leaderboard_instance: Control = null
var _sfx_move: AudioStreamWAV = null
var _sfx_select: AudioStreamWAV = null

var menu_options: Array[Dictionary] = [
	{ "id": "vs_mode", "text": "BATALLA VS", "sub": "HASTA 4 JUGADORES  •  MULTIPLAYER", "icon": "⚔", "action": "_on_vs_mode" },
	{ "id": "training", "text": "ENTRENAMIENTO", "sub": "PRÁCTICA LIBRE Y COMBOS", "icon": "🥋", "action": "_on_training" },
	{ "id": "leaderboard", "text": "CLASIFICACIÓN", "sub": "TABLA DE LÍDERES Y VICTORIAS", "icon": "🏆", "action": "_on_leaderboard" },
	{ "id": "options", "text": "OPCIONES", "sub": "SONIDO, PANTALLA Y CONTROLES", "icon": "⚙", "action": "_on_options" },
	{ "id": "quit", "text": "SALIR AL ESCRITORIO", "sub": "CERRAR JUEGO", "icon": "✕", "action": "_on_quit" }
]
#endregion

#region Ciclo de Vida
func _ready() -> void:
	AudioManager.play_menu_theme()
	_sfx_move = UIThemeUtils.synth_tone(720.0, 0.06, 0.25)
	_sfx_select = UIThemeUtils.synth_tone(1050.0, 0.12, 0.40)

	_init_roster_data()
	_setup_3d_background()
	_setup_character_showcase()
	_setup_main_menu_hidden()
	_show_press_start_screen()

func _process(delta: float) -> void:
	_bg_rotation += delta * 0.12
	if background_stage:
		var ring: Node3D = background_stage.get_node_or_null("BgEnergyRing")
		if ring:
			ring.rotation.z = _bg_rotation

	_showcase_timer += delta
	if showcase_model:
		showcase_model.rotation.y = deg_to_rad(-25.0) + sin(_showcase_timer * 0.5) * 0.08

	# Rotar automáticamente de luchador cada 7 segundos en la pantalla inicial.
	if press_start_visible and _showcase_timer > 7.0:
		_showcase_timer = 0.0
		var next_idx: int = (current_showcase_index + 1) % roster_data.size()
		_load_showcase_character(next_idx)

	if press_start_visible and press_start_label:
		_press_start_timer += delta
		var alpha: float = 0.45 + 0.55 * absf(sin(_press_start_timer * 3.5))
		press_start_label.modulate = Color(1.0, 1.0, 1.0, alpha)
#endregion

#region Escenario 3D y Carrusel de Personajes
func _init_roster_data() -> void:
	roster_data = [
		{
			"id": "lego_batman",
			"name": "LEGO BATMAN",
			"sub": "EL CABALLERO DE LA NOCHE",
			"model_path": "res://characters/lego_batman/lego_batman.glb",
			"scale": 0.98,
			"offset": Vector3(0.0, -0.1008, 0.0),
			"anim_lib": "",
			"color": Color(0.95, 0.82, 0.15),
			"logo": "res://assets/logos/logo_batman.png"
		},
		{
			"id": "miyabi",
			"name": "MIYABI HOSHIMI",
			"sub": "MAESTRA DE LA HOJA HELADA",
			"model_path": "res://characters/miyabi/miyabi.glb",
			"scale": 0.88,
			"offset": Vector3(0.0, -0.1001, 0.08),
			"anim_lib": "",
			"color": Color(0.95, 0.25, 0.45),
			"logo": "res://assets/logos/logo_miyabi.png"
		},
		{
			"id": "gogeta",
			"name": "GOGETA SSJ",
			"sub": "GUERRERO DE LA FUSIÓN SUPREMA",
			"model_path": "res://characters/gogeta_ssj/gogeta_ssj.glb",
			"scale": 1.09,
			"offset": Vector3(0.0, -0.1206, 0.03),
			"anim_lib": "res://resources/instances/gogeta_ssj_anim_lib.tres",
			"color": Color(0.25, 0.65, 1.0),
			"logo": "res://assets/logos/logo_gogeta.png"
		},
		{
			"id": "sakuya",
			"name": "SAKUYA IZAYOI",
			"sub": "DONCELLA MANIPULADORA DEL TIEMPO",
			"model_path": "res://characters/sakuya/sakuya.glb",
			"scale": 0.097,
			"offset": Vector3(0.0, -0.1013, 0.0),
			"anim_lib": "res://resources/instances/sakuya_anim_lib.tres",
			"color": Color(0.45, 0.75, 1.0),
			"logo": "res://assets/logos/logo_sakuya.png"
		},
		{
			"id": "hornet",
			"name": "HORNET",
			"sub": "PROTECTORA DE HALLOWNEST",
			"model_path": "res://characters/hornet/hornet.glb",
			"scale": 0.95,
			"offset": Vector3(0.0, -0.10, 0.0),
			"anim_lib": "",
			"color": Color(0.9, 0.15, 0.22),
			"logo": "res://assets/logos/logo_hornet.png"
		},
		{
			"id": "sans",
			"name": "SANS",
			"sub": "EL JUEZ DEL SUBSUELO",
			"model_path": "res://characters/sans/sans.glb",
			"scale": 0.0000069,
			"offset": Vector3(0.0, 0.7184, 1.8),
			"anim_lib": "res://characters/sans/sans_anim_lib.tres",
			"color": Color(0.55, 0.9, 0.4),
			"logo": "res://assets/logos/logo_sans.png"
		}
	]

func _setup_3d_background() -> void:
	if not background_stage:
		return

	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.03, 0.04, 0.08)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.4, 0.45, 0.65)
		env.ambient_light_energy = 0.9
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.glow_enabled = true
		env.glow_intensity = 0.8
		env.glow_bloom = 0.15

	# Piso reflectante de arena de combate.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(25, 25)
	ground.mesh = plane
	var g_mat := StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.06, 0.07, 0.11)
	g_mat.roughness = 0.25
	g_mat.metallic = 0.75
	ground.material_override = g_mat
	background_stage.add_child(ground)

	# Anillo luminoso giratorio en el fondo.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.6
	torus.outer_radius = 4.2
	ring.mesh = torus
	var r_mat := StandardMaterial3D.new()
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

	# Columnas arquitectónicas laterales.
	for side_x in [-5.5, 7.0]:
		var pil := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.5
		cyl.height = 9.0
		pil.mesh = cyl
		var p_mat := StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.12, 0.16, 0.28)
		p_mat.metallic = 0.5
		pil.material_override = p_mat
		pil.position = Vector3(side_x, 3.5, -3.5)
		background_stage.add_child(pil)

func _setup_character_showcase() -> void:
	if not character_showcase:
		return
	for child in character_showcase.get_children():
		child.queue_free()
	_load_showcase_character(0)

func _load_showcase_character(index: int) -> void:
	if index < 0 or index >= roster_data.size():
		return

	current_showcase_index = index
	var data: Dictionary = roster_data[index]

	if showcase_model:
		showcase_model.queue_free()
		showcase_model = null

	if character_name_label:
		character_name_label.text = data["name"]
		character_name_label.modulate = data["color"]
	if character_sub_label:
		character_sub_label.text = data["sub"]
	if logo_texture_rect and ResourceLoader.exists(data.get("logo", "")):
		logo_texture_rect.texture = load(data["logo"])

	if not ResourceLoader.exists(data["model_path"]):
		return

	var model_scene: PackedScene = load(data["model_path"])
	if not model_scene:
		return

	var model: Node3D = model_scene.instantiate()
	model.name = "ShowcaseModel"

	var char_root := Node3D.new()
	char_root.name = "CharacterRoot"
	char_root.position = data.get("offset", Vector3(0.0, -0.10, 0.0))
	char_root.rotation.y = deg_to_rad(-25.0)

	var humanoid := Node3D.new()
	humanoid.name = "Humanoid"
	char_root.add_child(humanoid)

	var s: float = data.get("scale", 1.0)
	model.scale = Vector3(s, s, s)
	humanoid.add_child(model)

	character_showcase.add_child(char_root)
	showcase_model = char_root

	_play_showcase_idle(char_root, model, data)

	showcase_model.scale = Vector3(0.01, 0.01, 0.01)
	var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(showcase_model, "scale", Vector3.ONE, 0.45)

func _play_showcase_idle(char_root: Node3D, model: Node3D, data: Dictionary) -> void:
	var idle_candidates: Array[String] = ["idle", "Idle", "wait", "Wait", "RIG - MiyabiAction-idle"]

	var ap: AnimationPlayer = _find_animation_player(model)
	if ap:
		for anim in idle_candidates:
			if ap.has_animation(anim):
				ap.play(anim)
				return

	var anim_lib_path: String = data.get("anim_lib", "")
	if anim_lib_path != "" and ResourceLoader.exists(anim_lib_path):
		var lib: AnimationLibrary = load(anim_lib_path)
		if lib:
			var new_ap := AnimationPlayer.new()
			new_ap.name = "ShowcaseAnimPlayer"
			new_ap.root_node = NodePath("..")
			new_ap.add_animation_library("", lib)
			char_root.add_child(new_ap)
			for anim in idle_candidates:
				if new_ap.has_animation(anim):
					new_ap.play(anim)
					return

	# Si el modelo no incluye pista de reposo, aplica un pulso suave de respiración.
	var base_scale: Vector3 = model.scale
	var tw: Tween = create_tween().set_loops()
	tw.tween_property(model, "scale", base_scale * Vector3(1.015, 1.02, 1.015), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(model, "scale", base_scale, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found:
			return found
	return null
#endregion

#region Construcción y Transiciones de la UI del Menú
func _setup_main_menu_hidden() -> void:
	if main_menu_container:
		main_menu_container.visible = false
		main_menu_container.modulate = Color(1, 1, 1, 0)
	_setup_menu_buttons()

func _setup_menu_buttons() -> void:
	for child in menu_buttons.get_children():
		child.queue_free()

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.08, 0.10, 0.16, 0.92)
	style_normal.border_width_left = 6
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.25, 0.35, 0.55, 0.6)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_bottom_right = 8
	style_normal.content_margin_left = 16

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.16, 0.24, 0.42, 0.98)
	style_hover.border_width_left = 8
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color(1.0, 0.85, 0.25, 1.0)
	style_hover.shadow_color = Color(1.0, 0.85, 0.25, 0.35)
	style_hover.shadow_size = 10
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_bottom_right = 8
	style_hover.content_margin_left = 22

	var style_pressed: StyleBoxFlat = style_hover.duplicate()
	style_pressed.bg_color = Color(1.0, 0.85, 0.25, 0.35)

	for i in range(menu_options.size()):
		var opt: Dictionary = menu_options[i]
		var btn := Button.new()
		btn.text = "  %s  %s" % [opt["icon"], opt["text"]]
		btn.custom_minimum_size = Vector2(330, 52)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_ALL

		if MENU_FONT:
			btn.add_theme_font_override("font", MENU_FONT)
		btn.add_theme_font_size_override("font_size", 22)

		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus", style_hover)

		btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.35, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(1.0, 0.92, 0.35, 1.0))
		btn.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_theme_constant_override("outline_size", 3)

		btn.mouse_entered.connect(func(idx: int = i) -> void: _on_menu_hover(idx))
		btn.pressed.connect(func(idx: int = i) -> void: _on_menu_select(idx))

		menu_buttons.add_child(btn)
		opt["button"] = btn

func _show_press_start_screen() -> void:
	press_start_visible = true
	_press_start_timer = 0.0
	if press_start_overlay:
		press_start_overlay.visible = true
		press_start_overlay.modulate = Color.WHITE

func _hide_press_start_screen() -> void:
	press_start_visible = false
	_play_sfx(_sfx_select)

	if press_start_overlay:
		var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(press_start_overlay, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func() -> void: press_start_overlay.visible = false)

	_show_main_menu()

func _show_main_menu() -> void:
	if not main_menu_container:
		return

	main_menu_container.visible = true
	main_menu_container.modulate = Color(1, 1, 1, 0)

	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(main_menu_container, "modulate:a", 1.0, 0.3)

	if camera:
		var cam_tw: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		cam_tw.tween_property(camera, "position", Vector3(0.5, 1.8, 4.8), 0.6)

	menu_selected_index = 0
	_update_menu_selection()

func _update_menu_selection() -> void:
	for i in range(menu_options.size()):
		var opt: Dictionary = menu_options[i]
		var btn: Button = opt.get("button", null)
		if is_instance_valid(btn) and i == menu_selected_index:
			btn.grab_focus()
#endregion

#region Navegación por Teclado, Mando y Ratón
func _on_menu_hover(index: int) -> void:
	if menu_selected_index != index:
		menu_selected_index = index
		_update_menu_selection()
		_play_sfx(_sfx_move)

func _on_menu_select(index: int) -> void:
	_play_sfx(_sfx_select)
	var opt: Dictionary = menu_options[index]
	if opt.has("action") and has_method(opt["action"]):
		call(opt["action"])

func _navigate_menu(direction: int) -> void:
	var new_index: int = clampi(menu_selected_index + direction, 0, menu_options.size() - 1)
	if new_index != menu_selected_index:
		menu_selected_index = new_index
		_update_menu_selection()
		_play_sfx(_sfx_move)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_controls_config_instance) or is_instance_valid(_leaderboard_instance):
		return

	if press_start_visible:
		if (event is InputEventKey and event.pressed) \
			or (event is InputEventJoypadButton and event.pressed) \
			or (event is InputEventMouseButton and event.pressed):
			_hide_press_start_screen()
		return

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

	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		if event.axis_value > 0.5 and _last_stick_dir != 1:
			_last_stick_dir = 1
			_navigate_menu(1)
		elif event.axis_value < -0.5 and _last_stick_dir != -1:
			_last_stick_dir = -1
			_navigate_menu(-1)
		elif absf(event.axis_value) < 0.25:
			_last_stick_dir = 0

	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_navigate_menu(-1)
			JOY_BUTTON_DPAD_DOWN:
				_navigate_menu(1)
			JOY_BUTTON_A, JOY_BUTTON_START:
				_on_menu_select(menu_selected_index)
			JOY_BUTTON_B:
				_on_quit()

func _play_sfx(stream: AudioStreamWAV) -> void:
	if is_inside_tree() and sfx_player and stream:
		sfx_player.stream = stream
		sfx_player.play()
#endregion

#region Acciones de las Opciones del Menú
func _on_vs_mode() -> void:
	GameManager.training_mode = false
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_training() -> void:
	GameManager.training_mode = true
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_leaderboard() -> void:
	if is_instance_valid(_leaderboard_instance):
		return
	_leaderboard_instance = LEADERBOARD_SCENE.instantiate()
	_leaderboard_instance.closed.connect(func() -> void:
		_leaderboard_instance = null
		_update_menu_selection()
	)
	$UILayer.add_child(_leaderboard_instance)

func _on_options() -> void:
	if is_instance_valid(_controls_config_instance):
		return
	_controls_config_instance = CONTROLS_CONFIG_SCENE.instantiate()
	_controls_config_instance.closed.connect(func() -> void:
		_controls_config_instance = null
		_update_menu_selection()
	)
	$UILayer.add_child(_controls_config_instance)

func _on_quit() -> void:
	get_tree().quit()
#endregion
