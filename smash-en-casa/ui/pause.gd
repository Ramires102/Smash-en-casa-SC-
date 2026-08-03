class_name PauseMenu
extends Control

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.toggle_pause()

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_menu_pressed() -> void:
	GameManager.toggle_pause()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
