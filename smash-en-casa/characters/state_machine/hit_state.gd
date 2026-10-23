class_name HitState
extends State

var _pending_knockback: Vector2 = Vector2.ZERO
var _hitlag_remaining: int = 0
var _hitstun_remaining: int = 0
var _knockback_scalar: float = 0.0
var _captured_hitlag_di: Vector2 = Vector2.ZERO
var _prev_sdi_dir: Vector2 = Vector2.ZERO
var _hdecay: float = 0.0
var _vdecay: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Hit", 1.0, 0.02)

	var knockback_vector: Vector2 = msg.get("knockback", Vector2.ZERO)
	var hitstun_frames: int = msg.get("hitstun_frames", 16)
	var hitlag_frames: int = msg.get("hitlag_frames", 5)

	_pending_knockback = knockback_vector
	_knockback_scalar = msg.get("knockback_scalar", knockback_vector.length() / Constants.KB_VELOCITY_SCALE)
	_hitlag_remaining = hitlag_frames
	_hitstun_remaining = maxi(1, hitstun_frames)
	_captured_hitlag_di = Vector2.ZERO
	_prev_sdi_dir = Vector2.ZERO
	_hdecay = absf(float(msg.get("hdecay", 0.0)))
	_vdecay = absf(float(msg.get("vdecay", 0.0)))

	if character:
		character.velocity = Vector2.ZERO
		character.is_fast_falling = false
		if _hitlag_remaining > 0 and character.anim_controller and character.anim_controller.has_method("set_paused"):
			character.anim_controller.set_paused(true)

	if _knockback_scalar >= 14.0:
		var shake_amt: float = clampf((_knockback_scalar - 10.0) * 0.22, 2.5, 11.0)
		Events.camera_shake_requested.emit(shake_amt)

func exit() -> void:
	_hitlag_remaining = 0
	_hitstun_remaining = 0
	if character and character.anim_controller and character.anim_controller.has_method("set_paused"):
		character.anim_controller.set_paused(false)
	_restore_visual_offset()

func physics_update(_delta: float) -> void:
	if character == null:
		return

	# ── Fase 1: Hitlag (Freeze frames + SDI + Vibración visual) ──────────
	if _hitlag_remaining > 0:
		_hitlag_remaining -= 1
		var stick: Vector2 = character.get_input_vector()
		if stick.length() > Constants.HITLAG_DI_DEADZONE:
			_captured_hitlag_di = stick
			# SDI (Smash Directional Influence)
			if stick.length() > 0.68 and (stick - _prev_sdi_dir).length() > 0.45:
				character.global_position += Vector2(stick.x, -stick.y).normalized() * 4.0
				_prev_sdi_dir = stick
		character.velocity = Vector2.ZERO
		_apply_hitlag_shake()

		if _hitlag_remaining == 0:
			_restore_visual_offset()
			if character.anim_controller and character.anim_controller.has_method("set_paused"):
				character.anim_controller.set_paused(false)

			var di_result: Dictionary = KnockbackCalculator.apply_hitlag_di(_pending_knockback, _captured_hitlag_di)
			_pending_knockback = di_result.get("vector", _pending_knockback)
			_hdecay = absf(float(di_result.get("hdecay", _hdecay)))
			_vdecay = absf(float(di_result.get("vdecay", _vdecay)))

			# Si el golpe tiene componente hacia arriba (vy < 0) y el personaje está en el suelo, despegarlo
			if _pending_knockback.y < -20.0 and character.is_on_floor():
				character.global_position.y -= 2.0

			character.velocity = _pending_knockback
		return

	# ── Fase 2: Hitstun real con trayectoria parabólica limpia ───────────
	_hitstun_remaining -= 1

	# Rebote contra paredes/suelo/techo a alto Knockback
	if _knockback_scalar >= Constants.BOUNCE_KB_THRESHOLD and character.get_slide_collision_count() > 0:
		var collision: KinematicCollision2D = character.get_last_slide_collision()
		if collision and _pending_knockback.length() > 160.0:
			var normal: Vector2 = collision.get_normal()
			character.velocity = _pending_knockback.bounce(normal) * Constants.BOUNCE_ELASTICITY
			_pending_knockback = character.velocity
		else:
			_pending_knockback = character.velocity
	else:
		_pending_knockback = character.velocity

	# Decay horizontal suave (la gravedad vertical ya la aplica character.gd con mult 0.42)
	var h_step: float = maxf(4.5, _hdecay * Constants.KB_DECAY_H_FACTOR)
	if character.is_on_floor():
		h_step *= 1.65 # Mayor fricción si se desliza por el piso
	character.velocity.x = move_toward(character.velocity.x, 0.0, h_step)

	# Ligera deriva aérea durante hitstun
	var drift_input: Vector2 = character.get_input_vector()
	if not character.is_on_floor() and absf(drift_input.x) > 0.15:
		character.velocity.x += drift_input.x * 2.8

	# Fin del Hitstun
	if _hitstun_remaining <= 0:
		if not character.is_on_floor() and _knockback_scalar >= Constants.TUMBLE_KB_THRESHOLD:
			state_machine.transition_to("Tumble", {
				"initial_velocity": character.velocity,
				"hitstun_frames": 0,
				"knockback_scalar": _knockback_scalar
			})
		elif character.is_on_floor():
			var input_vec: Vector2 = character.get_input_vector()
			if absf(input_vec.x) > 0.15:
				state_machine.transition_to("Dash" if absf(input_vec.x) > 0.65 else "Walk")
			else:
				state_machine.transition_to("Idle")
		else:
			state_machine.transition_to("Fall")

func _apply_hitlag_shake() -> void:
	if character and character.visual_controller:
		var amp: float = clampf(_knockback_scalar * 0.0022, 0.03, 0.09)
		var sign_dir: float = 1.0 if (_hitlag_remaining % 2 == 0) else -1.0
		character.visual_controller.hitlag_shake_offset = Vector3(
			sign_dir * amp,
			randf_range(-amp * 0.4, amp * 0.4),
			0.0
		)

func _restore_visual_offset() -> void:
	if character and character.visual_controller:
		character.visual_controller.hitlag_shake_offset = Vector3.ZERO
