class_name CharacterController
extends Node

@export var character: Character


# Valores de físicas 2D (cargados de CharacterData)
var run_speed: float = 2.18
var walk_speed: float = 1.05
var initial_dash_speed: float = 2.35
var traction: float = 0.11
var jump_velocity: float = 14.2
var short_hop_velocity: float = 10.8
var air_speed: float = 1.08
var air_acceleration: float = 0.055
var air_friction: float = 0.012
var smash_gravity: float = 0.09
var smash_fall_speed: float = 1.62
var smash_fast_fall_speed: float = 2.55

# Factores de escala 2D nativos (Píxeles/segundo)
const SPEED_SCALE_2D: float = 160.0
const JUMP_SCALE_2D: float = 38.0
const GRAVITY_SCALE_2D: float = 260.0

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


# ── Movimiento Terrestre 2D (px/s) ──────────────────────────────────────────
func get_run_speed() -> float:
	return run_speed * SPEED_SCALE_2D

func get_walk_speed() -> float:
	return walk_speed * (SPEED_SCALE_2D * 0.65)

func get_initial_dash_speed() -> float:
	return initial_dash_speed * (SPEED_SCALE_2D * 1.15)

func get_traction() -> float:
	return traction * 60.0 * 180.0

func accelerate_ground_velocity(target_speed_x: float, delta: float, accel_multiplier: float = 1.0) -> void:
	if character == null:
		return
	var accel: float = max(50.0, get_traction() * accel_multiplier)
	character.velocity.x = move_toward(character.velocity.x, target_speed_x, accel * delta)

# ── Salto y Gravedad 2D (px/s) ──────────────────────────────────────────────
func get_jump_velocity() -> float:
	return jump_velocity * JUMP_SCALE_2D

func get_short_hop_velocity() -> float:
	return short_hop_velocity * JUMP_SCALE_2D

func get_air_speed() -> float:
	return air_speed * (SPEED_SCALE_2D * 1.3)

func get_air_acceleration() -> float:
	return air_acceleration * 60.0 * 200.0

func get_air_friction() -> float:
	return air_friction * 60.0 * 150.0

func get_gravity_value() -> float:
	# En Godot 2D, Y positivo es abajo (+), por lo que la gravedad es POSITIVA (+)
	return smash_gravity * 60.0 * GRAVITY_SCALE_2D

func get_fall_speed() -> float:
	return smash_fall_speed * 320.0

func get_fast_fall_speed() -> float:
	return smash_fast_fall_speed * 280.0

func get_terminal_fall_speed(is_fast_falling: bool = false) -> float:
	return get_fast_fall_speed() if is_fast_falling else get_fall_speed()


func apply_air_friction(delta: float) -> void:
	if character == null:
		return
	var friction: float = get_air_friction()
	character.velocity.x = move_toward(character.velocity.x, 0.0, friction * delta)

## Air drift estilo Splash N Dash: acelera fuerte por input opuesto y fricción leve en neutral.
func apply_snd_air_movement(input_x: float, delta: float) -> void:
	if character == null:
		return

	var max_air_speed: float = get_air_speed()
	var air_accel: float = get_air_acceleration() * delta

	if absf(character.velocity.x) >= absf(max_air_speed):
		if character.velocity.x > 0.0:
			if input_x < -0.1:
				character.velocity.x -= air_accel
		elif character.velocity.x < 0.0:
			if input_x > 0.1:
				character.velocity.x += air_accel
	else:
		if input_x < -0.1:
			character.velocity.x -= air_accel
		elif input_x > 0.1:
			character.velocity.x += air_accel

	if absf(input_x) <= 0.1:
		var neutral_friction: float = air_accel / Constants.AIR_NEUTRAL_FRICTION_DIV
		if character.velocity.x < 0.0:
			character.velocity.x += neutral_friction
			if character.velocity.x > 0.0:
				character.velocity.x = 0.0
		elif character.velocity.x > 0.0:
			character.velocity.x -= neutral_friction
			if character.velocity.x < 0.0:
				character.velocity.x = 0.0

func set_facing_direction(dir: float) -> void:
	if dir != 0.0:
		facing_direction = sign(dir)
		if character and character.has_method("update_visual_rotation"):
			character.update_visual_rotation(facing_direction)

