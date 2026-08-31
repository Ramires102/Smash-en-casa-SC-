extends Area2D


onready var label = $"Label"

var is_grabbed = false


func _on_Ledge_L_body_exited(body):
	is_grabbed = false
