class_name SquatState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Squat")

func physics_update(delta: float) -> void:
	if not character:
		return

	var trac: float = character.controller.get_traction() if character.controller else 900.0
	character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_down_just_pressed() and character.global_position.y < -15.0:
		character.drop_through_platform()
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		var input_y: float = character.get_input_vector().y
		if input_y < -0.5:
			state_machine.transition_to("Spotdodge")
		else:
			state_machine.transition_to("Shield")
		return

	var prev_y: float = character.current_input.movement.y if character.current_input else 0.0
	if character.current_input:
		character.current_input.movement.y = minf(prev_y, -0.6)
	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
	if character.current_input:
		character.current_input.movement.y = prev_y

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if input_vec.y >= -0.5:
		if absf(input_vec.x) > 0.12:
			if character.is_dash_intent() or absf(input_vec.x) > 0.78:
				state_machine.transition_to("Dash")
			else:
				state_machine.transition_to("Walk")
		else:
			state_machine.transition_to("Idle")
