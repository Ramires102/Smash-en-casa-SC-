# ==============================================================================
# ControlsConfig (Ventana de Opciones y Configuración de Controles Estilo Yuzu)
# ==============================================================================
# Pantalla de configuración general accesible desde el Menú Principal y Pausa:
#   1. Pestañas para hasta 4 jugadores simultáneos (`Player 1` .. `Player 4`).
#   2. Asignación interactiva ("listening") de botones, ejes analógicos y teclas
#      con vista previa en vivo sobre un control de Xbox (`XboxControllerView`).
#   3. Gestión de perfiles de jugador (`Save`, `New`, `Delete`) sincronizados con
#      `InputManager` y la tabla de clasificación (`ProfileManager`).
#   4. Delega las pestañas de Audio y Créditos a `SettingsPanelsBuilder`.
# ==============================================================================
class_name ControlsConfig
extends Control

signal closed

const LISTEN_TIMEOUT_SEC: float = 5.0

#region Estado de Trabajo y Escucha de Entradas
## Copia temporal de las configuraciones de los 4 jugadores; solo se guarda al pulsar Apply u OK.
var _working_configs: Dictionary = {}
var _current_player: int = 1

var _listening_slot: String = ""
var _listen_timer: float = 0.0
var _initial_axis_values: Dictionary = {}

var _panels_builder := SettingsPanelsBuilder.new()
#endregion

#region Referencias de Nodos Generados
var _window_title_label: Label = null
var _sidebar_buttons: Dictionary = {}
var _controls_view: Control = null
var _audio_view: Control = null
var _credits_view: Control = null

var _player_tab_buttons: Dictionary = {}
var _connect_chk_box: ColorRect = null
var _connect_btn: Button = null
var _controller_type_opt: OptionButton = null
var _device_opt: OptionButton = null
var _profile_opt: OptionButton = null
var _binding_buttons: Dictionary = {}
var _lt_bar: ProgressBar = null
var _rt_bar: ProgressBar = null
var _range_spin: SpinBox = null
var _deadzone_label: Label = null
var _deadzone_slider: HSlider = null
var _vibration_chk: CheckBox = null
var _connected_leds: Dictionary = {}
var _xbox_view: XboxControllerView = null
var _status_toast_label: Label = null

var _new_profile_modal: Control = null
var _new_profile_input: LineEdit = null
var _vibration_modal: Control = null
var _vibration_slider: HSlider = null
var _vibration_val_label: Label = null
#endregion

#region Estilos del Tema Oscuro Estilo Yuzu
var _style_bind_normal: StyleBoxFlat
var _style_bind_hover: StyleBoxFlat
var _style_bind_listening: StyleBoxFlat
var _style_tab_active: StyleBoxFlat
var _style_tab_inactive: StyleBoxFlat
var _style_action_btn: StyleBoxFlat
var _style_action_btn_hover: StyleBoxFlat
var _style_sidebar_active: StyleBoxFlat
var _style_sidebar_inactive: StyleBoxFlat
var _style_sidebar_hover: StyleBoxFlat
#endregion

#region Ciclo de Vida
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_working_configs = InputManager.get_all_configs_copy()
	_init_styles()
	_build_yuzu_ui()
	_build_modals()
	_refresh_device_dropdown()
	_refresh_profile_dropdown()
	_select_player_tab(1)
	_select_section("controls")
	InputManager.controller_connection_changed.connect(_on_controller_connection_changed)

func _exit_tree() -> void:
	if InputManager.controller_connection_changed.is_connected(_on_controller_connection_changed):
		InputManager.controller_connection_changed.disconnect(_on_controller_connection_changed)

func _on_controller_connection_changed(_dev_id: int, _connected: bool) -> void:
	_refresh_device_dropdown()
	_refresh_ui_from_working_config()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	if _listening_slot != "":
		var prev_sec: int = int(ceil(_listen_timer))
		_listen_timer -= delta
		if _listen_timer <= 0.0:
			_stop_listening()
		elif int(ceil(_listen_timer)) != prev_sec:
			_refresh_ui_from_working_config()

	_update_live_controller_preview()
#endregion

#region Construcción de Estilos y Estructura Principal
func _init_styles() -> void:
	_style_bind_normal = UIThemeUtils.make_stylebox(Color(0.14, 0.15, 0.17, 1.0), Color(0.28, 0.30, 0.33, 1.0), 1, 3, 4.0, 2.0)
	_style_bind_hover = UIThemeUtils.make_stylebox(Color(0.18, 0.20, 0.23, 1.0), Color(0.24, 0.68, 0.91, 1.0), 1, 3, 4.0, 2.0)
	_style_bind_listening = UIThemeUtils.make_stylebox(Color(0.12, 0.26, 0.36, 1.0), Color(0.18, 0.92, 0.45, 1.0), 2, 3, 4.0, 2.0)

	_style_tab_active = UIThemeUtils.make_stylebox(Color(0.20, 0.21, 0.23, 1.0), Color(0.24, 0.68, 0.91, 1.0), 0, 0, 14.0, 4.0)
	_style_tab_active.border_color = Color(0.24, 0.68, 0.91, 1.0)
	_style_tab_active.border_width_top = 2
	_style_tab_active.border_width_left = 1
	_style_tab_active.border_width_right = 1

	_style_tab_inactive = UIThemeUtils.make_stylebox(Color(0.13, 0.14, 0.16, 1.0), Color(0.24, 0.26, 0.28, 1.0), 1, 0, 14.0, 4.0)
	_style_action_btn = UIThemeUtils.make_stylebox(Color(0.22, 0.24, 0.27, 1.0), Color(0.34, 0.36, 0.40, 1.0), 1, 3, 10.0, 4.0)
	_style_action_btn_hover = UIThemeUtils.make_stylebox(Color(0.26, 0.29, 0.33, 1.0), Color(0.24, 0.68, 0.91, 1.0), 1, 3, 10.0, 4.0)

	_style_sidebar_active = UIThemeUtils.make_stylebox(Color(0.26, 0.53, 0.74, 1.0))
	_style_sidebar_active.content_margin_left = 12
	_style_sidebar_active.content_margin_right = 8
	_style_sidebar_active.content_margin_top = 8
	_style_sidebar_active.content_margin_bottom = 8

	_style_sidebar_inactive = _style_sidebar_active.duplicate()
	_style_sidebar_inactive.bg_color = Color(0.08, 0.10, 0.13, 1.0)

	_style_sidebar_hover = _style_sidebar_active.duplicate()
	_style_sidebar_hover.bg_color = Color(0.16, 0.20, 0.26, 1.0)
	_style_sidebar_hover.border_color = Color(0.24, 0.68, 0.91, 0.6)
	_style_sidebar_hover.border_width_left = 2
	_style_sidebar_hover.content_margin_left = 10

