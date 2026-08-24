class_name KnockbackCalculator
extends RefCounted

## Calculadora matemática de empuje y físicas de combate calibradas para Godot 3D.
## Fórmulas canónicas de Super Smash Bros (SSBWiki) adaptadas a la escala del escenario.

# Constantes de combate calibradas
const MAX_DI_ANGLE_DEGREES: float = 18.0          # Influencia direccional máxima (Trajectory DI)
const BASE_DECAY_RATE: float = 42.0              # Tasa de desaceleración de lanzamiento (m/s²)
const LAUNCH_SPEED_SCALING: float = 0.55         # Factor de conversión KB escalar -> Velocidad en m/s

## Calcula el valor escalar de Knockback según la fórmula oficial de Super Smash Bros Ultimate
## KB = (((p/10 + p*d/20) * 200/(w+100) * 1.4) + base_kb) * scaling
static func calculate_knockback_magnitude(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float
) -> float:
	var w: float = maxf(target_weight, 1.0)
	var p: float = maxf(target_percentage, 0.0)
	var d: float = maxf(attack_damage, 0.0)
	
	# Factor porcentual escalado con el peso del defensor
	var percent_factor: float = (p * 0.1) + ((p * d) * 0.05)
	var weight_factor: float = 200.0 / (w + 100.0)
	
	var kb: float = ((percent_factor * weight_factor * 1.4) + base_knockback) * knockback_scaling
	return maxf(kb, 0.0)

## Calcula el ángulo final aplicando Directional Influence (DI) del defensor
static func apply_trajectory_di(base_angle_deg: float, di_input: Vector2, facing_dir: float) -> float:
	var angle_deg: float = base_angle_deg
	if facing_dir < 0.0:
		# Reflejar ángulo horizontal si mira a la izquierda
		angle_deg = 180.0 - angle_deg
		if angle_deg < 0.0:
			angle_deg += 360.0
	
	if di_input.length_squared() < 0.04:
		return angle_deg
	
	var stick_rad: float = atan2(di_input.y, di_input.x)
	var launch_rad: float = deg_to_rad(angle_deg)
	
	# La influencia es perpendicular a la trayectoria de lanzamiento
	var angle_diff: float = stick_rad - launch_rad
	var di_offset_deg: float = sin(angle_diff) * di_input.length() * MAX_DI_ANGLE_DEGREES
	
	return angle_deg + di_offset_deg

## Calcula el vector de velocidad inicial de lanzamiento en unidades de Godot (m/s)
static func calculate_knockback_vector(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float,
	angle_degrees: float,
	facing_direction: float,
	di_input: Vector2 = Vector2.ZERO,
	_speed_scale: float = 6.0
) -> Vector3:
	var kb_magnitude: float = calculate_knockback_magnitude(
		target_percentage,
		attack_damage,
		target_weight,
		base_knockback,
		knockback_scaling
	)
	
	# Aplicar Directional Influence (DI)
	var final_angle_deg: float = apply_trajectory_di(angle_degrees, di_input, facing_direction)
	var rad: float = deg_to_rad(final_angle_deg)
	
	# Convertir Knockback escalar a Launch Speed en m/s
	var launch_speed: float = kb_magnitude * LAUNCH_SPEED_SCALING
	
	var vx: float = cos(rad) * launch_speed
	var vy: float = sin(rad) * launch_speed
	
	return Vector3(vx, vy, 0.0)

## Devuelve la tasa de deceleración de knockback por segundo en unidades de Godot
static func get_knockback_decay_rate(_speed_scale: float = 6.0) -> float:
	return BASE_DECAY_RATE
