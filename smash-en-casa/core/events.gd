class_name EventBus
extends Node

# EventBus Singleton - Sistema global de señales desacopladas

@warning_ignore("unused_signal")
signal player_damaged(player_id: int, new_percentage: float, attack_data: Resource)
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
signal parry_executed(player_id: int)
@warning_ignore("unused_signal")
signal shield_broken(player_id: int)

@warning_ignore("unused_signal")
signal match_started
@warning_ignore("unused_signal")
signal match_paused(is_paused: bool)
@warning_ignore("unused_signal")
signal camera_shake_requested(intensity: float)