func _build_yuzu_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.05, 0.07, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var win_margin := MarginContainer.new()
	win_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_margin.add_theme_constant_override("margin_left", 10)
	win_margin.add_theme_constant_override("margin_right", 10)
	win_margin.add_theme_constant_override("margin_top", 8)
	win_margin.add_theme_constant_override("margin_bottom", 8)
	add_child(win_margin)

	var win_panel := PanelContainer.new()
	var win_sb: StyleBoxFlat = UIThemeUtils.make_stylebox(Color(0.18, 0.19, 0.21, 1.0), Color(0.30, 0.32, 0.35, 1.0), 1, 5)
	win_sb.shadow_color = Color(0, 0, 0, 0.55)
	win_sb.shadow_size = 14
	win_panel.add_theme_stylebox_override("panel", win_sb)
	win_margin.add_child(win_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	win_panel.add_child(root_vbox)

	# 1. Barra de título superior.
	root_vbox.add_child(_build_title_bar())

	# 2. Cuerpo central: Barra lateral izquierda + Vistas intercambiables.
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 0)
	root_vbox.add_child(body_hbox)

	body_hbox.add_child(_build_sidebar())

	_controls_view = _build_controls_section_view()
	body_hbox.add_child(_controls_view)

	var btn_factory := Callable(self, "_create_yuzu_action_button")
	var status_cb := Callable(self, "_show_status")
	_audio_view = _panels_builder.build_audio_view(btn_factory, status_cb)
	body_hbox.add_child(_audio_view)

	_credits_view = _panels_builder.build_credits_view(btn_factory, status_cb)
	body_hbox.add_child(_credits_view)

	# 3. Barra inferior de diálogo (Toast de estado + OK / Apply / Cancel).
	root_vbox.add_child(_build_dialog_footer())

func _build_title_bar() -> PanelContainer:
	var title_bar := PanelContainer.new()
	var title_sb: StyleBoxFlat = UIThemeUtils.make_stylebox(Color(0.13, 0.14, 0.16, 1.0))
	title_sb.border_color = Color(0.24, 0.26, 0.29, 1.0)
	title_sb.border_width_bottom = 1
	title_sb.content_margin_left = 10
	title_sb.content_margin_right = 8
	title_sb.content_margin_top = 4
	title_sb.content_margin_bottom = 4
	title_bar.add_theme_stylebox_override("panel", title_sb)

	var title_hbox := HBoxContainer.new()
	title_bar.add_child(title_hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "[XBOX]"
	icon_lbl.add_theme_font_size_override("font_size", 11)
	icon_lbl.add_theme_color_override("font_color", Color(0.24, 0.85, 0.42))
	title_hbox.add_child(icon_lbl)

	_window_title_label = Label.new()
	_window_title_label.text = "CONFIGURACIÓN DE CONTROLES — XBOX CONTROLLER (4 JUGADORES)"
	_window_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_window_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_window_title_label.add_theme_font_size_override("font_size", 12)
	_window_title_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.90))
	title_hbox.add_child(_window_title_label)

	var close_x_btn := Button.new()
	close_x_btn.text = "X"
	close_x_btn.flat = true
	close_x_btn.focus_mode = Control.FOCUS_NONE
	close_x_btn.add_theme_font_size_override("font_size", 12)
	close_x_btn.pressed.connect(_on_cancel_pressed)
	title_hbox.add_child(close_x_btn)
	return title_bar

func _build_sidebar() -> PanelContainer:
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(96, 0)
	var side_sb: StyleBoxFlat = UIThemeUtils.make_stylebox(Color(0.08, 0.10, 0.13, 1.0))
	side_sb.border_color = Color(0.22, 0.24, 0.27, 1.0)
	side_sb.border_width_right = 1
	sidebar.add_theme_stylebox_override("panel", side_sb)

	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 2)
	sidebar.add_child(side_vbox)

	var nav_items: Array[Dictionary] = [
		{"id": "controls", "label": "  🎮  Controles"},
		{"id": "audio", "label": "  🔊  Sonido"},
		{"id": "credits", "label": "  📜  Créditos"}
	]
	for item in nav_items:
		var sec_btn := Button.new()
		sec_btn.text = item["label"]
		sec_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sec_btn.focus_mode = Control.FOCUS_NONE
		sec_btn.custom_minimum_size = Vector2(96, 36)
		sec_btn.add_theme_font_size_override("font_size", 12)
		sec_btn.pressed.connect(func(sid: String = item["id"]) -> void: _select_section(sid))
		side_vbox.add_child(sec_btn)
		_sidebar_buttons[item["id"]] = sec_btn

	return sidebar

func _build_dialog_footer() -> PanelContainer:
	var bottom_bar := PanelContainer.new()
	var bottom_sb: StyleBoxFlat = UIThemeUtils.make_stylebox(Color(0.13, 0.14, 0.16, 1.0), Color.TRANSPARENT, 0, 0, 12.0, 6.0)
	bottom_sb.border_color = Color(0.24, 0.26, 0.29, 1.0)
	bottom_sb.border_width_top = 1
	bottom_bar.add_theme_stylebox_override("panel", bottom_sb)

	var bottom_hbox := HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	_status_toast_label = Label.new()
	_status_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_toast_label.add_theme_font_size_override("font_size", 11)
	_status_toast_label.add_theme_color_override("font_color", Color(0.25, 0.92, 0.48))
	bottom_hbox.add_child(_status_toast_label)

	var dlg_hbox := HBoxContainer.new()
	dlg_hbox.alignment = BoxContainer.ALIGNMENT_END
	dlg_hbox.add_theme_constant_override("separation", 6)
	bottom_hbox.add_child(dlg_hbox)

	var ok_btn := _create_yuzu_action_button("✓  OK", Vector2(76, 26))
	ok_btn.pressed.connect(_on_ok_pressed)
	dlg_hbox.add_child(ok_btn)

	var apply_btn := _create_yuzu_action_button("✓  Apply", Vector2(78, 26))
	apply_btn.pressed.connect(_on_apply_pressed)
	dlg_hbox.add_child(apply_btn)

	var cancel_btn := _create_yuzu_action_button("X  Cancel", Vector2(82, 26))
	cancel_btn.pressed.connect(_on_cancel_pressed)
	dlg_hbox.add_child(cancel_btn)
	return bottom_bar
#endregion

