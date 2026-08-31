class_name TumbleState
extends State

## Estado de Tumble 2D puro porteado 1:1 desde Splash N Dash (CharacterSM.gd:882-911).
## Permite: air movement 2D completo, doble salto, air dodge, teching al aterrizar.

var _hitstun_remaining: int = 0
var _entry_speed: float = 0.0
var _knockback_scalar: float = 0.0

# ── Tech Window (CharacterSM.gd:900-908) ──
var _tech_frames: int = 999
var _tech_cooldown: int = 0

var _hdecay: float = 0.0
var _vdecay: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	_hitstun_remaining = msg.get("hitstun_frames", 0)
	_knockback_scalar = msg.get("knockback_scalar", 0.0)
	_hdecay = msg.get("hdecay", 0.0)
	_vdecay = msg.get("vdecay", 0.0)
	_tech_frames = 999
	_tech_cooldown = 0

	if character:
		if msg.has("initial_velocity"):
			character.velocity = msg["initial_velocity"]
		_entry_speed = character.velocity.length()
		character.is_fast_falling = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

	dbg("enter", {
		"hitstun_frames": _hitstun_remaining,
		"kb_scalar": snapped(_knockback_scalar, 0.01),
		"entry_speed": snapped(_entry_speed, 0.01)
	})

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)
	dbg("exit", {
		"remaining_hitstun": _hitstun_remaining,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	if character == null:
		return

	# ── Air Movement exacto de SND 2D (CharacterSM.gd:884 → AIRMOVEMENT()) ──
	_apply_snd_air_movement(delta)
	
	# ── Tech Window (CharacterSM.gd:900-902) ──
	if _tech_cooldown > 0:
		_tech_cooldown -= 1
	
	if character.is_shield_just_pressed() and _tech_cooldown == 0:
		_tech_frames = 0
		_tech_cooldown = Constants.TECH_COOLDOWN_FRAMES
	else:
		_tech_frames += 1
	
	# ── Doble salto para salir de Tumble (CharacterSM.gd:885-893) ──
	if character.is_jump_just_pressed() and character.air_jumps_left > 0:
		character.is_fast_falling = false
		character.velocity.y = -character.controller.get_jump_velocity() if character.controller else -500.0
		character.air_jumps_left -= 1
		var input_vec: Vector2 = character.get_input_vector()
		if input_vec.x < -0.1:
			character.velocity.x = -(character.controller.get_air_speed() if character.controller else 280.0)
		elif input_vec.x > 0.1:
			character.velocity.x = (character.controller.get_air_speed() if character.controller else 280.0)
		dbg("to_fall_djump", {"reason": "double_jump_from_tumble"})
		state_machine.transition_to("Fall")
		return
	
	# ── Air Dodge desde Tumble (CharacterSM.gd:896-898) ──
	if character.is_shield_pressed() and character.can_air_dodge:
		dbg("to_airdodge", {"reason": "shield_in_tumble"})
		state_machine.transition_to("AirDodge")
		return

	# ── Aterrizar: Tech o Missed Tech (CharacterSM.gd:904-908) ──
	if character.is_on_floor():
		character.is_fast_falling = false
		character.velocity.y = 0.0
		
		# Si tech_frames < 20 → Tech exitoso
		if _tech_frames < Constants.TECH_WINDOW_FRAMES:
			var input_vec_ground: Vector2 = character.get_input_vector()
			var tech_dir: int = 0
			if input_vec_ground.x > 0.45:
				tech_dir = 1
			elif input_vec_ground.x < -0.45:
				tech_dir = -1
			
			dbg("to_ukemi", {
				"dir": tech_dir,
				"tech_frames": _tech_frames
			})
			state_machine.transition_to("Ukemi", {"dir": tech_dir})
			return
		
		# Missed Tech: 7 frames de landing lag
		dbg("missed_tech", {
			"tech_frames": _tech_frames,
			"lag_frames": Constants.MISSED_TECH_LANDING_LAG
		})
		state_machine.transition_to("Idle", {
			"landing_lag": Constants.MISSED_TECH_LANDING_LAG
		})
		return

	dbg_tick(delta, {
		"hitstun_remaining": _hitstun_remaining,
		"tech_frames": _tech_frames,
		"tech_cooldown": _tech_cooldown,
		"on_floor": character.is_on_floor(),
		"vx": snapped(character.velocity.x, 0.001),
		"vy": snapped(character.velocity.y, 0.001),
		"speed": snapped(character.velocity.length(), 0.01)
	})

## Movimiento aéreo exacto de SND 2D (CharacterSM.gd:1978-2014)
func _apply_snd_air_movement(delta: float) -> void:
	if character == null or character.controller == null:
		return
	
	var ctrl: CharacterController = character.controller
	var input_vec: Vector2 = character.get_input_vector()
	
	# ── Fast Fall (CharacterSM.gd:1981-1987) ──
	if character.is_down_just_pressed() and character.velocity.y > 0.0 and not character.is_fast_falling:
		character.velocity.y = ctrl.get_fast_fall_speed()
		character.is_fast_falling = true
	if character.is_fast_falling:
		character.velocity.y = ctrl.get_fast_fall_speed()

	# ── Aceleración/fricción aérea diferencial compartida ──
	ctrl.apply_snd_air_movement(input_vec.x, delta)
	if absf(input_vec.x) > 0.1:
		character.update_facing_direction(input_vec.x)