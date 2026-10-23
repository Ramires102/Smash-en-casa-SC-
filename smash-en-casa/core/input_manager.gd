extends Node

var last_press_time: Dictionary = {
	1: {"left": -10.0, "right": -10.0},
	2: {"left": -10.0, "right": -10.0}
}
var key_released_between: Dictionary = {
	1: {"left": true, "right": true},
	2: {"left": true, "right": true}
}
# Guarda el timestamp del último intento de dash para que dure una ventana de ~0.13s (8 frames)
var dash_intent_timestamp: Dictionary = {
	1: -10.0,
	2: -10.0
}
var _prev_move_x: Dictionary = {
	1: 0.0,
	2: 0.0
}

const DASH_BUFFER_WINDOW: float = 0.13
const STICK_FLICK_THRESHOLD: float = 0.55

func _ready() -> void:
	_setup_default_input_map()
	_setup_ui_input_map()

func _physics_process(_delta: float) -> void:
	# Detectar "Smash Flick" en joystick o cambio brusco de dirección (Dash-Dance)
	var now: float = Time.get_ticks_msec() / 1000.0
	for p_id in [1, 2]:
		var current_x: float = get_move_vector(p_id).x
		var prev_x: float = _prev_move_x[p_id]
		# Si el stick pasa rápido de zona neutra/opuesta a extremo (>0.78), registrar Dash
		if absf(current_x) >= 0.78 and (absf(current_x - prev_x) >= STICK_FLICK_THRESHOLD or signf(current_x) != signf(prev_x)):
			dash_intent_timestamp[p_id] = now
		_prev_move_x[p_id] = current_x

func _setup_ui_input_map() -> void:
	for dev in [0, 1]:
		_register_action_joy_button("ui_accept", JOY_BUTTON_A, dev)
		_register_action_joy_button("ui_select", JOY_BUTTON_A, dev)
		_register_action_joy_button("ui_cancel", JOY_BUTTON_B, dev)
		_register_action_joy_button("ui_cancel", JOY_BUTTON_START, dev)
		_register_action_joy_button("ui_left", JOY_BUTTON_DPAD_LEFT, dev)
		_register_action_joy_button("ui_right", JOY_BUTTON_DPAD_RIGHT, dev)
		_register_action_joy_button("ui_up", JOY_BUTTON_DPAD_UP, dev)
		_register_action_joy_button("ui_down", JOY_BUTTON_DPAD_DOWN, dev)
		_register_action_joy_axis("ui_left", JOY_AXIS_LEFT_X, -1.0, dev)
		_register_action_joy_axis("ui_right", JOY_AXIS_LEFT_X, 1.0, dev)
		_register_action_joy_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0, dev)
		_register_action_joy_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0, dev)

func _setup_default_input_map() -> void:
	# JUGADOR 1 (P1)
	_register_action_key("p1_left", KEY_A)
	_register_action_key("p1_right", KEY_D)
	_register_action_key("p1_up", KEY_W)
	_register_action_key("p1_down", KEY_S)
	_register_action_key("p1_jump", KEY_SPACE)
	_register_action_key("p1_attack", KEY_J)
	_register_action_key("p1_special", KEY_K)
	_register_action_key("p1_shield", KEY_L)

	_register_action_joy_axis("p1_left", JOY_AXIS_LEFT_X, -1.0, 0)
	_register_action_joy_axis("p1_right", JOY_AXIS_LEFT_X, 1.0, 0)
	_register_action_joy_axis("p1_up", JOY_AXIS_LEFT_Y, -1.0, 0)
	_register_action_joy_axis("p1_down", JOY_AXIS_LEFT_Y, 1.0, 0)
	_register_action_joy_button("p1_left", JOY_BUTTON_DPAD_LEFT, 0)
	_register_action_joy_button("p1_right", JOY_BUTTON_DPAD_RIGHT, 0)
	_register_action_joy_button("p1_up", JOY_BUTTON_DPAD_UP, 0)
	_register_action_joy_button("p1_down", JOY_BUTTON_DPAD_DOWN, 0)
	_register_action_joy_button("p1_jump", JOY_BUTTON_A, 0)
	_register_action_joy_button("p1_attack", JOY_BUTTON_X, 0)
	_register_action_joy_button("p1_attack", JOY_BUTTON_Y, 0)
	_register_action_joy_button("p1_special", JOY_BUTTON_B, 0)
	_register_action_joy_button("p1_shield", JOY_BUTTON_RIGHT_SHOULDER, 0)
	_register_action_joy_button("p1_shield", JOY_BUTTON_LEFT_SHOULDER, 0)
	_register_action_joy_axis("p1_shield", JOY_AXIS_TRIGGER_RIGHT, 1.0, 0)
	_register_action_joy_axis("p1_shield", JOY_AXIS_TRIGGER_LEFT, 1.0, 0)

	# JUGADOR 2 (P2)
	_register_action_key("p2_left", KEY_LEFT)
	_register_action_key("p2_right", KEY_RIGHT)
	_register_action_key("p2_up", KEY_UP)
	_register_action_key("p2_down", KEY_DOWN)
	_register_action_key("p2_jump", KEY_B)
	_register_action_key("p2_attack", KEY_N)
	_register_action_key("p2_special", KEY_M)
	_register_action_key("p2_shield", KEY_V)

	_register_action_key("p2_jump", KEY_KP_0)
	_register_action_key("p2_attack", KEY_KP_1)
	_register_action_key("p2_special", KEY_KP_2)
	_register_action_key("p2_shield", KEY_KP_3)

	_register_action_joy_axis("p2_left", JOY_AXIS_LEFT_X, -1.0, 1)
	_register_action_joy_axis("p2_right", JOY_AXIS_LEFT_X, 1.0, 1)
	_register_action_joy_axis("p2_up", JOY_AXIS_LEFT_Y, -1.0, 1)
	_register_action_joy_axis("p2_down", JOY_AXIS_LEFT_Y, 1.0, 1)
	_register_action_joy_button("p2_left", JOY_BUTTON_DPAD_LEFT, 1)
	_register_action_joy_button("p2_right", JOY_BUTTON_DPAD_RIGHT, 1)
	_register_action_joy_button("p2_up", JOY_BUTTON_DPAD_UP, 1)
	_register_action_joy_button("p2_down", JOY_BUTTON_DPAD_DOWN, 1)
	_register_action_joy_button("p2_jump", JOY_BUTTON_A, 1)
	_register_action_joy_button("p2_attack", JOY_BUTTON_X, 1)
	_register_action_joy_button("p2_attack", JOY_BUTTON_Y, 1)
	_register_action_joy_button("p2_special", JOY_BUTTON_B, 1)
	_register_action_joy_button("p2_shield", JOY_BUTTON_RIGHT_SHOULDER, 1)
	_register_action_joy_button("p2_shield", JOY_BUTTON_LEFT_SHOULDER, 1)
	_register_action_joy_axis("p2_shield", JOY_AXIS_TRIGGER_RIGHT, 1.0, 1)
	_register_action_joy_axis("p2_shield", JOY_AXIS_TRIGGER_LEFT, 1.0, 1)