#region Construcción de la Sección de Controles (4 Jugadores)
func _build_controls_section_view() -> MarginContainer:
	var right_margin := MarginContainer.new()
	right_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_theme_constant_override("margin_left", 8)
	right_margin.add_theme_constant_override("margin_right", 8)
	right_margin.add_theme_constant_override("margin_top", 6)
	right_margin.add_theme_constant_override("margin_bottom", 6)

	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 4)
	right_margin.add_child(right_vbox)

	# Pestañas Player 1..4
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 2)
	right_vbox.add_child(tabs_hbox)

	for p_id in range(1, InputManager.MAX_PLAYERS + 1):
		var tab_btn := Button.new()
		tab_btn.text = "Player %d" % p_id
		tab_btn.focus_mode = Control.FOCUS_NONE
		tab_btn.add_theme_font_size_override("font_size", 12)
		tab_btn.pressed.connect(func(pid: int = p_id) -> void: _select_player_tab(pid))
		tabs_hbox.add_child(tab_btn)
		_player_tab_buttons[p_id] = tab_btn

	var tab_spacer := Control.new()
	tab_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_hbox.add_child(tab_spacer)

	var tab_body := PanelContainer.new()
	tab_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_body.add_theme_stylebox_override(
		"panel", UIThemeUtils.make_stylebox(Color(0.20, 0.21, 0.23, 1.0), Color(0.28, 0.30, 0.33, 1.0), 1, 0, 8.0, 6.0)
	)
	right_vbox.add_child(tab_body)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_vbox.add_theme_constant_override("separation", 6)
	tab_body.add_child(inner_vbox)

	inner_vbox.add_child(_build_top_device_profile_row())

	var main_area := HBoxContainer.new()
	main_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_area.add_theme_constant_override("separation", 8)
	inner_vbox.add_child(main_area)

	main_area.add_child(_build_left_column())
	main_area.add_child(_build_center_column())
	main_area.add_child(_build_right_column())

	inner_vbox.add_child(_build_bottom_status_row())
	return right_margin

func _build_top_device_profile_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	# 1. Conectar Control + Tipo (Xbox / Teclado)
	var conn_vbox := VBoxContainer.new()
	conn_vbox.custom_minimum_size = Vector2(142, 0)
	conn_vbox.add_theme_constant_override("separation", 4)
	row.add_child(conn_vbox)

	var conn_hbox := HBoxContainer.new()
	conn_hbox.add_theme_constant_override("separation", 6)
	conn_vbox.add_child(conn_hbox)

	var led_frame := PanelContainer.new()
	led_frame.add_theme_stylebox_override(
		"panel", UIThemeUtils.make_stylebox(Color(0.12, 0.13, 0.15, 1.0), Color(0.32, 0.34, 0.38, 1.0), 1, 2, 2.0, 2.0)
	)
	conn_hbox.add_child(led_frame)

	_connect_chk_box = ColorRect.new()
	_connect_chk_box.custom_minimum_size = Vector2(12, 12)
	_connect_chk_box.color = Color(0.12, 0.95, 0.22, 1.0)
	led_frame.add_child(_connect_chk_box)

	_connect_btn = Button.new()
	_connect_btn.text = "Connect Controller"
	_connect_btn.flat = true
	_connect_btn.focus_mode = Control.FOCUS_NONE
	_connect_btn.add_theme_font_size_override("font_size", 11)
	_connect_btn.add_theme_color_override("font_color", Color(0.88, 0.90, 0.92))
	_connect_btn.pressed.connect(_on_toggle_connect_current_player)
	conn_hbox.add_child(_connect_btn)

	_controller_type_opt = OptionButton.new()
	_controller_type_opt.add_item("Xbox Controller", 0)
	_controller_type_opt.add_item("Teclado / Keyboard", 1)
	_controller_type_opt.custom_minimum_size = Vector2(140, 24)
	_controller_type_opt.focus_mode = Control.FOCUS_NONE
	_controller_type_opt.add_theme_font_size_override("font_size", 11)
	_controller_type_opt.item_selected.connect(_on_controller_type_selected)
	conn_vbox.add_child(_controller_type_opt)

	# 2. Dispositivo físico de entrada
	var dev_vbox := VBoxContainer.new()
	dev_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dev_vbox.add_theme_constant_override("separation", 4)
	row.add_child(dev_vbox)

	var dev_lbl := Label.new()
	dev_lbl.text = "Input Device"
	dev_lbl.add_theme_font_size_override("font_size", 11)
	dev_lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88))
	dev_vbox.add_child(dev_lbl)

	_device_opt = OptionButton.new()
	_device_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_device_opt.custom_minimum_size = Vector2(210, 24)
	_device_opt.focus_mode = Control.FOCUS_NONE
	_device_opt.add_theme_font_size_override("font_size", 11)
	_device_opt.item_selected.connect(_on_device_selected)
	dev_vbox.add_child(_device_opt)

	# 3. Perfil (Selector + Save + New + Delete)
	var prof_vbox := VBoxContainer.new()
	prof_vbox.add_theme_constant_override("separation", 4)
	row.add_child(prof_vbox)

	var prof_lbl := Label.new()
	prof_lbl.text = "Profile"
	prof_lbl.add_theme_font_size_override("font_size", 11)
	prof_lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88))
	prof_vbox.add_child(prof_lbl)

	var prof_hbox := HBoxContainer.new()
	prof_hbox.add_theme_constant_override("separation", 4)
	prof_vbox.add_child(prof_hbox)

	_profile_opt = OptionButton.new()
	_profile_opt.custom_minimum_size = Vector2(115, 24)
	_profile_opt.focus_mode = Control.FOCUS_NONE
	_profile_opt.add_theme_font_size_override("font_size", 11)
	_profile_opt.item_selected.connect(_on_profile_selected)
	prof_hbox.add_child(_profile_opt)

	var save_prof_btn := _create_yuzu_action_button("Save", Vector2(46, 24))
	save_prof_btn.pressed.connect(_on_profile_save_pressed)
	prof_hbox.add_child(save_prof_btn)

	var new_prof_btn := _create_yuzu_action_button("New", Vector2(44, 24))
	new_prof_btn.pressed.connect(_on_profile_new_pressed)
	prof_hbox.add_child(new_prof_btn)

	var del_prof_btn := _create_yuzu_action_button("Delete", Vector2(52, 24))
	del_prof_btn.pressed.connect(_on_profile_delete_pressed)
	prof_hbox.add_child(del_prof_btn)

	return row

