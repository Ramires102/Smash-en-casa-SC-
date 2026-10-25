class_name HUD
extends Control

signal countdown_finished

# P1 References
@onready var p1_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/PercentLabel
@onready var p1_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/NameRow/LivesRow/LivesLabel
@onready var p1_special_bar: ProgressBar = $MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/SpecialBar
@onready var p1_special_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/SpecialLabel
@onready var p1_logo: TextureRect = $MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Logo
@onready var p1_name_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Panel/P1Margin/P1HBox/P1Box/NameRow/NameLabel

# P2 References
@onready var p2_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/PercentLabel
@onready var p2_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/NameRow/LivesRow/LivesLabel
@onready var p2_special_bar: ProgressBar = $MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/SpecialBar
@onready var p2_special_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/SpecialLabel
@onready var p2_logo: TextureRect = $MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Logo
@onready var p2_name_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Panel/P2Margin/P2HBox/P2Box/NameRow/NameLabel

# Timer & Overlays
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerPanel/TimerBox/TimerLabel
@onready var countdown_container: CenterContainer = $CountdownContainer
@onready var countdown_label: Label = $CountdownContainer/CountdownLabel

func _ready() -> void:
	# EventBus connections
	Events.player_damaged.connect(_on_player_damaged)
	Events.special_meter_changed.connect(_on_special_meter_changed)
	Events.player_ko_event.connect(_on_player_ko_event)
	
	if countdown_container:
		countdown_container.visible = false
	
	_setup_character_visuals()
	update_special_meter(1, 0.0, 100.0)
	update_special_meter(2, 0.0, 100.0)

func _setup_character_visuals() -> void:
	if GameManager.player_1_data:
		if p1_name_label:
			p1_name_label.text = GameManager.player_1_data.character_name.to_upper()
		if p1_logo and "logo_texture" in GameManager.player_1_data and GameManager.player_1_data.logo_texture:
			p1_logo.texture = GameManager.player_1_data.logo_texture
			
	if GameManager.player_2_data:
		if p2_name_label:
			p2_name_label.text = GameManager.player_2_data.character_name.to_upper()
		if p2_logo and "logo_texture" in GameManager.player_2_data and GameManager.player_2_data.logo_texture:
			p2_logo.texture = GameManager.player_2_data.logo_texture

func _on_player_ko_event(player_id: int, _death_pos: Vector3, p1_lives: int, p2_lives: int) -> void:
	show_stock_score(player_id, p1_lives, p2_lives)

func _on_player_damaged(player_id: int, new_percentage: float, _impact: ImpactData) -> void:
	update_player_percentage(player_id, new_percentage)

func _on_special_meter_changed(player_id: int, current_charge: float, max_charge: float) -> void:
	update_special_meter(player_id, current_charge, max_charge)

func update_special_meter(player_id: int, current_charge: float, max_charge: float = 100.0) -> void:
	var pct: int = int(round((current_charge / maxf(1.0, max_charge)) * 100.0))
	var is_ready: bool = pct >= 100
	var label_text: String = "¡ESPECIAL LISTO!" if is_ready else ("ESPECIAL ↓: %d%%" % pct)
	var bar_color: Color = Color(1.0, 0.88, 0.25) if is_ready else Color(0.3, 0.75, 1.0)
	
	if player_id == 1:
		if p1_special_bar:
			p1_special_bar.max_value = max_charge
			p1_special_bar.value = current_charge
			p1_special_bar.modulate = bar_color
		if p1_special_label:
			p1_special_label.text = label_text
			p1_special_label.modulate = bar_color
	elif player_id == 2:
		if p2_special_bar:
			p2_special_bar.max_value = max_charge
			p2_special_bar.value = current_charge
			p2_special_bar.modulate = bar_color
		if p2_special_label:
			p2_special_label.text = label_text
			p2_special_label.modulate = bar_color

func _get_damage_color(pct: float) -> Color:
	if pct < 35.0:
		return Color(1.0, 1.0, 1.0) # White
	elif pct < 75.0:
		return Color(1.0, 0.9, 0.3) # Gold Yellow
	elif pct < 120.0:
		return Color(1.0, 0.52, 0.15) # Intense Orange
	else:
		return Color(1.0, 0.18, 0.25) # Critical Blood Red

func update_player_percentage(player_id: int, percentage: float) -> void:
	var text: String = Utils.format_percentage(percentage)
	var target_label: Label = p1_percent_label if player_id == 1 else p2_percent_label
	
	if target_label:
		target_label.text = text
		target_label.add_theme_color_override("font_color", _get_damage_color(percentage))
		
		# Smash Bros style impact bounce on hit
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		target_label.scale = Vector2(1.28, 1.28)
		target_label.pivot_offset = target_label.size * 0.5
		tw.tween_property(target_label, "scale", Vector2.ONE, 0.18)

func update_lives(player_id: int, lives: int) -> void:
	var text: String = "VIDAS: %d" % lives
	if player_id == 1 and p1_lives_label:
		p1_lives_label.text = text
	elif player_id == 2 and p2_lives_label:
		p2_lives_label.text = text

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
		countdown_label.pivot_offset = countdown_label.size / 2.0
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

# ==============================================================================
# Tournament Stock Score Popup (Super Smash Con / Fighting Game broadcast style)
# ==============================================================================
var _stock_popup: Control = null
var _stock_popup_tween: Tween = null
var _p1_score_label: Label = null
var _p2_score_label: Label = null
var _p1_stock_dots: HBoxContainer = null
var _p2_stock_dots: HBoxContainer = null
var _p1_logo_rect: TextureRect = null
var _p2_logo_rect: TextureRect = null

