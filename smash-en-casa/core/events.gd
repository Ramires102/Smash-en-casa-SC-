class_name EventBus
extends Node

# EventBus Singleton - Sistema global de señales desacopladas

@warning_ignore("unused_signal")
signal player_damaged(player_id: int, new_percentage: float, impact: ImpactData)
@warning_ignore("unused_signal")
signal player_died(player_id: int)
@warning_ignore("unused_signal")
signal stock_lost(player_id: int, remaining_lives: int)
@warning_ignore("unused_signal")
signal game_over(winner_id: int)

@warning_ignore("unused_signal")
signal attack_started(player_id: int, attack_data: Resource)
@warning_ignore("unused_signal")
signal attack_active(player_id: int, attack_data: Resource)
@warning_ignore("unused_signal")
signal attack_finished(player_id: int)
@warning_ignore("unused_signal")
signal attack_blocked(player_id: int, attacker_id: int)

@warning_ignore("unused_signal")
signal shield_broken(player_id: int)


@warning_ignore("unused_signal")
signal camera_shake_requested(intensity: float)
@warning_ignore("unused_signal")
signal time_freeze_requested(duration_sec: float, instigator: Node)
@warning_ignore("unused_signal")
signal time_stop_started(duration_sec: float, instigator: Node)
@warning_ignore("unused_signal")
signal time_stop_ended

var is_time_stopped: bool = false
var time_stop_instigator: Node = null
var time_stop_remaining_sec: float = 0.0

func trigger_time_stop(duration_sec: float, instigator: Node) -> void:
	is_time_stopped = true
	time_stop_instigator = instigator
	time_stop_remaining_sec = duration_sec
	time_freeze_requested.emit(duration_sec, instigator)
	time_stop_started.emit(duration_sec, instigator)

func _process(delta: float) -> void:
	if is_time_stopped:
		time_stop_remaining_sec -= delta
		if time_stop_remaining_sec <= 0.0:
			is_time_stopped = false
			time_stop_instigator = null
			time_stop_ended.emit()
