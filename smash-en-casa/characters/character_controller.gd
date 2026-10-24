class_name CharacterController
extends Node

@export var character: Character

# Constantes globales 1:1 con shared/constants.ts
const TS_GRAVITY: float = 26.0
const TS_TERMINAL_VELOCITY: float = 22.0
const TS_GROUND_FRICTION: float = 14.0
const TS_AIR_FRICTION: float = 3.5

# Stats en metros/s (idénticos a GogetaData / SansData en TypeScript)
var ts_movement_speed: float = 8.6
var ts_acceleration: float = 38.0
var ts_jump_force: float = 12.4
var ts_air_speed: float = 7.8

# Variables heredadas para compatibilidad con otros estados
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
var jumpsquat_frames: int = 0
var instant_run: bool = true

var facing_direction: float = 1.0

static func damp(current: float, target: float, lambda_val: float, dt: float) -> float:
	return lerpf(current, target, 1.0 - exp(-lambda_val * dt))

func setup(data: CharacterData) -> void:
	var is_sans: bool = false
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

		var c_name: String = ""
		if "character_name" in data:
			c_name = str(data.character_name).to_lower()
		elif "display_name" in data:
			c_name = str(data.display_name).to_lower()
		is_sans = c_name.contains("sans")

	if is_sans:
		# Stats exactos de SansData (sans_data.ts)
		ts_movement_speed = 7.4
		ts_acceleration = 34.0
		ts_jump_force = 11.8
		ts_air_speed = 7.2
	else:
		# Stats exactos de GogetaData (gogeta_data.ts)
		ts_movement_speed = 8.6
		ts_acceleration = 38.0
		ts_jump_force = 12.4
		ts_air_speed = 7.8

	jumpsquat_frames = 0
	instant_run = true

func get_jumpsquat_frames() -> int:
	return 0

func is_instant_run() -> bool:
	return true

# ── Movimiento Terrestre 2D (px/s) 1:1 con TypeScript ────────────────────────
func get_run_speed() -> float:
	return ts_movement_speed * Constants.UNIT_SIZE

func get_walk_speed() -> float:
	return ts_movement_speed * Constants.UNIT_SIZE

func get_initial_dash_speed() -> float:
	return ts_movement_speed * Constants.UNIT_SIZE

func get_traction() -> float:
	return TS_GROUND_FRICTION * Constants.UNIT_SIZE * 4.0

func accelerate_ground_velocity(target_speed_x: float, delta: float, _accel_multiplier: float = 1.0) -> void:
	if character == null:
		return
	character.velocity.x = damp(character.velocity.x, target_speed_x, ts_acceleration * 0.4, delta)

func apply_ground_friction(delta: float, mult: float = 1.0) -> void:
	if character == null:
		return
	character.velocity.x = damp(character.velocity.x, 0.0, TS_GROUND_FRICTION * mult, delta)

# ── Salto y Gravedad 2D (px/s) 1:1 con TypeScript ───────────────────────────
func get_jump_velocity() -> float:
	return ts_jump_force * Constants.UNIT_SIZE

func get_short_hop_velocity() -> float:
	return ts_jump_force * Constants.UNIT_SIZE

func get_air_speed() -> float:
	return ts_air_speed * Constants.UNIT_SIZE

func get_air_acceleration() -> float:
	return 8.0 * Constants.UNIT_SIZE

func get_air_friction() -> float:
	return TS_AIR_FRICTION * Constants.UNIT_SIZE

func get_gravity_value() -> float:
	return TS_GRAVITY * Constants.UNIT_SIZE

func get_fall_speed() -> float:
	return TS_TERMINAL_VELOCITY * Constants.UNIT_SIZE

func get_fast_fall_speed() -> float:
	return TS_TERMINAL_VELOCITY * 1.25 * Constants.UNIT_SIZE

func get_terminal_fall_speed(is_fast_falling: bool = false) -> float:
	return get_fast_fall_speed() if is_fast_falling else get_fall_speed()

func apply_air_friction(delta: float) -> void:
	if character == null:
		return
	character.velocity.x = damp(character.velocity.x, 0.0, TS_AIR_FRICTION, delta)

func apply_snd_air_movement(input_x: float, delta: float, lambda_val: float = 7.5) -> void:
	if character == null:
		return
	if absf(input_x) > 0.1:
		var target_vx: float = input_x * get_air_speed()
		character.velocity.x = damp(character.velocity.x, target_vx, lambda_val, delta)
	else:
		character.velocity.x = damp(character.velocity.x, 0.0, TS_AIR_FRICTION, delta)

func set_facing_direction(dir: float, smooth_turn: bool = false) -> void:
	if dir != 0.0:
		facing_direction = signf(dir)
		if character and character.has_method("update_visual_rotation"):
			character.update_visual_rotation(facing_direction, smooth_turn)
