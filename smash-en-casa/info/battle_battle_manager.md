# Explicación de `battle/battle_manager.gd`

## Resumen
Árbitro central de la partida. Supervisa las vidas (stocks) de P1 y P2, el temporizador regresivo de combate, la detección de KOs mediante las BlastZones del escenario, los reaparecimientos (respawns) con control de reingreso (debounce) y declara al ganador al finalizar las vidas o el tiempo.

## Explicación Línea por Línea
```gdscript
1: class_name BattleManager
2: extends Node

4: signal lives_updated(player_id: int, current_lives: int)
5: signal timer_updated(time_remaining: float)
6: signal match_finished(winner_id: int)
```
- Señales emitidas para mantener al HUD y al sistema de victoria informados.

```gdscript
40: var is_ko_processing: Dictionary = {}

42: func _on_player_ko(character: Character) -> void:
43: 	if not is_active or character == null: return
44: 	var pid: int = character.player_id
45: 	if is_ko_processing.get(pid, false): return
46: 	is_ko_processing[pid] = true
47: 	Events.camera_shake_requested.emit(10.0)
```
- Filtra eventos duplicados durante el procesamiento del KO, activa sacudida de cámara e inicia la pérdida de vida.

```gdscript
49: 	if pid == 1:
50: 		p1_lives -= 1
51: 		lives_updated.emit(1, p1_lives)
52: 		if p1_lives <= 0: _finish_game(2)
53: 		else:
54: 			spawn_manager.respawn_player(character)
55: 			get_tree().create_timer(0.5).timeout.connect(func(): is_ko_processing[1] = false)
```
- Descuenta la vida, notifica al HUD y reaparece al luchador o declara la victoria del rival si se agotaron los stocks.

## Comunicación e Interacciones
- **Escucha a**: `Stage.gd` (`blast_zone_entered`).
- **Comunica con**: `HUD.gd`, `SpawnManager.gd`, `GameManager.gd`, `Events.gd`.
