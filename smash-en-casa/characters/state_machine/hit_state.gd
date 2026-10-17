class_name HitState
extends State

## Estado de Hitstun 2D puro porteado 1:1 desde Splash N Dash (CharacterSM.gd:848-879).
## Implementa: hitlag freeze, wall/floor bounce 2D, per-component decay, y transición a Tumble.

var _pending_knockback: Vector2 = Vector2.ZERO
var _hitlag_remaining: int = 0
var _hitstun_remaining: int = 0
var _knockback_scalar: float = 0.0  ## KB escalar de SND para bounce/tumble thresholds
var _captured_hitlag_di: Vector2 = Vector2.ZERO
var _prev_sdi_dir: Vector2 = Vector2.ZERO

# ── Per-component decay de SND (Hitboxes.gd:108-118, CharacterSM.gd:862-870) ──
var _hdecay: float = 0.0
var _vdecay: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Hit", 1.0, 0.02)

	var knockback_vector: Vector2 = msg.get("knockback", Vector2.ZERO)
	var hitstun_frames: int = msg.get("hitstun_frames", 20)
	var hitlag_frames: int = msg.get("hitlag_frames", 6)

	_pending_knockback = knockback_vector
	_knockback_scalar = msg.get("knockback_scalar", knockback_vector.length())
	_hitlag_remaining = hitlag_frames
	_hitstun_remaining = maxi(1, hitstun_frames)
	_captured_hitlag_di = Vector2.ZERO
	_prev_sdi_dir = Vector2.ZERO
	
	_hdecay = msg.get("hdecay", 0.0)
	_vdecay = msg.get("vdecay", 0.0)

	if character:
		character.velocity = Vector2.ZERO
		if _hitlag_remaining > 0 and character.anim_controller and character.anim_controller.has_method("set_paused"):
			character.anim_controller.set_paused(true)

	# Activar cámara shake proporcional en impactos fuertes
	if _knockback_scalar >= 18.0:
		var shake_amt: float = clampf((_knockback_scalar - 14.0) * 0.16, 2.0, 10.0)
		Events.camera_shake_requested.emit(shake_amt)

	dbg("enter", {
		"knockback": {
			"x": snapped(knockback_vector.x, 0.001),
			"y": snapped(knockback_vector.y, 0.001),
			"length": snapped(knockback_vector.length(), 0.001)
		},
		"kb_scalar": snapped(_knockback_scalar, 0.001),
		"hitlag_frames": hitlag_frames,
		"hitstun_frames": _hitstun_remaining,
		"hdecay": snapped(_hdecay, 0.001),
		"vdecay": snapped(_vdecay, 0.001)
	})

