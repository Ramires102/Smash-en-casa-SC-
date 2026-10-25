class_name VictoryMenu
extends Control

@onready var winner_label: Label = get_node_or_null("VBoxContainer/WinnerLabel")

func _ready() -> void:
	print("VICTORY SCENE LOADED SUCCESSFULLY! Winner ID: ", GameManager.winner_player_id)
	var retry_btn: Button = get_node_or_null("VBoxContainer/RetryButton")
	if retry_btn:
		retry_btn.grab_focus()

	# Etiqueta de ganador
	if winner_label:
		if GameManager.winner_player_id == 1:
			var name_str = GameManager.player_1_data.character_name if GameManager.player_1_data else "JUGADOR 1"
			winner_label.text = "¡%s GANA!" % name_str.to_upper()
			winner_label.modulate = Color(0.3, 0.75, 1.0)
		elif GameManager.winner_player_id == 2:
			var name_str = GameManager.player_2_data.character_name if GameManager.player_2_data else "JUGADOR 2"
			winner_label.text = "¡%s GANA!" % name_str.to_upper()
			winner_label.modulate = Color(1.0, 0.35, 0.3)
		else:
			winner_label.text = "¡EMPATE!"
			winner_label.modulate = Color(1.0, 0.85, 0.2)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
