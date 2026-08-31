class_name DamageCalculator
extends RefCounted

static func apply_damage(current_percentage: float, damage: float) -> float:
	return clamp(current_percentage + damage, 0.0, Constants.MAX_PERCENTAGE)
