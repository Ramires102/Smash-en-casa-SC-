extends Node

signal controls_updated
signal controller_connection_changed(device_id: int, connected: bool)

const MAX_PLAYERS: int = 4
const CONFIG_SAVE_PATH: String = "user://controls_config.json"
const PROFILES_DIR: String = "user://control_profiles"

const DASH_BUFFER_WINDOW: float = 0.13
const STICK_FLICK_THRESHOLD: float = 0.55

const BINDING_SLOTS: Array[String] = [
	"stick_up", "stick_down", "stick_left", "stick_right",
	"dpad_up", "dpad_down", "dpad_left", "dpad_right",
	"btn_a", "btn_b", "btn_x", "btn_y",
	"btn_lb", "btn_lt", "btn_rb", "btn_rt",
	"btn_start"
]

var last_press_time: Dictionary = {}
var key_released_between: Dictionary = {}
var dash_intent_timestamp: Dictionary = {}
var _prev_move_x: Dictionary = {}

# Configuración activa por jugador (1 a 4)
var player_configs: Dictionary = {}
# Perfiles guardados: nombre_perfil -> Dictionary (bindings, deadzone, range, vibration)
var saved_profiles: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_runtime_tracking()
	_init_default_configs()
	_load_saved_profiles()
	load_config()
	apply_all_configs()
	_setup_ui_input_map()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _init_runtime_tracking() -> void:
	for p_id in range(1, MAX_PLAYERS + 1):
		last_press_time[p_id] = {"left": -10.0, "right": -10.0}
		key_released_between[p_id] = {"left": true, "right": true}
		dash_intent_timestamp[p_id] = -10.0
		_prev_move_x[p_id] = 0.0

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	controller_connection_changed.emit(device_id, connected)

func _init_default_configs() -> void:
	for p_id in range(1, MAX_PLAYERS + 1):
		player_configs[p_id] = create_default_player_config(p_id, "gamepad")

func create_default_player_config(player_id: int, mode: String = "gamepad") -> Dictionary:
	var dev_idx: int = clampi(player_id - 1, 0, 3)
	var use_kb: bool = (mode == "keyboard")
	var bindings: Dictionary = get_default_keyboard_bindings(player_id) if use_kb else get_default_xbox_bindings()
	return {
		"connected": player_id <= 2,
		"device": "keyboard" if use_kb else ("joy_%d" % dev_idx),
		"profile": "Teclado P%d" % player_id if use_kb else "Default",
		"deadzone": 0.15,
		"range": 0.95,
		"vibration": true,
		"vibration_strength": 1.0,
		"keep_kb_fallback": (not use_kb and player_id <= 2),
		"bindings": bindings
	}