func _build_left_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(168, 0)
	col.add_theme_constant_override("separation", 6)

	var ls_box: PanelContainer = SettingsPanelsBuilder.create_group_box("Left Stick")
	ls_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(ls_box)
	var ls_vbox: VBoxContainer = ls_box.get_meta("content")

	ls_vbox.add_child(_create_cross_pad_grid("stick_up", "stick_left", "stick_right", "stick_down"))

	var range_hbox := HBoxContainer.new()
	range_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	range_hbox.add_theme_constant_override("separation", 6)
	ls_vbox.add_child(range_hbox)

	var range_lbl := Label.new()
	range_lbl.text = "Range"
	range_lbl.add_theme_font_size_override("font_size", 10)
	range_lbl.add_theme_color_override("font_color", Color(0.80, 0.82, 0.86))
	range_hbox.add_child(range_lbl)

	_range_spin = SpinBox.new()
	_range_spin.min_value = 25.0
	_range_spin.max_value = 150.0
	_range_spin.step = 1.0
	_range_spin.value = 95.0
	_range_spin.suffix = "%"
	_range_spin.custom_minimum_size = Vector2(68, 22)
	_range_spin.value_changed.connect(_on_range_changed)
	range_hbox.add_child(_range_spin)

	_deadzone_label = Label.new()
	_deadzone_label.text = "Deadzone: 15%"
	_deadzone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deadzone_label.add_theme_font_size_override("font_size", 10)
	_deadzone_label.add_theme_color_override("font_color", Color(0.80, 0.82, 0.86))
	ls_vbox.add_child(_deadzone_label)

	_deadzone_slider = HSlider.new()
	_deadzone_slider.min_value = 0.0
	_deadzone_slider.max_value = 50.0
	_deadzone_slider.step = 1.0
	_deadzone_slider.value = 15.0
	_deadzone_slider.custom_minimum_size = Vector2(130, 14)
	var sl_fill: StyleBoxFlat = UIThemeUtils.make_stylebox(Color(0.24, 0.68, 0.91, 1.0), Color.TRANSPARENT, 0, 2, -1.0, 3.0)
	_deadzone_slider.add_theme_stylebox_override("grabber_area", sl_fill)
	_deadzone_slider.add_theme_stylebox_override("grabber_area_highlight", sl_fill)
	_deadzone_slider.value_changed.connect(_on_deadzone_changed)
	ls_vbox.add_child(_deadzone_slider)

	var dpad_box: PanelContainer = SettingsPanelsBuilder.create_group_box("D-Pad")
	col.add_child(dpad_box)
	var dpad_vbox: VBoxContainer = dpad_box.get_meta("content")
	dpad_vbox.add_child(_create_cross_pad_grid("dpad_up", "dpad_left", "dpad_right", "dpad_down"))

	return col

func _build_center_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)

	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 12)
	col.add_child(top_hbox)

	var left_trig_box: PanelContainer = SettingsPanelsBuilder.create_group_box("LB / LT (Escudo)")
	top_hbox.add_child(left_trig_box)
	var l_row := HBoxContainer.new()
	l_row.add_theme_constant_override("separation", 6)
	left_trig_box.get_meta("content").add_child(l_row)
	l_row.add_child(_create_labeled_bind_slot("LB", "btn_lb"))
	var lt_slot_vbox := _create_labeled_bind_slot("LT", "btn_lt")
	_lt_bar = SettingsPanelsBuilder.create_mini_trigger_bar()
	lt_slot_vbox.add_child(_lt_bar)
	l_row.add_child(lt_slot_vbox)

	var sys_box: PanelContainer = SettingsPanelsBuilder.create_group_box("Menu (Pausa)")
	sys_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_hbox.add_child(sys_box)
	sys_box.get_meta("content").add_child(_create_labeled_bind_slot("Start", "btn_start"))

	var right_trig_box: PanelContainer = SettingsPanelsBuilder.create_group_box("RB / RT (Escudo)")
	top_hbox.add_child(right_trig_box)
	var r_row := HBoxContainer.new()
	r_row.add_theme_constant_override("separation", 6)
	right_trig_box.get_meta("content").add_child(r_row)
	r_row.add_child(_create_labeled_bind_slot("RB", "btn_rb"))
	var rt_slot_vbox := _create_labeled_bind_slot("RT", "btn_rt")
	_rt_bar = SettingsPanelsBuilder.create_mini_trigger_bar()
	rt_slot_vbox.add_child(_rt_bar)
	r_row.add_child(rt_slot_vbox)

	_xbox_view = XboxControllerView.new()
	_xbox_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xbox_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_xbox_view)
	return col

func _build_right_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(174, 0)
	col.add_theme_constant_override("separation", 6)

	var fb_box: PanelContainer = SettingsPanelsBuilder.create_group_box("Face Buttons")
	col.add_child(fb_box)
	fb_box.get_meta("content").add_child(_create_xbox_face_diamond())

	col.add_child(SettingsPanelsBuilder.build_actions_help_box())
	return col

func _build_bottom_status_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)

	var vib_box: PanelContainer = SettingsPanelsBuilder.create_group_box("Vibration")
	row.add_child(vib_box)
	var vib_hbox := HBoxContainer.new()
	vib_hbox.add_theme_constant_override("separation", 6)
	vib_box.get_meta("content").add_child(vib_hbox)

	_vibration_chk = CheckBox.new()
	_vibration_chk.text = "Activar"
	_vibration_chk.focus_mode = Control.FOCUS_NONE
	_vibration_chk.add_theme_font_size_override("font_size", 10)
	_vibration_chk.toggled.connect(_on_vibration_toggled)
	vib_hbox.add_child(_vibration_chk)

	var vib_cfg_btn := _create_yuzu_action_button("Configure", Vector2(68, 22))
	vib_cfg_btn.pressed.connect(_on_vibration_configure_pressed)
	vib_hbox.add_child(vib_cfg_btn)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer_l)

	# Indicadores LED de los 4 controles permitidos.
	var conn_grid := GridContainer.new()
	conn_grid.columns = 5
	conn_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	conn_grid.add_theme_constant_override("h_separation", 6)
	conn_grid.add_theme_constant_override("v_separation", 2)
	row.add_child(conn_grid)

	var lbl_conn := Label.new()
	lbl_conn.text = "Connected"
	lbl_conn.add_theme_font_size_override("font_size", 10)
	lbl_conn.add_theme_color_override("font_color", Color(0.78, 0.80, 0.84))
	conn_grid.add_child(lbl_conn)

	for p_id in range(1, InputManager.MAX_PLAYERS + 1):
		var num_lbl := Label.new()
		num_lbl.text = str(p_id)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 10)
		num_lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88))
		conn_grid.add_child(num_lbl)

	var lbl_ctrls := Label.new()
	lbl_ctrls.text = "Controllers"
	lbl_ctrls.add_theme_font_size_override("font_size", 10)
	lbl_ctrls.add_theme_color_override("font_color", Color(0.78, 0.80, 0.84))
	conn_grid.add_child(lbl_ctrls)

	for p_id in range(1, InputManager.MAX_PLAYERS + 1):
		var led_btn := Button.new()
		led_btn.custom_minimum_size = Vector2(16, 16)
		led_btn.focus_mode = Control.FOCUS_NONE
		led_btn.tooltip_text = "Conectar / Desconectar Player %d" % p_id
		led_btn.pressed.connect(func(pid: int = p_id) -> void: _toggle_player_connected(pid))
		conn_grid.add_child(led_btn)
		_connected_leds[p_id] = led_btn

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer_r)

	var def_clear_hbox := HBoxContainer.new()
	def_clear_hbox.alignment = BoxContainer.ALIGNMENT_END
	def_clear_hbox.size_flags_vertical = Control.SIZE_SHRINK_END
	def_clear_hbox.add_theme_constant_override("separation", 6)
	row.add_child(def_clear_hbox)

	var defaults_btn := _create_yuzu_action_button("Defaults", Vector2(68, 26))
	defaults_btn.pressed.connect(_on_defaults_pressed)
	def_clear_hbox.add_child(defaults_btn)

	var clear_btn := _create_yuzu_action_button("Clear", Vector2(58, 26))
	clear_btn.pressed.connect(_on_clear_pressed)
	def_clear_hbox.add_child(clear_btn)

	return row

