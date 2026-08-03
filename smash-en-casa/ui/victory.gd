class_name VictoryMenu
extends Control

@onready var winner_label: Label = $VBoxContainer/WinnerLabel

func _ready() -> void:
	if winner_label:
		if GameManager.winner_player_id > 0:
			winner_label.text = "¡JUGADOR %d GANA!" % GameManager.winner_player_id
		else:
			winner_label.text = "¡EMPATE!"

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
