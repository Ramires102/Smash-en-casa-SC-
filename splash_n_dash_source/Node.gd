extends Node



var freeze_timer = Timer.new()
func freeze():
	freeze_timer.connect("timeout", self, "on_freeze_timeout")
	freeze_timer.set_wait_time(0.075)
	add_child(freeze_timer)


func on_freeze_timeout():
	get_tree().paused = false