func _create_cross_pad_grid(up_slot: String, left_slot: String, right_slot: String, down_slot: String) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)

	var up_row := HBoxContainer.new()
	up_row.alignment = BoxContainer.ALIGNMENT_CENTER
	up_row.add_child(_create_labeled_bind_slot("Up", up_slot))
	vbox.add_child(up_row)

	var mid_row := HBoxContainer.new()
	mid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_row.add_theme_constant_override("separation", 6)
	mid_row.add_child(_create_labeled_bind_slot("Left", left_slot))
	mid_row.add_child(_create_labeled_bind_slot("Right", right_slot))
	vbox.add_child(mid_row)

	var down_row := HBoxContainer.new()
	down_row.alignment = BoxContainer.ALIGNMENT_CENTER
	down_row.add_child(_create_labeled_bind_slot("Down", down_slot))
	vbox.add_child(down_row)
	return vbox

func _create_xbox_face_diamond() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(_create_labeled_bind_slot("Y (Ataque)", "btn_y"))
	vbox.add_child(top_row)

	var mid_row := HBoxContainer.new()
	mid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_row.add_theme_constant_override("separation", 6)
	mid_row.add_child(_create_labeled_bind_slot("X (Ataque)", "btn_x"))
	mid_row.add_child(_create_labeled_bind_slot("B (Especial)", "btn_b"))
	vbox.add_child(mid_row)

	var bot_row := HBoxContainer.new()
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_row.add_child(_create_labeled_bind_slot("A (Saltar)", "btn_a"))
	vbox.add_child(bot_row)
	return vbox

func _create_labeled_bind_slot(label_text: String, slot_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.76, 0.78, 0.82))
	box.add_child(lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(70, 22)
	btn.text = "[not set]"
	btn.clip_text = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	btn.add_theme_stylebox_override("normal", _style_bind_normal)
	btn.add_theme_stylebox_override("hover", _style_bind_hover)
	btn.add_theme_stylebox_override("pressed", _style_bind_listening)

	btn.pressed.connect(func() -> void: _start_listening(slot_name))
	btn.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			_clear_single_slot(slot_name)
			get_viewport().set_input_as_handled()
	)
	btn.mouse_entered.connect(func() -> void:
		if _xbox_view:
			_xbox_view.highlighted_slot = slot_name
	)
	btn.mouse_exited.connect(func() -> void:
		if _xbox_view and _xbox_view.highlighted_slot == slot_name:
			_xbox_view.highlighted_slot = ""
	)

	box.add_child(btn)
	_binding_buttons[slot_name] = btn
	return box

func _create_yuzu_action_button(text_val: String, min_sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text_val
	btn.custom_minimum_size = min_sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95))
	btn.add_theme_stylebox_override("normal", _style_action_btn)
	btn.add_theme_stylebox_override("hover", _style_action_btn_hover)
	btn.add_theme_stylebox_override("pressed", _style_bind_listening)
	return btn

func _build_modals() -> void:
	# Modal 1: Crear nuevo perfil de jugador.
	_new_profile_modal = ColorRect.new()
	_new_profile_modal.color = Color(0, 0, 0, 0.65)
	_new_profile_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_new_profile_modal.visible = false
	add_child(_new_profile_modal)

	var np_center := CenterContainer.new()
	np_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_new_profile_modal.add_child(np_center)

	var np_panel: PanelContainer = SettingsPanelsBuilder.create_group_box("Nuevo Perfil de Control")
	np_panel.custom_minimum_size = Vector2(280, 110)
	np_center.add_child(np_panel)
	var np_vbox: VBoxContainer = np_panel.get_meta("content")

	_new_profile_input = LineEdit.new()
	_new_profile_input.placeholder_text = "Nombre del perfil (ej. Torneo Xbox)"
	np_vbox.add_child(_new_profile_input)

	var np_btns := HBoxContainer.new()
	np_btns.alignment = BoxContainer.ALIGNMENT_END
	np_btns.add_theme_constant_override("separation", 6)
	np_vbox.add_child(np_btns)

	var np_ok := _create_yuzu_action_button("Crear", Vector2(64, 24))
	np_ok.pressed.connect(_on_confirm_new_profile)
	np_btns.add_child(np_ok)

	var np_cancel := _create_yuzu_action_button("Cancelar", Vector2(70, 24))
	np_cancel.pressed.connect(func() -> void: _new_profile_modal.visible = false)
	np_btns.add_child(np_cancel)

	# Modal 2: Intensidad y prueba de vibración.
	_vibration_modal = ColorRect.new()
	_vibration_modal.color = Color(0, 0, 0, 0.65)
	_vibration_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vibration_modal.visible = false
	add_child(_vibration_modal)

	var vib_center := CenterContainer.new()
	vib_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vibration_modal.add_child(vib_center)

	var vib_panel: PanelContainer = SettingsPanelsBuilder.create_group_box("Configuración de Vibración — Player")
	vib_panel.custom_minimum_size = Vector2(290, 130)
	vib_center.add_child(vib_panel)
	var vib_vbox: VBoxContainer = vib_panel.get_meta("content")

	_vibration_val_label = Label.new()
	_vibration_val_label.text = "Intensidad: 100%"
	_vibration_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vibration_val_label.add_theme_font_size_override("font_size", 11)
	vib_vbox.add_child(_vibration_val_label)

	_vibration_slider = HSlider.new()
	_vibration_slider.min_value = 0.0
	_vibration_slider.max_value = 100.0
	_vibration_slider.step = 5.0
	_vibration_slider.value = 100.0
	_vibration_slider.value_changed.connect(func(v: float) -> void:
		_vibration_val_label.text = "Intensidad: %d%%" % int(round(v))
		_working_configs[_current_player]["vibration_strength"] = v / 100.0
	)
	vib_vbox.add_child(_vibration_slider)

	var vib_btns := HBoxContainer.new()
	vib_btns.alignment = BoxContainer.ALIGNMENT_END
	vib_btns.add_theme_constant_override("separation", 6)
	vib_vbox.add_child(vib_btns)

	var test_vib := _create_yuzu_action_button("Probar Vibración", Vector2(115, 24))
	test_vib.pressed.connect(func() -> void:
		var dev_id: int = _get_working_device_id(_current_player)
		if dev_id >= 0 and dev_id in Input.get_connected_joypads():
			var str_val: float = float(_working_configs[_current_player].get("vibration_strength", 1.0))
			Input.start_joy_vibration(dev_id, 0.6 * str_val, 0.9 * str_val, 0.25)
			_show_status("Vibrando Control %d..." % dev_id)
		else:
			_show_status("No hay mando físico conectado en ese puerto")
	)
	vib_btns.add_child(test_vib)

	var close_vib := _create_yuzu_action_button("Cerrar", Vector2(68, 24))
	close_vib.pressed.connect(func() -> void: _vibration_modal.visible = false)
	vib_btns.add_child(close_vib)
