# ==============================================================================
# ProfileManager / LeaderboardManager (Autoload: ProfileManager)
# ==============================================================================
# Administra las estadísticas históricas de cada perfil de jugador y las guarda
# en formato JSON ("user://leaderboard.json").
# Cada vez que termina una partida, actualiza victorias, derrotas, porcentaje
# de victoria (win rate) y el personaje más utilizado de cada participante.
# ==============================================================================
class_name LeaderboardManager
extends Node

signal leaderboard_updated

const LEADERBOARD_SAVE_PATH: String = "user://leaderboard.json"
const DEFAULT_PROFILES: Array[String] = ["Default", "Teclado P1", "Teclado P2"]

## Diccionario maestro: nombre_perfil -> diccionario de estadísticas.
var profiles_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_leaderboard()
	_sync_with_input_profiles()

#region Sincronización y Creación de Perfiles
## Garantiza que todos los perfiles creados en Controles tengan entrada en el Leaderboard.
func _sync_with_input_profiles() -> void:
	var im: Node = get_node_or_null("/root/InputManager")
	if im and im.has_method("get_profile_names"):
		for p_name in im.get_profile_names():
			ensure_profile_exists(p_name)

## Crea un registro vacío para el perfil si aún no existe.
func ensure_profile_exists(profile_name: String) -> void:
	var clean: String = profile_name.strip_edges()
	if clean.is_empty():
		clean = "Default"
	if not profiles_data.has(clean):
		profiles_data[clean] = _create_empty_stats(clean)
		save_leaderboard()

func _create_empty_stats(profile_name: String) -> Dictionary:
	return {
		"name": profile_name,
		"wins": 0,
		"losses": 0,
		"matches": 0,
		"win_rate": 0.0,
		"favorite_character": "-",
		"char_usage": {},
		"last_played": "-"
	}
#endregion

#region Registro y Consulta de Estadísticas
## Registra el resultado de una partida para todos los jugadores participantes.
func record_match_result(
	active_pids: Array,
	winner_id: int,
	player_profiles: Dictionary,
	player_chars: Dictionary
) -> void:
	var date_str: String = Time.get_date_string_from_system()

	for pid in active_pids:
		var prof_name: String = str(player_profiles.get(pid, "Default")).strip_edges()
		if prof_name.is_empty():
			prof_name = "Player %d" % pid
		ensure_profile_exists(prof_name)

		var p_data: Dictionary = profiles_data[prof_name]
		var char_name: String = str(player_chars.get(pid, "Luchador")).to_upper()

		p_data["matches"] = int(p_data.get("matches", 0)) + 1
		p_data["last_played"] = date_str

		# Contabilizar uso de personaje y recalcular el favorito
		var usage: Dictionary = p_data.get("char_usage", {})
		usage[char_name] = int(usage.get(char_name, 0)) + 1
		p_data["char_usage"] = usage
		p_data["favorite_character"] = _find_most_used_character(usage, char_name)

		if pid == winner_id:
			p_data["wins"] = int(p_data.get("wins", 0)) + 1
		elif winner_id > 0:
			p_data["losses"] = int(p_data.get("losses", 0)) + 1

		var total_matches: int = int(p_data["matches"])
		var total_wins: int = int(p_data["wins"])
		p_data["win_rate"] = (float(total_wins) / float(maxi(1, total_matches))) * 100.0

	save_leaderboard()
	leaderboard_updated.emit()

func _find_most_used_character(usage: Dictionary, fallback_name: String) -> String:
	var best_char: String = fallback_name
	var best_count: int = 0
	for char_key in usage.keys():
		var count: int = int(usage[char_key])
		if count > best_count:
			best_count = count
			best_char = str(char_key)
	return best_char

## Devuelve los perfiles ordenados por: 1° Victorias, 2° % Victoria, 3° Partidas jugadas.
func get_ranked_leaderboard() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for k in profiles_data.keys():
		list.append(profiles_data[k].duplicate(true))

	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var w_a: int = int(a.get("wins", 0))
		var w_b: int = int(b.get("wins", 0))
		if w_a != w_b:
			return w_a > w_b
		var wr_a: float = float(a.get("win_rate", 0.0))
		var wr_b: float = float(b.get("win_rate", 0.0))
		if not is_equal_approx(wr_a, wr_b):
			return wr_a > wr_b
		return int(a.get("matches", 0)) > int(b.get("matches", 0))
	)
	return list

func get_profile_stats(profile_name: String) -> Dictionary:
	ensure_profile_exists(profile_name)
	return profiles_data.get(profile_name, {})

## Reinicia a cero todas las estadísticas conservando los nombres de los perfiles.
func reset_leaderboard() -> void:
	for k in profiles_data.keys():
		profiles_data[k] = _create_empty_stats(str(k))
	save_leaderboard()
	leaderboard_updated.emit()
#endregion

#region Persistencia en Disco (JSON)
func save_leaderboard() -> void:
	var f := FileAccess.open(LEADERBOARD_SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(profiles_data, "\t"))

func load_leaderboard() -> void:
	if FileAccess.file_exists(LEADERBOARD_SAVE_PATH):
		var f := FileAccess.open(LEADERBOARD_SAVE_PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				profiles_data = parsed

	for default_name in DEFAULT_PROFILES:
		ensure_profile_exists(default_name)
#endregion
