# ==============================================================================
# LeaderboardUI (Tabla de Clasificación por Perfiles de Jugador)
# ==============================================================================
# Muestra el ranking histórico almacenado por `ProfileManager`:
#   - Tarjetas superiores de resumen (Campeón actual, Partidas totales, Perfiles).
#   - Filas ordenadas con insignias de podio (Oro, Plata, Bronce), Victorias,
#     Derrotas, Win Rate % y Luchador Favorito.
#   - Reinicio seguro de estadísticas con doble clic de confirmación.
# ==============================================================================
class_name LeaderboardUI
extends Control

signal closed

#region Referencias de Escena
@onready var rank_container: VBoxContainer = $MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/RankVBox
@onready var stat_champion_lbl: Label = $MarginContainer/PanelContainer/VBoxContainer/SummaryRow/ChampCard/VBox/ValueLabel
@onready var stat_total_matches_lbl: Label = $MarginContainer/PanelContainer/VBoxContainer/SummaryRow/MatchesCard/VBox/ValueLabel
@onready var stat_profiles_lbl: Label = $MarginContainer/PanelContainer/VBoxContainer/SummaryRow/ProfilesCard/VBox/ValueLabel
@onready var reset_btn: Button = $MarginContainer/PanelContainer/VBoxContainer/BottomRow/ResetButton
@onready var back_btn: Button = $MarginContainer/PanelContainer/VBoxContainer/BottomRow/BackButton

var _confirm_reset_clicks: int = 0
#endregion

#region Ciclo de Vida y Navegación
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_refresh_data()

	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
		back_btn.grab_focus()
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)

	ProfileManager.leaderboard_updated.connect(_refresh_data)

func _exit_tree() -> void:
	if ProfileManager.leaderboard_updated.is_connected(_refresh_data):
		ProfileManager.leaderboard_updated.disconnect(_refresh_data)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
#endregion

#region Renderizado del Ranking
func _refresh_data() -> void:
	if not rank_container:
		return

	for child in rank_container.get_children():
		child.queue_free()

	var ranked: Array[Dictionary] = ProfileManager.get_ranked_leaderboard()
	var total_matches_all: int = 0
	var top_champ: String = "-"
	var max_wins: int = 0

	for entry in ranked:
		var wins: int = int(entry.get("wins", 0))
		total_matches_all += int(entry.get("matches", 0))
		if wins > max_wins:
			max_wins = wins
			top_champ = str(entry.get("name", "-"))

	if stat_champion_lbl:
		stat_champion_lbl.text = ("%s (%d W)" % [top_champ, max_wins]) if max_wins > 0 else "-"
	if stat_total_matches_lbl:
		stat_total_matches_lbl.text = str(total_matches_all)
	if stat_profiles_lbl:
		stat_profiles_lbl.text = str(ranked.size())

	if ranked.is_empty():
		var empty_lbl := _create_cell_label(
			"NO HAY PARTIDAS REGISTRADAS TODAVÍA.\n¡JUEGA UNA PARTIDA PARA ENTRAR EN LA TABLA!",
			0.0, 14, Color(0.7, 0.75, 0.85, 0.8), HORIZONTAL_ALIGNMENT_CENTER
		)
		rank_container.add_child(empty_lbl)
		return

	for i in range(ranked.size()):
		rank_container.add_child(_create_rank_row(i + 1, ranked[i]))

func _create_rank_row(pos: int, data: Dictionary) -> PanelContainer:
	var wins: int = int(data.get("wins", 0))
	var is_first: bool = (pos == 1 and wins > 0)
	var is_second: bool = (pos == 2 and wins > 0)
	var is_third: bool = (pos == 3 and wins > 0)

	var bg_col: Color
	var border_col: Color
	var border_w: int = 1
	var pos_text: String = "   #%d" % pos
	var pos_col := Color(0.65, 0.70, 0.80)

	if is_first:
		bg_col = Color(0.20, 0.16, 0.05, 0.95)
		border_col = Color(1.0, 0.84, 0.20, 1.0)
		border_w = 2
		pos_text = "🥇 #1"
		pos_col = Color(1.0, 0.86, 0.25)
	elif is_second:
		bg_col = Color(0.14, 0.16, 0.19, 0.9)
		border_col = Color(0.80, 0.82, 0.88, 0.8)
		pos_text = "🥈 #2"
		pos_col = Color(0.88, 0.90, 0.95)
	elif is_third:
		bg_col = Color(0.18, 0.12, 0.08, 0.9)
		border_col = Color(0.80, 0.50, 0.25, 0.8)
		pos_text = "🥉 #3"
		pos_col = Color(0.92, 0.60, 0.35)
	else:
		bg_col = Color(0.08, 0.10, 0.14, 0.85) if (pos % 2 == 0) else Color(0.10, 0.12, 0.17, 0.85)
		border_col = Color(0.22, 0.25, 0.30, 0.6)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", UIThemeUtils.make_stylebox(bg_col, border_col, border_w, 4, 12.0, 6.0)
	)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	var wr: float = float(data.get("win_rate", 0.0))
	var wr_col := Color(0.75, 0.80, 0.90)
	if wr >= 65.0:
		wr_col = Color(1.0, 0.85, 0.25)
	elif wr >= 50.0:
		wr_col = Color(0.35, 0.85, 1.0)

	hbox.add_child(_create_cell_label(pos_text, 45.0, 14, pos_col, HORIZONTAL_ALIGNMENT_LEFT))
	hbox.add_child(_create_cell_label(
		str(data.get("name", "Jugador")).to_upper(), 0.0, 14,
		Color.WHITE if is_first else Color(0.9, 0.92, 0.96), HORIZONTAL_ALIGNMENT_LEFT, true
	))
	hbox.add_child(_create_cell_label("%d W" % wins, 75.0, 14, Color(0.35, 0.88, 0.45)))
	hbox.add_child(_create_cell_label("%d L" % int(data.get("losses", 0)), 65.0, 13, Color(0.90, 0.35, 0.35)))
	hbox.add_child(_create_cell_label("%d Total" % int(data.get("matches", 0)), 70.0, 12, Color(0.70, 0.75, 0.85)))
	hbox.add_child(_create_cell_label("%.1f%% WR" % wr, 85.0, 13, wr_col))
	hbox.add_child(_create_cell_label(
		str(data.get("favorite_character", "-")), 130.0, 11,
		Color(0.85, 0.88, 0.95, 0.8), HORIZONTAL_ALIGNMENT_RIGHT
	))

	return panel

func _create_cell_label(
	text_val: String,
	min_width: float,
	font_size: int,
	color: Color,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER,
	expand: bool = false
) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.horizontal_alignment = align
	if min_width > 0.0:
		lbl.custom_minimum_size = Vector2(min_width, 0.0)
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl
#endregion

#region Acciones de Botones
func _on_reset_pressed() -> void:
	_confirm_reset_clicks += 1
	if _confirm_reset_clicks == 1:
		if reset_btn:
			reset_btn.text = "[!] CONFIRMAR REINICIO"
			reset_btn.modulate = Color(1.0, 0.35, 0.35)
	else:
		_confirm_reset_clicks = 0
		ProfileManager.reset_leaderboard()
		if reset_btn:
			reset_btn.text = "REINICIAR DATOS"
			reset_btn.modulate = Color.WHITE
		_refresh_data()

func _on_back_pressed() -> void:
	closed.emit()
	queue_free()
#endregion
