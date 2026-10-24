# ==============================================================================
# GameManager (Autoload / Singleton Core)
# Responsabilidad: Estado de sesión, parámetros de partida y control de pausa.
# Nota: No maneja reglas de combate en tiempo real ni físicas (ver BattleManager).
# ==============================================================================
extends Node

signal match_started
signal match_ended(winner_id: int)
signal pause_toggled(is_paused: bool)

# Configuración de partida
var player_1_data: Resource = null
var player_2_data: Resource = null
var stock_lives: int = 3
var time_limit_seconds: float = 480.0 # 8 minutos

# Catálogo de Escenarios de Batalla
const STAGES: Array[Dictionary] = [
	{
		"id": "astral",
		"name": "Santuario Astral",
		"scene_path": "res://battle/stage.tscn",
		"preview_path": "res://ui/character_select/stages/preview_astral.png",
		"sky_top_color": Color(0.14, 0.18, 0.38, 1.0),
		"sky_horizon_color": Color(0.88, 0.58, 0.65, 1.0),
		"ground_bottom_color": Color(0.08, 0.10, 0.18, 1.0),
		"ground_horizon_color": Color(0.88, 0.58, 0.65, 1.0),
		"sun_color": Color(1.0, 0.90, 0.75, 1.0),
		"theme_color": Color(0.35, 0.75, 1.0, 1.0)
	},
	{
		"id": "cyber",
		"name": "Cámara Cibernética",
		"scene_path": "res://battle/stage_cyber.tscn",
		"preview_path": "res://ui/character_select/stages/preview_cyber.png",
		"sky_top_color": Color(0.02, 0.04, 0.12, 1.0),
		"sky_horizon_color": Color(0.0, 0.45, 0.85, 1.0),
		"ground_bottom_color": Color(0.01, 0.02, 0.06, 1.0),
		"ground_horizon_color": Color(0.40, 0.05, 0.65, 1.0),
		"sun_color": Color(0.25, 0.85, 1.0, 1.0),
		"theme_color": Color(0.1, 0.9, 1.0, 1.0)
	},
	{
		"id": "volcano",
		"name": "Caldera Ardiente",
		"scene_path": "res://battle/stage_volcano.tscn",
		"preview_path": "res://ui/character_select/stages/preview_volcano.png",
		"sky_top_color": Color(0.12, 0.02, 0.02, 1.0),
		"sky_horizon_color": Color(0.85, 0.25, 0.05, 1.0),
		"ground_bottom_color": Color(0.08, 0.01, 0.01, 1.0),
		"ground_horizon_color": Color(0.70, 0.15, 0.0, 1.0),
		"sun_color": Color(1.0, 0.45, 0.10, 1.0),
		"theme_color": Color(1.0, 0.4, 0.1, 1.0)
	}
]
var selected_stage_index: int = 0

func get_selected_stage() -> Dictionary:
	return STAGES[clampi(selected_stage_index, 0, STAGES.size() - 1)]

func set_selected_stage_index(idx: int) -> void:
	selected_stage_index = posmod(idx, STAGES.size())

func get_selected_stage_scene_path() -> String:
	return get_selected_stage().get("scene_path", "res://battle/stage.tscn")

var is_paused: bool = false
var winner_player_id: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_toggled.emit(is_paused)

func start_match(p1_data: Resource, p2_data: Resource, lives: int = 3, timer: float = 480.0) -> void:
	player_1_data = p1_data
	player_2_data = p2_data
	stock_lives = lives
	time_limit_seconds = timer
	winner_player_id = -1
	match_started.emit()

func end_match(winner_id: int) -> void:
	winner_player_id = winner_id
	match_ended.emit(winner_id)
