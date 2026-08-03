# Explicación de `battle/battle.gd`

## Resumen
Script principal del nivel de combate (`Battle.tscn`). Instancia y ensambla todos los módulos: recupera los datos de `GameManager`, invoca a `SpawnManager` para crear los luchadores, conecta los eventos al `HUD` y `CameraController`, y arranca el `BattleManager`.

## Explicación Línea por Línea
```gdscript
1: class_name BattleScene
2: extends Node3D

4: @onready var stage: Stage = $Stage
5: @onready var spawn_manager: SpawnManager = $SpawnManager
6: @onready var battle_manager: BattleManager = $BattleManager
7: @onready var camera_controller: CameraController = $CameraController
8: @onready var hud: HUD = $CanvasLayer/HUD
```
- Referencias `@onready` a los subsistemas presentes en la escena.

```gdscript
15: func _ready() -> void:
16: 	var p1_data: CharacterData = GameManager.player_1_data
17: 	var p2_data: CharacterData = GameManager.player_2_data
18: 	p1_character = spawn_manager.spawn_player(character_base_scene, 1, p1_data)
19: 	p2_character = spawn_manager.spawn_player(character_base_scene, 2, p2_data)
20: 	add_child(p1_character)
21: 	add_child(p2_character)
```
- Lee la selección de personajes almacenada en `GameManager`, los instancia y los agrega al árbol de escena.

```gdscript
24: 	camera_controller.player_1 = p1_character
25: 	camera_controller.player_2 = p2_character
```
- Asigna los objetivos a la cámara 2.5D para su seguimiento dinámico.

```gdscript
28: 	p1_character.percentage_changed.connect(func(val): hud.update_player_percentage(1, val))
29: 	p2_character.percentage_changed.connect(func(val): hud.update_player_percentage(2, val))
```
- Conecta las señales de daño en % de ambos luchadores directamente al HUD.

```gdscript
39: func _on_match_finished(_winner_id: int) -> void:
40: 	get_tree().change_scene_to_file("res://ui/victory.tscn")
```
- Cambia a la escena de Victoria al finalizar la partida.

## Comunicación e Interacciones
- **Orquestador principal**: Integra `GameManager`, `Stage`, `SpawnManager`, `BattleManager`, `CameraController` y `HUD`.
