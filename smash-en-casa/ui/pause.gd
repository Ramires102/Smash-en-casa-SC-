class_name PauseMenu
extends Control

@onready var resume_btn: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton")
var _controls_config_instance: Control = null

func _ready() -> void:
	GameManager.pause_toggled.connect(_on_pause_toggled)
	visibility_changed.connect(_on_visibility_changed)
	visible = GameManager.is_paused
	if visible:
		_on_visibility_changed()

func _on_pause_toggled(is_paused: bool) -> void:
	visible = is_paused
	if not is_paused and _controls_config_instance and is_instance_valid(_controls_config_instance):
		_controls_config_instance.queue_free()
		_controls_config_instance = null
	if visible and resume_btn:
		resume_btn.grab_focus()

func _on_visibility_changed() -> void:
	if visible and resume_btn:
		resume_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if _controls_config_instance and is_instance_valid(_controls_config_instance):
		return
	var is_pause_action: bool = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)
	if not is_pause_action:
		for p_id in range(1, InputManager.MAX_PLAYERS + 1):
			if InputManager.is_player_connected(p_id) and InputMap.has_action("p%d_pause" % p_id) and event.is_action_pressed("p%d_pause" % p_id):
				is_pause_action = true
				break
	if is_pause_action:
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_controls_pressed() -> void:
	if _controls_config_instance and is_instance_valid(_controls_config_instance):
		return
	var cfg_scene := preload("res://ui/controls_config.tscn")
	_controls_config_instance = cfg_scene.instantiate()
	_controls_config_instance.closed.connect(func():
		_controls_config_instance = null
		if visible and resume_btn:
			resume_btn.grab_focus()
	)
	add_child(_controls_config_instance)

func _on_restart_pressed() -> void:
	GameManager.toggle_pause()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameManager.toggle_pause()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
