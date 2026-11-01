# ==============================================================================
# AirDodgeState — Esquive Aéreo Neutral y Direccional (Wavedash / Waveland)
# ==============================================================================
# Otorga intangibilidad temporal en el aire (gasta el recurso `can_air_dodge`
# hasta volver a pisar tierra o agarrar un borde). Si se inclina el stick, lanza
# al personaje en esa dirección permitiendo deslizarse sobre el suelo (Waveland).
# ==============================================================================
class_name AirDodgeState
extends State

const DIRECTIONAL_DODGE_SPEED: float = 500.0
const NEUTRAL_INERTIA_DAMPING: float = 0.35

var is_directional: bool = false
var dodge_timer: float = 0.0
var total_duration: float = 0.50
var invulnerability_duration: float = 0.35
var _invulnerable_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.can_air_dodge = false
		character.is_fast_falling = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.INTANGIBLE)

	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	dodge_timer = 0.0

	if input_vec.length() > 0.2:
		is_directional = true
		dodge_direction = Vector2(input_vec.x, -input_vec.y if input_vec.y != 0.0 else 0.0).normalized()
		total_duration = 0.52
		invulnerability_duration = 0.32
		_invulnerable_timer = invulnerability_duration

		if character:
			character.velocity = dodge_direction * DIRECTIONAL_DODGE_SPEED
			if absf(input_vec.x) > 0.1:
				character.set_facing_direction(signf(input_vec.x))
	else:
		is_directional = false
		dodge_direction = Vector2.ZERO
		total_duration = 0.45
		invulnerability_duration = 0.38
		_invulnerable_timer = invulnerability_duration

		if character:
			character.velocity *= NEUTRAL_INERTIA_DAMPING

	if character:
		character.play_anim("AirDodge")

func physics_update(delta: float) -> void:
	dodge_timer += delta

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta
		if _invulnerable_timer <= 0.0 and character:
			character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

	if character:
		if is_directional:
			character.velocity.x = move_toward(character.velocity.x, 0.0, 800.0 * delta)
			if dodge_timer > invulnerability_duration * 0.5:
				character.velocity.y += character.get_gravity_value() * delta * 0.75
		else:
			character.velocity.y += character.get_gravity_value() * delta * 0.4
			if character.controller:
				character.controller.apply_air_friction(delta)

	# Aterrizaje anticipado con penalización de frames (Landing Lag / Waveland)
	if character and character.is_on_floor():
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
		var landing_lag: int = Constants.AIRDODGE_LANDING_LAG_FRAMES if is_directional else Constants.NORMAL_LANDING_LAG_FRAMES
		state_machine.transition_to("Idle", {"landing_lag": landing_lag})
		return

	if dodge_timer >= total_duration:
		if character and not character.is_on_floor():
			state_machine.transition_to("Fall")
		else:
			state_machine.transition_to("Idle", {"landing_lag": Constants.NORMAL_LANDING_LAG_FRAMES})

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
