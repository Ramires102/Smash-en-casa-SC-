class_name PlayerProfile
extends RefCounted

const SAVE_PATH := "user://profiles/profile_default.json"

var username: String = "Jugador"
var matches_played: int = 0
var wins: int = 0

func record_win() -> void:
	matches_played += 1
	wins += 1
	save()

func record_loss() -> void:
	matches_played += 1
	save()

func save() -> void:
	var dir := "user://profiles"
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	var data := {
		"username": username,
		"matches_played": matches_played,
		"wins": wins
	}
	file.store_string(JSON.stringify(data, "\t"))

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_str := file.get_as_text()
	var parsed = JSON.parse_string(json_str)
	if parsed is Dictionary:
		username = parsed.get("username", "Jugador")
		matches_played = int(parsed.get("matches_played", 0))
		wins = int(parsed.get("wins", 0))