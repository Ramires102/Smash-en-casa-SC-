class_name SpawnManager
extends Node

@export var stage: Stage

func spawn_player(character_scene: PackedScene, player_id: int, data: CharacterData) -> Character:
	var instance: Character = character_scene.instantiate() as Character
	instance.player_id = player_id
	if stage:
		instance.global_position = stage.get_spawn_position(player_id)
	else:
		instance.global_position = Vector3(-4 if player_id == 1 else 4, 3, 0)
	
	if data:
		instance.character_data = data
	return instance

func respawn_player(character: Character) -> void:
	if stage:
		character.reset_player(stage.get_spawn_position(character.player_id))
	else:
		character.reset_player(Vector3(-4 if character.player_id == 1 else 4, 3, 0))