func _register_action_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey and ev.physical_keycode == keycode:
			return
	InputMap.action_add_event(action_name, event)

func _register_action_joy_button(action_name: String, button_index: JoyButton, device_id: int = 0) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.device = device_id
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventJoypadButton and ev.button_index == button_index and ev.device == device_id:
			return
	InputMap.action_add_event(action_name, event)

func _register_action_joy_axis(action_name: String, axis: JoyAxis, axis_value: float, device_id: int = 0) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	event.device = device_id
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventJoypadMotion and ev.axis == axis and signf(ev.axis_value) == signf(axis_value) and ev.device == device_id:
			return
	InputMap.action_add_event(action_name, event)

func _input(event: InputEvent) -> void:
	for p_id in [1, 2]:
		var prefix: String = "p%d_" % p_id
		var now: float = Time.get_ticks_msec() / 1000.0

		if event.is_action_pressed(prefix + "left", false) and not event.is_echo():
			var dt: float = now - last_press_time[p_id]["left"]
			if key_released_between[p_id]["left"] and dt >= 0.03 and dt <= 0.30:
				dash_intent_timestamp[p_id] = now
			last_press_time[p_id]["left"] = now
			key_released_between[p_id]["left"] = false
		elif event.is_action_released(prefix + "left"):
			key_released_between[p_id]["left"] = true

		if event.is_action_pressed(prefix + "right", false) and not event.is_echo():
			var dt: float = now - last_press_time[p_id]["right"]
			if key_released_between[p_id]["right"] and dt >= 0.03 and dt <= 0.30:
				dash_intent_timestamp[p_id] = now
			last_press_time[p_id]["right"] = now
			key_released_between[p_id]["right"] = false
		elif event.is_action_released(prefix + "right"):
			key_released_between[p_id]["right"] = true

func get_move_vector(player_id: int) -> Vector2:
	var prefix: String = "p%d_" % player_id
	var move_x: float = Input.get_action_strength(prefix + "right") - Input.get_action_strength(prefix + "left")
	var move_y: float = Input.get_action_strength(prefix + "up") - Input.get_action_strength(prefix + "down")
	return Vector2(move_x, move_y)

func is_dash_pressed(player_id: int) -> bool:
	var now: float = Time.get_ticks_msec() / 1000.0
	var move_x: float = get_move_vector(player_id).x
	if absf(move_x) < 0.2:
		return false
	return (now - dash_intent_timestamp.get(player_id, -10.0)) <= DASH_BUFFER_WINDOW

func consume_dash_intent(player_id: int) -> void:
	dash_intent_timestamp[player_id] = -10.0

func is_jump_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_jump" % player_id)

func is_attack_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_attack" % player_id)

func is_special_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_special" % player_id)

func is_shield_pressed(player_id: int) -> bool:
	return Input.is_action_pressed("p%d_shield" % player_id)

func is_shield_just_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_shield" % player_id)

func is_jump_held(player_id: int) -> bool:
	return Input.is_action_pressed("p%d_jump" % player_id)

func get_player_input(player_id: int) -> PlayerInput:
	var pi := PlayerInput.new()
	pi.movement = get_move_vector(player_id)
	pi.is_dash = is_dash_pressed(player_id)
	pi.jump_pressed = is_jump_pressed(player_id)
	pi.jump_held = is_jump_held(player_id)
	pi.attack_pressed = is_attack_pressed(player_id)
	pi.special_pressed = is_special_pressed(player_id)
	pi.shield_pressed = is_shield_pressed(player_id)
	pi.shield_just_pressed = is_shield_just_pressed(player_id)
	return pi
