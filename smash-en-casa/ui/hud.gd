# ==============================================================================
# HUD (Interfaz de Combate en Tiempo Real — 2 a 4 Jugadores)
# ==============================================================================
# Muestra en pantalla el estado del combate sin acoplarse a la física 2D:
#   1. Paneles dinámicos para P1..P4 (porcentaje de daño, vidas y perfil activo).
#   2. Medidores especiales exclusivos por personaje:
#        - Sakuya Izayoi: Barra porcentual para el Time Stop ("El Mundo").
#        - Hornet: 5 carretes de seda (`TextureProgressBar`) que se llenan por tercios.
#   3. Reloj central de la partida y cuenta regresiva inicial ("3, 2, 1, ¡SMASH!").
#   4. Atajo rápido manteniendo `[R]` para volver a la selección de personajes.
#   5. Guía discreta de controles en pantalla (Teclado J1 a la izquierda y Joystick a la derecha).
# ==============================================================================
class_name HUD
extends Control

signal countdown_finished

const SILK_SPOOL_PROGRESS: Texture2D = preload("res://assets/images/silk_spool_progress.png")
const SILK_SPOOL_SILHOUETTE: Texture2D = preload("res://assets/images/silk_spool_silhouette.png")
const HOLD_R_DURATION: float = 1.6

#region Referencias de Escena y Estado Interno
## Diccionario ID_Jugador (1..4) -> Diccionario con referencias a Labels y barras de su tarjeta.
var player_hud_data: Dictionary = {}

@onready var timer_label: Label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/TimerPanel/TimerBox/TimerLabel")
@onready var countdown_container: CenterContainer = get_node_or_null("CountdownContainer")
@onready var countdown_label: Label = get_node_or_null("CountdownContainer/CountdownLabel")
@onready var top_row: HBoxContainer = get_node_or_null("MarginContainer/VBoxContainer/TopRow")

var _hold_r_timer: float = 0.0
var _hold_r_container: PanelContainer = null
var _hold_r_bar: ProgressBar = null
var _hold_r_percent_lbl: Label = null
var _hold_r_fill_sb: StyleBoxFlat = null
var _controls_hints_row: HBoxContainer = null
#endregion

#region Ciclo de Vida
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.special_meter_changed.connect(_on_special_meter_changed)
	Events.player_ko_event.connect(_on_player_ko_event)

	if countdown_container:
		countdown_container.visible = false

	_init_player_panels()
	_setup_character_visuals()
	_build_controls_hints_ui()
	_build_hold_r_ui()

func _exit_tree() -> void:
	if Events.special_meter_changed.is_connected(_on_special_meter_changed):
		Events.special_meter_changed.disconnect(_on_special_meter_changed)
	if Events.player_ko_event.is_connected(_on_player_ko_event):
		Events.player_ko_event.disconnect(_on_player_ko_event)

func _process(delta: float) -> void:
	_handle_hold_r_exit(delta)
#endregion

#region Inicialización de Tarjetas por Jugador (1 a 4)
func _init_player_panels() -> void:
	player_hud_data.clear()
	var active_pids: Array[int] = GameManager.active_player_ids

	var p1_panel: Control = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel")
	if p1_panel:
		p1_panel.visible = active_pids.has(1)
		player_hud_data[1] = _extract_panel_nodes(p1_panel)

	var p2_panel: Control = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel")
	if p2_panel:
		p2_panel.visible = active_pids.has(2)
		player_hud_data[2] = _extract_panel_nodes(p2_panel)

	# Si participan P3 o P4, clonamos las tarjetas base manteniendo el reloj en el centro.
	if active_pids.has(3) and top_row and p1_panel:
		var p3_panel: Control = p1_panel.duplicate()
		p3_panel.name = "P3Panel"
		p3_panel.visible = true
		top_row.add_child(p3_panel)
		var timer_node: Node = top_row.get_node_or_null("TimerPanel")
		if timer_node:
			top_row.move_child(p3_panel, timer_node.get_index())
		player_hud_data[3] = _extract_panel_nodes(p3_panel)

	if active_pids.has(4) and top_row and p2_panel:
		var p4_panel: Control = p2_panel.duplicate()
		p4_panel.name = "P4Panel"
		p4_panel.visible = true
		top_row.add_child(p4_panel)
		player_hud_data[4] = _extract_panel_nodes(p4_panel)

