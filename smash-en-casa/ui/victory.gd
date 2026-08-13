class_name VictoryMenu
extends Control

@onready var winner_label: Label     = $VBoxContainer/WinnerLabel
@onready var dust_label: Label       = $VBoxContainer/DustEarnedLabel
@onready var victory_count: Label    = $VBoxContainer/DustHBox/VictoryCount
@onready var defeat_count: Label     = $VBoxContainer/DustHBox/DefeatCount

func _ready() -> void:
	# Etiqueta de ganador
	if winner_label:
		if GameManager.winner_player_id > 0:
			winner_label.text = "¡JUGADOR %d GANA!" % GameManager.winner_player_id
		else:
			winner_label.text = "¡EMPATE!"

	# Polvo ganado — siempre 15 victoria en local si hubo ganador
	if dust_label:
		if GameManager.winner_player_id > 0:
			dust_label.text = "✦ +15 Polvo de Victoria ganado"
			dust_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		else:
			dust_label.text = "Sin recompensa en empate"
			dust_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	# Contadores actuales
	_update_dust_counters()

func _update_dust_counters() -> void:
	if victory_count:
		victory_count.text = "✦ %d" % ProfileManager.get_victory_dust()
	if defeat_count:
		defeat_count.text  = "☽ %d" % ProfileManager.get_defeat_dust()

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
