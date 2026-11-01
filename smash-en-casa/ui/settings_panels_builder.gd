# ==============================================================================
# SettingsPanelsBuilder (Constructor Modular de Paneles de Opciones)
# ==============================================================================
# Extrae de `ControlsConfig` la construcción y lógica interna de:
#   1. Componentes reutilizables estilo Yuzu (`GroupBox`, barras analógicas, guía).
#   2. Pestaña de Mezcla de Audio (4 canales en vivo conectados a `AudioManager`).
#   3. Pestaña de Créditos y Agradecimientos (lectura de `data/credits.md` en BBCode).
# ==============================================================================
class_name SettingsPanelsBuilder
extends RefCounted

#region Estado Interno de Audio y Créditos
var _audio_sliders: Dictionary = {}
var _audio_labels: Dictionary = {}
var _audio_mutes: Dictionary = {}
var _credits_rich_label: RichTextLabel = null
#endregion

#region Componentes Reutilizables Estilo Yuzu
## Crea un contenedor con borde y encabezado estilo Yuzu. Expone su VBox interno en `meta("content")`.
static func create_group_box(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb: StyleBoxFlat = UIThemeUtils.make_stylebox(
		Color(0.18, 0.19, 0.21, 0.65), Color(0.28, 0.30, 0.33, 1.0), 1, 3, 6.0, 5.0
	)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
	vbox.add_child(title_lbl)

	var content_vbox := VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(content_vbox)
	panel.set_meta("content", content_vbox)
	return panel

## Crea una mini barra de progreso analógica para los gatillos LT y RT.
static func create_mini_trigger_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(68, 5)
	bar.add_theme_stylebox_override(
		"background", UIThemeUtils.make_stylebox(Color(0.11, 0.12, 0.14, 1.0), Color.TRANSPARENT, 0, 2)
	)
	bar.add_theme_stylebox_override(
		"fill", UIThemeUtils.make_stylebox(Color(0.24, 0.68, 0.91, 1.0), Color.TRANSPARENT, 0, 2)
	)
	return bar

## Construye el cuadro informativo de ayuda rápida de controles del juego.
static func build_actions_help_box() -> PanelContainer:
	var help_box: PanelContainer = create_group_box("Acciones del Juego")
	help_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var help_vbox: VBoxContainer = help_box.get_meta("content")
	help_vbox.add_theme_constant_override("separation", 4)

	var actions_info: Array[Array] = [
		["A", "Saltar / Doble Salto", Color(0.25, 0.88, 0.42)],
		["X", "Ataque Normal / Smash", Color(0.28, 0.68, 0.98)],
		["B", "Ataque Especial", Color(0.95, 0.35, 0.32)],
		["Y", "Ataque / Salto Alt.", Color(0.96, 0.82, 0.22)],
		["LB/RB/LT/RT", "Escudo / Dodge", Color(0.75, 0.82, 0.90)],
		["Start", "Pausar Partida", Color(0.75, 0.82, 0.90)]
	]
	for item in actions_info:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var k_lbl := Label.new()
		k_lbl.text = str(item[0]) + ":"
		k_lbl.add_theme_font_size_override("font_size", 10)
		k_lbl.add_theme_color_override("font_color", item[2])
		row.add_child(k_lbl)

		var d_lbl := Label.new()
		d_lbl.text = str(item[1])
		d_lbl.add_theme_font_size_override("font_size", 10)
		d_lbl.add_theme_color_override("font_color", Color(0.78, 0.80, 0.84))
		row.add_child(d_lbl)
		help_vbox.add_child(row)

	help_vbox.add_child(HSeparator.new())

	var tip_lbl := Label.new()
	tip_lbl.text = "CLIC IZQ: ASIGNAR BOTÓN/TECLA\nCLIC DER: BORRAR ([NOT SET])\nESC: CANCELAR ASIGNACIÓN"
	tip_lbl.add_theme_font_size_override("font_size", 9)
	tip_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.72))
	help_vbox.add_child(tip_lbl)
	return help_box
#endregion

