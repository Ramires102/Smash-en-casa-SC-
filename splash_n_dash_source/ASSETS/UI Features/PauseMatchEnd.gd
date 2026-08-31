extends Node


func pause():
	get_tree().paused = true
	if Globals.player_1["stocks"] > Globals.player_2["stocks"]:
		Globals.winner = "Player_1"
	else:
		Globals.winner = "Player_2"
	yield(get_tree().create_timer(1.5), "timeout")




	MusicController.fade_out()

	yield(MusicController.tween, "tween_completed")
	get_tree().change_scene("res://ASSETS/ResultsScreen/ResultsScreen.tscn")
	get_tree().paused = false
