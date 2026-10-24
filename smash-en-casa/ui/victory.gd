class_name VictoryMenu
extends Control

@onready var winner_label: Label = /WinnerLabel

func _ready() -> void:
	var retry_btn: Button = get_node_or_null("VBoxContainer/RetryButton")
	if retry_btn:
		retry_btn.grab_focus()

	# Etiqueta de ganador
	if winner_label:
		if GameManager.winner_player_id > 0:
			winner_label.text = "Â¡JUGADOR %d GANA!" % GameManager.winner_player_id
		else:
			winner_label.text = "Â¡EMPATE!"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")