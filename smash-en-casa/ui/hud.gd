class_name HUD
extends Control

@onready var p1_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Box/PercentLabel
@onready var p1_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Box/LivesLabel
@onready var p2_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Box/PercentLabel
@onready var p2_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Box/LivesLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerBox/TimerLabel

func _ready() -> void:
	# Conexión mediante EventBus desacoplado
	Events.player_damaged.connect(_on_player_damaged)

func _on_player_damaged(player_id: int, new_percentage: float, _attack_data: Resource) -> void:
	update_player_percentage(player_id, new_percentage)

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
