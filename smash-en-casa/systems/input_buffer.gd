class_name InputBuffer
extends Node

@export var buffer_window_seconds: float = 0.15

var action_timestamps: Dictionary = {}

func register_action(action_name: String) -> void:
	action_timestamps[action_name] = Time.get_ticks_msec() / 1000.0

func is_action_buffered(action_name: String) -> bool:
	if not action_timestamps.has(action_name):
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	return (now - action_timestamps[action_name]) <= buffer_window_seconds

func consume_action(action_name: String) -> void:
	action_timestamps.erase(action_name)
