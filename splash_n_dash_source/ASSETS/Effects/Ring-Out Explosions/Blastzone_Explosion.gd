extends AnimatedSprite



func _ready():
	connect("animation_finished", self, "animation_finished")
	play("Blastzone_P1")


func animation_finished():
	queue_free()
