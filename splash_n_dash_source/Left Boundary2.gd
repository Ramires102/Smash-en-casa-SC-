extends Area2D








func _ready():
	pass







func _on_Right_Boundary_area_entered(area):
	area.get_parent().global_position = Vector2(102, area.get_parent().global_position.y)
