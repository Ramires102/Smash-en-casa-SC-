class_name VictoryMenu
extends Control

@onready var winner_label: Label = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/WinnerLabel")
@onready var winner_logo: TextureRect = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/WinnerLogo")
@onready var retry_btn: Button = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/RetryButton")
@onready var card_panel: PanelContainer = get_node_or_null("CenterContainer/CardPanel")

func _ready() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_menu_theme"):
		am.play_menu_theme()

	if retry_btn:
		retry_btn.grab_focus()

	# Configurar ganador
	if winner_label:
		var wid: int = GameManager.winner_player_id
		if wid > 0:
			var p_data = GameManager.get_player_data(wid)
			var p_prof: String = GameManager.get_player_profile(wid)
			var char_name: String = p_data.character_name if p_data else "LUCHADOR"
			
			if p_prof != "" and p_prof != "Default":
				winner_label.text = "¡JUGADOR %d (%s) ES EL CAMPEÓN!\n[%s]" % [wid, p_prof.to_upper(), char_name.to_upper()]
			else:
				winner_label.text = "¡JUGADOR %d (%s) ES EL CAMPEÓN!" % [wid, char_name.to_upper()]

			match wid:
				1: winner_label.add_theme_color_override("font_color", Color(0.35, 0.8, 1.0))
				2: winner_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.45))
				3: winner_label.add_theme_color_override("font_color", Color(0.25, 0.90, 0.45))
				4: winner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
				_: winner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))

			if winner_logo and p_data and "logo_texture" in p_data and p_data.logo_texture:
				winner_logo.texture = p_data.logo_texture
				winner_logo.visible = true
		else:
			winner_label.text = "¡EMPATE DE TITANES!"
			winner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			if winner_logo:
				winner_logo.visible = false

	# Animación pop-in estilo fighting game con pivote centrado
	if card_panel:
		card_panel.custom_minimum_size = Vector2(480, 420)
		card_panel.pivot_offset = Vector2(240, 210)
		card_panel.scale = Vector2(0.8, 0.8)
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
