# ==============================================================================
# AudioManager (Autoload / Singleton Core)
# Responsabilidad: Reproducción centralizada de BGM y pool de canales para SFX.
# ==============================================================================
extends Node

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

const MAX_SFX_CHANNELS: int = 12

const MENU_THEME_PATH: String = "res://assets/audio/music/menu_theme.mp3"
const MENU_THEME_EXTERNAL: String = "/home/RodriFumo/Música/Menu theme.mp3"

const BATTLE_THEME_PATH: String = "res://assets/audio/music/battle_theme.mp3"
const BATTLE_THEME_EXTERNAL: String = "/home/RodriFumo/Música/battle.mpeg"

var menu_theme_stream: AudioStream = null
var battle_theme_stream: AudioStream = null

var _bgm_fade_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"Master"
	add_child(bgm_player)
	
	for i in range(MAX_SFX_CHANNELS):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		sfx_players.append(player)

	_init_music_streams()

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

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return
