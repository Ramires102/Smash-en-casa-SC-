# Explicación de `core/events.gd` (EventBus Singleton)

## Resumen
Patrón **EventBus** global implementado como Autoload (`Events`). Permite la comunicación totalmente desacoplada entre sistemas: los personajes emiten eventos (`player_damaged`, `attack_started`, `attack_blocked`, `parry_executed`, `shield_broken`, `player_died`), mientras que la UI (HUD), los administradores (`BattleManager`) y los efectos de sonido/cámara escuchan sin necesidad de mantener referencias directas entre nodos.

## Explicación Línea por Línea
```gdscript
1: extends Node

# Combate y Jugador
4: signal player_damaged(player_id: int, new_percentage: float, impact: ImpactData)
5: signal player_died(player_id: int)
6: signal stock_lost(player_id: int, remaining_lives: int)
7: signal game_over(winner_id: int)

# Ataques y Animaciones
10: signal attack_started(player_id: int, attack_data: Resource)
11: signal attack_active(player_id: int, attack_data: Resource)
12: signal attack_finished(player_id: int)
13: signal attack_blocked(player_id: int, attacker_id: int)
14: signal parry_executed(player_id: int)
15: signal shield_broken(player_id: int)

# Partida y Escenarios
18: signal match_started
19: signal match_paused(is_paused: bool)
20: signal camera_shake_requested(intensity: float)
```

## Comunicación e Interacciones
- **Emitido por**: `Character.gd`, `AttackController.gd`, `BattleManager.gd`.
- **Escuchado por**: `HUD.gd`, `CameraController.gd`, `ScreenShake.gd`, `AudioManager.gd`.
