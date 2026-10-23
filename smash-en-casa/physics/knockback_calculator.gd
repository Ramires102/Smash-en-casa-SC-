class_name KnockbackCalculator
extends RefCounted

const ANGLE_CONVERSION: float = PI / 180.0

## Normaliza knockback_scaling por si un recurso .tres usa escala 1.0 (multiplicador) o 100.0 (porcentaje)
static func _normalize_kb_scaling(raw_scaling: float) -> float:
	if raw_scaling <= 0.0:
		return 1.0
	if raw_scaling <= 5.0:
		return raw_scaling
	return raw_scaling / 100.0

# ── Fórmula de Knockback Escalar (Híbrida Smash + Escala 2D) ────────────
static func calculate_knockback_magnitude(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float
) -> float:
	var p: float = maxf(0.0, target_percentage)
	var d: float = maxf(1.0, attack_damage)
	var w: float = maxf(40.0, target_weight)
	var ks_mult: float = _normalize_kb_scaling(knockback_scaling)
	var bk: float = base_knockback

	# Si base_knockback fue cargado en escala chica (< 8.0), escalarlo proporcionalmente
	var normalized_bk: float = bk * 10.0 if (bk > 0.0 and bk < 6.0) else bk

	# Curva oficial de Smash Bros. adaptada a la escala /10 del proyecto
	var weight_factor: float = 200.0 / (w + 100.0)
	var percent_term: float = (p / 10.0) + ((p * d) / 18.0)
	var raw_kb: float = (((percent_term * weight_factor * 1.4) + 18.0) * ks_mult + normalized_bk) / 8.2

	return maxf(Constants.KB_MINIMUM_LAUNCH, raw_kb)

# ── Hitstun ─────────────────────────────────────────────────────────────
static func calculate_hitstun(kb: float) -> int:
	var frames: int = int(floor(kb * Constants.HITSTUN_MULTIPLIER))
	return maxi(Constants.HITSTUN_MIN_FRAMES, frames)

# ── Hitlag ──────────────────────────────────────────────────────────────
static func calculate_hitlag(damage: float, hitlag_modifier: float = 1.0) -> int:
	var mod: float = maxf(0.25, hitlag_modifier)
	var raw_frames: int = int(floor(((floor(damage) * Constants.HITLAG_DAMAGE_MULT) + Constants.HITLAG_BASE_FRAMES) / mod))
	return clampi(raw_frames, 3, Constants.HITLAG_MAX_FRAMES)

# ── Velocidad Horizontal de Lanzamiento ─────────────────────────────────
static func get_horizontal_velocity(kb: float, angle_deg: float) -> float:
	var initial_velocity: float = kb * Constants.KB_VELOCITY_SCALE
	var horizontal_velocity: float = initial_velocity * cos(angle_deg * ANGLE_CONVERSION)
	return round(horizontal_velocity * 1000.0) / 1000.0

# ── Velocidad Vertical de Lanzamiento ───────────────────────────────────
static func get_vertical_velocity(kb: float, angle_deg: float) -> float:
	var initial_velocity: float = kb * Constants.KB_VELOCITY_SCALE
	var vertical_velocity: float = initial_velocity * sin(angle_deg * ANGLE_CONVERSION)
	return round(vertical_velocity * 1000.0) / 1000.0

# ── Decay Horizontal (Siempre positivo para evitar aceleración inversa) ─
static func get_horizontal_decay(angle_deg: float) -> float:
	var decay: float = Constants.KB_DECAY_BASE * cos(angle_deg * ANGLE_CONVERSION)
	decay = round(decay * 100000.0) / 100000.0
	return absf(decay * 1000.0)

# ── Decay Vertical (Siempre positivo) ───────────────────────────────────
static func get_vertical_decay(angle_deg: float) -> float:
	var decay: float = Constants.KB_DECAY_BASE * sin(angle_deg * ANGLE_CONVERSION)
	decay = round(decay * 100000.0) / 100000.0
	return absf(decay * 1000.0)

# ── Ángulo Sakurai (361°) ───────────────────────────────────────────────
static func resolve_sakurai_angle(raw_angle: float, kb: float, target_in_air: bool) -> float:
	if is_equal_approx(raw_angle, Constants.SAKURAI_ANGLE) or is_equal_approx(raw_angle, Constants.SAKURAI_ANGLE_NEG):
		if kb > Constants.SAKURAI_KB_THRESHOLD:
			return Constants.SAKURAI_HIGH_AIR if target_in_air else Constants.SAKURAI_HIGH_GROUND
		else:
			return Constants.SAKURAI_LOW_AIR if target_in_air else Constants.SAKURAI_LOW_GROUND
	return raw_angle

