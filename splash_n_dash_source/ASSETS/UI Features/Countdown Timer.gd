extends AnimationPlayer


func _process(delta):

	if Globals.player_1["stocks"] == 0 or Globals.player_2["stocks"] == 0:
		play("Game")
	if round(Globals.round_time_m) == 0 and floor(Globals.round_time_s) == 5:
		play("5")
	if round(Globals.round_time_m) == 0 and floor(Globals.round_time_s) == 4:
		play("4")
	if round(Globals.round_time_m) == 0 and floor(Globals.round_time_s) == 3:
		play("3")
	if round(Globals.round_time_m) == 0 and floor(Globals.round_time_s) == 2:
		play("2")
	if round(Globals.round_time_m) == 0 and floor(Globals.round_time_s) == 1:
		play("1")
	if round(Globals.round_time_m) == 0 and floor(Globals.round_time_s) == 0:
		play("Time")
