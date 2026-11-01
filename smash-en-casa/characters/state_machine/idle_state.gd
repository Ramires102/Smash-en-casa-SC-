# ==============================================================================
# IdleState — Estado de Reposo en Suelo (y Recuperación de Aterrizaje)
# ==============================================================================
# Aplica fricción exponencial hasta detener al personaje. Si viene de un esquive
# aéreo (`landing_lag`), bloquea acciones durante esos frames de recuperación.
# ==============================================================================
class_name IdleState
extends State

var _landing_lag_remaining: int = 0

func enter(msg: Dictionary = {}) -> void:
	_landing_lag_remaining = maxi(0, int(msg.get("landing_lag", 0)))
	if character:
		character.play_anim("Idle")

func physics_update(delta: float) -> void:
	if character == null:
		return

	if character.controller:
		character.controller.apply_ground_friction(delta)
	else:
		character.velocity.x = CharacterController.damp(character.velocity.x, 0.0, 14.0, delta)

	if _landing_lag_remaining > 0:
		_landing_lag_remaining -= 1
		return

	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return
	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
	if character.is_jump_just_pressed():
		state_machine.transition_to("Jump")
		return
	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if character.try_drop_through_platform(input_vec):
		state_machine.transition_to("Fall")
		return

	if absf(input_vec.x) > 0.15:
		state_machine.transition_to("Run")
