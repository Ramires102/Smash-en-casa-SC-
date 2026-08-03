extends Node

# EventBus Singleton - Sistema global de señales desacopladas

# Combate y Jugador
signal player_damaged(player_id: int, new_percentage: float, attack_data: Resource)
signal player_died(player_id: int)
signal stock_lost(player_id: int, remaining_lives: int)
signal game_over(winner_id: int)

# Ataques y Animaciones
signal attack_started(player_id: int, attack_data: Resource)
signal attack_active(player_id: int, attack_data: Resource)
signal attack_finished(player_id: int)

# Partida y Escenarios
signal match_started
signal match_paused(is_paused: bool)
signal camera_shake_requested(intensity: float)
