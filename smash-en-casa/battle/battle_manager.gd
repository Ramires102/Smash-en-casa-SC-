class_name BattleManager
extends Node

signal lives_updated(player_id: int, current_lives: int)
signal timer_updated(time_remaining: float)
signal match_finished(winner_id: int)

@export var stage: Stage
@export var spawn_manager: SpawnManager

var player_lives: Dictionary = {} # pid -> int
var characters: Dictionary = {}   # pid -> Character
var current_time: float = 480.0
var is_active: bool = false

# Compatibilidad con accesos directos
var player_1: Character:
	get:
		return characters.get(1, null)
	set(val):
		if val: characters[1] = val

var player_2: Character:
	get:
		return characters.get(2, null)
	set(val):
		if val: characters[2] = val

var p1_lives: int:
	get:
		return player_lives.get(1, 3)
	set(val):
		player_lives[1] = val

var p2_lives: int:
	get:
		return player_lives.get(2, 3)
	set(val):
		player_lives[2] = val

func setup_match(p1: Character, p2: Character, initial_lives: int = 3, time_limit: float = 480.0) -> void:
	setup_match_multi({1: p1, 2: p2}, initial_lives, time_limit)

func setup_match_multi(chars_dict: Dictionary, initial_lives: int = 3, time_limit: float = 480.0) -> void:
	characters.clear()
	player_lives.clear()
	is_ko_processing.clear()
	current_time = time_limit
	is_active = false

	for pid in chars_dict.keys():
		var ch: Character = chars_dict[pid]
		if ch:
			characters[pid] = ch
			player_lives[pid] = initial_lives

	if stage and not stage.blast_zone_entered.is_connected(_on_player_ko):
		stage.blast_zone_entered.connect(_on_player_ko)

	if not Events.time_freeze_requested.is_connected(_on_time_freeze_requested):
		Events.time_freeze_requested.connect(_on_time_freeze_requested)

	for pid in player_lives.keys():
		lives_updated.emit(pid, player_lives[pid])
	timer_updated.emit(current_time)

var time_freeze_timer: float = 0.0

func _on_time_freeze_requested(duration_sec: float, _instigator: Node) -> void:
	time_freeze_timer = maxf(time_freeze_timer, duration_sec)

func start_battle() -> void:
	is_active = true

func _process(delta: float) -> void:
	if not is_active:
		return
	
	if time_freeze_timer > 0.0:
		time_freeze_timer -= delta
		# El reloj de combate no corre durante Time Stop
		return

	current_time -= delta
	timer_updated.emit(max(0.0, current_time))
	
	if current_time <= 0.0:
		_end_match_by_time()

var is_ko_processing: Dictionary = {}

func _enter_death_state(character: Character) -> void:
	if character and character.state_machine:
		character.state_machine.transition_to("Death")

func _on_player_ko(character: Character) -> void:
	if not is_active or character == null:
		return
	var pid: int = character.player_id
	if is_ko_processing.get(pid, false):
		return

	is_ko_processing[pid] = true
	Events.camera_shake_requested.emit(10.0)
	_enter_death_state(character)

	# Rayo de partículas y haz luminoso desde la zona de muerte hacia el centro del mapa
	var death_pos_3d := Vector3(
		character.global_position.x / Constants.UNIT_SIZE,
		-character.global_position.y / Constants.UNIT_SIZE,
		0.0
	)
	var stage_center := Vector3(0.0, 1.5, 0.0)
	var streak = DeathStreakVFX.new()
	var parent_node = character.get_parent()
	if parent_node:
		parent_node.add_child(streak)
		streak.setup(death_pos_3d, stage_center)

	var remaining: int = player_lives.get(pid, 1) - 1
	player_lives[pid] = remaining
	lives_updated.emit(pid, remaining)

	var p1_l: int = player_lives.get(1, 0)
	var p2_l: int = player_lives.get(2, 0)
	Events.player_ko_event.emit(pid, death_pos_3d, p1_l, p2_l)

	if remaining <= 0:
		get_tree().create_timer(0.25).timeout.connect(func():
			_check_elimination_status()
			is_ko_processing[pid] = false
		)
	else:
		get_tree().create_timer(0.35).timeout.connect(func():
			if is_instance_valid(character) and is_active:
				spawn_manager.respawn_player(character)
			is_ko_processing[pid] = false
		)

func _check_elimination_status() -> void:
	if not is_active:
		return
	var alive_pids: Array[int] = []
	for pid in player_lives.keys():
		if player_lives[pid] > 0:
			alive_pids.append(pid)

	if alive_pids.size() == 1:
		_finish_game(alive_pids[0])
	elif alive_pids.is_empty():
		_finish_game(0) # Empate general

func _end_match_by_time() -> void:
	is_active = false
	var best_pid: int = -1
	var max_l: int = -1
	var min_dmg: float = INF

	for pid in player_lives.keys():
		var l: int = player_lives[pid]
		var ch: Character = characters.get(pid, null)
		var dmg: float = ch.damage_percentage if ch else 999.0
		if l > max_l:
			max_l = l
			min_dmg = dmg
			best_pid = pid
		elif l == max_l and dmg < min_dmg:
			min_dmg = dmg
			best_pid = pid

	_finish_game(best_pid if best_pid > 0 else 0)

func _finish_game(winner_id: int) -> void:
	is_active = false
	match_finished.emit(winner_id)
	GameManager.end_match(winner_id)
