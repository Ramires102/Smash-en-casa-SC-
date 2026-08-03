class_name Utils
extends RefCounted

static func format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

static func format_percentage(value: float) -> String:
	return "%d%%" % int(value)
