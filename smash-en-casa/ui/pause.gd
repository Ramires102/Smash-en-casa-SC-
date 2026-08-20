class_name PauseMenu
extends Control

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	if visible:
		_on_visibility_changed()

func _on_visibility_changed() -> void:
	if visible:
		var resume_btn: Button = get_node_or_null("VBoxContainer/ResumeButton")
		if resume_btn:
			resume_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.toggle_pause()

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_menu_pressed() -> void:
	GameManager.toggle_pause()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
