class_name DazeState
extends State

var daze_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	var damage_pct: float = character.damage_percentage if character else 0.0
	daze_timer = clamp(4.0 + (damage_pct * 0.05), 4.0, 10.0)
	dbg("enter", {"damage_pct": snapped(damage_pct, 0.001), "daze_timer": snapped(daze_timer, 0.001)})
	
	if character:
		character.set_daze_effects_enabled(true)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Hit")

func exit() -> void:
	dbg("exit")
	if character:
		character.set_daze_effects_enabled(false)

func handle_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		daze_timer -= 0.15
		dbg("mash_input", {"daze_timer": snapped(daze_timer, 0.001)})

func physics_update(delta: float) -> void:
	daze_timer -= delta
	dbg_tick(delta, {
		"daze_timer": snapped(daze_timer, 0.001),
		"vx": snapped(character.velocity.x, 0.001) if character else 0.0
	})
	
	if character:
		var trac: float = character.controller.get_traction() if character.controller else 30.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
		character.update_daze_effects(delta, daze_timer)
	
	if daze_timer <= 0.0:
		if character:
			character.set_daze_effects_enabled(false)
			character.shield_health = Character.SHIELD_BREAK_RESPAWN_HP
			character.update_shield_scale()
			
			if character.is_on_floor():
				dbg("to_idle", {"reason": "daze_finished_ground"})
				state_machine.transition_to("Idle")
			else:
				dbg("to_fall", {"reason": "daze_finished_air"})
				state_machine.transition_to("Fall")
