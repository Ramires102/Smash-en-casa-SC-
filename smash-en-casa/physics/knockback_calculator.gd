class_name KnockbackCalculator
extends RefCounted

# Calculadora pura matemática de empuje (Formula estilo Smash Bros)
# F = (((% * Daño)/10 + (% * Daño)/20) * (200 / (Peso + 100)) * 1.4) + BaseKnockback

static func calculate_knockback_vector(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float,
	angle_degrees: float,
	facing_direction: float
) -> Vector3:
	var percent_factor: float = (target_percentage * 0.1) + (target_percentage * attack_damage * 0.05)
	var weight_factor: float = 200.0 / (target_weight + 100.0)
	var magnitude: float = ((percent_factor * weight_factor * 1.4) + base_knockback) * knockback_scaling
	
	var rad: float = deg_to_rad(angle_degrees)
	var dir_x: float = cos(rad) * facing_direction
	var dir_y: float = sin(rad)
	
	return Vector3(dir_x * magnitude, dir_y * magnitude, 0.0)
