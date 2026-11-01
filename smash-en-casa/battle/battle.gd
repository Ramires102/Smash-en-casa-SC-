# ==============================================================================
# BattleScene — Coordinador Principal de la Escena de Combate
# ==============================================================================
# Ensambla la partida al cargar battle.tscn:
#   1. Inicia el tema musical de combate (AudioManager).
#   2. Carga el escenario 3D/2D seleccionado en GameManager.
#   3. Instancia de 2 a 4 personajes mediante SpawnManager y los conecta al HUD
#      y a la cámara dinámica (CameraController).
#   4. Ejecuta la cuenta regresiva ("3, 2, 1, ¡SMASH!") antes de habilitar controles.
# ==============================================================================
class_name BattleScene
extends Node3D

@onready var stage: Stage = $Stage
@onready var spawn_manager: SpawnManager = $SpawnManager
@onready var battle_manager: BattleManager = $BattleManager
@onready var camera_controller: CameraController = $CameraController
@onready var hud: HUD = $CanvasLayer/HUD

@export var character_base_scene: PackedScene = preload("res://characters/character.tscn")

## Diccionario player_id (1..4) -> nodo Character vivo en escena.
var spawned_characters: Dictionary = {}

func _ready() -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_battle_theme"):
		am.play_battle_theme()

	var active_pids: Array[int] = GameManager.active_player_ids
	if active_pids.is_empty():
		active_pids = [1, 2]

	if not _has_minimum_valid_players(active_pids):
		push_warning("BattleScene: Se necesitan al menos 2 luchadores con datos válidos.")
		get_tree().call_deferred("change_scene_to_file", "res://ui/character_select.tscn")
		return

	_load_selected_stage()
	_spawn_active_players(active_pids)
	_wire_systems_and_start_countdown()

func _has_minimum_valid_players(active_pids: Array[int]) -> bool:
	var valid_count: int = 0
	for pid in active_pids:
		if GameManager.get_player_data(pid) != null:
			valid_count += 1
	return valid_count >= 2

func _load_selected_stage() -> void:
	var stage_path: String = GameManager.get_selected_stage_scene_path()
	if stage_path.is_empty() or stage_path == "res://battle/stage.tscn":
		return
	var stage_scene: PackedScene = load(stage_path)
	if stage_scene == null:
		return

	var new_stage: Stage = stage_scene.instantiate() as Stage
	var old_stage: Stage = stage
	var idx: int = old_stage.get_index()
	remove_child(old_stage)
	old_stage.queue_free()
	add_child(new_stage)
	move_child(new_stage, idx)
	stage = new_stage

func _spawn_active_players(active_pids: Array[int]) -> void:
	spawned_characters.clear()
	spawn_manager.stage = stage

	for pid in active_pids:
		var p_data: CharacterData = GameManager.get_player_data(pid) as CharacterData
		if p_data == null:
			continue
		var ch: Character = spawn_manager.spawn_player(character_base_scene, pid, p_data)
		add_child(ch)
		spawn_manager.set_initial_transform(ch, pid)
		ch.percentage_changed.connect(func(val: float, player_id: int = pid) -> void:
			hud.update_player_percentage(player_id, val)
		)
		ch.can_act = false
		spawned_characters[pid] = ch

func _wire_systems_and_start_countdown() -> void:
	camera_controller.players.clear()
	for ch in spawned_characters.values():
		camera_controller.players.append(ch)

	battle_manager.stage = stage
	battle_manager.spawn_manager = spawn_manager
	battle_manager.lives_updated.connect(func(pid: int, lives: int) -> void: hud.update_lives(pid, lives))
	battle_manager.timer_updated.connect(func(t: float) -> void: hud.update_timer(t))
	battle_manager.match_finished.connect(_on_match_finished)

	battle_manager.setup_match_multi(spawned_characters, GameManager.stock_lives, GameManager.time_limit_seconds)

	hud.countdown_finished.connect(func() -> void:
		battle_manager.start_battle()
		for ch in spawned_characters.values():
			ch.can_act = true
	)
	hud.start_countdown()

func _on_match_finished(winner_id: int) -> void:
	# Único punto donde se cierra la partida y se registra en el Leaderboard
	GameManager.end_match(winner_id)
	get_tree().call_deferred("change_scene_to_file", "res://ui/victory.tscn")
