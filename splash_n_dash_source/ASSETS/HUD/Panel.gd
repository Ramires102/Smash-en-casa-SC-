extends Panel

enum States{
	RESUME, 
	CHAR, 
	EXIT
}

var current_state = States.RESUME
onready var getpointer = $Pointer

func _process(delta):

	if get_parent().Paused == true:
		match current_state:
			States.RESUME:
				Resume()
				new_input()
				if Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("up_2"):
					current_state = States.EXIT
				if Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("down_2"):
					current_state = States.CHAR
			States.CHAR:
				Char()
				new_input()
				if Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("up_2"):
					current_state = States.RESUME
				if Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("down_2"):
					current_state = States.EXIT
			States.EXIT:
				Exit()
				new_input()
				if Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("up_2"):
					current_state = States.CHAR
				if Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("down_2"):
					current_state = States.RESUME

func Resume():
	getpointer.global_position = Vector2(1529.874, 522.5)

func Char():
	getpointer.global_position = Vector2(1538.349, 687.7)

func Exit():
	getpointer.global_position = Vector2(1534.111, 838.229)

func new_input():
	if Input.is_action_just_pressed("ui_select_1") or Input.is_action_just_pressed("ui_select_2"):
		var dec = getpointer.get_overlapping_areas()
		for b in dec:
			print(b.name)
			if b.name == "RESUME":
				b.get_parent().emit_signal("pressed")
			if b.name == "CHAR":
				b.get_parent().emit_signal("pressed")
			if b.name == "Exit":
				b.get_parent().emit_signal("pressed")
