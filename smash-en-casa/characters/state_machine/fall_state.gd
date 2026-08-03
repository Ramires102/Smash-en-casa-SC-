class_name FallState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

func physics_update(_delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector()
	character.velocity.x = input_vec.x * character.move_speed
	character.update_facing_direction(input_vec.x)

	if character.is_on_floor():
		if abs(input_vec.x) > 0.1:
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
