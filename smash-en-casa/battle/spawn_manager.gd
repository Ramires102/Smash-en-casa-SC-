class_name SpawnManager
extends Node

@export var stage: Stage

func spawn_player(character_scene: PackedScene, player_id: int, data: CharacterData) -> Character:
	var instance: Character = character_scene.instantiate() as Character
	instance.player_id = player_id
	if data:
		instance.character_data = data
	return instance

func set_initial_transform(instance: Character, player_id: int) -> void:
	if stage:
		instance.global_position = stage.get_spawn_position(player_id)
	else:
		instance.global_position = Vector2(-140.0 if player_id == 1 else 140.0, -80.0)
	
	var initial_facing: float = 1.0 if player_id == 1 else -1.0
	instance.set_facing_direction(initial_facing)

func respawn_player(character: Character) -> void:
	if stage:
		character.reset_player(stage.get_spawn_position(character.player_id))
	else:
		character.reset_player(Vector2(-140.0 if character.player_id == 1 else 140.0, -80.0))
