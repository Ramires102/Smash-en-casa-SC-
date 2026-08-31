extends Node


var title_music = load("res://ASSETS/TitleScreen/Music/Menu Music.mp3")
var css_music = load("res://ASSETS/TitleScreen/Music/CSS Music.mp3")
var sss_music = load("res://ASSETS/StageSelect/StageSelectSong.mp3")
var result_music = load("res://ASSETS/TitleScreen/Music/Result song.ogg")
var airport_music = load("res://ASSETS/TitleScreen/Music/Samuel's Airport Beat (192 kbps).mp3")
onready var tween = $Tween
onready var music = $Music

func _ready():
	pass


func play_music(name):
	music.stream = name
	music.play()


func fade_out():
	tween.interpolate_property($Music, "volume_db", null, - 60, 1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func fade_in():
	tween.interpolate_property($Music, "volume_db", null, 0, 1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()


