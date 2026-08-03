class_name IdleState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Idle")

func physics_update(_delta: float) -> void:
	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if abs(input_vec.x) > 0.1:
		state_machine.transition_to("Run")
		return

	if character.is_jump_just_pressed():
		state_machine.transition_to("Jump")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
