class_name WeaverlingProjectile
extends Projectile

@onready var silk_line: Line2D = get_node_or_null("SilkLine")
var _trail_points: Array[Vector2] = []

func _ready() -> void:
	super._ready()
	if silk_line:
		silk_line.top_level = true
		silk_line.width = 2.5
		silk_line.default_color = Color(1.0, 1.0, 1.0, 0.85)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_time_frozen:
		return
	
	# Trailing silk cord connected to origin
	if silk_line:
		_trail_points.push_front(global_position)
		if _trail_points.size() > 10:
			_trail_points.pop_back()
		silk_line.clear_points()
		for pt in _trail_points:
			silk_line.add_point(pt)
		
		# Pulsing silk glow
		var pulse = 0.75 + 0.25 * sin(_time_alive * 12.0)
		silk_line.modulate = Color(1.0, 1.0, 1.0, pulse)

func _exit_tree() -> void:
	super._exit_tree()
	if silk_line and is_instance_valid(silk_line):
		silk_line.queue_free()
