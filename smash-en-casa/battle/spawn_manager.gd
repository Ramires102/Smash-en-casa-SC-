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
		match player_id:
			1: instance.global_position = Vector2(-170.0, -80.0)
			2: instance.global_position = Vector2(170.0, -80.0)
			3: instance.global_position = Vector2(-65.0, -80.0)
			4: instance.global_position = Vector2(65.0, -80.0)
			_: instance.global_position = Vector2(0.0, -80.0)
	
	var initial_facing: float = 1.0 if (player_id % 2 != 0) else -1.0
	instance.set_facing_direction(initial_facing)

func respawn_player(character: Character) -> void:
	if stage:
		character.reset_player(stage.get_spawn_position(character.player_id))
	else:
		match character.player_id:
			1: character.reset_player(Vector2(-170.0, -80.0))
			2: character.reset_player(Vector2(170.0, -80.0))
			3: character.reset_player(Vector2(-65.0, -80.0))
			4: character.reset_player(Vector2(65.0, -80.0))
			_: character.reset_player(Vector2(0.0, -80.0))