func get_default_xbox_bindings() -> Dictionary:
	return {
		"stick_up": {"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "dir": -1.0},
		"stick_down": {"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "dir": 1.0},
		"stick_left": {"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "dir": -1.0},
		"stick_right": {"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "dir": 1.0},
		"dpad_up": {"type": "joy_button", "button": JOY_BUTTON_DPAD_UP},
		"dpad_down": {"type": "joy_button", "button": JOY_BUTTON_DPAD_DOWN},
		"dpad_left": {"type": "joy_button", "button": JOY_BUTTON_DPAD_LEFT},
		"dpad_right": {"type": "joy_button", "button": JOY_BUTTON_DPAD_RIGHT},
		"btn_a": {"type": "joy_button", "button": JOY_BUTTON_A},
		"btn_b": {"type": "joy_button", "button": JOY_BUTTON_B},
		"btn_x": {"type": "joy_button", "button": JOY_BUTTON_X},
		"btn_y": {"type": "joy_button", "button": JOY_BUTTON_Y},
		"btn_lb": {"type": "joy_button", "button": JOY_BUTTON_LEFT_SHOULDER},
		"btn_lt": {"type": "joy_axis", "axis": JOY_AXIS_TRIGGER_LEFT, "dir": 1.0},
		"btn_rb": {"type": "joy_button", "button": JOY_BUTTON_RIGHT_SHOULDER},
		"btn_rt": {"type": "joy_axis", "axis": JOY_AXIS_TRIGGER_RIGHT, "dir": 1.0},
		"btn_start": {"type": "joy_button", "button": JOY_BUTTON_START}
	}

func get_default_keyboard_bindings(player_id: int) -> Dictionary:
	match player_id:
		1:
			return {
				"stick_up": {"type": "key", "keycode": KEY_W},
				"stick_down": {"type": "key", "keycode": KEY_S},
				"stick_left": {"type": "key", "keycode": KEY_A},
				"stick_right": {"type": "key", "keycode": KEY_D},
				"dpad_up": {"type": "none"},
				"dpad_down": {"type": "none"},
				"dpad_left": {"type": "none"},
				"dpad_right": {"type": "none"},
				"btn_a": {"type": "key", "keycode": KEY_SPACE},
				"btn_b": {"type": "key", "keycode": KEY_K},
				"btn_x": {"type": "key", "keycode": KEY_J},
				"btn_y": {"type": "none"},
				"btn_lb": {"type": "key", "keycode": KEY_L},
				"btn_lt": {"type": "none"},
				"btn_rb": {"type": "none"},
				"btn_rt": {"type": "none"},
				"btn_start": {"type": "key", "keycode": KEY_ESCAPE}
			}
		2:
			return {
				"stick_up": {"type": "key", "keycode": KEY_UP},
				"stick_down": {"type": "key", "keycode": KEY_DOWN},
				"stick_left": {"type": "key", "keycode": KEY_LEFT},
				"stick_right": {"type": "key", "keycode": KEY_RIGHT},
				"dpad_up": {"type": "none"},
				"dpad_down": {"type": "none"},
				"dpad_left": {"type": "none"},
				"dpad_right": {"type": "none"},
				"btn_a": {"type": "key", "keycode": KEY_B},
				"btn_b": {"type": "key", "keycode": KEY_M},
				"btn_x": {"type": "key", "keycode": KEY_N},
				"btn_y": {"type": "key", "keycode": KEY_KP_0},
				"btn_lb": {"type": "key", "keycode": KEY_V},
				"btn_lt": {"type": "none"},
				"btn_rb": {"type": "key", "keycode": KEY_KP_3},
				"btn_rt": {"type": "none"},
				"btn_start": {"type": "key", "keycode": KEY_ESCAPE}
			}
		3:
			return {
				"stick_up": {"type": "key", "keycode": KEY_I},
				"stick_down": {"type": "key", "keycode": KEY_K},
				"stick_left": {"type": "key", "keycode": KEY_J},
				"stick_right": {"type": "key", "keycode": KEY_L},
				"dpad_up": {"type": "none"},
				"dpad_down": {"type": "none"},
				"dpad_left": {"type": "none"},
				"dpad_right": {"type": "none"},
				"btn_a": {"type": "key", "keycode": KEY_U},
				"btn_b": {"type": "key", "keycode": KEY_P},
				"btn_x": {"type": "key", "keycode": KEY_O},
				"btn_y": {"type": "none"},
				"btn_lb": {"type": "key", "keycode": KEY_SEMICOLON},
				"btn_lt": {"type": "none"},
				"btn_rb": {"type": "none"},
				"btn_rt": {"type": "none"},
				"btn_start": {"type": "key", "keycode": KEY_ESCAPE}
			}
		_:
			return {
				"stick_up": {"type": "key", "keycode": KEY_KP_8},
				"stick_down": {"type": "key", "keycode": KEY_KP_5},
				"stick_left": {"type": "key", "keycode": KEY_KP_4},
				"stick_right": {"type": "key", "keycode": KEY_KP_6},
				"dpad_up": {"type": "none"},
				"dpad_down": {"type": "none"},
				"dpad_left": {"type": "none"},
				"dpad_right": {"type": "none"},
				"btn_a": {"type": "key", "keycode": KEY_KP_0},
				"btn_b": {"type": "key", "keycode": KEY_KP_2},
				"btn_x": {"type": "key", "keycode": KEY_KP_1},
				"btn_y": {"type": "none"},
				"btn_lb": {"type": "key", "keycode": KEY_KP_3},
				"btn_lt": {"type": "none"},
				"btn_rb": {"type": "none"},
				"btn_rt": {"type": "none"},
				"btn_start": {"type": "key", "keycode": KEY_ESCAPE}
			}

func get_empty_bindings() -> Dictionary:
	var b: Dictionary = {}
	for slot in BINDING_SLOTS:
		b[slot] = {"type": "none"}
	return b

func format_binding(binding: Dictionary) -> String:
	if binding == null or binding.is_empty():
		return "[not set]"
	var btype: String = str(binding.get("type", "none"))
	match btype:
		"none":
			return "[not set]"
		"key":
			var kc: int = int(binding.get("keycode", 0))
			if kc == 0:
				return "[not set]"
			var k_str: String = OS.get_keycode_string(kc as Key)
			return "Key " + k_str if k_str != "" else ("Key %d" % kc)
		"joy_button":
			var btn: int = int(binding.get("button", -1))
			match btn:
				JOY_BUTTON_A:
					return "Button 0"
				JOY_BUTTON_B:
					return "Button 1"
				JOY_BUTTON_X:
					return "Button 2"
				JOY_BUTTON_Y:
					return "Button 3"
				JOY_BUTTON_LEFT_SHOULDER:
					return "Button 4"
				JOY_BUTTON_RIGHT_SHOULDER:
					return "Button 5"
				JOY_BUTTON_BACK:
					return "Button 6"
				JOY_BUTTON_START:
					return "Button 7"
				JOY_BUTTON_GUIDE:
					return "Button 8"
				JOY_BUTTON_LEFT_STICK:
					return "Button 9"
				JOY_BUTTON_RIGHT_STICK:
					return "Button 10"
				JOY_BUTTON_DPAD_UP:
					return "Hat Up"
				JOY_BUTTON_DPAD_DOWN:
					return "Hat Down"
				JOY_BUTTON_DPAD_LEFT:
					return "Hat Left"
				JOY_BUTTON_DPAD_RIGHT:
					return "Hat Right"
				_:
					return "Button %d" % btn
		"joy_axis":
			var axis: int = int(binding.get("axis", 0))
			var dir: float = float(binding.get("dir", 1.0))
			if axis == JOY_AXIS_TRIGGER_LEFT:
				return "Axis 2"
			elif axis == JOY_AXIS_TRIGGER_RIGHT:
				return "Axis 5"
			elif axis == JOY_AXIS_LEFT_Y:
				# En Yuzu Arriba suele mostrarse como Axis 1+ y Abajo como Axis 1-
				return "Axis 1+" if dir < 0.0 else "Axis 1-"
			elif axis == JOY_AXIS_RIGHT_Y:
				return "Axis 4+" if dir < 0.0 else "Axis 4-"
			var sign_str: String = "+" if dir >= 0.0 else "-"
			return "Axis %d%s" % [axis, sign_str]
	return "[not set]"

func get_device_id_for_player(player_id: int) -> int:
	var cfg: Dictionary = player_configs.get(player_id, {})
	var dev_str: String = str(cfg.get("device", "joy_%d" % (player_id - 1)))
	if dev_str == "keyboard":
		return -1
	if dev_str.begins_with("joy_"):
		return int(dev_str.trim_prefix("joy_"))
	return clampi(player_id - 1, 0, 3)

func is_player_connected(player_id: int) -> bool:
	var cfg: Dictionary = player_configs.get(player_id, {})
	return bool(cfg.get("connected", player_id <= 2))

func get_player_profile_name(player_id: int) -> String:
	var cfg: Dictionary = player_configs.get(player_id, {})
	return str(cfg.get("profile", "Default"))

func get_player_config_copy(player_id: int) -> Dictionary:
	if not player_configs.has(player_id):
		player_configs[player_id] = create_default_player_config(player_id)
	return player_configs[player_id].duplicate(true)

func get_all_configs_copy() -> Dictionary:
	var copy: Dictionary = {}
	for p_id in range(1, MAX_PLAYERS + 1):
		copy[p_id] = get_player_config_copy(p_id)
	return copy

func set_all_configs(new_configs: Dictionary, save_to_disk: bool = true) -> void:
	for p_id in range(1, MAX_PLAYERS + 1):
		if new_configs.has(p_id):
			player_configs[p_id] = new_configs[p_id].duplicate(true)
	apply_all_configs()
	if save_to_disk:
		save_config()
	controls_updated.emit()

func apply_all_configs() -> void:
	for p_id in range(1, MAX_PLAYERS + 1):
		_apply_player_config_to_input_map(p_id)

func _apply_player_config_to_input_map(player_id: int) -> void:
	var prefix: String = "p%d_" % player_id
	var actions: Array[String] = ["left", "right", "up", "down", "jump", "attack", "special", "shield", "pause"]
	var cfg: Dictionary = player_configs.get(player_id, create_default_player_config(player_id))
	var deadzone: float = clampf(float(cfg.get("deadzone", 0.15)), 0.0, 0.5)

	for act in actions:
		var full_action: String = prefix + act
		if not InputMap.has_action(full_action):
			InputMap.add_action(full_action)
		InputMap.action_erase_events(full_action)
		InputMap.action_set_deadzone(full_action, deadzone)

	if not bool(cfg.get("connected", player_id <= 2)):
		return

	var dev_id: int = get_device_id_for_player(player_id)
	var bindings: Dictionary = cfg.get("bindings", {})

	var slot_to_action: Dictionary = {
		"stick_up": prefix + "up",
		"dpad_up": prefix + "up",
		"stick_down": prefix + "down",
		"dpad_down": prefix + "down",
		"stick_left": prefix + "left",
		"dpad_left": prefix + "left",
		"stick_right": prefix + "right",
		"dpad_right": prefix + "right",
		"btn_a": prefix + "jump",
		"btn_b": prefix + "special",
		"btn_x": prefix + "attack",
		"btn_y": prefix + "attack",
		"btn_lb": prefix + "shield",
		"btn_lt": prefix + "shield",
		"btn_rb": prefix + "shield",
		"btn_rt": prefix + "shield",
		"btn_start": prefix + "pause"
	}

	for slot in slot_to_action.keys():
		var action_name: String = slot_to_action[slot]
		var bind_data: Dictionary = bindings.get(slot, {"type": "none"})
		_add_binding_to_action(action_name, bind_data, dev_id)

	# Si el jugador está en el modo por defecto (Gamepad + Teclado para P1/P2), mantener las teclas por defecto también activas
	if bool(cfg.get("keep_kb_fallback", false)) and dev_id >= 0:
		if player_id == 1:
			_register_action_key("p1_left", KEY_A)
			_register_action_key("p1_right", KEY_D)
			_register_action_key("p1_up", KEY_W)
			_register_action_key("p1_down", KEY_S)
			_register_action_key("p1_jump", KEY_SPACE)
			_register_action_key("p1_attack", KEY_J)
			_register_action_key("p1_special", KEY_K)
			_register_action_key("p1_shield", KEY_L)
			_register_action_key("p1_pause", KEY_ESCAPE)
		elif player_id == 2:
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

func _add_binding_to_action(action_name: String, bind_data: Dictionary, dev_id: int) -> void:
	if bind_data == null or bind_data.is_empty():
		return
	var btype: String = str(bind_data.get("type", "none"))
	match btype:
		"key":
			var kc: int = int(bind_data.get("keycode", 0))
			if kc > 0:
				_register_action_key(action_name, kc as Key)
		"joy_button":
			var btn: int = int(bind_data.get("button", -1))
			if btn >= 0:
				var target_dev: int = maxi(0, dev_id)
				_register_action_joy_button(action_name, btn as JoyButton, target_dev)
		"joy_axis":
			var axis: int = int(bind_data.get("axis", -1))
			var dir: float = float(bind_data.get("dir", 1.0))
			if axis >= 0:
				var target_dev: int = maxi(0, dev_id)
				_register_action_joy_axis(action_name, axis as JoyAxis, dir, target_dev)

func _setup_ui_input_map() -> void:
	for dev in range(MAX_PLAYERS):
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

func _register_action_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey and (ev.physical_keycode == keycode or ev.keycode == keycode):
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

# ==============================================================================
# Persistencia de Configuración y Perfiles (Estilo Yuzu)
# ==============================================================================
func save_config() -> void:
	var file := FileAccess.open(CONFIG_SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	var serializable: Dictionary = {}
	for p_id in range(1, MAX_PLAYERS + 1):
		serializable[str(p_id)] = player_configs.get(p_id, create_default_player_config(p_id))
	file.store_string(JSON.stringify(serializable, "\t"))

func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_SAVE_PATH):
		return
	var file := FileAccess.open(CONFIG_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for p_id in range(1, MAX_PLAYERS + 1):
			var key: String = str(p_id)
			if parsed.has(key) and parsed[key] is Dictionary:
				var loaded_cfg: Dictionary = parsed[key]
				var base_cfg: Dictionary = create_default_player_config(p_id)
				for k in loaded_cfg.keys():
					if k == "bindings" and loaded_cfg[k] is Dictionary:
						for slot in BINDING_SLOTS:
							if loaded_cfg[k].has(slot):
								base_cfg["bindings"][slot] = loaded_cfg[k][slot]
					else:
						base_cfg[k] = loaded_cfg[k]
				player_configs[p_id] = base_cfg

func _load_saved_profiles() -> void:
	saved_profiles.clear()
	saved_profiles["Default"] = {
		"deadzone": 0.15,
		"range": 0.95,
		"vibration": true,
		"bindings": get_default_xbox_bindings()
	}
	saved_profiles["Teclado P1"] = {
		"deadzone": 0.15,
		"range": 1.0,
		"vibration": false,
		"bindings": get_default_keyboard_bindings(1)
	}
	saved_profiles["Teclado P2"] = {
		"deadzone": 0.15,
		"range": 1.0,
		"vibration": false,
		"bindings": get_default_keyboard_bindings(2)
	}

	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)
		return

	var dir := DirAccess.open(PROFILES_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			var prof_name: String = fname.get_basename()
			var f := FileAccess.open(PROFILES_DIR + "/" + fname, FileAccess.READ)
			if f:
				var data = JSON.parse_string(f.get_as_text())
				if data is Dictionary:
					saved_profiles[prof_name] = data
		fname = dir.get_next()
	dir.list_dir_end()

func get_profile_names() -> Array[String]:
	var names: Array[String] = ["Default", "Teclado P1", "Teclado P2"]
	for k in saved_profiles.keys():
		if not (k in names):
			names.append(str(k))
	return names

func save_profile(profile_name: String, cfg: Dictionary) -> bool:
	var clean_name: String = profile_name.strip_edges()
	if clean_name == "":
		return false
	var prof_data: Dictionary = {
		"deadzone": float(cfg.get("deadzone", 0.15)),
		"range": float(cfg.get("range", 0.95)),
		"vibration": bool(cfg.get("vibration", true)),
		"bindings": cfg.get("bindings", {}).duplicate(true)
	}
	saved_profiles[clean_name] = prof_data
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)
	var f := FileAccess.open(PROFILES_DIR + "/" + clean_name + ".json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(prof_data, "\t"))
		return true
	return false

func delete_profile(profile_name: String) -> bool:
	if profile_name in ["Default", "Teclado P1", "Teclado P2"]:
		return false
	saved_profiles.erase(profile_name)
	var path: String = PROFILES_DIR + "/" + profile_name + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return true

func get_profile_data(profile_name: String) -> Dictionary:
	if saved_profiles.has(profile_name):
		return saved_profiles[profile_name].duplicate(true)
	return saved_profiles["Default"].duplicate(true)

# ==============================================================================
# Evaluación en Tiempo Real para Vista Previa del Control Xbox y Gameplay
# ==============================================================================
func get_binding_strength_raw(bind_data: Dictionary, dev_id: int) -> float:
	if bind_data == null or bind_data.is_empty():
		return 0.0
	var btype: String = str(bind_data.get("type", "none"))
	match btype:
		"key":
			var kc: int = int(bind_data.get("keycode", 0))
			if kc > 0 and Input.is_key_pressed(kc as Key):
				return 1.0
		"joy_button":
			var btn: int = int(bind_data.get("button", -1))
			var target_dev: int = maxi(0, dev_id)
			if btn >= 0 and Input.is_joy_button_pressed(target_dev, btn as JoyButton):
				return 1.0
		"joy_axis":
			var axis: int = int(bind_data.get("axis", -1))
			var dir: float = float(bind_data.get("dir", 1.0))
			var target_dev: int = maxi(0, dev_id)
			if axis >= 0:
				var val: float = Input.get_joy_axis(target_dev, axis as JoyAxis)
				if axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
					return clampf(val, 0.0, 1.0)
				if dir > 0.0 and val > 0.0:
					return clampf(val, 0.0, 1.0)
				elif dir < 0.0 and val < 0.0:
					return clampf(-val, 0.0, 1.0)
	return 0.0

func trigger_player_vibration(player_id: int, weak_mag: float = 0.5, strong_mag: float = 0.8, duration: float = 0.2) -> void:
	var cfg: Dictionary = player_configs.get(player_id, {})
	if not bool(cfg.get("vibration", true)):
		return
	var dev_id: int = get_device_id_for_player(player_id)
	if dev_id >= 0 and dev_id in Input.get_connected_joypads():
		var mult: float = clampf(float(cfg.get("vibration_strength", 1.0)), 0.0, 1.0)
		Input.start_joy_vibration(dev_id, weak_mag * mult, strong_mag * mult, duration)

# ==============================================================================
# Procesamiento de Gameplay (4 Jugadores Simultáneos)
# ==============================================================================
func _physics_process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	for p_id in range(1, MAX_PLAYERS + 1):
		if not is_player_connected(p_id):
			continue
		var current_x: float = get_move_vector(p_id).x
		var prev_x: float = _prev_move_x.get(p_id, 0.0)
		if absf(current_x) >= 0.78 and (absf(current_x - prev_x) >= STICK_FLICK_THRESHOLD or signf(current_x) != signf(prev_x)):
			dash_intent_timestamp[p_id] = now
		_prev_move_x[p_id] = current_x

func _input(event: InputEvent) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	for p_id in range(1, MAX_PLAYERS + 1):
		if not is_player_connected(p_id):
			continue
		var prefix: String = "p%d_" % p_id
		if not InputMap.has_action(prefix + "left") or not InputMap.has_action(prefix + "right"):
			continue

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
	if not is_player_connected(player_id):
		return Vector2.ZERO
	var prefix: String = "p%d_" % player_id
	if not InputMap.has_action(prefix + "right"):
		return Vector2.ZERO
	var move_x: float = Input.get_action_strength(prefix + "right") - Input.get_action_strength(prefix + "left")
	var move_y: float = Input.get_action_strength(prefix + "up") - Input.get_action_strength(prefix + "down")
	var cfg: Dictionary = player_configs.get(player_id, {})
	var range_val: float = maxf(0.25, float(cfg.get("range", 0.95)))
	move_x = clampf(move_x / range_val, -1.0, 1.0)
	move_y = clampf(move_y / range_val, -1.0, 1.0)
	return Vector2(move_x, move_y)

func is_dash_pressed(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	var move_x: float = get_move_vector(player_id).x
	if absf(move_x) < 0.2:
		return false
	return (now - dash_intent_timestamp.get(player_id, -10.0)) <= DASH_BUFFER_WINDOW

func consume_dash_intent(player_id: int) -> void:
	dash_intent_timestamp[player_id] = -10.0

func is_jump_pressed(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	return Input.is_action_just_pressed("p%d_jump" % player_id)

func is_attack_pressed(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	return Input.is_action_just_pressed("p%d_attack" % player_id)

func is_special_pressed(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	return Input.is_action_just_pressed("p%d_special" % player_id)

func is_shield_pressed(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	return Input.is_action_pressed("p%d_shield" % player_id)

func is_shield_just_pressed(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	return Input.is_action_just_pressed("p%d_shield" % player_id)

func is_jump_held(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	return Input.is_action_pressed("p%d_jump" % player_id)

func is_pause_just_pressed(player_id: int) -> bool:
	if not is_player_connected(player_id):
		return false
	var act: String = "p%d_pause" % player_id
	return InputMap.has_action(act) and Input.is_action_just_pressed(act)

func get_player_input(player_id: int) -> PlayerInput:
	var pi := PlayerInput.new()
	if not is_player_connected(player_id):
		return pi
	pi.movement = get_move_vector(player_id)
	pi.is_dash = is_dash_pressed(player_id)
	pi.jump_pressed = is_jump_pressed(player_id)
	pi.jump_held = is_jump_held(player_id)
	pi.attack_pressed = is_attack_pressed(player_id)
	pi.special_pressed = is_special_pressed(player_id)
	pi.shield_pressed = is_shield_pressed(player_id)
	pi.shield_just_pressed = is_shield_just_pressed(player_id)
	return pi
