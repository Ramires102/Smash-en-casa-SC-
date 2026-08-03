# Explicación de `battle/battle_manager.gd`

## Resumen
Árbitro central de la partida. Supervisa las vidas (stocks) de P1 y P2, el temporizador regresivo de combate, la detección de KOs mediante las BlastZones del escenario, los reaparecimientos (respawns) y determina el ganador al finalizar el tiempo o las vidas.

## Explicación Línea por Línea
```gdscript
1: class_name BattleManager
2: extends Node

4: signal lives_updated(player_id: int, current_lives: int)
5: signal timer_updated(time_remaining: float)
6: signal match_finished(winner_id: int)
```
- Señales emitidas para mantener al HUD y al sistema de victoria informados en todo momento.

```gdscript
8: @export var stage: Stage
9: @export var spawn_manager: SpawnManager
10: var p1_lives: int = 3
11: var p2_lives: int = 3
12: var current_time: float = 480.0
13: var is_active: bool = false
```
- Variables de control de reglas.

```gdscript
18: func setup_match(p1: Character, p2: Character, initial_lives: int = 3, time_limit: float = 480.0) -> void:
19: 	player_1 = p1
20: 	player_2 = p2
21: 	p1_lives = initial_lives
22: 	p2_lives = initial_lives
23: 	current_time = time_limit
24: 	is_active = true
25: 	if stage: stage.blast_zone_entered.connect(_on_player_ko)
```
- Inicia el combate, registra a ambos luchadores y conecta la señal `blast_zone_entered` del escenario.

```gdscript
39: func _on_player_ko(character: Character) -> void:
40: 	if not is_active: return
41: 	if character.player_id == 1:
42: 		p1_lives -= 1
43: 		lives_updated.emit(1, p1_lives)
44: 		if p1_lives <= 0: _finish_game(2)
45: 		else: spawn_manager.respawn_player(character)
```
- Al detectar que un personaje cruzó la `BlastZone`, descuenta 1 vida, actualiza el HUD y decide si reaparecerlo o declarar KO definitivo.

```gdscript
67: func _finish_game(winner_id: int) -> void:
68: 	is_active = false
69: 	match_finished.emit(winner_id)
70: 	GameManager.end_match(winner_id)
```
- Declara al ganador y notifica a `GameManager`.

## Comunicación e Interacciones
- **Escucha a**: `Stage.gd` (`blast_zone_entered`).
- **Comunica con**: `HUD.gd`, `SpawnManager.gd`, `GameManager.gd`.