func _build_stock_popup() -> void:
	if _stock_popup != null:
		return

	_stock_popup = Control.new()
	_stock_popup.name = "StockScorePopup"
	_stock_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stock_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stock_popup.visible = false
	add_child(_stock_popup)

	var bar_container = PanelContainer.new()
	bar_container.custom_minimum_size = Vector2(560, 80)
	bar_container.anchors_preset = Control.PRESET_CENTER
	bar_container.anchor_left = 0.5
	bar_container.anchor_top = 0.52
	bar_container.anchor_right = 0.5
	bar_container.anchor_bottom = 0.52
	bar_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.10, 0.92)
	style.border_color = Color(1.0, 0.85, 0.25, 0.85)
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 16
	bar_container.add_theme_stylebox_override("panel", style)
	_stock_popup.add_child(bar_container)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	bar_container.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	var font_res = preload("res://ui/Fondos de texto/kamikaze_condensed.tres") if ResourceLoader.exists("res://ui/Fondos de texto/kamikaze_condensed.tres") else null

	# P1 Logo
	_p1_logo_rect = TextureRect.new()
	_p1_logo_rect.custom_minimum_size = Vector2(48, 48)
	_p1_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_p1_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if GameManager.player_1_data and "logo_texture" in GameManager.player_1_data and GameManager.player_1_data.logo_texture:
		_p1_logo_rect.texture = GameManager.player_1_data.logo_texture
	hbox.add_child(_p1_logo_rect)

	# P1 Stock icons
	_p1_stock_dots = HBoxContainer.new()
	_p1_stock_dots.add_theme_constant_override("separation", 6)
	hbox.add_child(_p1_stock_dots)

	# P1 Score
	_p1_score_label = Label.new()
	_p1_score_label.text = "3"
	if font_res:
		_p1_score_label.add_theme_font_override("font", font_res)
	_p1_score_label.add_theme_font_size_override("font_size", 54)
	_p1_score_label.add_theme_color_override("font_color", Color(0.35, 0.8, 1.0))
	_p1_score_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_p1_score_label.add_theme_constant_override("outline_size", 8)
	hbox.add_child(_p1_score_label)

	# Center Divider
	var div_panel = PanelContainer.new()
	div_panel.custom_minimum_size = Vector2(32, 10)
	var div_style = StyleBoxFlat.new()
	div_style.bg_color = Color(1.0, 0.85, 0.3, 0.95)
	div_panel.add_theme_stylebox_override("panel", div_style)
	hbox.add_child(div_panel)

	# P2 Score
	_p2_score_label = Label.new()
	_p2_score_label.text = "2"
	if font_res:
		_p2_score_label.add_theme_font_override("font", font_res)
	_p2_score_label.add_theme_font_size_override("font_size", 54)
	_p2_score_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.45))
	_p2_score_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_p2_score_label.add_theme_constant_override("outline_size", 8)
	hbox.add_child(_p2_score_label)

	# P2 Stock icons
	_p2_stock_dots = HBoxContainer.new()
	_p2_stock_dots.add_theme_constant_override("separation", 6)
	hbox.add_child(_p2_stock_dots)

	# P2 Logo
	_p2_logo_rect = TextureRect.new()
	_p2_logo_rect.custom_minimum_size = Vector2(48, 48)
	_p2_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_p2_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if GameManager.player_2_data and "logo_texture" in GameManager.player_2_data and GameManager.player_2_data.logo_texture:
		_p2_logo_rect.texture = GameManager.player_2_data.logo_texture
	hbox.add_child(_p2_logo_rect)

func _update_stock_dots(container: HBoxContainer, lives: int, color: Color) -> void:
	for child in container.get_children():
		child.queue_free()
	for i in range(maxi(0, lives)):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = color
		container.add_child(dot)

func show_stock_score(_ko_player_id: int, p1_lives: int, p2_lives: int) -> void:
	_build_stock_popup()
	if not _stock_popup:
		return

	if _p1_logo_rect and GameManager.player_1_data and "logo_texture" in GameManager.player_1_data and GameManager.player_1_data.logo_texture:
		_p1_logo_rect.texture = GameManager.player_1_data.logo_texture
	if _p2_logo_rect and GameManager.player_2_data and "logo_texture" in GameManager.player_2_data and GameManager.player_2_data.logo_texture:
		_p2_logo_rect.texture = GameManager.player_2_data.logo_texture

	if _p1_score_label:
		_p1_score_label.text = str(maxi(0, p1_lives))
	if _p2_score_label:
		_p2_score_label.text = str(maxi(0, p2_lives))

	if _p1_stock_dots:
		_update_stock_dots(_p1_stock_dots, p1_lives, Color(0.25, 0.75, 1.0))
	if _p2_stock_dots:
		_update_stock_dots(_p2_stock_dots, p2_lives, Color(1.0, 0.35, 0.3))

	if _stock_popup_tween:
		_stock_popup_tween.kill()

	_stock_popup.visible = true
	_stock_popup.modulate.a = 0.0
	_stock_popup.scale = Vector2(1.2, 1.2)
	_stock_popup.pivot_offset = _stock_popup.size * 0.5

	_stock_popup_tween = create_tween()
	_stock_popup_tween.tween_property(_stock_popup, "modulate:a", 1.0, 0.15)
	_stock_popup_tween.parallel().tween_property(_stock_popup, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_stock_popup_tween.tween_interval(1.8)
	_stock_popup_tween.tween_property(_stock_popup, "modulate:a", 0.0, 0.3)
	_stock_popup_tween.tween_callback(func(): _stock_popup.visible = false)
