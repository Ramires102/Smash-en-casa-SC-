class_name PlayerProfile
extends RefCounted

const SAVE_PATH := "user://profiles/profile_default.json"

var username: String = "Jugador"
var victory_dust: int = 0
var defeat_dust: int = 0
var total_pulls: int = 0

# ── Economía ──────────────────────────────────────────────────
const PULL_COST_VICTORY: int = 160
const PULL_COST_DEFEAT:  int = 200
const PULL_COST_VICTORY_10: int = 1600
const PULL_COST_DEFEAT_10:  int = 2000

func add_victory_dust(amount: int) -> void:
	victory_dust += amount
	save()

func add_defeat_dust(amount: int) -> void:
	defeat_dust += amount
	save()

func can_pull_victory() -> bool:
	return victory_dust >= PULL_COST_VICTORY

func can_pull_defeat() -> bool:
	return defeat_dust >= PULL_COST_DEFEAT

func can_pull_victory_10() -> bool:
	return victory_dust >= PULL_COST_VICTORY_10

func can_pull_defeat_10() -> bool:
	return defeat_dust >= PULL_COST_DEFEAT_10

func spend_victory() -> bool:
	if not can_pull_victory():
		return false
	victory_dust -= PULL_COST_VICTORY
	total_pulls += 1
	save()
	return true

func spend_defeat() -> bool:
	if not can_pull_defeat():
		return false
	defeat_dust -= PULL_COST_DEFEAT
	total_pulls += 1
	save()
	return true

func spend_victory_10() -> bool:
	if not can_pull_victory_10():
		return false
	victory_dust -= PULL_COST_VICTORY_10
	total_pulls += 10
	save()
	return true

func spend_defeat_10() -> bool:
	if not can_pull_defeat_10():
		return false
	defeat_dust -= PULL_COST_DEFEAT_10
	total_pulls += 10
	save()
	return true

# ── Persistencia ──────────────────────────────────────────────
func save() -> void:
	DirAccess.make_dir_recursive_absolute("user://profiles")
	var data := {
		"username":     username,
		"victory_dust": victory_dust,
		"defeat_dust":  defeat_dust,
		"total_pulls":  total_pulls,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		username     = parsed.get("username",     "Jugador")
		victory_dust = parsed.get("victory_dust", 0)
		defeat_dust  = parsed.get("defeat_dust",  0)
		total_pulls  = parsed.get("total_pulls",  0)
