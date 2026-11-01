# Explicación de `core/events.gd` (EventBus Singleton)

## Resumen
Patrón **EventBus (Observer)** global implementado como Autoload (`Events`). Permite la comunicación desacoplada entre sistemas: los personajes y el árbitro emiten eventos clave de partida, mientras que el HUD, la cámara y los efectos visuales reaccionan sin mantener referencias cruzadas directas.

## Señales Activas (`core/events.gd`)
```gdscript
extends Node

# Eventos de Jugador y Combate
signal player_died(player_id: int)
signal player_ko_event(player_id: int, death_pos_3d: Vector3)
signal stock_lost(player_id: int, remaining_lives: int)
signal game_over(winner_id: int)

# Eventos de Escudo y Defensa
signal parry_executed(player_id: int)
signal shield_broken(player_id: int)

# Eventos Globales de Cámara y Partida
signal match_paused(is_paused: bool)
signal camera_shake_requested(intensity: float)
signal dramatic_zoom_requested(target_pos_3d: Vector3, duration: float)
```

## Comunicación e Interacciones
- **Emitido por**: `Character`, `ShieldController`, `BattleManager`, `GameManager`.
- **Escuchado por**: `HUD`, `Battle`, `CameraController`, `PauseMenu`.
