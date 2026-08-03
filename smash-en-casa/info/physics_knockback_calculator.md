# Explicación de `physics/knockback_calculator.gd`

## Resumen
Calculadora matemática pura (stateless utility) para computar el vector de impulso y lanzamiento ($Vector3$) de los golpes basándose en la fórmula oficial de retroceso estilo Super Smash Bros.

## Explicación Línea por Línea
```gdscript
1: class_name KnockbackCalculator
2: extends RefCounted

5: static func calculate_knockback_vector(
6: 	target_percentage: float,
7: 	attack_damage: float,
8: 	target_weight: float,
9: 	base_knockback: float,
10: 	knockback_scaling: float,
11: 	angle_degrees: float,
12: 	facing_direction: float
13: ) -> Vector3:
```
- Función estática pura `calculate_knockback_vector` que recibe el estado del combate y devuelve la velocidad de impulso en tres dimensiones $Vector3$.

```gdscript
14: 	var percent_factor: float = (target_percentage * 0.1) + (target_percentage * attack_damage * 0.05)
15: 	var weight_factor: float = 200.0 / (target_weight + 100.0)
16: 	var magnitude: float = ((percent_factor * weight_factor * 1.4) + base_knockback) * knockback_scaling
```
- Implementación de la ecuación de física:
  - A mayor porcentaje de daño del objetivo, mayor magnitud de lanzamiento.
  - A mayor peso del personaje objetivo (`target_weight`), menor será `weight_factor`, reduciendo el retroceso recibido.

```gdscript
18: 	var rad: float = deg_to_rad(angle_degrees)
19: 	var dir_x: float = cos(rad) * facing_direction
20: 	var dir_y: float = sin(rad)
21: 	return Vector3(dir_x * magnitude, dir_y * magnitude, 0.0)
```
- Convierte el ángulo en radianes y calcula las componentes horizontal ($X$) y vertical ($Y$) multiplicadas por la orientación del atacante (`facing_direction`). Retorna el vector $Vector3$ con $Z=0$.

## Comunicación e Interacciones
- **Consumido por**: `Character.gd` dentro de `on_hit_received()`.
