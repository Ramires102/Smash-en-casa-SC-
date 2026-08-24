class_name CharacterController
extends Node

@export var character: CharacterBody3D
@export var facing_angle: float = 90.0

# Smash Ultimate physics (loaded from CharacterData)
var run_speed: float = 1.76
var walk_speed: float = 1.05
var initial_dash_speed: float = 1.98
var traction: float = 0.08
var jump_velocity: float = 14.0
var short_hop_velocity: float = 10.5
var air_speed: float = 1.0
var air_acceleration: float = 0.05
var air_friction: float = 0.01
var smash_gravity: float = 0.09
var smash_fall_speed: float = 1.60
var smash_fast_fall_speed: float = 2.56

# Escala para convertir unidades de Smash a unidades de Godot 3D
const SPEED_SCALE: float = 6.0
const GRAVITY_SCALE: float = 60.0
const WALK_SPEED_MULT: float = 0.82
const WALK_RUN_CAP_RATIO: float = 0.72

var facing_direction: float = 1.0

# Ajustes de control terrestre
const GROUND_ACCEL_MULT: float = 1.0

func setup(data: CharacterData) -> void:
	if data:
		run_speed = data.run_speed
		walk_speed = data.walk_speed
		initial_dash_speed = data.initial_dash_speed
		traction = data.traction
		jump_velocity = data.jump_velocity
		short_hop_velocity = data.short_hop_velocity
		air_speed = data.air_speed
		air_acceleration = data.air_acceleration
		air_friction = data.air_friction
		smash_gravity = data.gravity
		smash_fall_speed = data.fall_speed
		smash_fast_fall_speed = data.fast_fall_speed

func get_input_vector(player_input: PlayerInput = null) -> Vector2:
	return player_input.movement if player_input else Vector2.ZERO

# ── Movimiento Terrestre ───────────────────────────────────────────────────
func get_run_speed() -> float:
	return run_speed * SPEED_SCALE

func get_walk_speed() -> float:
	var walk_target: float = walk_speed * SPEED_SCALE * WALK_SPEED_MULT
	var run_cap: float = get_run_speed() * WALK_RUN_CAP_RATIO
	return min(walk_target, run_cap)

func get_initial_dash_speed() -> float:
	return initial_dash_speed * SPEED_SCALE

func get_traction() -> float:
	return traction * SPEED_SCALE * 60.0 # Tasa de frenado por segundo

func get_ground_acceleration() -> float:
	return get_traction() * GROUND_ACCEL_MULT

func accelerate_ground_velocity(target_speed_x: float, delta: float, accel_multiplier: float = 1.0) -> void:
	if character == null:
		return
	var accel: float = max(1.0, get_ground_acceleration() * accel_multiplier)
	character.velocity.x = move_toward(character.velocity.x, target_speed_x, accel * delta)

# ── Salto y Movimiento Aéreo (Air Drift) ──────────────────────────────────
func get_jump_velocity() -> float:
	return jump_velocity

func get_short_hop_velocity() -> float:
	return short_hop_velocity

func get_air_speed() -> float:
	return air_speed * SPEED_SCALE

func get_air_acceleration() -> float:
	# Aceleración horizontal aérea por segundo
	return air_acceleration * SPEED_SCALE * 60.0

func get_air_friction() -> float:
	# Fricción/resistencia aérea por segundo cuando no hay input de stick
	return air_friction * SPEED_SCALE * 60.0

## Acelera suavemente la velocidad horizontal en el aire hacia la velocidad objetivo (Air Drift)
func accelerate_air_velocity(target_speed_x: float, delta: float) -> void:
	if character == null:
		return
	var accel: float = get_air_acceleration()
	character.velocity.x = move_toward(character.velocity.x, target_speed_x, accel * delta)

## Aplica resistencia/fricción aérea desacelerando suavemente hacia 0 cuando no hay input horizontal
func apply_air_friction(delta: float) -> void:
	if character == null:
		return
	var friction: float = get_air_friction()
	character.velocity.x = move_toward(character.velocity.x, 0.0, friction * delta)

# ── Gravedad y Caída ───────────────────────────────────────────────────────
func get_gravity_value() -> float:
	# Retorna gravedad negativa (hacia abajo en Godot 3D)
	return -smash_gravity * GRAVITY_SCALE * SPEED_SCALE

func get_fall_speed() -> float:
	return smash_fall_speed * SPEED_SCALE

func get_fast_fall_speed() -> float:
	return smash_fast_fall_speed * SPEED_SCALE

func get_terminal_fall_speed(is_fast_falling: bool = false) -> float:
	return get_fast_fall_speed() if is_fast_falling else get_fall_speed()

# ── Combate y Knockback ───────────────────────────────────────────────────
func get_knockback_decay_rate() -> float:
	return KnockbackCalculator.get_knockback_decay_rate(SPEED_SCALE)

# ── Orientación y Utilidades ───────────────────────────────────────────────
func set_facing_direction(dir: float) -> void:
	if dir != 0.0:
		facing_direction = sign(dir)
		if character:
			character.rotation_degrees = Vector3.ZERO
			var humanoid: Node3D = character.get_node_or_null("Humanoid")
			if humanoid:
				humanoid.rotation_degrees.y = facing_angle if facing_direction > 0 else (-facing_angle)

func apply_horizontal_movement(input_x: float) -> void:
	if input_x != 0.0:
		set_facing_direction(sign(input_x))

func apply_jump(multiplier: float = 1.0) -> void:
	if character:
		character.velocity.y = jump_velocity * multiplier
