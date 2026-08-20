class_name BattleScene
extends Node3D

@onready var stage: Stage = $Stage
@onready var spawn_manager: SpawnManager = $SpawnManager
@onready var battle_manager: BattleManager = $BattleManager
@onready var camera_controller: CameraController = $CameraController
@onready var hud: HUD = $CanvasLayer/HUD

@export var character_base_scene: PackedScene = preload("res://characters/character.tscn")

var p1_character: Character
var p2_character: Character

func _ready() -> void:
	var p1_data: CharacterData = GameManager.player_1_data
	if p1_data == null:
		p1_data = preload("res://resources/instances/john_placeholder_data.tres")
		
	var p2_data: CharacterData = GameManager.player_2_data
	if p2_data == null:
		p2_data = preload("res://resources/instances/gogeta_data.tres")

	p1_character = spawn_manager.spawn_player(character_base_scene, 1, p1_data)
	p2_character = spawn_manager.spawn_player(character_base_scene, 2, p2_data)

	add_child(p1_character)
	add_child(p2_character)

	spawn_manager.set_initial_transform(p1_character, 1)
	spawn_manager.set_initial_transform(p2_character, 2)

	# Conectar cámara
	camera_controller.player_1 = p1_character
	camera_controller.player_2 = p2_character

	# Conectar HUD a señales de los luchadores
	p1_character.percentage_changed.connect(func(val): hud.update_player_percentage(1, val))
	p2_character.percentage_changed.connect(func(val): hud.update_player_percentage(2, val))

	# Conectar BattleManager
	battle_manager.stage = stage
	battle_manager.spawn_manager = spawn_manager
	battle_manager.lives_updated.connect(func(pid, lives): hud.update_lives(pid, lives))
	battle_manager.timer_updated.connect(func(t): hud.update_timer(t))
	battle_manager.match_finished.connect(_on_match_finished)
	
	battle_manager.setup_match(p1_character, p2_character, GameManager.stock_lives, GameManager.time_limit_seconds)

func _on_match_finished(_winner_id: int) -> void:
	get_tree().call_deferred("change_scene_to_file", "res://ui/victory.tscn")
