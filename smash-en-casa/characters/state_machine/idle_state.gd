class_name IdleState
extends State

var _landing_lag_remaining: int = 0

func enter(msg: Dictionary = {}) -> void:
	_landing_lag_remaining = maxi(0, int(msg.get("landing_lag", 0)))
	if character:
		if _landing_lag_remaining <= 0 and absf(character.velocity.x) < 40.0:
			character.velocity.x = 0.0
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

	if character.velocity.x != 0.0:
		var trac: float = character.controller.get_traction() if character.controller else 1000.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	if _landing_lag_remaining > 0:
		_landing_lag_remaining -= 1
		return

	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return

	if input_vec.y < -0.55:
		if character.global_position.y < -15.0 and character.is_down_just_pressed():
			character.drop_through_platform()
			state_machine.transition_to("Fall")
			return
		state_machine.transition_to("Squat")
		return

	if absf(input_vec.x) > 0.12:
		if character.controller and character.controller.is_instant_run():
			state_machine.transition_to("Dash")
			return
		if character.is_dash_intent() or absf(input_vec.x) > 0.78:
			state_machine.transition_to("Dash")
		else:
			state_machine.transition_to("Walk")
