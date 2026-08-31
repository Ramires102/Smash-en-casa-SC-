class_name DeathState
extends State

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Death")
	if character:
		character.velocity = Vector2.ZERO
		character.visible = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.INVULNERABLE)