#endregion

#region Pestañas, Dispositivos, Perfiles y Vista Previa en Vivo
func _select_section(section_id: String) -> void:
	_stop_listening()
	if _controls_view: _controls_view.visible = (section_id == "controls")
	if _audio_view: _audio_view.visible = (section_id == "audio")
	if _credits_view: _credits_view.visible = (section_id == "credits")

	for s_id in _sidebar_buttons:
		var btn: Button = _sidebar_buttons[s_id]
		var is_active: bool = (s_id == section_id)
		btn.add_theme_stylebox_override("normal", _style_sidebar_active if is_active else _style_sidebar_inactive)
		btn.add_theme_stylebox_override("hover", _style_sidebar_active if is_active else _style_sidebar_hover)
		btn.add_theme_stylebox_override("pressed", _style_sidebar_active)
		btn.add_theme_color_override("font_color", Color.WHITE if is_active else Color(0.75, 0.78, 0.82))

	if _window_title_label:
		match section_id:
			"controls": _window_title_label.text = "CONFIGURACIÓN DE CONTROLES — XBOX CONTROLLER (4 JUGADORES)"
			"audio": _window_title_label.text = "AJUSTES DE AUDIO — VOLUMEN GENERAL, VOCES, MÚSICA Y SFX"
			"credits": _window_title_label.text = "CRÉDITOS Y AGRADECIMIENTOS — RECURSOS, MODELOS 3D Y MÚSICA"

func _select_player_tab(player_id: int) -> void:
	_stop_listening()
	_current_player = clampi(player_id, 1, InputManager.MAX_PLAYERS)
	for p_id in _player_tab_buttons.keys():
		var btn: Button = _player_tab_buttons[p_id]
		var active: bool = (p_id == _current_player)
		btn.add_theme_stylebox_override("normal", _style_tab_active if active else _style_tab_inactive)
		btn.add_theme_stylebox_override("hover", _style_tab_active if active else _style_tab_inactive)
		btn.add_theme_color_override("font_color", Color.WHITE if active else Color(0.68, 0.70, 0.74))
	_refresh_ui_from_working_config()

func _refresh_device_dropdown() -> void:
	if not _device_opt:
		return
	_device_opt.clear()
	var connected_pads: Array[int] = Input.get_connected_joypads()
	for i in range(InputManager.MAX_PLAYERS):
		var label: String = "Xbox Virtual / Gamepad %d" % i
		if i in connected_pads:
			var jname: String = Input.get_joy_name(i)
			label = ("%s %d" % [jname, i]) if jname != "" else ("Xbox Controller %d" % i)
		_device_opt.add_item(label, i)
		_device_opt.set_item_metadata(i, "joy_%d" % i)

	var kb_idx: int = _device_opt.item_count
	_device_opt.add_item("Keyboard Only (Teclado)", kb_idx)
	_device_opt.set_item_metadata(kb_idx, "keyboard")

func _refresh_profile_dropdown() -> void:
	if not _profile_opt:
		return
	_profile_opt.clear()
	var names: Array[String] = InputManager.get_profile_names()
	for i in range(names.size()):
		_profile_opt.add_item(names[i], i)
		_profile_opt.set_item_metadata(i, names[i])

func _refresh_ui_from_working_config() -> void:
	var cfg: Dictionary = _working_configs.get(_current_player, {})
	var is_conn: bool = bool(cfg.get("connected", _current_player <= 2))

	if _connect_chk_box:
		_connect_chk_box.color = Color(0.12, 0.95, 0.22, 1.0) if is_conn else Color(0.16, 0.17, 0.19, 1.0)

	for p_id in range(1, InputManager.MAX_PLAYERS + 1):
		if _connected_leds.has(p_id):
			var p_conn: bool = bool(_working_configs[p_id].get("connected", p_id <= 2))
			var led_btn: Button = _connected_leds[p_id]
			var sb: StyleBoxFlat = UIThemeUtils.make_stylebox(
				Color(0.12, 0.95, 0.22, 1.0) if p_conn else Color(0.15, 0.16, 0.18, 1.0),
				Color(0.95, 0.95, 0.95, 0.9) if p_id == _current_player else Color(0.32, 0.34, 0.38, 1.0),
				2 if p_id == _current_player else 1,
				2
			)
			led_btn.add_theme_stylebox_override("normal", sb)
			led_btn.add_theme_stylebox_override("hover", sb)
			led_btn.add_theme_stylebox_override("pressed", sb)

	var dev_str: String = str(cfg.get("device", "joy_%d" % (_current_player - 1)))
	if _device_opt:
		for i in range(_device_opt.item_count):
			if str(_device_opt.get_item_metadata(i)) == dev_str:
				_device_opt.select(i)
				break

	if _controller_type_opt:
		_controller_type_opt.select(1 if dev_str == "keyboard" else 0)

	var prof_str: String = str(cfg.get("profile", "Default"))
	if _profile_opt:
		for i in range(_profile_opt.item_count):
			if str(_profile_opt.get_item_metadata(i)) == prof_str:
				_profile_opt.select(i)
				break

	var bindings: Dictionary = cfg.get("bindings", {})
	for slot in _binding_buttons.keys():
		var btn: Button = _binding_buttons[slot]
		if _listening_slot == slot:
			btn.text = "[Wait %ds]" % int(ceil(_listen_timer))
			btn.add_theme_stylebox_override("normal", _style_bind_listening)
		else:
			btn.text = InputManager.format_binding(bindings.get(slot, {"type": "none"}))
			btn.add_theme_stylebox_override("normal", _style_bind_normal)

	var rng_pct: float = round(float(cfg.get("range", 0.95)) * 100.0)
	if _range_spin and not _range_spin.get_line_edit().has_focus():
		_range_spin.set_value_no_signal(rng_pct)

	var dz_pct: float = round(float(cfg.get("deadzone", 0.15)) * 100.0)
	if _deadzone_slider:
		_deadzone_slider.set_value_no_signal(dz_pct)
	if _deadzone_label:
		_deadzone_label.text = "Deadzone: %d%%" % int(dz_pct)

	if _vibration_chk:
		_vibration_chk.set_pressed_no_signal(bool(cfg.get("vibration", true)))

	if _xbox_view:
		_xbox_view.controller_connected = is_conn
		_xbox_view.deadzone = float(cfg.get("deadzone", 0.15))
		_xbox_view.listening_slot = _listening_slot

