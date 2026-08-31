extends Area2D








func _ready():
	pass



func _on_Upper_Boundary_area_entered(area):
	area.get_parent().global_position = Vector2(area.get_parent().global_position.x, 978)
