class_name DeathState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Death")
	character.velocity = Vector3.ZERO
	character.visible = false