func _update_live_controller_preview() -> void:
	if not _xbox_view:
		return
	var cfg: Dictionary = _working_configs.get(_current_player, {})
	var bindings: Dictionary = cfg.get("bindings", {})
	var dev_id: int = _get_working_device_id(_current_player)

	for slot in InputManager.BINDING_SLOTS:
		var bdata: Dictionary = bindings.get(slot, {"type": "none"})
		_xbox_view.active_slots[slot] = InputManager.get_binding_strength_raw(bdata, dev_id)

	var raw_vec := Vector2(
		float(_xbox_view.active_slots.get("stick_right", 0.0)) - float(_xbox_view.active_slots.get("stick_left", 0.0)),
		float(_xbox_view.active_slots.get("stick_up", 0.0)) - float(_xbox_view.active_slots.get("stick_down", 0.0))
	)
	if raw_vec.length() > 1.0:
		raw_vec = raw_vec.normalized()
	_xbox_view.stick_vector = raw_vec

	if _lt_bar:
		_lt_bar.value = float(_xbox_view.active_slots.get("btn_lt", 0.0))
	if _rt_bar:
		_rt_bar.value = float(_xbox_view.active_slots.get("btn_rt", 0.0))
#endregion

#region Sistema de Escucha de Entradas (Remapeo en Tiempo Real)
func _start_listening(slot_name: String) -> void:
	_listening_slot = slot_name
	_listen_timer = LISTEN_TIMEOUT_SEC
	_initial_axis_values.clear()
	for dev in range(InputManager.MAX_PLAYERS):
		for ax in range(JOY_AXIS_MAX):
			_initial_axis_values["%d_%d" % [dev, ax]] = Input.get_joy_axis(dev, ax as JoyAxis)
	_refresh_ui_from_working_config()

func _stop_listening() -> void:
	if _listening_slot == "":
		return
	_listening_slot = ""
	_listen_timer = 0.0
	_refresh_ui_from_working_config()

func _clear_single_slot(slot_name: String) -> void:
	if _listening_slot == slot_name:
		_listening_slot = ""
	_working_configs[_current_player]["bindings"][slot_name] = {"type": "none"}
	_refresh_ui_from_working_config()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if (_new_profile_modal and _new_profile_modal.visible) or (_vibration_modal and _vibration_modal.visible):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_new_profile_modal.visible = false
			_vibration_modal.visible = false
			get_viewport().set_input_as_handled()
		return

	if _listening_slot != "":
		if event is InputEventKey and event.pressed and not event.is_echo():
			get_viewport().set_input_as_handled()
			if event.keycode == KEY_ESCAPE:
				_stop_listening()
			elif event.keycode in [KEY_BACKSPACE, KEY_DELETE]:
				_clear_single_slot(_listening_slot)
			else:
				var kc: int = event.keycode if event.keycode != 0 else event.physical_keycode
				_working_configs[_current_player]["keep_kb_fallback"] = false
				_assign_binding(_listening_slot, {"type": "key", "keycode": kc})
			return

		if event is InputEventJoypadButton and event.pressed and _accepts_joy_event(event.device):
			get_viewport().set_input_as_handled()
			_assign_binding(_listening_slot, {"type": "joy_button", "button": event.button_index})
			return

		if event is InputEventJoypadMotion and _accepts_joy_event(event.device):
			var key: String = "%d_%d" % [event.device, event.axis]
			var init_val: float = float(_initial_axis_values.get(key, 0.0))
			if absf(event.axis_value) >= 0.55 and absf(event.axis_value - init_val) >= 0.40:
				get_viewport().set_input_as_handled()
				var dir: float = 1.0 if event.axis_value >= 0.0 else -1.0
				_assign_binding(_listening_slot, {"type": "joy_axis", "axis": event.axis, "dir": dir})
			return
		return

	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()

func _accepts_joy_event(event_device: int) -> bool:
	var target_dev: int = _get_working_device_id(_current_player)
	if target_dev < 0:
		_working_configs[_current_player]["device"] = "joy_%d" % clampi(event_device, 0, 3)
		return true
	if event_device == target_dev:
		return true
	return not (target_dev in Input.get_connected_joypads())

func _assign_binding(slot_name: String, bind_data: Dictionary) -> void:
	_working_configs[_current_player]["bindings"][slot_name] = bind_data
	_listening_slot = ""
	_listen_timer = 0.0
	_refresh_ui_from_working_config()

func _get_working_device_id(player_id: int) -> int:
	var cfg: Dictionary = _working_configs.get(player_id, {})
	var dev_str: String = str(cfg.get("device", "joy_%d" % (player_id - 1)))
	if dev_str == "keyboard":
		return -1
	if dev_str.begins_with("joy_"):
		return int(dev_str.trim_prefix("joy_"))
	return clampi(player_id - 1, 0, 3)
#endregion

#region Callbacks de Perfiles, Ajustes y Diálogo
func _on_toggle_connect_current_player() -> void:
	_toggle_player_connected(_current_player)

func _toggle_player_connected(player_id: int) -> void:
	var next_state: bool = not bool(_working_configs[player_id].get("connected", player_id <= 2))
	_working_configs[player_id]["connected"] = next_state
	_refresh_ui_from_working_config()
	_show_status("Player %d %s" % [player_id, "Conectado" if next_state else "Desconectado"])

