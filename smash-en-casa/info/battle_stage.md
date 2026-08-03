# Explicación de `battle/stage.gd`

## Resumen
Script del escenario 3D. Mantiene las referencias a los puntos de spawn de P1 y P2 (`SpawnP1`, `SpawnP2`) y gestiona el área de detección de límites `BlastZone` (`Area3D`).

## Explicación Línea por Línea
```gdscript
1: class_name Stage
2: extends Node3D

4: signal blast_zone_entered(body: Node3D)
5: @export var stage_name: String = "Escenario Principal"
6: @onready var spawn_p1: Node3D = $SpawnP1
7: @onready var spawn_p2: Node3D = $SpawnP2
8: @onready var blast_zone: Area3D = $BlastZone
```
- Define la señal `blast_zone_entered` y las referencias a los nodos de spawn y blast zone.

```gdscript
10: func _ready() -> void:
11: 	if blast_zone:
12: 		blast_zone.body_entered.connect(_on_blast_zone_body_entered)

14: func _on_blast_zone_body_entered(body: Node3D) -> void:
15: 	if body is Character:
16: 		blast_zone_entered.emit(body)
```
- Escucha cuando un `Character` sale de los límites de la arena y cruza la `BlastZone`, emitiendo la señal `blast_zone_entered`.

```gdscript
18: func get_spawn_position(player_id: int) -> Vector3:
19: 	if player_id == 1 and spawn_p1: return spawn_p1.global_position
20: 	elif player_id == 2 and spawn_p2: return spawn_p2.global_position
21: 	return Vector3(0, 5, 0)
```
- Retorna la posición $Vector3$ de spawn correspondiente a cada jugador.

## Comunicación e Interacciones
- **Comunica con**: `BattleManager.gd` (notificando KOs) y `SpawnManager.gd`.
