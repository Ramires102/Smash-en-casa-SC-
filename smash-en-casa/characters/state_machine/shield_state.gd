class_name ShieldState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("Humanoid/ShieldMesh"):
		character.get_node("Humanoid/ShieldMesh").visible = true
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Shield")

func exit() -> void:
	if character and character.has_node("Humanoid/ShieldMesh"):
		character.get_node("Humanoid/ShieldMesh").visible = false

func physics_update(_delta: float) -> void:
	character.velocity.x = move_toward(character.velocity.x, 0, character.move_speed)
	
	if not character.is_shield_pressed():
		if character.is_on_floor():
			state_machine.transition_to("Idle")
		else:
			state_machine.transition_to("Fall")
