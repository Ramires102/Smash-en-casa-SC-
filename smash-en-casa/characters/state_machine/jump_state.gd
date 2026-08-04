class_name JumpState
extends State

func enter(msg: Dictionary = {}) -> void:
	var mult: float = msg.get("multiplier", 1.0)
	if mult < 1.0:
		# Short Hop
		var shv: float = character.controller.get_short_hop_velocity() if character and character.controller else 10.5
		character.velocity.y = shv
	else:
		# Full Hop
		character.velocity.y = character.jump_velocity
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Jump")

func physics_update(_delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector()
	var air_spd: float = character.controller.get_air_speed() if character and character.controller else 6.0
	character.velocity.x = input_vec.x * air_spd
	character.update_facing_direction(input_vec.x)

	if character.velocity.y <= 0:
		state_machine.transition_to("Fall")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
