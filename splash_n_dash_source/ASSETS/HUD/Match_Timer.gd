extends Label

var time = Globals.css.time * 60
var timer_on = false


func _ready():
	timer_on = true
func _process(delta):
	if (timer_on):
		time -= delta
		
	var secs = fmod(time, 60)
	var mins = fmod(time, 60 * 60) / 60
	
	Globals.round_time_m = mins
	Globals.round_time_s = secs
	var time_passed = "%d:%02d" % [mins, secs]
	text = time_passed
	
	pass

