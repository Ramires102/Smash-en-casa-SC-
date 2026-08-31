extends Control


onready var winner_img = get_node("AnimationPlayer/Whole Screen/Whole Screen/Left Side/Winner Image/Winner_img")
onready var winner_txt = get_node("AnimationPlayer/Whole Screen/Whole Screen/Left Side/WinnerName/Winner_Text")

export var FOX: Texture
export var WOLF: Texture
export var MARIO: Texture
var counter = 3600

func _ready():

	MusicController.fade_in()
	MusicController.play_music(MusicController.result_music)
	player_display()

func _process(delta):
	counter -= 1
	if counter == 0:
		MusicController.fade_out()
		Transitions.fade_out()
		yield(MusicController.tween, "tween_completed")
		get_tree().change_scene("res://CSS.tscn")
	if (Input.is_action_just_pressed("ui_select_1") or Input.is_action_just_pressed("ui_select_2")) and counter < 3300:
		MusicController.fade_out()
<< << << < HEAD

== == == = 
		Transitions.fade_out()
>> >> >> > 37a4169f44b0996ba31bde205352b6048d24f1df
		yield(get_tree().create_timer(0.8), "timeout")
		get_tree().change_scene("res://CSS.tscn")


func player_display():
	match Globals.winner:
		"Player_1":
			char_data_1()
		"Player_2":
			char_data_2()

func char_data_1():
	match Globals.css["char_1"]:
		"FOX":
			winner_img.set_texture(FOX)
			winner_txt.text = "FOX"
		"WOLF":
			winner_img.set_texture(WOLF)
			winner_txt.text = "WOLF"
		"MARIO":
			winner_img.set_texture(MARIO)
			winner_txt.text = "MARIO"

func char_data_2():
	match Globals.css["char_2"]:
		"FOX":
			winner_img.set_texture(FOX)
			winner_txt.text = "FOX"
		"WOLF":
			winner_img.set_texture(WOLF)
			winner_txt.text = "WOLF"
		"MARIO":
			winner_img.set_texture(MARIO)
			winner_txt.text = "MARIO"
