class_name HitState
extends State

var stun_timer: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Hit")

	var knockback_vector: Vector3 = msg.get("knockback", Vector3.ZERO)
	character.velocity = knockback_vector
	stun_timer = clamp(knockback_vector.length() * 0.02, 0.25, 1.5)
	dbg("enter", {
		"knockback": {
			"x": snapped(knockback_vector.x, 0.001),
			"y": snapped(knockback_vector.y, 0.001),
			"z": snapped(knockback_vector.z, 0.001)
		},
		"stun_timer": snapped(stun_timer, 0.001)
	})

func exit() -> void:
	dbg("exit")

func physics_update(delta: float) -> void:
	stun_timer -= delta
	dbg_tick(delta, {
		"stun_timer": snapped(stun_timer, 0.001),
		"vx": snapped(character.velocity.x, 0.001),
		"vy": snapped(character.velocity.y, 0.001)
	})
	if stun_timer <= 0.0:
		if character.is_on_floor():
			dbg("to_idle", {"reason": "hitstun_finished_ground"})
			state_machine.transition_to("Idle")
		else:
			dbg("to_fall", {"reason": "hitstun_finished_air"})
			state_machine.transition_to("Fall")