#region Construcción del Panel de Sonido (Audio Mixer)
func build_audio_view(action_btn_factory: Callable, status_callback: Callable) -> Control:
	var margin := _create_section_margin()
	var panel := _create_section_panel()
	margin.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "Mezcla de Canales de Audio"
	hdr_lbl.add_theme_font_size_override("font_size", 14)
	hdr_lbl.add_theme_color_override("font_color", Color(0.24, 0.68, 0.91))
	header_hbox.add_child(hdr_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	var reset_btn: Button = action_btn_factory.call("↺  Restablecer Predeterminados", Vector2(210, 26))
	reset_btn.pressed.connect(func() -> void: _on_audio_reset_defaults(status_callback))
	header_hbox.add_child(reset_btn)

	vbox.add_child(_create_audio_channel_row(
		"master",
		"🔊  Volumen General (Master)",
		"Control maestro que afecta todos los sonidos del juego globalmente.",
		AudioManager.get_master_volume(),
		func() -> void: AudioManager.play_test_sfx(),
		action_btn_factory
	))
	vbox.add_child(_create_audio_channel_row(
		"voices",
		"🗣️  Voces y Gritos de Personajes",
		"Volumen de exclamaciones y gritos de combate de los luchadores (ej. Hornet: 'Shaw!', 'Adeeno!').",
		AudioManager.get_voices_volume(),
		func() -> void: AudioManager.play_test_voice(),
		action_btn_factory
	))
	vbox.add_child(_create_audio_channel_row(
		"music",
		"🎵  Música y Sonido de Ambiente",
		"Banda sonora de escenarios de combate y pantallas de selección.",
		AudioManager.get_music_volume(),
		func() -> void: AudioManager.play_test_music(),
		action_btn_factory
	))
	vbox.add_child(_create_audio_channel_row(
		"sfx",
		"💥  Efectos de Combate (SFX)",
		"Impactos de golpes, tajos de seda, escudos, proyectiles y parries.",
		AudioManager.get_sfx_volume(),
		func() -> void: AudioManager.play_test_sfx(),
		action_btn_factory
	))

	vbox.add_child(HSeparator.new())

	var info_lbl := Label.new()
	info_lbl.text = "💡 Los ajustes en las barras de volumen tienen efecto inmediato. Pulsa 'Apply' u 'OK' para guardarlos de forma permanente."
	info_lbl.add_theme_font_size_override("font_size", 11)
	info_lbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.75))
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_lbl)

	return margin

func _create_audio_channel_row(
	channel_id: String,
	title: String,
	description: String,
	initial_val: float,
	test_callable: Callable,
	action_btn_factory: Callable
) -> Control:
	var group := PanelContainer.new()
	group.add_theme_stylebox_override(
		"panel", UIThemeUtils.make_stylebox(Color(0.14, 0.15, 0.18, 1.0), Color(0.25, 0.27, 0.30, 1.0), 1, 4, 12.0, 8.0)
	)

	var row_vbox := VBoxContainer.new()
	row_vbox.add_theme_constant_override("separation", 5)
	group.add_child(row_vbox)

	var top_h := HBoxContainer.new()
	row_vbox.add_child(top_h)

	var t_lbl := Label.new()
	t_lbl.text = title
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_lbl.add_theme_font_size_override("font_size", 12)
	t_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	top_h.add_child(t_lbl)

	var test_btn: Button = action_btn_factory.call("▶  Probar", Vector2(82, 22))
	test_btn.pressed.connect(test_callable)
	top_h.add_child(test_btn)

	var d_lbl := Label.new()
	d_lbl.text = description
	d_lbl.add_theme_font_size_override("font_size", 10)
	d_lbl.add_theme_color_override("font_color", Color(0.60, 0.64, 0.70))
	row_vbox.add_child(d_lbl)

	var ctrl_h := HBoxContainer.new()
	ctrl_h.add_theme_constant_override("separation", 10)
	row_vbox.add_child(ctrl_h)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = round(initial_val * 100.0)
	ctrl_h.add_child(slider)
	_audio_sliders[channel_id] = slider

	var pct_lbl := Label.new()
	pct_lbl.custom_minimum_size = Vector2(45, 0)
	pct_lbl.text = "%d%%" % int(slider.value)
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_lbl.add_theme_font_size_override("font_size", 11)
	pct_lbl.add_theme_color_override("font_color", Color(0.24, 0.68, 0.91))
	ctrl_h.add_child(pct_lbl)
	_audio_labels[channel_id] = pct_lbl

	var mute_chk := CheckBox.new()
	mute_chk.text = "Silenciar"
	mute_chk.focus_mode = Control.FOCUS_NONE
	mute_chk.button_pressed = (initial_val <= 0.001)
	mute_chk.add_theme_font_size_override("font_size", 11)
	ctrl_h.add_child(mute_chk)
	_audio_mutes[channel_id] = mute_chk

	slider.value_changed.connect(func(v: float) -> void: _on_audio_slider_changed(channel_id, v))
	mute_chk.toggled.connect(func(pressed: bool) -> void: _on_audio_mute_toggled(channel_id, pressed))
	return group

