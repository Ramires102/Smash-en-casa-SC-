class_name IdleState
extends State

var _landing_lag_remaining: int = 0

func enter(msg: Dictionary = {}) -> void:
	_landing_lag_remaining = maxi(0, int(msg.get("landing_lag", 0)))
	if character:
		character.set_menacing_aura_enabled(true)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Idle")

func exit() -> void:
	if character:
		character.set_menacing_aura_enabled(false)

func physics_update(delta: float) -> void:
	if character == null:
		return
	character.update_menacing_aura(delta)

	# Frenado exponencial suave idéntico a idle_state.ts (GROUND_FRICTION = 14.0)
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
	if input_vec.y < -0.65 and character.global_position.y < -10.0 and character.is_down_just_pressed():
		character.global_position.y += 12.0
		character.velocity.y = maxf(character.velocity.y, 60.0)
		state_machine.transition_to("Fall")
		return

	if absf(input_vec.x) > 0.15:
		state_machine.transition_to("Run")
