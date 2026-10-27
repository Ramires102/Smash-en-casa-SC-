class_name HUD
extends Control

signal countdown_finished

# Referencias a paneles por jugador (1 a 4)
var player_hud_data: Dictionary = {}

# Timer & Overlays
@onready var timer_label: Label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/TimerPanel/TimerBox/TimerLabel")
@onready var countdown_container: CenterContainer = get_node_or_null("CountdownContainer")
@onready var countdown_label: Label = get_node_or_null("CountdownContainer/CountdownLabel")
@onready var top_row: HBoxContainer = get_node_or_null("MarginContainer/VBoxContainer/TopRow")

func _ready() -> void:
	# EventBus connections
	Events.player_damaged.connect(_on_player_damaged)
	Events.special_meter_changed.connect(_on_special_meter_changed)
	Events.player_ko_event.connect(_on_player_ko_event)
	
	if countdown_container:
		countdown_container.visible = false

	_init_player_panels()
	_setup_character_visuals()

func _init_player_panels() -> void:
	player_hud_data.clear()

	# P1 existente
	var p1_panel = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel")
	if p1_panel:
		player_hud_data[1] = {
			"panel": p1_panel,
			"percent": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/PercentLabel"),
			"lives": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/NameRow/LivesRow/LivesLabel"),
			"name": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/NameRow/NameLabel"),
			"logo": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Logo"),
			"special_bar": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/SpecialBar"),
			"special_label": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/SpecialLabel")
		}

	# P2 existente
	var p2_panel = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel")
	if p2_panel:
		player_hud_data[2] = {
			"panel": p2_panel,
			"percent": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/PercentLabel"),
			"lives": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/NameRow/LivesRow/LivesLabel"),
			"name": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/NameRow/NameLabel"),
			"logo": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Logo"),
			"special_bar": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/SpecialBar"),
			"special_label": get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/SpecialLabel")
		}

	# Si P3 y/o P4 están activos, crear sus paneles clonando P1/P2
	var active_pids: Array[int] = GameManager.active_player_ids
	if active_pids.has(3) and top_row and p1_panel:
		var p3_panel = p1_panel.duplicate()
		p3_panel.name = "P3Panel"
		top_row.add_child(p3_panel)
		top_row.move_child(p3_panel, top_row.get_node("TimerPanel").get_index())
		player_hud_data[3] = _extract_panel_nodes(p3_panel)

	if active_pids.has(4) and top_row and p2_panel:
		var p4_panel = p2_panel.duplicate()
		p4_panel.name = "P4Panel"
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
		"special_label": null
	}
	_find_hud_children(panel, dict)
	return dict

func _find_hud_children(node: Node, dict: Dictionary) -> void:
	if node is Label:
		if node.name == "PercentLabel": dict["percent"] = node
		elif node.name == "LivesLabel": dict["lives"] = node
		elif node.name == "NameLabel": dict["name"] = node
		elif node.name == "SpecialLabel": dict["special_label"] = node
	elif node is TextureRect and "Logo" in node.name:
		dict["logo"] = node
	elif node is ProgressBar and node.name == "SpecialBar":
		dict["special_bar"] = node

	for child in node.get_children():
		_find_hud_children(child, dict)

func _is_player_sakuya(player_id: int) -> bool:
	var data = GameManager.get_player_data(player_id)
	if data == null:
		return false
	return data.character_name.to_lower().contains("sakuya")

func _is_player_hornet(player_id: int) -> bool:
	var data = GameManager.get_player_data(player_id)
	if data == null:
		return false
	return data.character_name.to_lower().contains("hornet")

func _setup_character_visuals() -> void:
	for pid in player_hud_data.keys():
		var data = GameManager.get_player_data(pid)
		var hdata: Dictionary = player_hud_data[pid]
		var is_sakuya: bool = _is_player_sakuya(pid)
		var is_hornet: bool = _is_player_hornet(pid)
		var has_meter: bool = is_sakuya or is_hornet

		if hdata["special_bar"]:
			hdata["special_bar"].visible = has_meter
		if hdata["special_label"]:
			hdata["special_label"].visible = has_meter
		if is_sakuya:
			update_special_meter(pid, 0.0, 100.0)
		elif is_hornet:
			update_special_meter(pid, 5.0, 5.0)

		if data:
			if hdata["name"]:
				var prof: String = GameManager.get_player_profile(pid)
				hdata["name"].text = "P%d: %s" % [pid, data.character_name.to_upper()]
				if prof != "" and prof != "Default":
					hdata["name"].text = "%s (%s)" % [data.character_name.to_upper(), prof]
			if hdata["logo"] and "logo_texture" in data and data.logo_texture:
				hdata["logo"].texture = data.logo_texture

