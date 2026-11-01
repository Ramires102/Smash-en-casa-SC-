# ==============================================================================
# BattleManager — Árbitro de Reglas de Combate en Tiempo Real
# ==============================================================================
# Controla el transcurso del enfrentamiento:
#   - Descuenta el temporizador de la partida (deteniéndose durante Time Stop).
#   - Escucha Stage.blast_zone_entered cuando un jugador cae al vacío (KO).
#   - Dispara efectos de muerte (DeathStreakVFX + Camera Shake), resta vidas,
#     coordina el reaparecimiento (SpawnManager) y declara al ganador.
# ==============================================================================
class_name BattleManager
extends Node

signal lives_updated(player_id: int, current_lives: int)
signal timer_updated(time_remaining: float)
signal match_finished(winner_id: int)

@export var stage: Stage
@export var spawn_manager: SpawnManager

var player_lives: Dictionary = {}    # player_id -> vidas restantes
var characters: Dictionary = {}      # player_id -> Character
var is_ko_processing: Dictionary = {} # player_id -> bool (evita doble KO en un mismo frame)

var current_time: float = 480.0
var time_freeze_timer: float = 0.0
var is_active: bool = false

func _exit_tree() -> void:
	if Events.time_freeze_requested.is_connected(_on_time_freeze_requested):
		Events.time_freeze_requested.disconnect(_on_time_freeze_requested)

#region Configuración e Inicio de Combate
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

func start_battle() -> void:
	is_active = true

func _on_time_freeze_requested(duration_sec: float, _instigator: Node) -> void:
	time_freeze_timer = maxf(time_freeze_timer, duration_sec)

func _process(delta: float) -> void:
	if not is_active:
		return

	# El reloj oficial de combate se congela durante "El Mundo" de Sakuya
	if time_freeze_timer > 0.0:
		time_freeze_timer -= delta
		return

	current_time -= delta
	timer_updated.emit(maxf(0.0, current_time))

	if current_time <= 0.0:
		_end_match_by_time()
#endregion

#region Gestión de KOs, Respawn y Condiciones de Victoria
func _on_player_ko(character: Character) -> void:
	if not is_active or character == null:
		return
	var pid: int = character.player_id
	if is_ko_processing.get(pid, false):
		return

	is_ko_processing[pid] = true
	Events.camera_shake_requested.emit(10.0)
	if character.state_machine:
		character.state_machine.transition_to("Death")

	# Dispara el haz luminoso de eliminación estilo Smash Bros desde el borde hacia el centro
	var death_pos_3d: Vector3 = Utils.pos_2d_to_3d(character.global_position)
	var parent_node: Node = character.get_parent()
	if parent_node:
		var streak := DeathStreakVFX.new()
		parent_node.add_child(streak)
		streak.setup(death_pos_3d, Vector3(0.0, 1.5, 0.0))

	var remaining: int = int(player_lives.get(pid, 1)) - 1
	player_lives[pid] = remaining
	lives_updated.emit(pid, remaining)
	Events.player_ko_event.emit(pid, death_pos_3d)

	if remaining <= 0:
		get_tree().create_timer(0.25).timeout.connect(func() -> void:
			_check_elimination_status()
			is_ko_processing[pid] = false
		)
	else:
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if is_instance_valid(character) and is_active and spawn_manager:
				spawn_manager.respawn_player(character)
			is_ko_processing[pid] = false
		)

func _check_elimination_status() -> void:
	if not is_active:
		return
	var alive_pids: Array[int] = []
	for pid in player_lives.keys():
		if int(player_lives[pid]) > 0:
			alive_pids.append(pid)

	if alive_pids.size() == 1:
		_finish_game(alive_pids[0])
	elif alive_pids.is_empty():
		_finish_game(0) # Empate simultáneo

## Si se agota el tiempo, gana quien conserve más vidas (y a igual vidas, menor % de daño).
func _end_match_by_time() -> void:
	is_active = false
	var best_pid: int = -1
	var max_lives: int = -1
	var min_dmg: float = INF

	for pid in player_lives.keys():
		var lives: int = int(player_lives[pid])
		var ch: Character = characters.get(pid, null)
		var dmg: float = ch.damage_percentage if ch else 999.0
		if lives > max_lives or (lives == max_lives and dmg < min_dmg):
			max_lives = lives
			min_dmg = dmg
			best_pid = pid

	_finish_game(best_pid if best_pid > 0 else 0)

func _finish_game(winner_id: int) -> void:
	is_active = false
	match_finished.emit(winner_id)
#endregion
