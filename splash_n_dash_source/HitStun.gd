extends Timer

onready var timer = self
onready var parent = get_parent()






func _ready():
	pass





func _on_Timer_timeout():
	print("yoshi")
	parent.hitstun = false
	get_tree().paused = false


	
