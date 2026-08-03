# Explicación de `battle/spawn_manager.gd`

## Resumen
Gestor encargado de instanciar inicialmente a los luchadores y reaparecerlos (respawn) en sus respectivas coordenadas cuando pierden una vida.

## Explicación Línea por Línea
```gdscript
1: class_name SpawnManager
2: extends Node

4: @export var stage: Stage
```
- Referencia al escenario activo.

```gdscript
6: func spawn_player(character_scene: PackedScene, player_id: int, data: CharacterData) -> Character:
7: 	var instance: Character = character_scene.instantiate() as Character
8: 	instance.player_id = player_id
9: 	if stage: instance.global_position = stage.get_spawn_position(player_id)
10: 	if data: instance.character_data = data
11: 	return instance
```
- Instancia la escena base `Character.tscn`, asigna el `player_id` y su `CharacterData`, posicionándolo en el spawn del escenario.

```gdscript
13: func respawn_player(character: Character) -> void:
14: 	if stage:
15: 		character.reset_player(stage.get_spawn_position(character.player_id))
```
- Invoca `reset_player()` en el personaje para restablecer porcentaje a 0% y ubicarlo nuevamente en el punto de aparición.

## Comunicación e Interacciones
- **Comunica con**: `BattleScene.gd` y `BattleManager.gd`.
