class_name LeaderboardManager
extends Node

signal leaderboard_updated

const LEADERBOARD_SAVE_PATH: String = "user://leaderboard.json"

# Diccionario maestro de perfiles:
# profile_name -> {
#   "name": String,
#   "wins": int,
#   "losses": int,
#   "matches": int,
#   "win_rate": float,
#   "favorite_character": String,
#   "char_usage": Dictionary, # char_name -> count
#   "last_played": String
# }
var profiles_data: Dictionary = {}
var current_profile: PlayerProfile = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_profile = PlayerProfile.new()
	current_profile.load_from_disk()
	load_leaderboard()
	_sync_with_input_profiles()

func _sync_with_input_profiles() -> void:
	if not Engine.has_singleton("InputManager") and not get_node_or_null("/root/InputManager"):
		return
	var im = get_node_or_null("/root/InputManager")
	if im and im.has_method("get_profile_names"):
		for p_name in im.get_profile_names():
			ensure_profile_exists(p_name)

func ensure_profile_exists(profile_name: String) -> void:
	var clean := profile_name.strip_edges()
	if clean == "":
		clean = "Default"
	if not profiles_data.has(clean):
		profiles_data[clean] = {
			"name": clean,
			"wins": 0,
			"losses": 0,
			"matches": 0,
			"win_rate": 0.0,
			"favorite_character": "-",
			"char_usage": {},
			"last_played": "-"
		}
		save_leaderboard()

func record_match_result(active_pids: Array, winner_id: int, player_profiles: Dictionary, player_chars: Dictionary) -> void:
	var date_str := Time.get_date_string_from_system()

	for pid in active_pids:
		var prof_name: String = str(player_profiles.get(pid, "Default")).strip_edges()
		if prof_name == "":
			prof_name = "Player %d" % pid
		ensure_profile_exists(prof_name)

		var p_data: Dictionary = profiles_data[prof_name]
		var char_name: String = str(player_chars.get(pid, "Luchador")).to_upper()

		p_data["matches"] = int(p_data.get("matches", 0)) + 1
		p_data["last_played"] = date_str

		# Trackear personaje usado
		var usage: Dictionary = p_data.get("char_usage", {})
		usage[char_name] = int(usage.get(char_name, 0)) + 1
		p_data["char_usage"] = usage
		
		# Determinar personaje favorito más usado
		var best_char: String = char_name
		var best_count: int = 0
		for c in usage.keys():
			if usage[c] > best_count:
				best_count = usage[c]
				best_char = c
		p_data["favorite_character"] = best_char

		if pid == winner_id:
			p_data["wins"] = int(p_data.get("wins", 0)) + 1
		elif winner_id > 0:
			p_data["losses"] = int(p_data.get("losses", 0)) + 1

		var total_m: int = p_data["matches"]
		var total_w: int = p_data["wins"]
		p_data["win_rate"] = (float(total_w) / float(maxi(1, total_m))) * 100.0

	# Guardar y notificar
	save_leaderboard()
	leaderboard_updated.emit()

func get_ranked_leaderboard() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for k in profiles_data.keys():
		var d: Dictionary = profiles_data[k].duplicate(true)
		list.append(d)

	# Ordenar por:
	# 1. Victorias descendente
	# 2. Win rate descendente
	# 3. Partidas totales descendente
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

func reset_leaderboard() -> void:
	for k in profiles_data.keys():
		profiles_data[k]["wins"] = 0
		profiles_data[k]["losses"] = 0
		profiles_data[k]["matches"] = 0
		profiles_data[k]["win_rate"] = 0.0
		profiles_data[k]["favorite_character"] = "-"
		profiles_data[k]["char_usage"] = {}
		profiles_data[k]["last_played"] = "-"
	save_leaderboard()
	leaderboard_updated.emit()

func save_leaderboard() -> void:
	var f := FileAccess.open(LEADERBOARD_SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(profiles_data, "\t"))

func load_leaderboard() -> void:
	if not FileAccess.file_exists(LEADERBOARD_SAVE_PATH):
		# Inicializar con perfiles base
		ensure_profile_exists("Default")
		ensure_profile_exists("Teclado P1")
		ensure_profile_exists("Teclado P2")
		return
	var f := FileAccess.open(LEADERBOARD_SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		profiles_data = parsed
	ensure_profile_exists("Default")
	ensure_profile_exists("Teclado P1")
	ensure_profile_exists("Teclado P2")

# Métodos heredados para compatibilidad
func record_win() -> void:
	if current_profile:
		current_profile.record_win()

func record_loss() -> void:
	if current_profile:
		current_profile.record_loss()
