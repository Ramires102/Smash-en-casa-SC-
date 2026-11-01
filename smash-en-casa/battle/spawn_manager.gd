# ==============================================================================
# SpawnManager — Instanciación y Reaparición de Luchadores
# ==============================================================================
# Crea las instancias de Character al inicio del combate y las reposiciona en
# las coordenadas de aparición del escenario tanto al arrancar como tras un KO.
# ==============================================================================
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
	instance.global_position = _resolve_spawn_position(player_id)
	var initial_facing: float = 1.0 if (player_id % 2 != 0) else -1.0
	instance.set_facing_direction(initial_facing)

func respawn_player(character: Character) -> void:
	character.reset_player(_resolve_spawn_position(character.player_id))

func _resolve_spawn_position(player_id: int) -> Vector2:
	if stage:
		return stage.get_spawn_position(player_id)
	return Stage.get_default_spawn_position(player_id)