func _on_player_ko_event(player_id: int, _death_pos: Vector3, p1_lives: int, p2_lives: int) -> void:
	# Feedback visual cuando un jugador es noqueado
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	if hdata.has("percent") and hdata["percent"]:
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hdata["percent"].scale = Vector2(1.4, 1.4)
		tw.tween_property(hdata["percent"], "scale", Vector2.ONE, 0.25)

func _on_player_damaged(player_id: int, new_percentage: float, _impact: ImpactData) -> void:
	update_player_percentage(player_id, new_percentage)

func _on_special_meter_changed(player_id: int, current_charge: float, max_charge: float) -> void:
	update_special_meter(player_id, current_charge, max_charge)

func update_special_meter(player_id: int, current_charge: float, max_charge: float = 100.0) -> void:
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	var is_sakuya: bool = _is_player_sakuya(player_id)
	var is_hornet: bool = _is_player_hornet(player_id)

	if not is_sakuya and not is_hornet:
		if hdata.get("special_bar"): hdata["special_bar"].visible = false
		if hdata.get("special_label"): hdata["special_label"].visible = false
		return

	var label_text: String = ""
	var bar_color: Color = Color.WHITE

	if is_sakuya:
		var pct: int = int(round((current_charge / maxf(1.0, max_charge)) * 100.0))
		var is_ready: bool = pct >= 100
		label_text = "¡ESPECIAL LISTO!" if is_ready else ("ESPECIAL ↓: %d%%" % pct)
		bar_color = Color(1.0, 0.88, 0.25) if is_ready else Color(0.3, 0.75, 1.0)
	elif is_hornet:
		var silk_int: int = int(current_charge)
		label_text = "¡SEDA MÁXIMA (5/5)!" if silk_int >= 5 else ("SEDA: %d / 5" % silk_int)
		bar_color = Color(1.0, 0.95, 0.95) if silk_int >= 5 else Color(0.9, 0.25, 0.35)

	if hdata.get("special_bar"):
		hdata["special_bar"].visible = true
		hdata["special_bar"].max_value = max_charge
		hdata["special_bar"].value = current_charge
		hdata["special_bar"].modulate = bar_color
	if hdata.get("special_label"):
		hdata["special_label"].visible = true
		hdata["special_label"].text = label_text
		hdata["special_label"].modulate = bar_color

func _get_damage_color(pct: float) -> Color:
	if pct < 35.0:
		return Color(1.0, 1.0, 1.0)
	elif pct < 75.0:
		return Color(1.0, 0.9, 0.3)
	elif pct < 120.0:
		return Color(1.0, 0.52, 0.15)
	else:
		return Color(1.0, 0.18, 0.25)

func update_player_percentage(player_id: int, percentage: float) -> void:
	var text: String = Utils.format_percentage(percentage)
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	var target_label: Label = hdata.get("percent", null)
	
	if target_label:
		target_label.text = text
		target_label.add_theme_color_override("font_color", _get_damage_color(percentage))
		
		# Smash Bros style impact bounce on hit
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		target_label.pivot_offset = target_label.size * 0.5
		target_label.scale = Vector2(1.28, 1.28)
		tw.tween_property(target_label, "scale", Vector2.ONE, 0.18)

func update_lives(player_id: int, lives: int) -> void:
	var text: String = "VIDAS: %d" % maxi(0, lives)
	var hdata: Dictionary = player_hud_data.get(player_id, {})
	var target_label: Label = hdata.get("lives", null)
	if target_label:
		target_label.text = text
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
		countdown_label.text = step.text
		countdown_label.modulate = step.color
		countdown_label.pivot_offset = countdown_label.get_minimum_size() * 0.5
		countdown_label.scale = Vector2(1.8, 1.8)

		var tween := create_tween().set_parallel(true)
		tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(countdown_label, "modulate:a", 1.0, 0.1)

		if i == steps.size() - 1:
			countdown_finished.emit()
			await get_tree().create_timer(0.65).timeout
			var fade_tween := create_tween()
			fade_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.3)
			await fade_tween.finished
			countdown_container.visible = false
		else:
			await get_tree().create_timer(0.8).timeout
