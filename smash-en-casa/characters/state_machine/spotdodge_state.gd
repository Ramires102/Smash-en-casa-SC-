class_name SpotDodgeState
extends State

var dodge_timer: float = 0.0
const DODGE_DURATION: float = 0.35

func enter(_msg: Dictionary = {}) -> void:
	dodge_timer = DODGE_DURATION
	dbg("enter", {"dodge_timer": snapped(dodge_timer, 0.001)})
	if character:
		character.velocity.x = 0.0
		character.set_hurtbox_state(Hurtbox.HurtboxState.INTANGIBLE)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Spotdodge")

func exit() -> void:
	dbg("exit")
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

func physics_update(delta: float) -> void:
	dodge_timer -= delta
	if character:
		character.velocity.x = 0.0
	dbg_tick(delta, {
		"dodge_timer": snapped(dodge_timer, 0.001)
	})
	
	if dodge_timer <= 0.0:
		if character and character.is_on_floor():
			dbg("to_idle", {"reason": "spotdodge_finished_ground"})
			state_machine.transition_to("Idle")
		else:
			dbg("to_fall", {"reason": "spotdodge_finished_air"})
			state_machine.transition_to("Fall")