# ── Angle Flippers 2D Corregidos ────────────────────────────────────────
static func apply_angle_flipper(
	flipper: int,
	kb: float,
	angle_deg: float,
	attacker_dir: float,
	attacker_pos: Vector2,
	target_pos: Vector2,
	hitbox_pos: Vector2
) -> Dictionary:
	var dir_sign: float = -1.0 if attacker_dir < 0.0 else 1.0
	var result: Dictionary = {"vx": 0.0, "vy": 0.0, "hdecay": 0.0, "vdecay": 0.0}

	match flipper:
		0: # Estándar: angle_deg se define mirando a la derecha (0°=adelante, 90°=arriba, 270°=spike abajo)
			var base_vx: float = get_horizontal_velocity(kb, angle_deg)
			var base_vy: float = -get_vertical_velocity(kb, angle_deg) # En 2D de Godot, Y negativo es hacia arriba
			result.vx = base_vx * dir_sign
			result.vy = base_vy
			result.hdecay = get_horizontal_decay(angle_deg)
			result.vdecay = get_vertical_decay(angle_deg)

		1, 2: # Radial desde/hacia el centro de la Hitbox
			var delta_vec: Vector2 = (target_pos - hitbox_pos) if flipper == 1 else (hitbox_pos - target_pos)
			if delta_vec.length_squared() < 1.0:
				delta_vec = Vector2(dir_sign, -0.5)
			var dir_norm: Vector2 = delta_vec.normalized()
			var speed: float = kb * Constants.KB_VELOCITY_SCALE
			result.vx = dir_norm.x * speed
			result.vy = dir_norm.y * speed
			var rad_deg: float = rad_to_deg(atan2(-dir_norm.y, absf(dir_norm.x)))
			result.hdecay = get_horizontal_decay(rad_deg)
			result.vdecay = get_vertical_decay(rad_deg)

		3, 4: # Hacia el centro del atacante (3) o alejándose del centro del atacante (4)
			var away_sign: float = signf(target_pos.x - attacker_pos.x)
			if is_zero_approx(away_sign):
				away_sign = dir_sign
			var final_dir: float = -away_sign if flipper == 3 else away_sign
			result.vx = absf(get_horizontal_velocity(kb, angle_deg)) * final_dir
			result.vy = -get_vertical_velocity(kb, angle_deg)
			result.hdecay = get_horizontal_decay(angle_deg)
			result.vdecay = get_vertical_decay(angle_deg)

		5: # Reverse Hit (invierte dirección horizontal)
			result.vx = -get_horizontal_velocity(kb, angle_deg) * dir_sign
			result.vy = -get_vertical_velocity(kb, angle_deg)
			result.hdecay = get_horizontal_decay(angle_deg)
			result.vdecay = get_vertical_decay(angle_deg)

		6, 7: # Autolink / Empuje relativo al atacante
			var rel_sign: float = signf(target_pos.x - attacker_pos.x)
			if is_zero_approx(rel_sign):
				rel_sign = dir_sign
			var horiz_sign: float = -rel_sign if flipper == 6 else rel_sign
			result.vx = absf(get_horizontal_velocity(kb, angle_deg)) * horiz_sign
			result.vy = -get_vertical_velocity(kb, angle_deg)
			result.hdecay = get_horizontal_decay(angle_deg)
			result.vdecay = get_vertical_decay(angle_deg)

	return result

# ── Hitlag DI (Directional Influence Perpendicular Real) ────────────────
static func apply_hitlag_di(knockback_vector: Vector2, di_input: Vector2) -> Dictionary:
	var speed: float = knockback_vector.length()
	if speed <= 0.001:
		return {
			"vector": knockback_vector,
			"hdecay": 0.0,
			"vdecay": 0.0,
			"angle_deg": 0.0
		}

	if di_input.length() < Constants.HITLAG_DI_DEADZONE:
		return _build_di_result_from_vector(knockback_vector)

	# En coordenadas 2D de Godot (Y negativo = arriba), convertimos el stick del jugador
	# (donde arriba es +Y) al espacio 2D de pantalla (arriba es -Y):
	var stick_2d := Vector2(clampf(di_input.x, -1.0, 1.0), -clampf(di_input.y, -1.0, 1.0)).normalized()
	var launch_dir := knockback_vector.normalized()

	# El DI real en Smash es máximo cuando el stick es PERPENDICULAR al vector de lanzamiento
	var cross_factor: float = launch_dir.cross(stick_2d)
	var angle_offset: float = cross_factor * Constants.HITLAG_DI_ANGLE_INFLUENCE

	var rotated_dir: Vector2 = launch_dir.rotated(angle_offset)

	# Ligerísima modulación de velocidad según qué tan alineado está el stick (TDI)
	var dot_factor: float = launch_dir.dot(stick_2d)
	var adjusted_speed: float = speed * (1.0 + dot_factor * Constants.HITLAG_DI_SPEED_INFLUENCE)

	return _build_di_result_from_vector(rotated_dir * adjusted_speed)

static func _build_di_result_from_vector(launch_vector: Vector2) -> Dictionary:
	var vector_angle_deg: float = rad_to_deg(atan2(-launch_vector.y, absf(launch_vector.x)))
	return {
		"vector": launch_vector,
		"hdecay": get_horizontal_decay(vector_angle_deg),
		"vdecay": get_vertical_decay(vector_angle_deg),
		"angle_deg": vector_angle_deg
	}

# ── API Principal 2D ────────────────────────────────────────────────────
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
