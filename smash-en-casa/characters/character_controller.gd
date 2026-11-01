# ==============================================================================
# CharacterController — Motor de Locomoción 2D del Luchador
# ==============================================================================
# Gestiona velocidades terrestres y aéreas, fricción, fuerza de salto, gravedad
# y dirección de mirada. Trabaja internamente con unidades métricas (m/s) y las
# convierte a píxeles 2D multiplicando por Constants.UNIT_SIZE.
# ==============================================================================
class_name CharacterController
extends Node

@export var character: Character

#region Constantes Físicas Base (en metros/s y metros/s²)
const TS_GRAVITY: float = 26.0
const TS_TERMINAL_VELOCITY: float = 22.0
const TS_GROUND_FRICTION: float = 14.0
const TS_AIR_FRICTION: float = 3.5
#endregion

#region Atributos de Movimiento Activos
var ts_movement_speed: float = 8.6
var ts_acceleration: float = 38.0
var ts_jump_force: float = 12.4
var ts_air_speed: float = 7.8
var facing_direction: float = 1.0
#endregion

## Interpolación exponencial independiente de los FPS (suavizado frame-rate independent).
static func damp(current: float, target: float, lambda_val: float, dt: float) -> float:
	return lerpf(current, target, 1.0 - exp(-lambda_val * dt))

func setup(data: CharacterData) -> void:
	var is_sans: bool = data != null and data.character_name.to_lower().contains("sans")
	if is_sans:
		ts_movement_speed = 7.4
		ts_acceleration = 34.0
		ts_jump_force = 11.8
		ts_air_speed = 7.2
	else:
		ts_movement_speed = 8.6
		ts_acceleration = 38.0
		ts_jump_force = 12.4
		ts_air_speed = 7.8

#region Movimiento Terrestre (px/s)
func get_jumpsquat_frames() -> int:
	return 0

func get_run_speed() -> float:
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
#endregion

#region Salto, Caída y Movimiento Aéreo (px/s)
func get_jump_velocity() -> float:
	return ts_jump_force * Constants.UNIT_SIZE

func get_air_speed() -> float:
	return ts_air_speed * Constants.UNIT_SIZE

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
#endregion

#region Orientación Horizontal
func set_facing_direction(dir: float, smooth_turn: bool = false) -> void:
	if dir != 0.0:
		facing_direction = signf(dir)
		if character:
			character.update_visual_rotation(facing_direction, smooth_turn)
#endregion