func _on_controller_type_selected(idx: int) -> void:
	if idx == 1:
		_working_configs[_current_player]["device"] = "keyboard"
		_working_configs[_current_player]["bindings"] = InputManager.get_default_keyboard_bindings(_current_player)
		_working_configs[_current_player]["keep_kb_fallback"] = false
		_show_status("Disposición de Teclado cargada (Player %d)" % _current_player)
	else:
		_working_configs[_current_player]["device"] = "joy_%d" % (_current_player - 1)
		_working_configs[_current_player]["bindings"] = InputManager.get_default_xbox_bindings()
		_working_configs[_current_player]["keep_kb_fallback"] = (_current_player <= 2)
		_show_status("Disposición Xbox cargada (Player %d)" % _current_player)
	_refresh_ui_from_working_config()

func _on_device_selected(idx: int) -> void:
	var meta: String = str(_device_opt.get_item_metadata(idx))
	var prev_dev: String = str(_working_configs[_current_player].get("device", ""))
	_working_configs[_current_player]["device"] = meta
	if meta == "keyboard" and prev_dev != "keyboard":
		_working_configs[_current_player]["bindings"] = InputManager.get_default_keyboard_bindings(_current_player)
		_working_configs[_current_player]["keep_kb_fallback"] = false
	elif meta.begins_with("joy_") and prev_dev == "keyboard":
		_working_configs[_current_player]["bindings"] = InputManager.get_default_xbox_bindings()
		_working_configs[_current_player]["keep_kb_fallback"] = (_current_player <= 2)
	_refresh_ui_from_working_config()

func _on_profile_selected(idx: int) -> void:
	var prof_name: String = str(_profile_opt.get_item_metadata(idx))
	var prof_data: Dictionary = InputManager.get_profile_data(prof_name)
	_working_configs[_current_player]["profile"] = prof_name
	_working_configs[_current_player]["deadzone"] = float(prof_data.get("deadzone", 0.15))
	_working_configs[_current_player]["range"] = float(prof_data.get("range", 0.95))
	_working_configs[_current_player]["vibration"] = bool(prof_data.get("vibration", true))
	if prof_data.has("bindings"):
		_working_configs[_current_player]["bindings"] = prof_data["bindings"].duplicate(true)
	if prof_name.begins_with("Teclado"):
		_working_configs[_current_player]["device"] = "keyboard"
		_working_configs[_current_player]["keep_kb_fallback"] = false
	_refresh_ui_from_working_config()
	_show_status("Perfil '%s' cargado en Player %d" % [prof_name, _current_player])

func _on_profile_save_pressed() -> void:
	var prof_name: String = str(_working_configs[_current_player].get("profile", "Default"))
	if InputManager.save_profile(prof_name, _working_configs[_current_player]):
		_show_status("Perfil '%s' guardado" % prof_name)

func _on_profile_new_pressed() -> void:
	_stop_listening()
	if _new_profile_modal and _new_profile_input:
		_new_profile_input.text = ""
		_new_profile_modal.visible = true
		_new_profile_input.grab_focus()

func _on_confirm_new_profile() -> void:
	var name_str: String = _new_profile_input.text.strip_edges()
	if name_str == "":
		return
	_working_configs[_current_player]["profile"] = name_str
	InputManager.save_profile(name_str, _working_configs[_current_player])
	_new_profile_modal.visible = false
	_refresh_profile_dropdown()
	_refresh_ui_from_working_config()
	_show_status("Perfil '%s' creado y guardado" % name_str)

func _on_profile_delete_pressed() -> void:
	var prof_name: String = str(_working_configs[_current_player].get("profile", "Default"))
	if InputManager.delete_profile(prof_name):
		_working_configs[_current_player]["profile"] = "Default"
		_refresh_profile_dropdown()
		_refresh_ui_from_working_config()
		_show_status("Perfil '%s' eliminado" % prof_name)
	else:
		_show_status("Los perfiles predeterminados no se pueden borrar")

func _on_range_changed(val: float) -> void:
	_working_configs[_current_player]["range"] = clampf(val / 100.0, 0.25, 1.50)

func _on_deadzone_changed(val: float) -> void:
	_working_configs[_current_player]["deadzone"] = clampf(val / 100.0, 0.0, 0.50)
	if _deadzone_label:
		_deadzone_label.text = "Deadzone: %d%%" % int(round(val))
	if _xbox_view:
		_xbox_view.deadzone = _working_configs[_current_player]["deadzone"]

func _on_vibration_toggled(pressed: bool) -> void:
	_working_configs[_current_player]["vibration"] = pressed

func _on_vibration_configure_pressed() -> void:
	_stop_listening()
	if _vibration_modal and _vibration_slider:
		var pct: float = round(float(_working_configs[_current_player].get("vibration_strength", 1.0)) * 100.0)
		_vibration_slider.set_value_no_signal(pct)
		_vibration_val_label.text = "Intensidad (Player %d): %d%%" % [_current_player, int(pct)]
		_vibration_modal.visible = true

func _on_defaults_pressed() -> void:
	_stop_listening()
	var dev_str: String = str(_working_configs[_current_player].get("device", "joy_%d" % (_current_player - 1)))
	var mode: String = "keyboard" if dev_str == "keyboard" else "gamepad"
	var def_cfg: Dictionary = InputManager.create_default_player_config(_current_player, mode)
	def_cfg["connected"] = _working_configs[_current_player].get("connected", true)
	def_cfg["device"] = dev_str
	_working_configs[_current_player] = def_cfg
	_refresh_ui_from_working_config()
	_show_status("Player %d restaurado a valores por defecto" % _current_player)

func _on_clear_pressed() -> void:
	_stop_listening()
	_working_configs[_current_player]["bindings"] = InputManager.get_empty_bindings()
	_working_configs[_current_player]["keep_kb_fallback"] = false
	_refresh_ui_from_working_config()
	_show_status("Controles de Player %d limpiados" % _current_player)

func _on_apply_pressed() -> void:
	_stop_listening()
	InputManager.set_all_configs(_working_configs, true)
	AudioManager.save_audio_settings()
	_show_status("✓ Configuración aplicada y guardada")

func _on_ok_pressed() -> void:
	_stop_listening()
	InputManager.set_all_configs(_working_configs, true)
	AudioManager.save_audio_settings()
	closed.emit()
	queue_free()

func _on_cancel_pressed() -> void:
	_stop_listening()
	AudioManager.load_audio_settings()
	closed.emit()
	queue_free()

func _show_status(msg: String) -> void:
	if not _status_toast_label:
		return
	_status_toast_label.text = msg
	_status_toast_label.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_status_toast_label, "modulate:a", 0.0, 0.4)
#endregion
