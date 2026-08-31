class_name KnockbackCalculator
extends RefCounted

## Calculadora de knockback 2D pura porteada 1:1 desde Splash N Dash (Hitboxes.gd).
## Todas las fórmulas operan en espacio de coordenadas 2D de Godot (X derecho +, Y abajo +).

const ANGLE_CONVERSION: float = PI / 180.0  ## Hitboxes.gd:98

# ── Fórmula de Knockback Escalar (Hitboxes.gd:178-188) ──────────────────
# KB = ((kb_scaling/100) * ((14 * (p+d) * (d+2)) / (w+100) + 18) + base_kb) / 10
# p = target percentage tras recibir el daño, d = damage, w = weight
static func calculate_knockback_magnitude(
	target_percentage: float,
	attack_damage: float,
	target_weight: float,
	base_knockback: float,
	knockback_scaling: float
) -> float:
	var p: float = target_percentage
	var d: float = attack_damage
	var w: float = target_weight
	var ks: float = knockback_scaling
	var bk: float = base_knockback
	return ((ks / 100.0) * ((((14.0 * (p + d) * (d + 2.0))) / (w + 100.0)) + 18.0) + bk) / 10.0

# ── Hitstun (Hitboxes.gd:99-100) ──────────────────────────────────────
# getHitstun(knockback / 0.3) → floor(knockback / 0.3 * 0.4)
# = floor(knockback * 1.33333)
static func calculate_hitstun(kb: float) -> int:
	return int(floor(kb / 0.3 * 0.4))

# ── Hitlag (Hitboxes.gd:90-93) ────────────────────────────────────────
# hitlag(d, hit) → floor(((floor(d) * 0.65) + 6) / hit)
static func calculate_hitlag(damage: float, hitlag_modifier: float = 1.0) -> int:
	return int(floor(((floor(damage) * 0.65) + 6.0) / hitlag_modifier))

# ── Velocidad Horizontal de Lanzamiento (Hitboxes.gd:120-127) ────────
# initialVelocity = knockback * 30
# horizontalVelocity = initialVelocity * cos(angle * PI/180)
static func get_horizontal_velocity(kb: float, angle: float) -> float:
	var initial_velocity: float = kb * Constants.KB_VELOCITY_SCALE
	var horizontal_angle: float = cos(angle * ANGLE_CONVERSION)
	var horizontal_velocity: float = initial_velocity * horizontal_angle
	horizontal_velocity = round(horizontal_velocity * 100000.0) / 100000.0
	return horizontal_velocity

# ── Velocidad Vertical de Lanzamiento (Hitboxes.gd:129-136) ──────────
# verticalVelocity = initialVelocity * sin(angle * PI/180)
static func get_vertical_velocity(kb: float, angle: float) -> float:
	var initial_velocity: float = kb * Constants.KB_VELOCITY_SCALE
	var vertical_angle: float = sin(angle * ANGLE_CONVERSION)
	var vertical_velocity: float = initial_velocity * vertical_angle
	vertical_velocity = round(vertical_velocity * 100000.0) / 100000.0
	return vertical_velocity

# ── Decay Horizontal (Hitboxes.gd:108-112) ────────────────────────────
# decay = 0.051 * cos(angle * PI/180); decay = round(decay*100000)/100000; decay *= 1000
static func get_horizontal_decay(angle: float) -> float:
	var decay: float = Constants.KB_DECAY_BASE * cos(angle * ANGLE_CONVERSION)
	decay = round(decay * 100000.0) / 100000.0
	decay = decay * 1000.0
	return decay

# ── Decay Vertical (Hitboxes.gd:114-118) ──────────────────────────────
# decay = 0.051 * sin(angle * PI/180); decay = round(decay*100000)/100000; decay *= 1000; return abs(decay)
static func get_vertical_decay(angle: float) -> float:
	var decay: float = Constants.KB_DECAY_BASE * sin(angle * ANGLE_CONVERSION)
	decay = round(decay * 100000.0) / 100000.0
	decay = decay * 1000.0
	return abs(decay)

