class_name HUD
extends Control

signal countdown_finished

@onready var p1_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Box/PercentLabel
@onready var p1_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Box/LivesLabel
@onready var p1_special_bar: ProgressBar = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Box/SpecialBar")
@onready var p1_special_label: Label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P1Box/SpecialLabel")
@onready var p2_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Box/PercentLabel
@onready var p2_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Box/LivesLabel
@onready var p2_special_bar: ProgressBar = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Box/SpecialBar")
@onready var p2_special_label: Label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/P2Box/SpecialLabel")
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerBox/TimerLabel

@onready var countdown_container: CenterContainer = get_node_or_null("CountdownContainer")
@onready var countdown_label: Label = get_node_or_null("CountdownContainer/CountdownLabel")

func _ready() -> void:
	# Conexión mediante EventBus desacoplado
	Events.player_damaged.connect(_on_player_damaged)
	Events.special_meter_changed.connect(_on_special_meter_changed)
	if countdown_container:
		countdown_container.visible = false
	update_special_meter(1, 0.0, 100.0)
	update_special_meter(2, 0.0, 100.0)

func _on_player_damaged(player_id: int, new_percentage: float, _impact: ImpactData) -> void:
	update_player_percentage(player_id, new_percentage)

func _on_special_meter_changed(player_id: int, current_charge: float, max_charge: float) -> void:
	update_special_meter(player_id, current_charge, max_charge)

func update_special_meter(player_id: int, current_charge: float, max_charge: float = 100.0) -> void:
	var pct: int = int(round((current_charge / maxf(1.0, max_charge)) * 100.0))
	var is_ready: bool = pct >= 100
	var label_text: String = "¡ESPECIAL ↓ LISTO!" if is_ready else ("Especial ↓: %d%%" % pct)
	var bar_color: Color = Color(0.2, 0.95, 1.0) if is_ready else Color(0.65, 0.78, 0.95)
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

func update_player_percentage(player_id: int, percentage: float) -> void:
	var text: String = Utils.format_percentage(percentage)
	if player_id == 1 and p1_percent_label:
		p1_percent_label.text = text
	elif player_id == 2 and p2_percent_label:
		p2_percent_label.text = text

func update_lives(player_id: int, lives: int) -> void:
	var text: String = "Vidas: %d" % lives
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
		tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(countdown_label, "modulate:a", 1.0, 0.1)

		if i == steps.size() - 1:
			# "¡SMASH!" Step: desbloquear la batalla de inmediato
			countdown_finished.emit()
			await get_tree().create_timer(0.65).timeout
			var fade_tween := create_tween()
			fade_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.35)
			await fade_tween.finished
			countdown_container.visible = false
		else:
			await get_tree().create_timer(0.85).timeout
