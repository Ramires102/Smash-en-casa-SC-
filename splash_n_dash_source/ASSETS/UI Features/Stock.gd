extends Label



export var stocks = 4
onready var global = $"/root/Globals"

func _ready():
	stocks = Globals.css["stocks"]
	set_text(str(Globals.css["stocks"]))


func _on_Control_pressed():
	if stocks == 99:
		stocks = 1
		Globals.css["stocks"] = stocks
		self.text = str(Globals.css["stocks"])
	elif stocks <= 10:
		self.align = Label.ALIGN_CENTER
		stocks += 1
		Globals.css["stocks"] = stocks
		self.text = str(Globals.css["stocks"])
	elif stocks > 9:
		self.align = Label.ALIGN_LEFT
		stocks += 1
		Globals.css["stocks"] = stocks
		self.text = str(Globals.css["stocks"])


func _on_Control3_pressed():
	if stocks == 1:
		stocks = 99
		Globals.css["stocks"] = stocks
		self.text = str(Globals.css["stocks"])
	elif stocks <= 10:
		self.align = Label.ALIGN_CENTER
		stocks -= 1
		Globals.css["stocks"] = stocks
		self.text = str(Globals.css["stocks"])
	elif stocks > 9:
		self.align = Label.ALIGN_LEFT
		stocks -= 1
		Globals.css["stocks"] = stocks
		self.text = str(Globals.css["stocks"])
