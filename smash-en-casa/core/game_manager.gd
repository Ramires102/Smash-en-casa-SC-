# ==============================================================================
# GameManager (Autoload Global)
# ==============================================================================
# Gestiona el estado general de la sesión de juego:
#   1. Qué jugadores están activos (1 a 4), sus personajes elegidos y sus perfiles.
#   2. El catálogo de escenarios seleccionables y sus colores de iluminación.
#   3. El estado global de pausa y el registro del ganador al terminar la partida.
# Nota: Las reglas en tiempo real del combate viven en BattleManager.
# ==============================================================================
extends Node

#region Señales de Sesión
signal match_started
signal match_ended(winner_id: int)
signal pause_toggled(is_paused: bool)
#endregion

#region Datos de Jugadores y Reglas de Partida
## Diccionario ID_Jugador (1..4) -> CharacterData seleccionado.
var players_data: Dictionary = {1: null, 2: null, 3: null, 4: null}

## Diccionario ID_Jugador (1..4) -> Nombre del perfil de control activo (usado en Leaderboard).
var player_profiles: Dictionary = {1: "Default", 2: "Teclado P2", 3: "Default", 4: "Default"}

## Lista ordenada de IDs de jugadores que participan en la partida actual.
var active_player_ids: Array[int] = [1, 2]

var stock_lives: int = 3
var time_limit_seconds: float = 480.0 # 8 minutos por defecto
var training_mode: bool = false
var is_paused: bool = false
var winner_player_id: int = -1
#endregion

#region Catálogo de Escenarios
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
#endregion

func _ready() -> void:
	# Debe seguir procesándose incluso cuando el árbol de escenas está en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS

#region API de Escenarios y Pausa
func get_selected_stage() -> Dictionary:
	return STAGES[clampi(selected_stage_index, 0, STAGES.size() - 1)]

func set_selected_stage_index(idx: int) -> void:
	selected_stage_index = posmod(idx, STAGES.size())

func get_selected_stage_scene_path() -> String:
	return get_selected_stage().get("scene_path", "res://battle/stage.tscn")

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_toggled.emit(is_paused)
#endregion

#region API de Jugadores y Ciclo de Partida
func get_player_data(player_id: int) -> Resource:
	return players_data.get(player_id, null)

func get_player_profile(player_id: int) -> String:
	return player_profiles.get(player_id, "Default")

## Configura una partida multijugador (2 a 4 jugadores) antes de cargar la escena Battle.
func start_match_multi(
	p_data_dict: Dictionary,
	lives: int = 3,
	timer: float = 480.0,
	p_profiles: Dictionary = {}
) -> void:
	players_data.clear()
	active_player_ids.clear()

	for pid in range(1, 5):
		if p_data_dict.has(pid) and p_data_dict[pid] != null:
			players_data[pid] = p_data_dict[pid]
			active_player_ids.append(pid)
		else:
			players_data[pid] = null

	for pid in p_profiles.keys():
		player_profiles[pid] = str(p_profiles[pid])

	stock_lives = lives
	time_limit_seconds = timer
	winner_player_id = -1
	match_started.emit()

## Cierra la partida actual y registra victorias/derrotas en la tabla de clasificación.
func end_match(winner_id: int) -> void:
	winner_player_id = winner_id

	var char_names: Dictionary = {}
	for pid in active_player_ids:
		var pdata: Resource = get_player_data(pid)
		if pdata and "character_name" in pdata:
			char_names[pid] = pdata.character_name
		else:
			char_names[pid] = "Luchador"

	var pm: Node = get_node_or_null("/root/ProfileManager")
	if pm and pm.has_method("record_match_result"):
		pm.record_match_result(active_player_ids, winner_id, player_profiles, char_names)

	match_ended.emit(winner_id)
#endregion
