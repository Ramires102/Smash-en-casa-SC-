# Explicación de `core/game_manager.gd`

## Resumen
Es el Autoload (Singleton) principal que mantiene el estado global del juego (personajes seleccionados para P1 y P2, vidas iniciales, tiempo límite, pausa y estado de partida).

## Explicación Línea por Línea
```gdscript
1: extends Node
```
- Hereda de `Node` para ser registrado en la raíz del árbol de escenas (`/root/GameManager`).

```gdscript
3: signal match_started
4: signal match_ended(winner_id: int)
5: signal pause_toggled(is_paused: bool)
```
- Señales globales para notificar el inicio de la partida, el fin con el ID del ganador y el cambio de estado de pausa.

```gdscript
7: # Configuración de partida
8: var player_1_data: Resource = null
9: var player_2_data: Resource = null
10: var stock_lives: int = 3
11: var time_limit_seconds: float = 480.0 # 8 minutos
12: var is_paused: bool = false
13: var winner_player_id: int = -1
```
- Variables globales para almacenar las configuraciones elegidas en las pantallas de UI y transmitirlas a la escena de batalla.

```gdscript
15: func _ready() -> void:
16: 	process_mode = Node.PROCESS_MODE_ALWAYS
```
- `process_mode = PROCESS_MODE_ALWAYS`: Garantiza que `GameManager` siga ejecutándose aun cuando la escena del juego se pause con `get_tree().paused = true`.

```gdscript
18: func toggle_pause() -> void:
19: 	is_paused = !is_paused
20: 	get_tree().paused = is_paused
21: 	pause_toggled.emit(is_paused)
```
- Alterna el estado de pausa del motor y emite la señal `pause_toggled`.

```gdscript
23: func start_match(p1_data: Resource, p2_data: Resource, lives: int = 3, timer: float = 480.0) -> void:
24: 	player_1_data = p1_data
25: 	player_2_data = p2_data
26: 	stock_lives = lives
27: 	time_limit_seconds = timer
28: 	winner_player_id = -1
29: 	match_started.emit()
```
- Guarda los `CharacterData` de P1 y P2 elegidos en el menú de selección e inicia la partida.

```gdscript
31: func end_match(winner_id: int) -> void:
32: 	winner_player_id = winner_id
33: 	match_ended.emit(winner_id)
```
- Registra el ganador final (1, 2 o 0 para empate) y emite la señal de cierre.

## Comunicación e Interacciones
- **Emite señales a**: `BattleScene`, `HUD`, `PauseMenu`.
- **Llamado por**: `CharacterSelect.gd` (para iniciar combate), `BattleManager.gd` (al terminar combate), `PauseMenu.gd` (al pausar).
