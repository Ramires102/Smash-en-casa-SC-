class_name FallState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

func physics_update(_delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector()
	var air_spd: float = character.controller.get_air_speed() if character and character.controller else 6.0
	character.velocity.x = input_vec.x * air_spd
	character.update_facing_direction(input_vec.x)

	if character.is_on_floor():
		if abs(input_vec.x) > 0.1:
			if InputManager.is_dash_pressed(character.player_id):
				state_machine.transition_to("Dash")
			else:
				state_machine.transition_to("Walk")
		else:
			state_machine.transition_to("Idle")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
