# Explicación de `systems/screen_shake.gd`

## Resumen
Sistema visual para generar temblores y sacudidas de cámara ante impactos de alto retroceso (knockback).

## Explicación Línea por Línea
```gdscript
1: class_name ScreenShake
2: extends Node

4: @export var camera: Camera3D
5: var shake_intensity: float = 0.0
6: var shake_decay: float = 5.0
7: var rng := RandomNumberGenerator.new()
```
- Referencia a la cámara y variables de atenuación exponencial de la sacudida.

```gdscript
9: func _process(delta: float) -> void:
10: 	if shake_intensity > 0.0 and camera:
11: 		camera.h_offset = rng.randf_range(-shake_intensity, shake_intensity)
12: 		camera.v_offset = rng.randf_range(-shake_intensity, shake_intensity)
13: 		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
14: 	elif camera:
15: 		camera.h_offset = 0.0
16: 		camera.v_offset = 0.0
```
- Modifica aleatoriamente `h_offset` y `v_offset` de la `Camera3D` mientras `shake_intensity > 0`.

```gdscript
18: func trigger_shake(intensity: float = 0.5) -> void:
19: 	shake_intensity = intensity
```
- Dispara la sacudida con una intensidad personalizada.

## Comunicación e Interacciones
- **Modifica**: `Camera3D`. Invocado por eventos de golpe fuerte.
