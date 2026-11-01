# ==============================================================================
# VictoryMenu (Pantalla de Resultados Post-Combate)
# ==============================================================================
# Muestra al campeón de la partida (o empate), su perfil de control activo y el
# emblema de su personaje, ofreciendo revancha rápida, cambio de luchador o
# regreso al menú principal.
# ==============================================================================
class_name VictoryMenu
extends Control

const PLAYER_COLORS: Dictionary = {
	1: Color(0.35, 0.80, 1.00),
	2: Color(1.00, 0.35, 0.45),
	3: Color(0.25, 0.90, 0.45),
	4: Color(1.00, 0.85, 0.25)
}

@onready var winner_label: Label = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/WinnerLabel")
@onready var winner_logo: TextureRect = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/WinnerLogo")
@onready var retry_btn: Button = get_node_or_null("CenterContainer/CardPanel/MarginContainer/VBoxContainer/RetryButton")
@onready var card_panel: PanelContainer = get_node_or_null("CenterContainer/CardPanel")

#region Ciclo de Vida y Presentación
func _ready() -> void:
	AudioManager.play_menu_theme()

	if retry_btn:
		retry_btn.grab_focus()

	_populate_winner_card()
	_play_entrance_animation()

func _populate_winner_card() -> void:
	if not winner_label:
		return

	var wid: int = GameManager.winner_player_id
	if wid > 0:
		var p_data: CharacterData = GameManager.get_player_data(wid)
		var p_prof: String = GameManager.get_player_profile(wid)
		var char_name: String = p_data.character_name if p_data else "LUCHADOR"

		if p_prof != "" and p_prof != "Default":
			winner_label.text = "¡JUGADOR %d (%s) ES EL CAMPEÓN!\n[%s]" % [wid, p_prof.to_upper(), char_name.to_upper()]
		else:
			winner_label.text = "¡JUGADOR %d (%s) ES EL CAMPEÓN!" % [wid, char_name.to_upper()]

		var accent: Color = PLAYER_COLORS.get(wid, Color(1.0, 0.85, 0.25))
		winner_label.add_theme_color_override("font_color", accent)

		if winner_logo and p_data and p_data.logo_texture:
			winner_logo.texture = p_data.logo_texture
			winner_logo.visible = true
	else:
		winner_label.text = "¡EMPATE DE TITANES!"
		winner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		if winner_logo:
			winner_logo.visible = false

func _play_entrance_animation() -> void:
	if not card_panel:
		return
	card_panel.custom_minimum_size = Vector2(480, 420)
	card_panel.pivot_offset = Vector2(240, 210)
	card_panel.scale = Vector2(0.8, 0.8)
	var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_panel, "scale", Vector2.ONE, 0.4)
#endregion

#region Navegación (Conectada desde victory.tscn)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
#endregion
