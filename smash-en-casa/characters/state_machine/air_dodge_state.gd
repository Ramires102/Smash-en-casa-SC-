class_name AirDodgeState
extends State

## Estado de Esquive Aéreo (Air Dodge) 2D puro.
## Soporta esquive neutral y direccional (habilita Wavedash/Waveland).

var is_directional: bool = false
var dodge_timer: float = 0.0
var total_duration: float = 0.50
var invulnerability_duration: float = 0.35
var _invulnerable_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO

const DIRECTIONAL_DODGE_SPEED: float = 500.0  ## En px/s (SND standard)
const NEUTRAL_INERTIA_DAMPING: float = 0.35

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.can_air_dodge = false
		character.is_fast_falling = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.INTANGIBLE)

	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	dodge_timer = 0.0

	if input_vec.length() > 0.2:
		# ── Esquive Aéreo Direccional 2D ──
		is_directional = true
		# En 2D Y negativo es UP (input_vec.y < 0 si pulsas arriba)
		dodge_direction = Vector2(input_vec.x, -input_vec.y if input_vec.y != 0 else 0.0).normalized()
		total_duration = 0.52
		invulnerability_duration = 0.32
		_invulnerable_timer = invulnerability_duration
		
		if character:
			character.velocity = dodge_direction * DIRECTIONAL_DODGE_SPEED
			character.set_facing_direction(signf(input_vec.x) if absf(input_vec.x) > 0.1 else character.get_facing_direction())
	else:
		# ── Esquive Aéreo Neutral ──
		is_directional = false
		dodge_direction = Vector2.ZERO
		total_duration = 0.45
		invulnerability_duration = 0.38
		_invulnerable_timer = invulnerability_duration
		
		if character:
			character.velocity *= NEUTRAL_INERTIA_DAMPING

	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("AirDodge")

	dbg("enter", {
		"directional": is_directional,
		"dir": {
			"x": snapped(dodge_direction.x, 0.01),
			"y": snapped(dodge_direction.y, 0.01)
		}
	})

func physics_update(delta: float) -> void:
	dodge_timer += delta

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta
		if _invulnerable_timer <= 0.0 and character:
			character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

	if character:
		if is_directional:
			var decel_rate: float = 800.0
			character.velocity.x = move_toward(character.velocity.x, 0.0, decel_rate * delta)
			if dodge_timer > invulnerability_duration * 0.5:
				character.velocity.y += character.get_gravity_value() * delta * 0.75
		else:
			character.velocity.y += character.get_gravity_value() * delta * 0.4
			if character.controller:
				character.controller.apply_air_friction(delta)

	dbg_tick(delta, {
		"timer": snapped(dodge_timer, 0.01),
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

	# ── Detección de Aterrizaje / Waveland ──
	if character and character.is_on_floor():
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
		var landing_lag: int = Constants.AIRDODGE_LANDING_LAG_FRAMES if is_directional else Constants.NORMAL_LANDING_LAG_FRAMES
		if is_directional and absf(character.velocity.x) > 40.0:
			dbg("waveland", {
				"vx": snapped(character.velocity.x, 0.01),
				"landing_lag": landing_lag
			})
		else:
			dbg("landed_idle", {"landing_lag": landing_lag})
		state_machine.transition_to("Idle", {"landing_lag": landing_lag})
		return

	if dodge_timer >= total_duration:
		if character and not character.is_on_floor():
			dbg("to_fall", {"reason": "airdodge_completed"})
			state_machine.transition_to("Fall")
		else:
			dbg("to_idle", {
				"reason": "airdodge_grounded",
				"landing_lag": Constants.NORMAL_LANDING_LAG_FRAMES
			})
			state_machine.transition_to("Idle", {"landing_lag": Constants.NORMAL_LANDING_LAG_FRAMES})

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
