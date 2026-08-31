extends Label



export var minutes = 1
export var seconds = ":00"

func _ready():
	minutes = Globals.css["time"]
	set_text(str(Globals.css["time"]) + seconds)



func _on_Control_pressed():
	if minutes == 60:
		minutes = 1
		Globals.css["time"] = minutes
		self.text = str(Globals.css["time"]) + seconds
	elif minutes <= 10:
		self.align = Label.ALIGN_CENTER
		minutes += 1
		Globals.css["time"] = minutes
		self.text = str(Globals.css["time"]) + seconds
	elif minutes > 9:
		self.align = Label.ALIGN_LEFT
		minutes += 1
		Globals.css["time"] = minutes
		self.text = str(Globals.css["time"]) + seconds


func _on_Control3_pressed():
	if minutes == 1:
		minutes = 60
		Globals.css["time"] = minutes
		self.text = str(Globals.css["time"]) + seconds
	elif minutes <= 10:
		self.align = Label.ALIGN_CENTER
		minutes -= 1
		Globals.css["time"] = minutes
		self.text = str(Globals.css["time"]) + seconds
	elif minutes > 9:
		self.align = Label.ALIGN_LEFT
		minutes -= 1
		Globals.css["time"] = minutes
		self.text = str(Globals.css["time"]) + seconds