func _on_audio_slider_changed(channel_id: String, val: float) -> void:
	var linear_val: float = clampf(val / 100.0, 0.0, 1.0)
	if _audio_labels.has(channel_id):
		_audio_labels[channel_id].text = "%d%%" % int(val)
	if _audio_mutes.has(channel_id) and val > 0.0:
		_audio_mutes[channel_id].set_pressed_no_signal(false)
	_apply_audio_channel(channel_id, linear_val)

func _on_audio_mute_toggled(channel_id: String, pressed: bool) -> void:
	if pressed:
		_apply_audio_channel(channel_id, 0.0)
		if _audio_labels.has(channel_id):
			_audio_labels[channel_id].text = "0%"
	else:
		var last_val: float = 100.0
		if _audio_sliders.has(channel_id):
			last_val = maxf(_audio_sliders[channel_id].value, 20.0)
			_audio_sliders[channel_id].value = last_val
		_on_audio_slider_changed(channel_id, last_val)

func _apply_audio_channel(channel_id: String, linear_val: float) -> void:
	match channel_id:
		"master": AudioManager.set_master_volume(linear_val, false)
		"voices": AudioManager.set_voices_volume(linear_val, false)
		"music": AudioManager.set_music_volume(linear_val, false)
		"sfx": AudioManager.set_sfx_volume(linear_val, false)

func _on_audio_reset_defaults(status_callback: Callable) -> void:
	var defaults := {"master": 100.0, "voices": 90.0, "music": 80.0, "sfx": 85.0}
	for ch in defaults:
		if _audio_sliders.has(ch):
			_audio_sliders[ch].value = defaults[ch]
		if _audio_mutes.has(ch):
			_audio_mutes[ch].button_pressed = false
		_on_audio_slider_changed(ch, defaults[ch])
	if status_callback.is_valid():
		status_callback.call("Audio restablecido a valores predeterminados")
#endregion

#region Construcción del Panel de Créditos (Markdown)
func build_credits_view(action_btn_factory: Callable, status_callback: Callable) -> Control:
	var margin := _create_section_margin()
	var panel := _create_section_panel()
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var top_h := HBoxContainer.new()
	vbox.add_child(top_h)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(title_vbox)

	var h_lbl := Label.new()
	h_lbl.text = "Créditos, Modelos y Agradecimientos"
	h_lbl.add_theme_font_size_override("font_size", 14)
	h_lbl.add_theme_color_override("font_color", Color(0.24, 0.68, 0.91))
	title_vbox.add_child(h_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Archivo editable para desarrolladores: data/credits.md"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.63))
	title_vbox.add_child(sub_lbl)

	var reload_btn: Button = action_btn_factory.call("🔄  Recargar Archivo", Vector2(150, 26))
	reload_btn.pressed.connect(func() -> void: load_and_display_credits(status_callback))
	top_h.add_child(reload_btn)

	var text_panel := PanelContainer.new()
	text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_panel.add_theme_stylebox_override(
		"panel", UIThemeUtils.make_stylebox(Color(0.12, 0.13, 0.15, 1.0), Color(0.24, 0.26, 0.28, 1.0), 1, 3, 16.0, 14.0)
	)
	vbox.add_child(text_panel)

	_credits_rich_label = RichTextLabel.new()
	_credits_rich_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_credits_rich_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_credits_rich_label.bbcode_enabled = true
	_credits_rich_label.selection_enabled = false
	_credits_rich_label.scroll_following = false
	text_panel.add_child(_credits_rich_label)

	load_and_display_credits(Callable())
	return margin

func load_and_display_credits(status_callback: Callable) -> void:
	if not _credits_rich_label:
		return

	var content: String = ""
	for path in ["res://data/credits.md", "data/credits.md"]:
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				content = f.get_as_text()
				f.close()
				break

	if content == "":
		_credits_rich_label.text = "[color=#e06c75]No se pudo cargar el archivo data/credits.md[/color]"
		return

	_credits_rich_label.text = UIThemeUtils.markdown_to_bbcode(content)
	if status_callback.is_valid():
		status_callback.call("Créditos actualizados desde data/credits.md")

func _create_section_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	return margin

func _create_section_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel", UIThemeUtils.make_stylebox(Color(0.20, 0.21, 0.23, 1.0), Color(0.28, 0.30, 0.33, 1.0), 1, 4, 16.0, 12.0)
	)
	return panel
#endregion

