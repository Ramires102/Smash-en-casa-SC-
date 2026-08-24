class_name RollState
extends State

var roll_timer: float = 0.0
var roll_dir: float = 1.0
const ROLL_DURATION: float = 0.4
const ROLL_SPEED: float = 12.0

func enter(msg: Dictionary = {}) -> void:
	roll_dir = msg.get("dir", character.get_facing_direction())
	roll_timer = ROLL_DURATION
	dbg("enter", {"roll_dir": roll_dir, "roll_timer": snapped(roll_timer, 0.001)})
	if character:
		character.set_facing_direction(roll_dir)
		character.set_hurtbox_state(Hurtbox.HurtboxState.INTANGIBLE)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Roll")

func exit() -> void:
	dbg("exit", {"vx": snapped(character.velocity.x, 0.001) if character else 0.0})
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
	
	# Al terminar la rodada tras cruzar al enemigo, orientar automáticamente la mirada hacia el rival
	if character:
		var parent_node := character.get_parent()
		if parent_node:
			for other in parent_node.get_children():
				if other is Character and other != character and other.visible:
					var dx: float = other.global_position.x - character.global_position.x
					if abs(dx) > 0.01:
						character.set_facing_direction(sign(dx))

func physics_update(delta: float) -> void:
	roll_timer -= delta
	if character:
		character.velocity.x = roll_dir * ROLL_SPEED
	dbg_tick(delta, {
		"roll_timer": snapped(roll_timer, 0.001),
		"vx": snapped(character.velocity.x, 0.001) if character else 0.0,
		"roll_dir": roll_dir
	})
	
	if roll_timer <= 0.0:
		if character:
			character.velocity.x = 0.0
		if character and character.is_on_floor():
			dbg("to_idle", {"reason": "roll_finished_ground"})
			state_machine.transition_to("Idle")
		else:
			dbg("to_fall", {"reason": "roll_finished_air"})
			state_machine.transition_to("Fall")
