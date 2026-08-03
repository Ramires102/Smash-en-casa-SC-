class_name Helpers
extends RefCounted

static func constrain_to_2d_plane(node: Node3D, z_pos: float = 0.0) -> void:
	if node:
		node.global_position.z = z_pos