func _extract_panel_nodes(panel: Node) -> Dictionary:
	var dict := {
		"panel": panel,
		"percent": null,
		"lives": null,
		"name": null,
		"logo": null,
		"special_bar": null,
		"special_label": null,
		"silk_spools": null,
		"silk_container": null
	}
	_find_hud_children(panel, dict)
	return dict

func _find_hud_children(node: Node, dict: Dictionary) -> void:
	if node is Label:
		match node.name:
			"PercentLabel": dict["percent"] = node
			"LivesLabel": dict["lives"] = node
			"NameLabel": dict["name"] = node
			"SpecialLabel": dict["special_label"] = node
	elif node is TextureRect and "Logo" in node.name:
		dict["logo"] = node
	elif node is ProgressBar and node.name == "SpecialBar":
		dict["special_bar"] = node

	for child in node.get_children():
		_find_hud_children(child, dict)

func _setup_character_visuals() -> void:
	for pid in player_hud_data.keys():
		var data: CharacterData = GameManager.get_player_data(pid)
		var hdata: Dictionary = player_hud_data[pid]
		var is_sakuya: bool = _player_name_contains(pid, "sakuya")
		var is_hornet: bool = _player_name_contains(pid, "hornet")

		if is_hornet:
			if hdata.get("special_bar"):
				hdata["special_bar"].visible = false
			_ensure_hornet_silk_ui(hdata)
			update_special_meter(pid, 5.0, 5.0)
		elif is_sakuya:
			if hdata.get("silk_container"):
				hdata["silk_container"].visible = false
			if hdata.get("special_bar"):
				hdata["special_bar"].visible = true
			update_special_meter(pid, 0.0, 100.0)
		else:
			if hdata.get("special_bar"): hdata["special_bar"].visible = false
			if hdata.get("special_label"): hdata["special_label"].visible = false
			if hdata.get("silk_container"): hdata["silk_container"].visible = false

		if data:
			if hdata["name"]:
				var prof: String = GameManager.get_player_profile(pid)
				if prof != "" and prof != "Default":
					hdata["name"].text = "%s (%s)" % [data.character_name.to_upper(), prof]
				else:
					hdata["name"].text = "P%d: %s" % [pid, data.character_name.to_upper()]
			if hdata["logo"] and data.logo_texture:
				hdata["logo"].texture = data.logo_texture

func _player_name_contains(player_id: int, token: String) -> bool:
	var data: CharacterData = GameManager.get_player_data(player_id)
	return data != null and data.character_name.to_lower().contains(token)
#endregion

#region Medidores Especiales (Sakuya y Hornet)
func _ensure_hornet_silk_ui(hdata: Dictionary) -> void:
	if hdata.get("silk_spools") != null:
		if hdata.get("silk_container") != null:
			hdata["silk_container"].visible = true
		return

	var spools: Array[TextureProgressBar] = []
	var silk_box := HBoxContainer.new()
	silk_box.name = "SilkSpoolsContainer"
	silk_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	silk_box.add_theme_constant_override("separation", 6)

	for i in range(5):
		var tpb := TextureProgressBar.new()
		tpb.name = "SilkSpool_%d" % i
		tpb.texture_under = SILK_SPOOL_SILHOUETTE
		tpb.texture_progress = SILK_SPOOL_PROGRESS
		tpb.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
		tpb.min_value = 0.0
		tpb.max_value = 1.0
		tpb.step = 0.005
		tpb.value = 1.0
		tpb.custom_minimum_size = Vector2(26, 36)
		tpb.nine_patch_stretch = true
		silk_box.add_child(tpb)
		spools.append(tpb)

	var parent_box: Node = hdata["special_bar"].get_parent() if hdata.get("special_bar") else hdata.get("panel")
	if parent_box:
		parent_box.add_child(silk_box)
		if hdata.get("special_bar"):
			parent_box.move_child(silk_box, hdata["special_bar"].get_index())

	hdata["silk_spools"] = spools
	hdata["silk_container"] = silk_box

