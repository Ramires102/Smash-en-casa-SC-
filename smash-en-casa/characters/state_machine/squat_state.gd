class_name SquatState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.velocity.x = 0.0
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Squat")

func physics_update(_delta: float) -> void:
	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	
	if input_vec.y >= -0.5:
		if abs(input_vec.x) > 0.1:
			if InputManager.is_dash_pressed(character.player_id):
				state_machine.transition_to("Dash")
			else:
				state_machine.transition_to("Walk")
		else:
			state_machine.transition_to("Idle")
		return

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
