extends Area2D








func _ready():
	pass







func _on_Left_Boundary_area_entered(area):
	area.get_parent().global_position = Vector2(1810, area.get_parent().global_position.y)