func _on_special_meter_changed(player_id: int, current_charge: float, max_charge: float) -> void:
	update_special_meter(player_id, current_charge, max_charge)

func update_special_meter(player_id: int, current_charge: float, max_charge: float = 100.0) -> void:
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	if hdata.is_empty():
		return

	var is_sakuya: bool = _player_name_contains(player_id, "sakuya")
	var is_hornet: bool = _player_name_contains(player_id, "hornet")

	if not is_sakuya and not is_hornet:
		if hdata.get("special_bar"): hdata["special_bar"].visible = false
		if hdata.get("special_label"): hdata["special_label"].visible = false
		if hdata.get("silk_container"): hdata["silk_container"].visible = false
		return

	var label_text: String = ""
	var bar_color: Color = Color.WHITE

	if is_sakuya:
		var pct: int = int(round((current_charge / maxf(1.0, max_charge)) * 100.0))
		var is_ready: bool = pct >= 100
		label_text = "¡ESPECIAL LISTO!" if is_ready else ("ESPECIAL ↓: %d%%" % pct)
		bar_color = Color(1.0, 0.88, 0.25) if is_ready else Color(0.3, 0.75, 1.0)
		if hdata.get("special_bar"):
			hdata["special_bar"].visible = true
			hdata["special_bar"].max_value = max_charge
			hdata["special_bar"].value = current_charge
			hdata["special_bar"].modulate = bar_color
		if hdata.get("silk_container"):
			hdata["silk_container"].visible = false

	elif is_hornet:
		if hdata.get("special_bar"):
			hdata["special_bar"].visible = false
		if hdata.get("silk_spools") == null:
			_ensure_hornet_silk_ui(hdata)
		if hdata.get("silk_container"):
			hdata["silk_container"].visible = true

		var silk_int: int = int(floor(current_charge))
		var partial_fill: float = fmod(current_charge, 1.0)
		var hits_charged: int = int(round(partial_fill * 3.0))

		if silk_int >= 5:
			label_text = "¡SEDA COMPLETA (5/5)!"
			bar_color = Color.WHITE
		elif hits_charged > 0:
			label_text = "SEDA: %d / 5   [CARGA: %d/3]" % [silk_int, hits_charged]
			bar_color = Color(1.0, 0.90, 0.95)
		else:
			label_text = "SEDA: %d / 5" % silk_int
			bar_color = Color(0.95, 0.50, 0.60)

		var spools: Array = hdata.get("silk_spools", [])
		for i in range(spools.size()):
			var tpb: TextureProgressBar = spools[i] as TextureProgressBar
			if i < silk_int:
				tpb.value = 1.0
				tpb.modulate = Color.WHITE
			elif i == silk_int and silk_int < 5:
				tpb.value = partial_fill
				tpb.modulate = Color.WHITE
			else:
				tpb.value = 0.0
				tpb.modulate = Color(0.9, 0.9, 0.95, 0.88)

	if hdata.get("special_label"):
		hdata["special_label"].visible = true
		hdata["special_label"].text = label_text
		hdata["special_label"].modulate = bar_color
#endregion

#region Porcentaje de Daño, Vidas, Reloj y Cuenta Regresiva
func _on_player_ko_event(player_id: int, _death_pos: Vector3) -> void:
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	var pct_lbl: Label = hdata.get("percent", null)
	if pct_lbl:
		var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pct_lbl.scale = Vector2(1.4, 1.4)
		tw.tween_property(pct_lbl, "scale", Vector2.ONE, 0.25)

func update_player_percentage(player_id: int, percentage: float) -> void:
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	var target_label: Label = hdata.get("percent", null)
	if not target_label:
		return

	target_label.text = Utils.format_percentage(percentage)
	target_label.add_theme_color_override("font_color", _get_damage_color(percentage))

	# Rebote elástico estilo Smash Bros al actualizar el porcentaje.
	var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	target_label.pivot_offset = target_label.size * 0.5
	target_label.scale = Vector2(1.28, 1.28)
	tw.tween_property(target_label, "scale", Vector2.ONE, 0.18)

