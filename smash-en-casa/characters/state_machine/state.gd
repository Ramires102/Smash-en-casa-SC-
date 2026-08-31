class_name State
extends Node

const FSM_DEBUG_ENABLED: bool = true
const FSM_DEBUG_TICK_INTERVAL: float = 0.20

var character: Character
var state_machine: Node
var _dbg_tick_accum: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func dbg(event_name: String, payload: Dictionary = {}) -> void:
	if not FSM_DEBUG_ENABLED:
		return
	var player_label: String = "?"
	if character and character.has_method("get"):
		var maybe_id: Variant = character.get("player_id")
		if maybe_id != null:
			player_label = str(maybe_id)
	var line: String = "[FSM][P%s][%s] %s" % [player_label, name, event_name]
	if not payload.is_empty():
		line += " | " + JSON.stringify(payload)
	print(line)

func dbg_tick(delta: float, payload: Dictionary = {}) -> void:
	if not FSM_DEBUG_ENABLED:
		return
	_dbg_tick_accum += delta
	if _dbg_tick_accum >= FSM_DEBUG_TICK_INTERVAL:
		_dbg_tick_accum = 0.0
		dbg("tick", payload)
