class_name BattleManager
extends Node

signal lives_updated(player_id: int, current_lives: int)
signal timer_updated(time_remaining: float)
signal match_finished(winner_id: int)

@export var stage: Stage
@export var spawn_manager: SpawnManager

var p1_lives: int = 3
var p2_lives: int = 3
var current_time: float = 480.0
var is_active: bool = false

var player_1: Character
var player_2: Character

func setup_match(p1: Character, p2: Character, initial_lives: int = 3, time_limit: float = 480.0) -> void:
	player_1 = p1
	player_2 = p2
	p1_lives = initial_lives
	p2_lives = initial_lives
	current_time = time_limit
	is_active = true

	if stage:
		stage.blast_zone_entered.connect(_on_player_ko)

	lives_updated.emit(1, p1_lives)
	lives_updated.emit(2, p2_lives)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	current_time -= delta
	timer_updated.emit(max(0.0, current_time))
	
	if current_time <= 0.0:
		_end_match_by_time()

var is_ko_processing: Dictionary = {}

func _on_player_ko(character: Character) -> void:
	if not is_active or character == null:
		return
	var pid: int = character.player_id
	if is_ko_processing.get(pid, false):
		return

	is_ko_processing[pid] = true
	Events.camera_shake_requested.emit(10.0)

	if pid == 1:
		p1_lives -= 1
		lives_updated.emit(1, p1_lives)
		if p1_lives <= 0:
			_finish_game(2) # P2 gana
		else:
			spawn_manager.respawn_player(character)
			get_tree().create_timer(0.5).timeout.connect(func(): is_ko_processing[1] = false)
	elif pid == 2:
		p2_lives -= 1
		lives_updated.emit(2, p2_lives)
		if p2_lives <= 0:
			_finish_game(1) # P1 gana
		else:
			spawn_manager.respawn_player(character)
			get_tree().create_timer(0.5).timeout.connect(func(): is_ko_processing[2] = false)

func _end_match_by_time() -> void:
	is_active = false
	if p1_lives > p2_lives:
		_finish_game(1)
	elif p2_lives > p1_lives:
		_finish_game(2)
	else:
		# Empate por muerte súbita / menor porcentaje
		if player_1 and player_2:
			if player_1.damage_percentage <= player_2.damage_percentage:
				_finish_game(1)
			else:
				_finish_game(2)
		else:
			_finish_game(0)

func _finish_game(winner_id: int) -> void:
	is_active = false
	match_finished.emit(winner_id)
	GameManager.end_match(winner_id)