# ── Ángulo Sakurai / S-Angle (Hitboxes.gd:190-213) ───────────────────
# Ángulo 361 y -181 se resuelven dinámicamente según KB y estado aéreo/terrestre
static func resolve_sakurai_angle(raw_angle: float, kb: float, target_in_air: bool) -> float:
	if raw_angle == Constants.SAKURAI_ANGLE:
		# Hitboxes.gd:191-201
		if kb > Constants.SAKURAI_KB_THRESHOLD:
			return Constants.SAKURAI_HIGH_AIR if target_in_air else Constants.SAKURAI_HIGH_GROUND
		else:
			return Constants.SAKURAI_LOW_AIR if target_in_air else Constants.SAKURAI_LOW_GROUND
	elif raw_angle == Constants.SAKURAI_ANGLE_NEG:
		# Hitboxes.gd:202-212 — ángulo negado: (-angle) + 180
		if kb > Constants.SAKURAI_KB_THRESHOLD:
			if target_in_air:
				return (-Constants.SAKURAI_HIGH_AIR) + 180.0
			else:
				return (-Constants.SAKURAI_HIGH_GROUND) + 180.0
		else:
			if target_in_air:
				return (-Constants.SAKURAI_LOW_AIR) + 180.0
			else:
				return (-Constants.SAKURAI_LOW_GROUND) + 180.0
	return raw_angle

# ── Angle Flippers 2D (Hitboxes.gd:217-284) ─────────────────────────
# Calcula el vector de lanzamiento 2D y decays según el modo de angle flipper.
# attacker_pos, target_pos, hitbox_pos: Vector2 en world space
# attacker_dir: 1.0 o -1.0
static func apply_angle_flipper(
	flipper: int,
	kb: float,
	angle: float,
	attacker_dir: float,
	attacker_pos: Vector2,
	target_pos: Vector2,
	hitbox_pos: Vector2
) -> Dictionary:
	var result: Dictionary = {"vx": 0.0, "vy": 0.0, "hdecay": 0.0, "vdecay": 0.0}
	var xangle: float = 0.0
	
	match flipper:
		0: # Hitboxes.gd:224-228 — Trayectoria estándar
			result.vx = get_horizontal_velocity(kb, -angle)
			result.vy = get_vertical_velocity(kb, -angle)
			result.hdecay = get_horizontal_decay(-angle)
			result.vdecay = get_vertical_decay(angle)
			
		1: # Hitboxes.gd:229-237 — Lanzamiento alejándose del centro de la Hitbox (hitbox -> target)
			if attacker_dir == -1.0:
				xangle = -(hitbox_pos.angle_to_point(target_pos) * 180.0 / PI)
			else:
				xangle = (hitbox_pos.angle_to_point(target_pos) * 180.0 / PI)
			result.vx = get_horizontal_velocity(kb, xangle + 180.0)
			result.vy = get_vertical_velocity(kb, -xangle)
			result.hdecay = get_horizontal_decay(angle + 180.0)
			result.vdecay = get_vertical_decay(xangle)
			
		2: # Hitboxes.gd:240-248 — Lanzamiento hacia el centro de la Hitbox (target -> hitbox)
			if attacker_dir == -1.0:
				xangle = -(target_pos.angle_to_point(hitbox_pos) * 180.0 / PI)
			else:
				xangle = (target_pos.angle_to_point(hitbox_pos) * 180.0 / PI)
			result.vx = get_horizontal_velocity(kb, -xangle + 180.0)
			result.vy = get_vertical_velocity(kb, -xangle)
			result.hdecay = get_horizontal_decay(xangle + 180.0)
			result.vdecay = get_vertical_decay(xangle)
			
		3: # Hitboxes.gd:251-259 — Hacia el centro horizontal del atacante
			if attacker_dir == -1.0:
				xangle = -(target_pos.angle_to_point(hitbox_pos) * 180.0 / PI) + 180.0
			else:
				xangle = (target_pos.angle_to_point(hitbox_pos) * 180.0 / PI)
			result.vx = get_horizontal_velocity(kb, xangle)
			result.vy = get_vertical_velocity(kb, -angle)
			result.hdecay = get_horizontal_decay(xangle)
			result.vdecay = get_vertical_decay(angle)
			
		4: # Hitboxes.gd:260-268 — Alejándose del centro horizontal del atacante
			if attacker_dir == -1.0:
				xangle = -(target_pos.angle_to_point(hitbox_pos) * 180.0 / PI) + 180.0
			else:
				xangle = (target_pos.angle_to_point(hitbox_pos) * 180.0 / PI)
			result.vx = get_horizontal_velocity(kb, -xangle * 180.0)
			result.vy = get_vertical_velocity(kb, -angle)
			result.hdecay = get_horizontal_decay(angle)
			result.vdecay = get_vertical_decay(angle)
			
		5: # Hitboxes.gd:269-273 — Ángulo invertido horizontalmente
			result.vx = get_horizontal_velocity(kb, angle + 180.0)
			result.vy = get_vertical_velocity(kb, -angle)
			result.hdecay = get_horizontal_decay(angle + 180.0)
			result.vdecay = get_vertical_decay(angle)
			
		6: # Hitboxes.gd:274-278 — Lanzamiento horizontal directo hacia el atacante
			if attacker_dir == -1.0:
				xangle = -(target_pos.angle_to_point(attacker_pos) * 180.0 / PI)
			else:
				xangle = (target_pos.angle_to_point(attacker_pos) * 180.0 / PI)
			result.vx = get_horizontal_velocity(kb, xangle)
			result.vy = get_vertical_velocity(kb, -angle)
			result.hdecay = get_horizontal_decay(xangle)
			result.vdecay = get_vertical_decay(angle)
			
		7: # Hitboxes.gd:280-284 — Lanzamiento horizontal directo alejándose del atacante
			if attacker_dir == -1.0:
				xangle = -(target_pos.angle_to_point(attacker_pos) * 180.0 / PI)
			else:
				xangle = (target_pos.angle_to_point(attacker_pos) * 180.0 / PI)
			result.vx = get_horizontal_velocity(kb, -xangle + 180.0)
			result.vy = get_vertical_velocity(kb, -angle)
			result.hdecay = get_horizontal_decay(angle)
			result.vdecay = get_vertical_decay(angle)
	
	return result

