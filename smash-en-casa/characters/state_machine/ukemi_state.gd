class_name UkemiState
extends State

## Estado de Ukemi (Tech) 2D puro porteado desde Splash N Dash (CharacterSM.gd:TECH states).
## Neutral Tech, Tech Roll Forward, Tech Roll Backward con invulnerabilidad.

var _timer: float = 0.0
var _intangibility_timer: float = 0.0
var _tech_dir: int = 0

const NEUTRAL_TECH_DURATION: float = 0.22
const ROLL_TECH_DURATION: float = 0.30

func enter(msg: Dictionary = {}) -> void:
	_tech_dir = clampi(msg.get("dir", 0), -1, 1)
	_timer = ROLL_TECH_DURATION if _tech_dir != 0 else NEUTRAL_TECH_DURATION
	_intangibility_timer = Constants.UKEMI_INVULN_SECONDS

	if character:
		character.is_fast_falling = false
		character.velocity.y = 0.0
		character.set_hurtbox_state(Hurtbox.HurtboxState.INTANGIBLE)
		if _tech_dir != 0:
			character.set_facing_direction(float(_tech_dir))

	if character and character.has_node("AnimationController"):
		if _tech_dir == 0:
			character.get_node("AnimationController").play_animation("Spotdodge")
		else:
			character.get_node("AnimationController").play_animation("Roll")

	dbg("enter", {
		"dir": _tech_dir,
		"duration": snapped(_timer, 0.001)
	})

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
	dbg("exit", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	if character == null:
		return

	_timer -= delta

	if _intangibility_timer > 0.0:
		_intangibility_timer -= delta
		if _intangibility_timer <= 0.0:
			character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

	if _tech_dir == 0:
		var trac: float = character.controller.get_traction() if character.controller else 900.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta * 1.5)
	else:
		character.velocity.x = float(_tech_dir) * Constants.UKEMI_ROLL_SPEED

	character.velocity.y = 0.0

	dbg_tick(delta, {
		"timer": snapped(_timer, 0.001),
		"intangibility": snapped(_intangibility_timer, 0.001),
		"dir": _tech_dir,
		"vx": snapped(character.velocity.x, 0.001)
	})

	if _timer <= 0.0:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
		if character.is_on_floor():
			var input_vec: Vector2 = character.get_input_vector()
			if abs(input_vec.x) > 0.1:
				dbg("to_run", {"reason": "ukemi_finished_ground_input"})
				state_machine.transition_to("Run")
			else:
				dbg("to_idle", {"reason": "ukemi_finished_ground"})
				state_machine.transition_to("Idle")
		else:
			dbg("to_fall", {"reason": "ukemi_finished_air"})
			state_machine.transition_to("Fall")