func _get_damage_color(pct: float) -> Color:
	if pct < 35.0:
		return Color.WHITE
	elif pct < 75.0:
		return Color(1.0, 0.9, 0.3)
	elif pct < 120.0:
		return Color(1.0, 0.52, 0.15)
	return Color(1.0, 0.18, 0.25)

func update_lives(player_id: int, lives: int) -> void:
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	var target_label: Label = hdata.get("lives", null)
	if target_label:
		target_label.text = "VIDAS: %d" % maxi(0, lives)
		if lives <= 0:
			target_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

func update_timer(time_seconds: float) -> void:
	if timer_label:
		timer_label.text = Utils.format_time(time_seconds)

func start_countdown() -> void:
	if not countdown_container or not countdown_label:
		countdown_finished.emit()
		return

	countdown_container.visible = true
	var steps: Array[Dictionary] = [
		{"text": "3", "color": Color(1.0, 0.25, 0.25)},
		{"text": "2", "color": Color(1.0, 0.85, 0.15)},
		{"text": "1", "color": Color(0.25, 0.85, 1.0)},
		{"text": "¡SMASH!", "color": Color(0.3, 1.0, 0.4)}
	]

	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		countdown_label.text = step["text"]
		countdown_label.modulate = step["color"]
		countdown_label.pivot_offset = countdown_label.get_minimum_size() * 0.5
		countdown_label.scale = Vector2(1.8, 1.8)

		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(countdown_label, "modulate:a", 1.0, 0.1)

		if i == steps.size() - 1:
			countdown_finished.emit()
			await get_tree().create_timer(0.65).timeout
			var fade_tween: Tween = create_tween()
			fade_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.3)
			await fade_tween.finished
			countdown_container.visible = false
		else:
			await get_tree().create_timer(0.8).timeout
#endregion

#region Guía Discreta de Controles en Combate (Teclado J1 y Joystick)
func _build_controls_hints_ui() -> void:
	if _controls_hints_row != null:
		return

	var main_vbox: VBoxContainer = get_node_or_null("MarginContainer/VBoxContainer") as VBoxContainer
	if main_vbox == null:
		return

	main_vbox.add_theme_constant_override("separation", 6)

	_controls_hints_row = HBoxContainer.new()
	_controls_hints_row.name = "ControlsHintsRow"
	_controls_hints_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_hints_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls_hints_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_controls_hints_row.add_theme_constant_override("separation", 12)

	var kb_rows: Array[Array] = [
		[
			{"key": "WASD", "label": "Moverse", "color": Color(0.86, 0.93, 1.0)},
			{"key": "ESPACIO", "label": "Saltar", "color": Color(0.86, 0.93, 1.0)}
		],
		[
			{"key": "J", "label": "Ataque normal", "color": Color(0.55, 0.84, 1.0)},
			{"key": "K", "label": "Especial", "color": Color(1.0, 0.62, 0.58)},
			{"key": "L", "label": "Escudo", "color": Color(0.82, 0.90, 0.96)}
		]
	]
	var kb_card: PanelContainer = _create_controls_card(
		"KeyboardControlsCard",
		"TECLADO (J1)",
		kb_rows,
		Color(0.32, 0.72, 0.96, 0.36),
		Color(0.64, 0.87, 1.0, 0.88),
		false
	)
	_controls_hints_row.add_child(kb_card)

	var center_spacer := Control.new()
	center_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls_hints_row.add_child(center_spacer)

	var joy_rows: Array[Array] = [
		[
			{"key": "STICK / D-PAD", "label": "Moverse", "color": Color(0.88, 0.92, 0.98)},
			{"key": "A", "label": "Saltar", "color": Color(0.46, 0.90, 0.56)}
		],
		[
			{"key": "X / Y", "label": "Ataque normal", "color": Color(0.50, 0.80, 1.0)},
			{"key": "B", "label": "Especial", "color": Color(0.98, 0.52, 0.50)},
			{"key": "LB / RB / LT / RT", "label": "Escudo", "color": Color(0.84, 0.88, 0.94)}
		]
	]
	var joy_card: PanelContainer = _create_controls_card(
		"JoystickControlsCard",
		"JOYSTICK",
		joy_rows,
		Color(0.78, 0.82, 0.90, 0.30),
		Color(0.84, 0.88, 0.95, 0.82),
		true
	)
	_controls_hints_row.add_child(joy_card)

	main_vbox.add_child(_controls_hints_row)

