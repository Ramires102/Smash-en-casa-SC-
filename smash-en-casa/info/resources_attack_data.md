# Explicación de `resources/attack_data.gd`

## Resumen
Definición del Resource de Ataques. Contiene los parámetros numéricos de daño, física de retroceso, frame data de animación, daño extra a escudos (`bonus_shield_damage`), multiplicadores aéreos (`is_aerial`) y audio de cada movimiento.

## Explicación Línea por Línea
```gdscript
1: class_name AttackData
2: extends Resource

4: @export var attack_name: String = "Neutral Attack"
5: @export var damage: float = 8.0
6: @export var base_knockback: float = 15.0
7: @export var knockback_scaling: float = 1.0
8: @export var angle_degrees: float = 45.0
```
- Daño en porcentaje (ej. 8.0%), retroceso base constante, escala de empuje con porcentaje acumulado y ángulo de salida en grados.

```gdscript
9: @export var startup_frames: int = 4
10: @export var active_frames: int = 6
11: @export var recovery_frames: int = 10
```
- Frame Data clásico de juegos de pelea: inicio, ventana activa y recuperación.

```gdscript
12: @export var animation_name: String = "AttackNeutral"
13: @export var hit_sfx: AudioStream
14: @export var bonus_shield_damage: float = 0.0
15: @export var is_aerial: bool = false
```
- `bonus_shield_damage`: Daño adicional directo al escudo (ej. rompedores de escudo como Marth Shield Breaker).
- `is_aerial`: Define si el ataque es aéreo para calcular el multiplicador de Shieldstun ($0.33\times$ para aéreos, $1.0\times$ para terrestres).

## Comunicación e Interacciones
- **Contenido en**: `MoveSet.gd`.
- **Enviado por**: `Hitbox.gd` hacia `Hurtbox.gd` -> `Character.gd` -> `KnockbackCalculator.gd`.