func exit() -> void:
	_hitlag_remaining = 0
	_hitstun_remaining = 0
	if character and character.anim_controller and character.anim_controller.has_method("set_paused"):
		character.anim_controller.set_paused(false)
	_restore_visual_offset()
	dbg("exit", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	# ── Fase 1: Hitlag (Freeze frames con SDI + micro-vibración) ──
	if _hitlag_remaining > 0:
		_hitlag_remaining -= 1
		if character:
			var stick: Vector2 = character.get_input_vector()
			if stick.length() > Constants.HITLAG_DI_DEADZONE:
				_captured_hitlag_di = stick
			# SDI (Smash Directional Influence): desplazamientos discretos por flick
			if stick.length() > 0.68 and (stick - _prev_sdi_dir).length() > 0.45:
				character.global_position += Vector2(stick.x, -stick.y).normalized() * 4.5
			_prev_sdi_dir = stick
			character.velocity = Vector2.ZERO
		_apply_hitlag_shake()
		
		if _hitlag_remaining == 0:
			_restore_visual_offset()
			if character and character.anim_controller and character.anim_controller.has_method("set_paused"):
				character.anim_controller.set_paused(false)
			var di_result: Dictionary = KnockbackCalculator.apply_hitlag_di(_pending_knockback, _captured_hitlag_di)
			_pending_knockback = di_result.get("vector", _pending_knockback)
			_hdecay = float(di_result.get("hdecay", _hdecay))
			_vdecay = float(di_result.get("vdecay", _vdecay))
			if character:
				character.velocity = _pending_knockback
			dbg("hitlag_end", {
				"launch_speed": snapped(_pending_knockback.length(), 0.01),
				"di_x": snapped(_captured_hitlag_di.x, 0.001),
				"di_y": snapped(_captured_hitlag_di.y, 0.001)
			})
		return

	# ── Fase 2: Hitstun real con decay de Knockback estilo Smash Bros. ──
	_hitstun_remaining -= 1
	
	if character:
		# ── Wall/Floor Bounce 2D usando la última colisión de move_and_slide ──
		if _knockback_scalar >= Constants.BOUNCE_KB_THRESHOLD and character.get_slide_collision_count() > 0:
			var collision: KinematicCollision2D = character.get_last_slide_collision()
			if collision and _pending_knockback.length() > 140.0:
				var normal: Vector2 = collision.get_normal()
				character.velocity = _pending_knockback.bounce(normal) * Constants.BOUNCE_ELASTICITY
				_pending_knockback = character.velocity
		else:
			_pending_knockback = character.velocity

		# ── Decay vertical por frame ──
		var max_fall: float = character.get_terminal_fall_speed()
		if character.velocity.y < 0.0:
			character.velocity.y = move_toward(character.velocity.y, 0.0, _vdecay * Constants.KB_DECAY_V_FACTOR)
		elif character.velocity.y > max_fall:
			character.velocity.y = move_toward(character.velocity.y, max_fall, _vdecay * Constants.KB_DECAY_V_FACTOR)
		
		# ── Decay horizontal por frame ──
		var h_step: float = absf(_hdecay) * Constants.KB_DECAY_H_FACTOR
		if h_step < 6.0:
			h_step = 6.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, h_step)

		# ── Ligera deriva aérea durante hitstun (Hitstun Drift) ──
		var drift_input: Vector2 = character.get_input_vector()
		if not character.is_on_floor() and absf(drift_input.x) > 0.15:
			character.velocity.x += drift_input.x * 3.2

	dbg_tick(delta, {
		"hitstun_remaining": _hitstun_remaining,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"speed": snapped(character.velocity.length() if character else 0.0, 0.01)
	})

	# ── Fin del Hitstun → Transición a Tumble, Idle, Run o Fall ──
	if _hitstun_remaining <= 0:
		if character and not character.is_on_floor() and _knockback_scalar >= Constants.TUMBLE_KB_THRESHOLD:
			dbg("to_tumble_end", {"reason": "hitstun_expired_high_kb"})
			state_machine.transition_to("Tumble", {
				"initial_velocity": character.velocity,
				"hitstun_frames": 0,
				"knockback_scalar": _knockback_scalar
			})
		else:
			if character and character.is_on_floor():
				var input_vec: Vector2 = character.get_input_vector()
				if abs(input_vec.x) > 0.15:
					dbg("to_run", {"reason": "hitstun_finished_ground_input"})
					state_machine.transition_to("Run" if abs(input_vec.x) > 0.6 else "Walk")
				else:
					dbg("to_idle", {"reason": "hitstun_finished_ground"})
					state_machine.transition_to("Idle")
			else:
				dbg("to_fall", {"reason": "hitstun_finished_air"})
				state_machine.transition_to("Fall")

func _apply_hitlag_shake() -> void:
	if character and character.visual_controller:
		var amp: float = clampf(_knockback_scalar * 0.0018, 0.025, 0.075)
		var sign_dir: float = 1.0 if (_hitlag_remaining % 2 == 0) else -1.0
		character.visual_controller.hitlag_shake_offset = Vector3(
			sign_dir * amp,
			randf_range(-amp * 0.5, amp * 0.5),
			0.0
		)

func _restore_visual_offset() -> void:
	if character and character.visual_controller:
		character.visual_controller.hitlag_shake_offset = Vector3.ZERO

