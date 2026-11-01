# ==============================================================================
# KnockbackCalculator — Motor Matemático de Empuje, Hitstun y Hitlag
# ==============================================================================
# Implementa las ecuaciones de combate de un Platform Fighter estilo Smash Bros:
#   - A mayor % acumulado del defensor y menor peso, mayor velocidad de eyección.
#   - Calcula cuántos frames queda aturdido el defensor (Hitstun) y cuántos frames
#     se congelan ambos personajes en el instante del golpe (Hitlag / Hitstop).
# ==============================================================================
class_name KnockbackCalculator
extends RefCounted

const DEG_TO_RAD: float = PI / 180.0

## Ecuación principal de magnitud de Knockback estilo Super Smash Bros.
static func calculate_knockback_magnitude(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float
) -> float:
	# Normaliza recursos que guarden scaling como entero (ej. 100 -> 1.00)
	var growth: float = knockback_scaling / 100.0 if knockback_scaling > 1.5 else knockback_scaling
	var base_kb: float = base_knockback * 0.45 if base_knockback > 14.0 else base_knockback

	var weight_factor: float = 200.0 / (target_weight + 100.0)
	var percent_term: float = (target_percentage / 10.0) + ((target_percentage * attack_damage) / 20.0)
	var scaled_kb: float = percent_term * weight_factor * 1.35 * growth + base_kb
	return clampf(scaled_kb, 3.5, 34.0)

## Frames que el rival permanece sin poder actuar durante el vuelo tras recibir el golpe.
static func calculate_hitstun(kb: float) -> int:
	return clampi(int(round(kb * 1.65)), 10, 55)

## Frames de congelamiento de impacto (Hitstop) al conectar un golpe.
static func calculate_hitlag(damage: float, hitlag_modifier: float = 1.0) -> int:
	var base_stop: int = clampi(int(round(3.0 + damage * 0.35)), 3, 12)
	return maxi(2, int(round(float(base_stop) / maxf(0.25, hitlag_modifier))))

static func get_horizontal_velocity(kb: float, angle_deg: float) -> float:
	return (kb * Constants.UNIT_SIZE) * cos(angle_deg * DEG_TO_RAD)

static func get_vertical_velocity(kb: float, angle_deg: float) -> float:
	return (kb * Constants.UNIT_SIZE) * sin(angle_deg * DEG_TO_RAD)

static func get_horizontal_decay(angle_deg: float) -> float:
	return Constants.KB_DECAY_BASE * cos(angle_deg * DEG_TO_RAD) * 1000.0

static func get_vertical_decay(angle_deg: float) -> float:
	return absf(Constants.KB_DECAY_BASE * sin(angle_deg * DEG_TO_RAD) * 1000.0)

## Resuelve el código especial de Ángulo Sakurai (361° / -181°).
static func resolve_sakurai_angle(raw_angle: float, kb: float, target_in_air: bool) -> float:
	if raw_angle == Constants.SAKURAI_ANGLE:
		if kb > Constants.SAKURAI_KB_THRESHOLD:
			return Constants.SAKURAI_HIGH_AIR if target_in_air else Constants.SAKURAI_HIGH_GROUND
		return Constants.SAKURAI_LOW_AIR if target_in_air else Constants.SAKURAI_LOW_GROUND
	elif raw_angle == Constants.SAKURAI_ANGLE_NEG:
		if kb > Constants.SAKURAI_KB_THRESHOLD:
			return (-Constants.SAKURAI_HIGH_AIR + 180.0) if target_in_air else (-Constants.SAKURAI_HIGH_GROUND + 180.0)
		return (-Constants.SAKURAI_LOW_AIR + 180.0) if target_in_air else (-Constants.SAKURAI_LOW_GROUND + 180.0)
	return raw_angle

## Calcula de una sola vez velocidad inicial (vx, vy), desaceleración, hitstun y hitlag.
static func calculate_full_knockback(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float,
	raw_angle: float,
	hitlag_modifier: float,
	attacker_dir: float,
	target_in_air: bool
) -> Dictionary:
	var kb: float = calculate_knockback_magnitude(
		target_percentage, attack_damage, target_weight,
		base_knockback, knockback_scaling
	)
	var resolved_angle: float = resolve_sakurai_angle(raw_angle, kb, target_in_air)

	# En Godot 2D: X+ apunta a la derecha e Y- apunta hacia arriba (por eso se invierte el signo de angle)
	var dir_sign: float = -1.0 if attacker_dir < 0.0 else 1.0
	return {
		"kb": kb,
		"vx": get_horizontal_velocity(kb, -resolved_angle) * dir_sign,
		"vy": get_vertical_velocity(kb, -resolved_angle),
		"hdecay": get_horizontal_decay(-resolved_angle),
		"vdecay": get_vertical_decay(resolved_angle),
		"hitstun": calculate_hitstun(kb),
		"hitlag": calculate_hitlag(attack_damage, hitlag_modifier),
		"resolved_angle": resolved_angle
	}
