class_name VictoryMenu
extends Control

@onready var winner_label: Label = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/WinnerLabel")
@onready var winner_logo: TextureRect = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/WinnerLogo")
@onready var retry_btn: Button = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/RetryButton")
@onready var card_panel: PanelContainer = get_node_or_null("CenterContainer/CardPanel")

func _ready() -> void:
	if retry_btn:
		retry_btn.grab_focus()

	# Configurar ganador
	if winner_label:
		if GameManager.winner_player_id == 1:
			var name_str = GameManager.player_1_data.character_name if GameManager.player_1_data else "JUGADOR 1"
			winner_label.text = "¡%s ES EL CAMPEÓN!" % name_str.to_upper()
			winner_label.add_theme_color_override("font_color", Color(0.35, 0.8, 1.0))
			if winner_logo and GameManager.player_1_data and "logo_texture" in GameManager.player_1_data and GameManager.player_1_data.logo_texture:
				winner_logo.texture = GameManager.player_1_data.logo_texture
		elif GameManager.winner_player_id == 2:
			var name_str = GameManager.player_2_data.character_name if GameManager.player_2_data else "JUGADOR 2"
			winner_label.text = "¡%s ES EL CAMPEÓN!" % name_str.to_upper()
			winner_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.45))
			if winner_logo and GameManager.player_2_data and "logo_texture" in GameManager.player_2_data and GameManager.player_2_data.logo_texture:
				winner_logo.texture = GameManager.player_2_data.logo_texture
		else:
			winner_label.text = "¡EMPATE DE TITANES!"
			winner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			if winner_logo:
				winner_logo.visible = false

	# Animación pop-in estilo fighting game
	if card_panel:
		card_panel.scale = Vector2(0.8, 0.8)
		card_panel.pivot_offset = card_panel.size * 0.5
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.4)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
