extends Label


var hours
var minutes

func _ready():
	set_process(true)

func _process(delta):
	hours = OS.get_time()["hour"]
	minutes = OS.get_time()["minute"]
	if hours >= 10:
		if OS.get_time()["minute"] >= 10:
			set_text(str(hours) + ":" + str(minutes) + "PM")
		else:
			set_text(str(hours) + ":" + "0" + str(minutes) + "PM")
	else:
		if OS.get_time()["minute"] >= 10:
			set_text("0" + str(hours) + ":" + str(minutes) + "AM")
		else:
			set_text("0" + str(hours) + ":" + "0" + str(minutes) + "AM")