# ── Hitlag DI (influencia direccional durante freeze) ─────────────────────
# Basado en PlatformFighter: input horizontal rota el ángulo de salida,
# input vertical modifica levemente la velocidad resultante.
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

	var di_x: float = clampf(di_input.x, -1.0, 1.0)
	var di_y_pf: float = -clampf(di_input.y, -1.0, 1.0)
	var launch_angle_rad: float = atan2(knockback_vector.y, knockback_vector.x)
	var adjusted_angle_rad: float = launch_angle_rad + (Constants.HITLAG_DI_ANGLE_INFLUENCE * di_x)

	var adjusted_vector: Vector2 = Vector2(cos(adjusted_angle_rad), sin(adjusted_angle_rad)) * speed

	# El input Y interno usa arriba(+)/abajo(-); se invierte para mantener el
	# mismo sentido de modificación de velocidad que PlatformFighter.
	adjusted_vector -= adjusted_vector * (Constants.HITLAG_DI_SPEED_INFLUENCE * di_y_pf)

	return _build_di_result_from_vector(adjusted_vector)

static func _build_di_result_from_vector(launch_vector: Vector2) -> Dictionary:
	var vector_angle_deg: float = rad_to_deg(atan2(launch_vector.y, launch_vector.x))
	return {
		"vector": launch_vector,
		"hdecay": get_horizontal_decay(vector_angle_deg),
		"vdecay": get_vertical_decay(-vector_angle_deg),
		"angle_deg": -vector_angle_deg
	}

# ── API Principal 2D ────────────────────────────────────────────────
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
	# 1. Calcular KB escalar
	var kb: float = calculate_knockback_magnitude(
		target_percentage, attack_damage, target_weight,
		base_knockback, knockback_scaling
	)
	
	# 2. Resolver Sakurai angle
	var resolved_angle: float = resolve_sakurai_angle(raw_angle, kb, target_in_air)
	
	# 3. Aplicar angle flipper en 2D
	var flipper_result: Dictionary = apply_angle_flipper(
		angle_flipper, kb, resolved_angle,
		attacker_dir, attacker_pos, target_pos, hitbox_pos
	)
	
	# 4. Calcular hitstun y hitlag
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

