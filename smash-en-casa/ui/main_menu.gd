class_name MainMenu
extends Control

func _ready() -> void:
	var start_btn: Button = get_node_or_null("VBoxContainer/StartButton")
	if start_btn:
		start_btn.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_gacha_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/gacha.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
