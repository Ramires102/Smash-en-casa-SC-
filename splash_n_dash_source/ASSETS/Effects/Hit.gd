extends AnimatedSprite

export (int) var number

func _ready():
	connect("animation_finished", self, "animation_finished")
	play(str(number))


func animation_finished():
	queue_free()
