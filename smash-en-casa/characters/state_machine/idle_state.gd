class_name IdleState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.velocity.x = 0.0
		character.set_menacing_aura_enabled(true)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Idle")

func exit() -> void:
	if character:
		character.set_menacing_aura_enabled(false)

func physics_update(delta: float) -> void:
	if character:
		character.update_menacing_aura(delta)

	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()

	if input_vec.y < -0.5:
		state_machine.transition_to("Squat")
		return

	if abs(input_vec.x) > 0.1:
		if character.is_dash_intent():
			state_machine.transition_to("Dash")
		else:
			state_machine.transition_to("Walk")
		return

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
