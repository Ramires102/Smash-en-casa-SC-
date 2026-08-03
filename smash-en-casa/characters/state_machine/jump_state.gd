class_name JumpState
extends State

func enter(_msg: Dictionary = {}) -> void:
	character.velocity.y = character.jump_velocity
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Jump")

func physics_update(_delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector()
	character.velocity.x = input_vec.x * character.move_speed
	character.update_facing_direction(input_vec.x)

	if character.velocity.y <= 0:
		state_machine.transition_to("Fall")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
