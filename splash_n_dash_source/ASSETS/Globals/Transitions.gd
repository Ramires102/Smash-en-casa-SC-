extends CanvasLayer

onready var anim = $AnimationPlayer

func fade_out():
	anim.play("FadeOut")

func fade_in():
	anim.play("FadeIn")

func full():
	anim.play("full")

func _ready():
	fade_out()