func _create_controls_card(
	node_name: String,
	title: String,
	rows: Array[Array],
	border_col: Color,
	title_col: Color,
	align_right: bool
) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_SHRINK_END if align_right else Control.SIZE_SHRINK_BEGIN
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.modulate = Color(1.0, 1.0, 1.0, 0.82)

	var card_sb: StyleBoxFlat = UIThemeUtils.make_stylebox(
		Color(0.04, 0.06, 0.10, 0.56), border_col, 1, 4, 8.0, 5.0
	)
	if align_right:
		card_sb.border_width_right = 2
	else:
		card_sb.border_width_left = 2
	card.add_theme_stylebox_override("panel", card_sb)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)

	var ui_font: Font = ThemeDB.fallback_font

	var title_lbl := Label.new()
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if align_right else HORIZONTAL_ALIGNMENT_LEFT
	title_lbl.add_theme_font_override("font", ui_font)
	title_lbl.add_theme_font_size_override("font_size", 9)
	title_lbl.add_theme_color_override("font_color", title_col)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	title_lbl.add_theme_constant_override("outline_size", 2)
	vbox.add_child(title_lbl)

	for row_items in rows:
		var row_hbox := HBoxContainer.new()
		row_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_hbox.alignment = BoxContainer.ALIGNMENT_END if align_right else BoxContainer.ALIGNMENT_BEGIN
		row_hbox.add_theme_constant_override("separation", 8)
		for item in row_items:
			row_hbox.add_child(_create_control_hint_item(
				str(item["key"]),
				str(item["label"]),
				item["color"] as Color,
				ui_font
			))
		vbox.add_child(row_hbox)

	return card

func _create_control_hint_item(key_text: String, action_text: String, key_color: Color, ui_font: Font) -> HBoxContainer:
	var item_box := HBoxContainer.new()
	item_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_box.add_theme_constant_override("separation", 4)

	var key_badge := PanelContainer.new()
	key_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_badge.add_theme_stylebox_override(
		"panel",
		UIThemeUtils.make_stylebox(Color(0.12, 0.16, 0.23, 0.82), Color(0.65, 0.75, 0.88, 0.34), 1, 3, 4.0, 1.0)
	)
	item_box.add_child(key_badge)

	var key_lbl := Label.new()
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_lbl.text = key_text
	key_lbl.add_theme_font_override("font", ui_font)
	key_lbl.add_theme_font_size_override("font_size", 10)
	key_lbl.add_theme_color_override("font_color", key_color)
	key_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	key_lbl.add_theme_constant_override("outline_size", 1)
	key_badge.add_child(key_lbl)

	var desc_lbl := Label.new()
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.text = action_text
	desc_lbl.add_theme_font_override("font", ui_font)
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94, 0.92))
	desc_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.78))
	desc_lbl.add_theme_constant_override("outline_size", 2)
	item_box.add_child(desc_lbl)

	return item_box
#endregion

