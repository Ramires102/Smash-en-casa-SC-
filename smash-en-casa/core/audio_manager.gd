# ==============================================================================
# AudioManager (Autoload / Singleton Core)
# Responsabilidad: Reproducción centralizada de BGM, SFX y Voces, gestión de buses
# y configuración persistente de volúmenes (Master, Música/Ambiente, SFX, Voces).
# ==============================================================================
extends Node

const SETTINGS_FILE_PATH: String = "user://audio_settings.json"

const MAX_SFX_CHANNELS: int = 12
const MAX_VOICE_CHANNELS: int = 6

const MENU_THEME_PATH: String = "res://assets/audio/music/menu_theme.mp3"
const MENU_THEME_EXTERNAL: String = "/home/RodriFumo/Música/Menu theme.mp3"

const BATTLE_THEME_PATH: String = "res://assets/audio/music/battle_theme.mp3"
const BATTLE_THEME_EXTERNAL: String = "/home/RodriFumo/Música/battle.mpeg"

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var voice_players: Array[AudioStreamPlayer] = []

var menu_theme_stream: AudioStream = null
var battle_theme_stream: AudioStream = null

var _bgm_fade_tween: Tween = null

# Niveles lineales de volumen (0.0 a 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.80
var sfx_volume: float = 0.85
var voices_volume: float = 0.90

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"Music"
	add_child(bgm_player)
	
	for i in range(MAX_SFX_CHANNELS):
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		sfx_players.append(player)

	for i in range(MAX_VOICE_CHANNELS):
		var v_player := AudioStreamPlayer.new()
		v_player.bus = &"Voices"
		add_child(v_player)
		voice_players.append(v_player)

	_init_music_streams()
	load_audio_settings()

func _setup_audio_buses() -> void:
	var required_buses: Array[StringName] = [&"Music", &"SFX", &"Voices"]
	for bus_name in required_buses:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			AudioServer.add_bus()
			var new_idx: int = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(new_idx, bus_name)
			AudioServer.set_bus_send(new_idx, &"Master")

func _init_music_streams() -> void:
	menu_theme_stream = _load_audio_stream(MENU_THEME_PATH, MENU_THEME_EXTERNAL)
	battle_theme_stream = _load_audio_stream(BATTLE_THEME_PATH, BATTLE_THEME_EXTERNAL)

func _load_audio_stream(res_path: String, external_path: String) -> AudioStream:
	var stream: AudioStream = null
	if ResourceLoader.exists(res_path):
		stream = load(res_path)
	elif FileAccess.file_exists(external_path):
		var f := FileAccess.open(external_path, FileAccess.READ)
		if f:
			var mp3 := AudioStreamMP3.new()
			mp3.data = f.get_buffer(f.get_length())
			stream = mp3

	if stream is AudioStreamMP3:
		stream.loop = true
	return stream

# ------------------------------------------------------------------------------
# Control de Volúmenes y Buses
# ------------------------------------------------------------------------------
func _apply_bus_volume(bus_name: StringName, linear_val: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if linear_val <= 0.001:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear_val))

func set_master_volume(val: float, save: bool = true) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume(&"Master", master_volume)
	if save:
		save_audio_settings()

func set_music_volume(val: float, save: bool = true) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume(&"Music", music_volume)
	if save:
		save_audio_settings()

func set_sfx_volume(val: float, save: bool = true) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume(&"SFX", sfx_volume)
	if save:
		save_audio_settings()

func set_voices_volume(val: float, save: bool = true) -> void:
	voices_volume = clampf(val, 0.0, 1.0)
	_apply_bus_volume(&"Voices", voices_volume)
	if save:
		save_audio_settings()

func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func get_voices_volume() -> float:
	return voices_volume

func save_audio_settings() -> void:
	var data: Dictionary = {
		"master": master_volume,
		"music": music_volume,
		"sfx": sfx_volume,
		"voices": voices_volume
	}
	var f := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
		f.close()

func load_audio_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		# Valores predeterminados óptimos
		set_master_volume(1.0, false)
		set_music_volume(0.80, false)
		set_sfx_volume(0.85, false)
		set_voices_volume(0.90, false)
		return

	var f := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not f:
		return

	var content: String = f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(content) == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		if d.has("master"): set_master_volume(float(d["master"]), false)
		if d.has("music"): set_music_volume(float(d["music"]), false)
		if d.has("sfx"): set_sfx_volume(float(d["sfx"]), false)
		if d.has("voices"): set_voices_volume(float(d["voices"]), false)

# ------------------------------------------------------------------------------
# Reproducción de Música
# ------------------------------------------------------------------------------
func play_menu_theme() -> void:
	if menu_theme_stream == null:
		menu_theme_stream = _load_audio_stream(MENU_THEME_PATH, MENU_THEME_EXTERNAL)
	if menu_theme_stream:
		play_bgm(menu_theme_stream)

func play_battle_theme() -> void:
	if battle_theme_stream == null:
		battle_theme_stream = _load_audio_stream(BATTLE_THEME_PATH, BATTLE_THEME_EXTERNAL)
	if battle_theme_stream:
		play_bgm(battle_theme_stream)

func play_bgm(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	if bgm_player.stream == stream and bgm_player.playing:
		return

	if stream is AudioStreamMP3:
		stream.loop = true

	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()

	bgm_player.volume_db = 0.0
	bgm_player.stream = stream
	bgm_player.play()

func stop_bgm(fade_duration: float = 0.2) -> void:
	if not is_inside_tree() or not bgm_player.playing:
		return
	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()

	if fade_duration > 0.0:
		_bgm_fade_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_bgm_fade_tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration)
		_bgm_fade_tween.tween_callback(func():
			bgm_player.stop()
			bgm_player.volume_db = 0.0
		)
	else:
		bgm_player.stop()
		bgm_player.volume_db = 0.0

# ------------------------------------------------------------------------------
# Reproducción de SFX y Voces
# ------------------------------------------------------------------------------
func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return

func play_voice(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	for player in voice_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return
	# Si todos están ocupados, usar el primero
	if voice_players.size() > 0:
		var p := voice_players[0]
		p.stream = stream
		p.pitch_scale = pitch_scale
		p.play()

# ------------------------------------------------------------------------------
# Sonidos de Prueba (Test SFX)
# ------------------------------------------------------------------------------
func play_test_sfx() -> void:
	var test_path := "res://assets/audio/sfx/undertale_hit.wav"
	if ResourceLoader.exists(test_path):
		play_sfx(load(test_path) as AudioStream, randf_range(0.95, 1.05))

func play_test_voice() -> void:
	var test_path := "res://assets/audio/sfx/undertale_gaster.wav"
	if ResourceLoader.exists(test_path):
		play_voice(load(test_path) as AudioStream, randf_range(1.1, 1.25))

func play_test_music() -> void:
	if not bgm_player.playing:
		play_menu_theme()
