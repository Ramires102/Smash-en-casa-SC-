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
	_register_action_key("p1_left", KEY_A)
	_register_action_key("p1_right", KEY_D)
	_register_action_key("p1_up", KEY_W)
	_register_action_key("p1_down", KEY_S)
	_register_action_key("p1_jump", KEY_SPACE)
	_register_action_key("p1_attack", KEY_J)
	_register_action_key("p1_special", KEY_K)
	_register_action_key("p1_shield", KEY_L)

	_register_action_key("p2_left", KEY_LEFT)
	_register_action_key("p2_right", KEY_RIGHT)
	_register_action_key("p2_up", KEY_UP)
	_register_action_key("p2_down", KEY_DOWN)
	_register_action_key("p2_jump", KEY_B)
	_register_action_key("p2_jump", KEY_KP_0)
	_register_action_key("p2_attack", KEY_N)
	_register_action_key("p2_attack", KEY_KP_1)
	_register_action_key("p2_special", KEY_M)
	_register_action_key("p2_special", KEY_KP_2)
	_register_action_key("p2_shield", KEY_V)
	_register_action_key("p2_shield", KEY_KP_3)

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
