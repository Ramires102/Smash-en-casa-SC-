class_name SquatState
extends State

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character:
		character.velocity.x = 0.0
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Squat")

func exit() -> void:
	dbg("exit")

func physics_update(_delta: float) -> void:
	dbg_tick(_delta, {
		"input_x": snapped(character.get_input_vector().x, 0.001),
		"input_y": snapped(character.get_input_vector().y, 0.001)
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
	
	if input_vec.y >= -0.5:
		if abs(input_vec.x) > 0.1:
			if character.is_dash_intent():
				dbg("to_dash", {"reason": "dash_intent_from_squat", "input_x": snapped(input_vec.x, 0.001)})
				state_machine.transition_to("Dash")
			else:
				dbg("to_walk", {"reason": "horizontal_input_from_squat", "input_x": snapped(input_vec.x, 0.001)})
				state_machine.transition_to("Walk")
		else:
			dbg("to_idle", {"reason": "neutral_from_squat"})
			state_machine.transition_to("Idle")
		return

	if character.is_jump_just_pressed():
		dbg("to_jumpsquat", {"reason": "jump_pressed"})
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed"})
		state_machine.transition_to("Attack")
		return
