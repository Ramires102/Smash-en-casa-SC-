extends Node

# Singleton que expone el perfil activo del jugador local.
# Cuando se implemente el online, este nodo recibirá el perfil
# del jugador autenticado sin modificar nada más del juego.

signal dust_changed(victory: int, defeat: int)

var current_profile: PlayerProfile

func _ready() -> void:
	current_profile = PlayerProfile.new()
	current_profile.load_from_disk()

# ── Atajos públicos ───────────────────────────────────────────
func add_victory_dust(amount: int) -> void:
	current_profile.add_victory_dust(amount)
	dust_changed.emit(current_profile.victory_dust, current_profile.defeat_dust)

func add_defeat_dust(amount: int) -> void:
	current_profile.add_defeat_dust(amount)
	dust_changed.emit(current_profile.victory_dust, current_profile.defeat_dust)

func get_victory_dust() -> int:
	return current_profile.victory_dust

func get_defeat_dust() -> int:
	return current_profile.defeat_dust

func try_pull_victory() -> bool:
	var ok := current_profile.spend_victory()
	if ok:
		dust_changed.emit(current_profile.victory_dust, current_profile.defeat_dust)
	return ok

func try_pull_defeat() -> bool:
	var ok := current_profile.spend_defeat()
	if ok:
		dust_changed.emit(current_profile.victory_dust, current_profile.defeat_dust)
	return ok

func try_pull_victory_10() -> bool:
	var ok := current_profile.spend_victory_10()
	if ok:
		dust_changed.emit(current_profile.victory_dust, current_profile.defeat_dust)
	return ok

func try_pull_defeat_10() -> bool:
	var ok := current_profile.spend_defeat_10()
	if ok:
		dust_changed.emit(current_profile.victory_dust, current_profile.defeat_dust)
	return ok
