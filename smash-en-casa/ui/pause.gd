# ==============================================================================
# PauseMenu (Menú de Pausa Durante el Combate)
# ==============================================================================
# Superposición modal que escucha la tecla Escape o el botón Start de cualquiera
# de los mandos activos para detener/reanudar la partida.
# Importante: Usa `PROCESS_MODE_ALWAYS` para poder capturar la entrada tanto
# cuando el combate está en curso como cuando `SceneTree.paused == true`.
# ==============================================================================
class_name PauseMenu
extends Control

const CONTROLS_CONFIG_SCENE: PackedScene = preload("res://ui/controls_config.tscn")

@onready var resume_btn: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton")

var _controls_config_instance: Control = null

#region Ciclo de Vida y Visibilidad
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.pause_toggled.connect(_on_pause_toggled)
	visibility_changed.connect(_on_visibility_changed)
	visible = GameManager.is_paused
	if visible:
		_on_visibility_changed()

func _exit_tree() -> void:
	if GameManager.pause_toggled.is_connected(_on_pause_toggled):
		GameManager.pause_toggled.disconnect(_on_pause_toggled)

func _on_pause_toggled(is_paused: bool) -> void:
	visible = is_paused
	if not is_paused and is_instance_valid(_controls_config_instance):
		_controls_config_instance.queue_free()
		_controls_config_instance = null
	if visible and resume_btn:
		resume_btn.grab_focus()

func _on_visibility_changed() -> void:
	if visible and resume_btn:
		resume_btn.grab_focus()
#endregion

#region Entrada de Pausa (Teclado y hasta 4 Mandos)
func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_controls_config_instance):
		return

	var is_pause_action: bool = event.is_action_pressed("ui_cancel") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE
	)

	if not is_pause_action:
		for p_id in range(1, InputManager.MAX_PLAYERS + 1):
			var action_name: String = "p%d_pause" % p_id
			if InputManager.is_player_connected(p_id) and InputMap.has_action(action_name) and event.is_action_pressed(action_name):
				is_pause_action = true
				break

	if is_pause_action:
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()
#endregion

#region Acciones de Botones (Conectadas desde pause.tscn)
func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_controls_pressed() -> void:
	if is_instance_valid(_controls_config_instance):
		return
	_controls_config_instance = CONTROLS_CONFIG_SCENE.instantiate()
	_controls_config_instance.closed.connect(func() -> void:
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
#endregion
