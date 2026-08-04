# Explicación de `battle/stage.gd`

## Resumen
Script del escenario 3D. Mantiene las referencias a los puntos de spawn de P1 y P2 (`SpawnP1`, `SpawnP2`) y gestiona el área de detección de límites `BlastZone` (`Area3D`) tanto por señales (`body_exited` y `body_entered`) como por comprobación física de respaldo.

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
11: func _ready() -> void:
12: 	if blast_zone:
13: 		blast_zone.body_entered.connect(_on_blast_zone_body_entered)
14: 		blast_zone.body_exited.connect(_on_blast_zone_body_exited)
```
- Conecta tanto `body_entered` como `body_exited` para capturar cualquier cruce de frontera de los luchadores fuera del escenario.

```gdscript
24: func _physics_process(_delta: float) -> void:
25: 	var parent_node := get_parent()
26: 	if parent_node:
27: 		for child in parent_node.get_children():
28: 			if child is Character and child.visible:
29: 				if child.global_position.y < -15.0 or abs(child.global_position.x) > 30.0:
30: 					blast_zone_entered.emit(child)
```
- Verificación física de seguridad que emite `blast_zone_entered` si un personaje cae por debajo de $Y < -15.0$ o sobrepasa los laterales $|X| > 30.0$.

```gdscript
32: func get_spawn_position(player_id: int) -> Vector3:
33: 	if player_id == 1 and spawn_p1: return spawn_p1.global_position
34: 	elif player_id == 2 and spawn_p2: return spawn_p2.global_position
35: 	return Vector3(0, 5, 0)
```
- Retorna la posición $Vector3$ de spawn correspondiente a cada jugador.

## Comunicación e Interacciones
- **Comunica con**: `BattleManager.gd` (notificando KOs) y `SpawnManager.gd`.
