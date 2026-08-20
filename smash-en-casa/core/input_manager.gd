# ==============================================================================
# InputManager (Autoload / Singleton Core)
# Responsabilidad: Mapeo global de controles (P1/P2) y consulta centralizada de inputs.
# Nota: No altera directamente físicas ni lógica de combate de los personajes.
# ==============================================================================
extends Node

# Mapeo de controles por jugador (Player 1, Player 2)

var last_press_time: Dictionary = {
	1: {"left": -10.0, "right": -10.0},
	2: {"left": -10.0, "right": -10.0}
}
var key_released_between: Dictionary = {
	1: {"left": true, "right": true},
	2: {"left": true, "right": true}
}
var is_dash_intent: Dictionary = {
	1: false,
	2: false
}

func _ready() -> void:
	_setup_default_input_map()

func _setup_default_input_map() -> void:
	# =========================================================================
	# JUGADOR 1 (P1): Teclado (WASD + J/K/L) + Joystick (Device 0)
	# =========================================================================
	# Teclado P1
	_register_action_key("p1_left", KEY_A)
	_register_action_key("p1_right", KEY_D)
	_register_action_key("p1_up", KEY_W)
	_register_action_key("p1_down", KEY_S)
	_register_action_key("p1_jump", KEY_SPACE)
	_register_action_key("p1_attack", KEY_J)
	_register_action_key("p1_special", KEY_K)
	_register_action_key("p1_shield", KEY_L)

	# Joystick P1 (Device 0)
	_register_action_joy_axis("p1_left", JOY_AXIS_LEFT_X, -1.0, 0)
	_register_action_joy_axis("p1_right", JOY_AXIS_LEFT_X, 1.0, 0)
	_register_action_joy_axis("p1_up", JOY_AXIS_LEFT_Y, -1.0, 0)
	_register_action_joy_axis("p1_down", JOY_AXIS_LEFT_Y, 1.0, 0)
	_register_action_joy_button("p1_left", JOY_BUTTON_DPAD_LEFT, 0)
	_register_action_joy_button("p1_right", JOY_BUTTON_DPAD_RIGHT, 0)
	_register_action_joy_button("p1_up", JOY_BUTTON_DPAD_UP, 0)
	_register_action_joy_button("p1_down", JOY_BUTTON_DPAD_DOWN, 0)
	_register_action_joy_button("p1_jump", JOY_BUTTON_X, 0)
	_register_action_joy_button("p1_jump", JOY_BUTTON_Y, 0)
	_register_action_joy_button("p1_attack", JOY_BUTTON_A, 0)
	_register_action_joy_button("p1_special", JOY_BUTTON_B, 0)
	_register_action_joy_button("p1_shield", JOY_BUTTON_RIGHT_SHOULDER, 0)
	_register_action_joy_button("p1_shield", JOY_BUTTON_LEFT_SHOULDER, 0)
	_register_action_joy_axis("p1_shield", JOY_AXIS_TRIGGER_RIGHT, 1.0, 0)
	_register_action_joy_axis("p1_shield", JOY_AXIS_TRIGGER_LEFT, 1.0, 0)

	# =========================================================================
	# JUGADOR 2 (P2): Teclado (Flechas + B/N/M/V o Numpad) + Joystick (Device 1)
	# =========================================================================
	# Teclado P2 - Primario
	_register_action_key("p2_left", KEY_LEFT)
	_register_action_key("p2_right", KEY_RIGHT)
	_register_action_key("p2_up", KEY_UP)
	_register_action_key("p2_down", KEY_DOWN)
	_register_action_key("p2_jump", KEY_B)
	_register_action_key("p2_attack", KEY_N)
	_register_action_key("p2_special", KEY_M)
	_register_action_key("p2_shield", KEY_V)

	# Teclado P2 - Secundario (Numpad)
	_register_action_key("p2_jump", KEY_KP_0)
	_register_action_key("p2_attack", KEY_KP_1)
	_register_action_key("p2_special", KEY_KP_2)
	_register_action_key("p2_shield", KEY_KP_3)

	# Joystick P2 (Device 1)
	_register_action_joy_axis("p2_left", JOY_AXIS_LEFT_X, -1.0, 1)
	_register_action_joy_axis("p2_right", JOY_AXIS_LEFT_X, 1.0, 1)
	_register_action_joy_axis("p2_up", JOY_AXIS_LEFT_Y, -1.0, 1)
	_register_action_joy_axis("p2_down", JOY_AXIS_LEFT_Y, 1.0, 1)
	_register_action_joy_button("p2_left", JOY_BUTTON_DPAD_LEFT, 1)
	_register_action_joy_button("p2_right", JOY_BUTTON_DPAD_RIGHT, 1)
	_register_action_joy_button("p2_up", JOY_BUTTON_DPAD_UP, 1)
	_register_action_joy_button("p2_down", JOY_BUTTON_DPAD_DOWN, 1)
	_register_action_joy_button("p2_jump", JOY_BUTTON_X, 1)
	_register_action_joy_button("p2_jump", JOY_BUTTON_Y, 1)
	_register_action_joy_button("p2_attack", JOY_BUTTON_A, 1)
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
	
	var existing_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for ev in existing_events:
		if ev is InputEventKey and ev.physical_keycode == keycode:
			return
			
	InputMap.action_add_event(action_name, event)

func _register_action_joy_button(action_name: String, button_index: JoyButton, device_id: int = 0) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.device = device_id
	
	var existing_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for ev in existing_events:
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
	
	var existing_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for ev in existing_events:
		if ev is InputEventJoypadMotion and ev.axis == axis and sign(ev.axis_value) == sign(axis_value) and ev.device == device_id:
			return
			
	InputMap.action_add_event(action_name, event)

func _input(event: InputEvent) -> void:
	for p_id in [1, 2]:
		var prefix: String = "p%d_" % p_id
		var now: float = Time.get_ticks_msec() / 1000.0

		# Izquierda
		if event.is_action_pressed(prefix + "left", false) and not event.is_echo():
			var dt: float = now - last_press_time[p_id]["left"]
			if key_released_between[p_id]["left"] and dt >= 0.05 and dt <= 0.28:
				is_dash_intent[p_id] = true
			else:
				is_dash_intent[p_id] = false
			last_press_time[p_id]["left"] = now
			key_released_between[p_id]["left"] = false

		elif event.is_action_released(prefix + "left"):
			key_released_between[p_id]["left"] = true

		# Derecha
		if event.is_action_pressed(prefix + "right", false) and not event.is_echo():
			var dt: float = now - last_press_time[p_id]["right"]
			if key_released_between[p_id]["right"] and dt >= 0.05 and dt <= 0.28:
				is_dash_intent[p_id] = true
			else:
				is_dash_intent[p_id] = false
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
	var result: bool = is_dash_intent.get(player_id, false)
	if result:
		is_dash_intent[player_id] = false
	return result

func is_jump_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_jump" % player_id)

func is_attack_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_attack" % player_id)

func is_special_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_special" % player_id)

func is_shield_pressed(player_id: int) -> bool:
	return Input.is_action_pressed("p%d_shield" % player_id)

func is_jump_held(player_id: int) -> bool:
	return Input.is_action_pressed("p%d_jump" % player_id)
