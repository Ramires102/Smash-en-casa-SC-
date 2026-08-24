class_name IdleState
extends State

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character:
		character.velocity.x = 0.0
		character.set_menacing_aura_enabled(true)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Idle")

func exit() -> void:
	dbg("exit")
	if character:
		character.set_menacing_aura_enabled(false)

func physics_update(delta: float) -> void:
	if character:
		character.update_menacing_aura(delta)
		dbg_tick(delta, {
			"vx": snapped(character.velocity.x, 0.001),
			"input_x": snapped(character.get_input_vector().x, 0.001),
			"dash_intent": character.is_dash_intent()
		})

	if not character.is_on_floor():
		dbg("to_fall", {"reason": "left_floor"})
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		dbg("to_shield", {"reason": "shield_pressed"})
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()

	if input_vec.y < -0.5:
		dbg("to_squat", {"reason": "down_input", "input_y": snapped(input_vec.y, 0.001)})
		state_machine.transition_to("Squat")
		return

	if abs(input_vec.x) > 0.1:
		if character.is_dash_intent():
			dbg("to_dash", {"reason": "dash_intent", "input_x": snapped(input_vec.x, 0.001)})
			state_machine.transition_to("Dash")
		else:
			dbg("to_walk", {"reason": "horizontal_input", "input_x": snapped(input_vec.x, 0.001)})
			state_machine.transition_to("Walk")
		return

	if character.is_jump_just_pressed():
		dbg("to_jumpsquat", {"reason": "jump_pressed"})
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed"})
		state_machine.transition_to("Attack")
		return
