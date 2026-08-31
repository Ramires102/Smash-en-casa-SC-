extends Control


enum States{
	PLAY, 
	OPTIONS, 
	EXIT
}

func _ready():
	$Menu / CenterRow / Buttons / SinglePlayerButton.grab_focus()
	Transitions.fade_in()
	MusicController.fade_in()

	MusicController.play_music(MusicController.title_music)

var current_state = States.PLAY
onready var getpointer = $Pointer

func _process(delta):
	if Input.is_action_just_pressed("ui_select_1") or Input.is_action_just_pressed("ui_select_2"):
		var dec = getpointer.get_overlapping_areas()
		for b in dec:
			if b.name == "Play":
				b.get_parent().emit_signal("pressed")
			elif b.name == "Option":
				b.get_parent().emit_signal("pressed")
			elif b.name == "Exit":
				b.get_parent().emit_signal("pressed")
	match current_state:
		States.PLAY:
			play()
			if Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("up_2"):
				current_state = States.EXIT
			if Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("down_2"):
				current_state = States.OPTIONS
		States.OPTIONS:
			options()
			if Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("up_2"):
				current_state = States.PLAY
			if Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("down_2"):
				current_state = States.EXIT
		States.EXIT:
			exit()
			if Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("up_2"):
				current_state = States.OPTIONS
			if Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("down_2"):
				current_state = States.PLAY
	var dec = getpointer.get_overlapping_areas()
	
	

func play():
	getpointer.global_position = Vector2(172.859, 377.148)

func options():
	getpointer.global_position = Vector2(172.859, 567.966)

func exit():
	getpointer.global_position = Vector2(172.859, 758.785)
