extends Node

signal match_started
signal match_ended(winner_id: int)
signal pause_toggled(is_paused: bool)

# Configuración de partida
var player_1_data: Resource = null
var player_2_data: Resource = null
var stock_lives: int = 3
var time_limit_seconds: float = 480.0 # 8 minutos

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
