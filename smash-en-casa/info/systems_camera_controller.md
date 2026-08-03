# Explicación de `systems/camera_controller.gd`

## Resumen
Controlador de cámara 2.5D que persigue el punto medio entre Jugador 1 y Jugador 2, ajustando la distancia (zoom Z) dinámicamente según la separación horizontal y vertical entre ellos.

## Explicación Línea por Línea
```gdscript
1: class_name CameraController
2: extends Camera3D

4: @export var player_1: Node3D
5: @export var player_2: Node3D
6: @export var min_distance: float = 12.0
7: @export var max_distance: float = 24.0
8: @export var margin: float = 4.0
9: @export var smooth_speed: float = 5.0
```
- Referencias exportadas a ambos luchadores y parámetros de distancia mínima/máxima y suavizado `lerp`.

```gdscript
11: func _physics_process(delta: float) -> void:
12: 	if not player_1 or not player_2: return
13: 	var p1_pos: Vector3 = player_1.global_position
14: 	var p2_pos: Vector3 = player_2.global_position
15: 	var center: Vector3 = (p1_pos + p2_pos) * 0.5
16: 	center.z = 0.0
```
- Calcula el centro geométrico $(P1 + P2) / 2$ y bloquea Z en 0.

```gdscript
18: 	var distance: float = p1_pos.distance_to(p2_pos)
19: 	var target_z: float = clamp(distance + margin, min_distance, max_distance)
20: 	var target_pos := Vector3(center.x, center.y + 2.0, target_z)
21: 	global_position = global_position.lerp(target_pos, smooth_speed * delta)
```
- Ajusta el zoom en el eje Z mediante la distancia entre luchadores y suaviza el encuadre usando interpolación lineal `lerp`.

## Comunicación e Interacciones
- **Sigue a**: `Character.gd` (P1 y P2).
