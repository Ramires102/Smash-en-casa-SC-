# ==============================================================================
# State — Clase Base Abstracta del Patrón Estado (FSM)
# ==============================================================================
# Cada comportamiento del luchador (Idle, Run, Jump, Attack, Hit, Shield, etc.)
# hereda de esta clase y sobrescribe únicamente los métodos que necesita:
#   - enter(msg): se ejecuta una vez al entrar al estado.
#   - exit(): se ejecuta al salir hacia otro estado (limpieza).
#   - handle_input / update / physics_update: lógica activa mientras está vigente.
# ==============================================================================
class_name State
extends Node

const FSM_DEBUG_ENABLED: bool = false
const FSM_DEBUG_TICK_INTERVAL: float = 0.20

var character: Character
var state_machine: StateMachine
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

#region Trazas Opcionales de Depuración (Desactivadas por Defecto)
func dbg(event_name: String, payload: Dictionary = {}) -> void:
	if not FSM_DEBUG_ENABLED:
		return
	var player_label: String = str(character.player_id) if character else "?"
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
#endregion
