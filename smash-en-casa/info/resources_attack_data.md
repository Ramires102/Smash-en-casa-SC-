# Explicación de `resources/attack_data.gd`

## Resumen
Definición del Resource de Ataques. Contiene los parámetros numéricos de daño, física de retroceso, frame data de animación y audio de cada movimiento.

## Explicación Línea por Línea
```gdscript
1: class_name AttackData
2: extends Resource
```
- Define un nuevo tipo de recurso editable desde la interfaz del editor de Godot (Inspector).

```gdscript
4: @export var attack_name: String = "Neutral Attack"
5: @export var damage: float = 8.0
6: @export var base_knockback: float = 15.0
7: @export var knockback_scaling: float = 1.0
8: @export var angle_degrees: float = 45.0
```
- Daño en porcentaje (ej. 8.0%), retroceso base constante, escala de empuje con porcentaje acumulado y ángulo de salida en grados (45° por defecto).

```gdscript
9: @export var startup_frames: int = 4
10: @export var active_frames: int = 6
11: @export var recovery_frames: int = 10
```
- Frame Data clásico de juegos de pelea:
  - `startup_frames`: Duración del inicio del golpe antes de conectar.
  - `active_frames`: Duración de la ventana donde la Hitbox está activa.
  - `recovery_frames`: Tiempo de recuperación pos-ataque.

```gdscript
12: @export var animation_name: String = "AttackNeutral"
13: @export var hit_sfx: AudioStream
```
- Nombre de la animación a reproducir y efecto de sonido al impactar la Hurtbox.

## Comunicación e Interacciones
- **Contenido en**: `MoveSet.gd`.
- **Enviado por**: `Hitbox.gd` hacia `Hurtbox.gd` -> `Character.gd` -> `KnockbackCalculator.gd`.
