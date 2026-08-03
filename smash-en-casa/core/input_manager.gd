extends Node

# Mapeo de controles por jugador (Player 1, Player 2)

func _ready() -> void:
	_setup_default_input_map()

func _setup_default_input_map() -> void:
	# Controles P1 (Teclado)
	_register_action_key("p1_left", KEY_A)
	_register_action_key("p1_right", KEY_D)
	_register_action_key("p1_up", KEY_W)
	_register_action_key("p1_down", KEY_S)
	_register_action_key("p1_jump", KEY_SPACE)
	_register_action_key("p1_attack", KEY_J)
	_register_action_key("p1_special", KEY_K)
	_register_action_key("p1_shield", KEY_L)

	# Controles P2 (Teclado secundario)
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
	
	# Evitar agregar duplicados
	var existing_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for ev in existing_events:
		if ev is InputEventKey and ev.physical_keycode == keycode:
			return
			
	InputMap.action_add_event(action_name, event)

func get_move_vector(player_id: int) -> Vector2:
	var prefix: String = "p%d_" % player_id
	var move_x: float = Input.get_action_strength(prefix + "right") - Input.get_action_strength(prefix + "left")
	var move_y: float = Input.get_action_strength(prefix + "up") - Input.get_action_strength(prefix + "down")
	return Vector2(move_x, move_y)

func is_jump_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_jump" % player_id)

func is_attack_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_attack" % player_id)

func is_special_pressed(player_id: int) -> bool:
	return Input.is_action_just_pressed("p%d_special" % player_id)

func is_shield_pressed(player_id: int) -> bool:
	return Input.is_action_pressed("p%d_shield" % player_id)
