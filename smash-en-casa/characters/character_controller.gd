class_name CharacterController
extends Node

@export var character: Character

# Valores de físicas 2D (cargados de CharacterData)
var run_speed: float = 2.18
var walk_speed: float = 1.05
var initial_dash_speed: float = 2.35
var traction: float = 0.11
var jump_velocity: float = 14.2
var short_hop_velocity: float = 10.2
var air_speed: float = 1.12
var air_acceleration: float = 0.065
var air_friction: float = 0.014
var smash_gravity: float = 0.095
var smash_fall_speed: float = 1.65
var smash_fast_fall_speed: float = 2.65
var jumpsquat_frames: int = 3
var instant_run: bool = false

# Factores de escala 2D nativos (Píxeles/segundo, donde 28 px = 1 metro)
const SPEED_SCALE_2D: float = 172.0
const JUMP_SCALE_2D: float = 39.5
const GRAVITY_SCALE_2D: float = 275.0

var facing_direction: float = 1.0

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
		jumpsquat_frames = data.jumpsquat_frames
		instant_run = data.instant_run

func get_jumpsquat_frames() -> int:
	return maxi(2, jumpsquat_frames)

func is_instant_run() -> bool:
	return instant_run

# ── Movimiento Terrestre 2D (px/s) ──────────────────────────────────────
func get_run_speed() -> float:
	return run_speed * SPEED_SCALE_2D

func get_walk_speed() -> float:
	return walk_speed * (SPEED_SCALE_2D * 0.68)

func get_initial_dash_speed() -> float:
	return maxf(get_run_speed() * 1.08, initial_dash_speed * (SPEED_SCALE_2D * 1.15))

func get_traction() -> float:
	return maxf(950.0, traction * 60.0 * 210.0)

func accelerate_ground_velocity(target_speed_x: float, delta: float, accel_multiplier: float = 1.0) -> void:
	if character == null:
		return
	var accel: float = maxf(600.0, get_traction() * 1.35 * accel_multiplier)
	character.velocity.x = move_toward(character.velocity.x, target_speed_x, accel * delta)

# ── Salto y Gravedad 2D (px/s) ──────────────────────────────────────────
func get_jump_velocity() -> float:
	return jump_velocity * JUMP_SCALE_2D

func get_short_hop_velocity() -> float:
	# Garantiza que el Short Hop sea ~68% de la velocidad del Full Hop (altura ~46%)
	var raw_sh: float = short_hop_velocity * JUMP_SCALE_2D
	var max_allowed_sh: float = get_jump_velocity() * 0.72
	return minf(raw_sh, max_allowed_sh)

func get_air_speed() -> float:
	return air_speed * (SPEED_SCALE_2D * 1.32)

func get_air_acceleration() -> float:
	return maxf(780.0, air_acceleration * 60.0 * 240.0)

func get_air_friction() -> float:
	return air_friction * 60.0 * 140.0

func get_gravity_value() -> float:
	return smash_gravity * 60.0 * GRAVITY_SCALE_2D

func get_fall_speed() -> float:
	return smash_fall_speed * 315.0

func get_fast_fall_speed() -> float:
	return maxf(get_fall_speed() * 1.55, smash_fast_fall_speed * 290.0)

func get_terminal_fall_speed(is_fast_falling: bool = false) -> float:
	return get_fast_fall_speed() if is_fast_falling else get_fall_speed()

func apply_air_friction(delta: float) -> void:
	if character == null:
		return
	var friction: float = get_air_friction()
	character.velocity.x = move_toward(character.velocity.x, 0.0, friction * delta)

## Air drift estilo Smash: excelente respuesta al cambiar de dirección en el aire y conservación de momentum
func apply_snd_air_movement(input_x: float, delta: float) -> void:
	if character == null:
		return
	var max_air_speed: float = get_air_speed()
	var air_accel: float = get_air_acceleration()

	if absf(input_x) > 0.12:
		var target_vx: float = signf(input_x) * max_air_speed
		# Si el jugador lleva más velocidad que max_air_speed (ej. saltó desde un Dash)
		# en la misma dirección, conservar ese momentum extra suavemente
		if signf(character.velocity.x) == signf(input_x) and absf(character.velocity.x) > max_air_speed:
			var overflow_friction: float = get_air_friction() * 0.65
			character.velocity.x = move_toward(character.velocity.x, target_vx, overflow_friction * delta)
		else:
			# Si frena hacia el lado opuesto en el aire, darle 25% más de respuesta
			var turn_boost: float = 1.25 if (signf(character.velocity.x) != signf(input_x) and absf(character.velocity.x) > 20.0) else 1.0
			character.velocity.x = move_toward(character.velocity.x, target_vx, air_accel * turn_boost * delta)
	else:
		var neutral_friction: float = (air_accel / Constants.AIR_NEUTRAL_FRICTION_DIV) * delta
		character.velocity.x = move_toward(character.velocity.x, 0.0, neutral_friction)

func set_facing_direction(dir: float) -> void:
	if dir != 0.0:
		facing_direction = signf(dir)
		if character and character.has_method("update_visual_rotation"):
			character.update_visual_rotation(facing_direction)