#region Atajo Rápido: Mantener [R] para Volver a Selección
func _build_hold_r_ui() -> void:
	if _hold_r_container:
		return

	_hold_r_container = PanelContainer.new()
	_hold_r_container.name = "HoldRExitOverlay"
	_hold_r_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hold_r_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hold_r_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hold_r_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hold_r_container.offset_left = -170
	_hold_r_container.offset_right = 170
	_hold_r_container.offset_top = -80
	_hold_r_container.offset_bottom = -20
	_hold_r_container.custom_minimum_size = Vector2(340, 56)

	var box_sb: StyleBoxFlat = UIThemeUtils.make_stylebox(
		Color(0.04, 0.06, 0.10, 0.92), Color(0.95, 0.35, 0.20, 0.85), 2, 6, 14.0, 8.0
	)
	box_sb.shadow_color = Color(0, 0, 0, 0.7)
	box_sb.shadow_size = 10
	_hold_r_container.add_theme_stylebox_override("panel", box_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_hold_r_container.add_child(vbox)

	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 8)
	vbox.add_child(top_h)

	var badge_panel := PanelContainer.new()
	badge_panel.add_theme_stylebox_override(
		"panel", UIThemeUtils.make_stylebox(Color(0.95, 0.35, 0.20, 1.0), Color.TRANSPARENT, 0, 4, 6.0, 1.0)
	)
	top_h.add_child(badge_panel)

	var badge_lbl := Label.new()
	badge_lbl.text = "R"
	badge_lbl.add_theme_font_size_override("font_size", 12)
	badge_lbl.add_theme_color_override("font_color", Color.WHITE)
	badge_panel.add_child(badge_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = "MANTÉN [R] PARA VOLVER A SELECCIÓN"
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	top_h.add_child(msg_lbl)

	_hold_r_percent_lbl = Label.new()
	_hold_r_percent_lbl.text = "0%"
	_hold_r_percent_lbl.add_theme_font_size_override("font_size", 12)
	_hold_r_percent_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	top_h.add_child(_hold_r_percent_lbl)

	_hold_r_bar = ProgressBar.new()
	_hold_r_bar.custom_minimum_size = Vector2(0, 10)
	_hold_r_bar.min_value = 0.0
	_hold_r_bar.max_value = 1.0
	_hold_r_bar.value = 0.0
	_hold_r_bar.show_percentage = false
	_hold_r_bar.add_theme_stylebox_override(
		"background", UIThemeUtils.make_stylebox(Color(0.08, 0.10, 0.14, 0.9), Color.TRANSPARENT, 0, 3)
	)

	_hold_r_fill_sb = UIThemeUtils.make_stylebox(Color(0.95, 0.35, 0.20, 1.0), Color.TRANSPARENT, 0, 3)
	_hold_r_bar.add_theme_stylebox_override("fill", _hold_r_fill_sb)
	vbox.add_child(_hold_r_bar)

	_hold_r_container.visible = false
	_hold_r_container.modulate.a = 0.0
	add_child(_hold_r_container)

func _handle_hold_r_exit(delta: float) -> void:
	if _hold_r_container == null:
		return

	if Input.is_key_pressed(KEY_R):
		_hold_r_timer += delta
		_hold_r_container.visible = true
		_hold_r_container.modulate.a = move_toward(_hold_r_container.modulate.a, 1.0, delta * 8.0)

		var progress: float = clampf(_hold_r_timer / HOLD_R_DURATION, 0.0, 1.0)
		_hold_r_bar.value = progress
		_hold_r_percent_lbl.text = "%d%%" % int(progress * 100.0)
		_hold_r_fill_sb.bg_color = Color(0.95, 0.35, 0.20).lerp(Color(0.20, 0.95, 0.45), progress)

		if _hold_r_timer >= HOLD_R_DURATION:
			_hold_r_timer = 0.0
			_hold_r_container.visible = false
			if GameManager.is_paused:
				GameManager.toggle_pause()
			get_tree().change_scene_to_file("res://ui/character_select.tscn")
	elif _hold_r_timer > 0.0:
		_hold_r_timer = maxf(0.0, _hold_r_timer - delta * 3.5)
		var progress: float = clampf(_hold_r_timer / HOLD_R_DURATION, 0.0, 1.0)
		_hold_r_bar.value = progress
		_hold_r_percent_lbl.text = "%d%%" % int(progress * 100.0)
		_hold_r_container.modulate.a = move_toward(_hold_r_container.modulate.a, 0.0, delta * 6.0)
		if _hold_r_container.modulate.a <= 0.02:
			_hold_r_container.visible = false
	else:
		_hold_r_container.visible = false
#endregion
