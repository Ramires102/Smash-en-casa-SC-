class_name KnockbackCalculator
extends RefCounted

const ANGLE_CONVERSION: float = PI / 180.0

# ── Ecuación exacta de KnockbackCalculator.calculateKnockback (knockback_calculator.ts) ──
static func calculate_knockback_magnitude(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float
) -> float:
	# Si un recurso viejo tenía knockback_scaling en escala 80..120 en vez de 0.08..0.19, normalizarlo
	var growth: float = knockback_scaling / 100.0 if knockback_scaling > 1.5 else knockback_scaling
	var base_kb: float = base_knockback * 0.45 if base_knockback > 14.0 else base_knockback

	var weight_factor: float = 200.0 / (target_weight + 100.0)
	var percent_term: float = (target_percentage / 10.0) + ((target_percentage * attack_damage) / 20.0)
	var scaled_kb: float = percent_term * weight_factor * 1.35 * growth + base_kb
	return clampf(scaled_kb, 3.5, 34.0)

# ── Hitstun exacto de DamageCalculator.calculateHitstunFrames (damage_calculator.ts) ──
static func calculate_hitstun(kb: float) -> int:
	return clampi(int(round(kb * 1.65)), 10, 55)

# ── Hitlag exacto de DamageCalculator.calculateHitstopFrames (damage_calculator.ts) ──
static func calculate_hitlag(damage: float, hitlag_modifier: float = 1.0) -> int:
	var base_stop: int = clampi(int(round(3.0 + damage * 0.35)), 3, 12)
	return maxi(2, int(round(float(base_stop) / maxf(0.25, hitlag_modifier))))

static func get_horizontal_velocity(kb: float, angle: float) -> float:
	var initial_velocity: float = kb * Constants.UNIT_SIZE
	return initial_velocity * cos(angle * ANGLE_CONVERSION)

static func get_vertical_velocity(kb: float, angle: float) -> float:
	var initial_velocity: float = kb * Constants.UNIT_SIZE
	return initial_velocity * sin(angle * ANGLE_CONVERSION)

static func get_horizontal_decay(angle: float) -> float:
	return Constants.KB_DECAY_BASE * cos(angle * ANGLE_CONVERSION) * 1000.0

static func get_vertical_decay(angle: float) -> float:
	return absf(Constants.KB_DECAY_BASE * sin(angle * ANGLE_CONVERSION) * 1000.0)

static func resolve_sakurai_angle(raw_angle: float, kb: float, target_in_air: bool) -> float:
	if raw_angle == Constants.SAKURAI_ANGLE:
		if kb > Constants.SAKURAI_KB_THRESHOLD:
			return Constants.SAKURAI_HIGH_AIR if target_in_air else Constants.SAKURAI_HIGH_GROUND
		else:
			return Constants.SAKURAI_LOW_AIR if target_in_air else Constants.SAKURAI_LOW_GROUND
	elif raw_angle == Constants.SAKURAI_ANGLE_NEG:
		if kb > Constants.SAKURAI_KB_THRESHOLD:
			return (-Constants.SAKURAI_HIGH_AIR + 180.0) if target_in_air else (-Constants.SAKURAI_HIGH_GROUND + 180.0)
		else:
			return (-Constants.SAKURAI_LOW_AIR + 180.0) if target_in_air else (-Constants.SAKURAI_LOW_GROUND + 180.0)
	return raw_angle

static func apply_angle_flipper(
	_flipper: int,
	kb: float,
	angle: float,
	_attacker_dir: float,
	_attacker_pos: Vector2,
	_target_pos: Vector2,
	_hitbox_pos: Vector2
) -> Dictionary:
	# En Godot 2D: X+ es derecha, Y- es arriba (por eso usamos -angle para sen/cos)
	var dir_sign: float = -1.0 if _attacker_dir < 0.0 else 1.0
	return {
		"vx": get_horizontal_velocity(kb, -angle) * dir_sign,
		"vy": get_vertical_velocity(kb, -angle),
		"hdecay": get_horizontal_decay(-angle),
		"vdecay": get_vertical_decay(angle)
	}

static func apply_hitlag_di(knockback_vector: Vector2, _di_input: Vector2) -> Dictionary:
	var vector_angle_deg: float = rad_to_deg(atan2(knockback_vector.y, knockback_vector.x))
	return {
		"vector": knockback_vector,
		"hdecay": get_horizontal_decay(vector_angle_deg),
		"vdecay": get_vertical_decay(-vector_angle_deg),
		"angle_deg": -vector_angle_deg
	}

static func calculate_full_knockback(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float,
	raw_angle: float,
	angle_flipper: int,
	hitlag_modifier: float,
	attacker_dir: float,
	attacker_pos: Vector2,
	target_pos: Vector2,
	hitbox_pos: Vector2,
	target_in_air: bool
) -> Dictionary:
	var kb: float = calculate_knockback_magnitude(
		target_percentage, attack_damage, target_weight,
		base_knockback, knockback_scaling
	)
	var resolved_angle: float = resolve_sakurai_angle(raw_angle, kb, target_in_air)
	var flipper_result: Dictionary = apply_angle_flipper(
		angle_flipper, kb, resolved_angle,
		attacker_dir, attacker_pos, target_pos, hitbox_pos
	)
	var hitstun: int = calculate_hitstun(kb)
	var hitlag: int = calculate_hitlag(attack_damage, hitlag_modifier)

	return {
		"kb": kb,
		"vx": flipper_result.vx,
		"vy": flipper_result.vy,
		"hdecay": flipper_result.hdecay,
		"vdecay": flipper_result.vdecay,
		"hitstun": hitstun,
		"hitlag": hitlag,
		"resolved_angle": resolved_angle
	}
