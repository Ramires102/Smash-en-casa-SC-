class_name DamageCalculator
extends RefCounted

static func apply_damage(current_percentage: float, damage: float) -> float:
	return clamp(current_percentage + damage, 0.0, Constants.MAX_PERCENTAGE)

## Calcula frames de hitstun según el knockback recibido (6 a 60 frames)
static func calculate_hitstun_frames(knockback_magnitude: float) -> int:
	return clampi(int(floor(knockback_magnitude * 0.35)), 6, 60)

## Calcula frames de hitlag (freeze de impacto) según el daño (3 a 16 frames)
static func calculate_hitlag_frames(damage: float) -> int:
	return clampi(int(floor(damage * 0.5 + 3)), 3, 16)
