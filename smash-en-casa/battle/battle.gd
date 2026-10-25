class_name BattleScene
extends Node3D

@onready var stage: Stage = $Stage
@onready var spawn_manager: SpawnManager = $SpawnManager
@onready var battle_manager: BattleManager = $BattleManager
@onready var camera_controller: CameraController = $CameraController
@onready var hud: HUD = $CanvasLayer/HUD

@export var character_base_scene: PackedScene = preload("res://characters/character.tscn")

var spawned_characters: Dictionary = {} # pid -> Character

# Compatibilidad con accesos directos
var p1_character: Character:
	get:
		return spawned_characters.get(1, null)
var p2_character: Character:
	get:
		return spawned_characters.get(2, null)

func _ready() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_battle_theme"):
		am.play_battle_theme()

	var active_pids: Array[int] = GameManager.active_player_ids
	if active_pids.is_empty():
		active_pids = [1, 2]

	# Validar que al menos haya 2 luchadores seleccionados
	var valid_count: int = 0
	for pid in active_pids:
		if GameManager.get_player_data(pid) != null:
			valid_count += 1

	if valid_count < 2:
		push_warning("BattleScene: Se necesitan al menos 2 luchadores con datos validos.")
		get_tree().call_deferred("change_scene_to_file", "res://ui/character_select.tscn")
		return

	# Cargar escenario seleccionado
	var stage_path = GameManager.get_selected_stage_scene_path()
	if stage_path != "" and stage_path != "res://battle/stage.tscn":
		var stage_scene: PackedScene = load(stage_path)
		if stage_scene:
			var new_stage = stage_scene.instantiate() as Stage
			var old_stage = stage
			var idx = old_stage.get_index()
			remove_child(old_stage)
			old_stage.queue_free()
			add_child(new_stage)
			move_child(new_stage, idx)
			stage = new_stage

	spawned_characters.clear()

	# Spawnear cada jugador activo (hasta 4)
	for pid in active_pids:
		var p_data = GameManager.get_player_data(pid)
		if p_data == null:
			continue
		var ch: Character = spawn_manager.spawn_player(character_base_scene, pid, p_data)
		add_child(ch)
		spawn_manager.set_initial_transform(ch, pid)
		ch.percentage_changed.connect(func(val, player_id = pid): hud.update_player_percentage(player_id, val))
		ch.can_act = false
		spawned_characters[pid] = ch

	# Conectar cámara con todos los jugadores activos
	camera_controller.players.clear()
	for ch in spawned_characters.values():
		camera_controller.players.append(ch)

	# Conectar BattleManager
	battle_manager.stage = stage
	battle_manager.spawn_manager = spawn_manager
	battle_manager.lives_updated.connect(func(pid, lives): hud.update_lives(pid, lives))
	battle_manager.timer_updated.connect(func(t): hud.update_timer(t))
	battle_manager.match_finished.connect(_on_match_finished)

	battle_manager.setup_match_multi(spawned_characters, GameManager.stock_lives, GameManager.time_limit_seconds)

	# Conectar cuenta regresiva del HUD
	hud.countdown_finished.connect(func():
		battle_manager.start_battle()
		for ch in spawned_characters.values():
			ch.can_act = true
	)
	hud.start_countdown()

func _on_match_finished(winner_id: int) -> void:
	GameManager.end_match(winner_id)
	get_tree().call_deferred("change_scene_to_file", "res://ui/victory.tscn")
