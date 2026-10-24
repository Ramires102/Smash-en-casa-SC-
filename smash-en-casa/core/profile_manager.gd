extends Node

var current_profile: PlayerProfile

func _ready() -> void:
	current_profile = PlayerProfile.new()
	current_profile.load_from_disk()

func record_win() -> void:
	if current_profile:
		current_profile.record_win()

func record_loss() -> void:
	if current_profile:
		current_profile.record_loss()