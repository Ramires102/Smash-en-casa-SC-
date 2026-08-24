class_name DeathState
extends State

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Death")
	character.velocity = Vector3.ZERO
	character.visible = false
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.INVULNERABLE)
