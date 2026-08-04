class_name WalkState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Walk")

func physics_update(_delta: float) -> void:
	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if abs(input_vec.x) < 0.1:
		character.velocity.x = 0.0
		state_machine.transition_to("Idle")
		return

	if input_vec.y < -0.5:
		state_machine.transition_to("Squat")
		return

	if InputManager.is_dash_pressed(character.player_id):
		state_machine.transition_to("Dash")
		return

	var walk_spd: float = character.controller.get_walk_speed() if character.controller else 6.0
	character.velocity.x = input_vec.x * walk_spd
	character.update_facing_direction(input_vec.x)

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
