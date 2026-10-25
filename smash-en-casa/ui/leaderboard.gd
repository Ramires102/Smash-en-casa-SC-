class_name LeaderboardUI
extends Control

signal closed

@onready var rank_container: VBoxContainer = $MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/RankVBox
@onready var stat_champion_lbl: Label = $MarginContainer/PanelContainer/VBoxContainer/SummaryRow/ChampCard/VBox/ValueLabel
@onready var stat_total_matches_lbl: Label = $MarginContainer/PanelContainer/VBoxContainer/SummaryRow/MatchesCard/VBox/ValueLabel
@onready var stat_profiles_lbl: Label = $MarginContainer/PanelContainer/VBoxContainer/SummaryRow/ProfilesCard/VBox/ValueLabel
@onready var reset_btn: Button = $MarginContainer/PanelContainer/VBoxContainer/BottomRow/ResetButton
@onready var back_btn: Button = $MarginContainer/PanelContainer/VBoxContainer/BottomRow/BackButton

var _confirm_reset_clicks: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_refresh_data()
	
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
		back_btn.grab_focus()
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
		
	var pm = get_node_or_null("/root/ProfileManager")
	if pm and pm.has_signal("leaderboard_updated"):
		pm.leaderboard_updated.connect(_refresh_data)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _refresh_data() -> void:
	if not rank_container:
		return

	for c in rank_container.get_children():
		c.queue_free()

	var pm = get_node_or_null("/root/ProfileManager")
	var ranked: Array[Dictionary] = []
	if pm and pm.has_method("get_ranked_leaderboard"):
		ranked = pm.get_ranked_leaderboard()

	var total_matches_all: int = 0
	var top_champ: String = "-"
	var max_wins: int = 0

	for p in ranked:
		var w: int = int(p.get("wins", 0))
		var m: int = int(p.get("matches", 0))
		total_matches_all += m
		if w > max_wins:
			max_wins = w
			top_champ = str(p.get("name", "-"))

	if stat_champion_lbl:
		stat_champion_lbl.text = ("%s (%d W)" % [top_champ, max_wins]) if max_wins > 0 else "-"
	if stat_total_matches_lbl:
		stat_total_matches_lbl.text = str(total_matches_all)
	if stat_profiles_lbl:
		stat_profiles_lbl.text = str(ranked.size())

	if ranked.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "NO HAY PARTIDAS REGISTRADAS TODAVÍA.\n¡JUEGA UNA PARTIDA PARA ENTRAR EN LA TABLA!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 14)
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
		rank_container.add_child(empty_lbl)
		return

	# Generar filas de la tabla de clasificación
	for i in range(ranked.size()):
		var data: Dictionary = ranked[i]
		var row := _create_rank_row(i + 1, data)
		rank_container.add_child(row)

func _create_rank_row(pos: int, data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	
	var is_first: bool = (pos == 1 and int(data.get("wins", 0)) > 0)
	var is_second: bool = (pos == 2 and int(data.get("wins", 0)) > 0)
	var is_third: bool = (pos == 3 and int(data.get("wins", 0)) > 0)

	if is_first:
		sb.bg_color = Color(0.20, 0.16, 0.05, 0.95)
		sb.border_color = Color(1.0, 0.84, 0.20, 1.0)
		sb.set_border_width_all(2)
	elif is_second:
		sb.bg_color = Color(0.14, 0.16, 0.19, 0.9)
		sb.border_color = Color(0.80, 0.82, 0.88, 0.8)
		sb.set_border_width_all(1)
	elif is_third:
		sb.bg_color = Color(0.18, 0.12, 0.08, 0.9)
		sb.border_color = Color(0.80, 0.50, 0.25, 0.8)
		sb.set_border_width_all(1)
	else:
		sb.bg_color = Color(0.08, 0.10, 0.14, 0.85) if (pos % 2 == 0) else Color(0.10, 0.12, 0.17, 0.85)
		sb.border_color = Color(0.22, 0.25, 0.30, 0.6)
		sb.set_border_width_all(1)

	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	# Posición con insignia
	var pos_lbl := Label.new()
	pos_lbl.custom_minimum_size = Vector2(45, 0)
	if is_first:
		pos_lbl.text = "🥇 #1"
		pos_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25))
	elif is_second:
		pos_lbl.text = "🥈 #2"
		pos_lbl.add_theme_color_override("font_color", Color(0.88, 0.90, 0.95))
	elif is_third:
		pos_lbl.text = "🥉 #3"
		pos_lbl.add_theme_color_override("font_color", Color(0.92, 0.60, 0.35))
	else:
		pos_lbl.text = "   #%d" % pos
		pos_lbl.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80))
	pos_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(pos_lbl)

	# Nombre de perfil
	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name", "Jugador")).to_upper()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if is_first else Color(0.9, 0.92, 0.96))
	hbox.add_child(name_lbl)

	# Victorias
	var wins_lbl := Label.new()
	wins_lbl.custom_minimum_size = Vector2(75, 0)
	wins_lbl.text = "%d W" % int(data.get("wins", 0))
	wins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wins_lbl.add_theme_font_size_override("font_size", 14)
	wins_lbl.add_theme_color_override("font_color", Color(0.35, 0.88, 0.45))
	hbox.add_child(wins_lbl)

	# Derrotas
	var loss_lbl := Label.new()
	loss_lbl.custom_minimum_size = Vector2(65, 0)
	loss_lbl.text = "%d L" % int(data.get("losses", 0))
	loss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loss_lbl.add_theme_font_size_override("font_size", 13)
	loss_lbl.add_theme_color_override("font_color", Color(0.90, 0.35, 0.35))
	hbox.add_child(loss_lbl)

	# Partidas
	var mat_lbl := Label.new()
	mat_lbl.custom_minimum_size = Vector2(70, 0)
	mat_lbl.text = "%d Total" % int(data.get("matches", 0))
	mat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mat_lbl.add_theme_font_size_override("font_size", 12)
	mat_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85))
	hbox.add_child(mat_lbl)

	# Win Rate %
	var wr_lbl := Label.new()
	wr_lbl.custom_minimum_size = Vector2(85, 0)
	var wr: float = float(data.get("win_rate", 0.0))
	wr_lbl.text = "%.1f%% WR" % wr
	wr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wr_lbl.add_theme_font_size_override("font_size", 13)
	if wr >= 65.0:
		wr_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	elif wr >= 50.0:
		wr_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	else:
		wr_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90))
	hbox.add_child(wr_lbl)

	# Luchador Favorito
	var fav_lbl := Label.new()
	fav_lbl.custom_minimum_size = Vector2(130, 0)
	fav_lbl.text = str(data.get("favorite_character", "-"))
	fav_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fav_lbl.add_theme_font_size_override("font_size", 11)
	fav_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.8))
	hbox.add_child(fav_lbl)

	return panel

func _on_reset_pressed() -> void:
	_confirm_reset_clicks += 1
	if _confirm_reset_clicks == 1:
		if reset_btn:
			reset_btn.text = "[!] CONFIRMAR REINICIO"
			reset_btn.modulate = Color(1.0, 0.35, 0.35)
	else:
		_confirm_reset_clicks = 0
		var pm = get_node_or_null("/root/ProfileManager")
		if pm and pm.has_method("reset_leaderboard"):
			pm.reset_leaderboard()
		if reset_btn:
			reset_btn.text = "REINICIAR DATOS"
			reset_btn.modulate = Color(1.0, 1.0, 1.0)
		_refresh_data()

func _on_back_pressed() -> void:
	closed.emit()
	queue_free()
