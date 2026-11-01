# ==============================================================================
# EventBus (Autoload: Events)
# ==============================================================================
# Patrón Publicador/Suscriptor global para desacoplar sistemas independientes
# (por ejemplo: que un proyectil agite la cámara o que un personaje actualice el
# medidor especial en el HUD sin tener referencias directas entre sí).
# ==============================================================================
class_name EventBus
extends Node

#region Señales Globales Activas
## Se emite cuando un luchador cae fuera de los límites del escenario (KO).
@warning_ignore("unused_signal")
signal player_ko_event(player_id: int, death_pos_3d: Vector3)

## Se emite cuando cambia la barra especial de un personaje (Seda de Hornet o Reloj de Sakuya).
@warning_ignore("unused_signal")
signal special_meter_changed(player_id: int, current_charge: float, max_charge: float)

## Solicita una sacudida de cámara proporcional a la fuerza del impacto.
@warning_ignore("unused_signal")
signal camera_shake_requested(intensity: float)

## Señales del sistema de Detención del Tiempo ("El Mundo" de Sakuya).
@warning_ignore("unused_signal")
signal time_freeze_requested(duration_sec: float, instigator: Node)
@warning_ignore("unused_signal")
signal time_stop_started(duration_sec: float, instigator: Node)
@warning_ignore("unused_signal")
signal time_stop_ended
#endregion

#region Estado Global de Detención del Tiempo (Time Stop)
var is_time_stopped: bool = false
var time_stop_instigator: Node = null
var time_stop_remaining_sec: float = 0.0

## Congela el tiempo para todos los personajes y proyectiles excepto quien lo activó.
func trigger_time_stop(duration_sec: float, instigator: Node) -> void:
	is_time_stopped = true
	time_stop_instigator = instigator
	time_stop_remaining_sec = duration_sec
	time_freeze_requested.emit(duration_sec, instigator)
	time_stop_started.emit(duration_sec, instigator)

func _process(delta: float) -> void:
	if not is_time_stopped:
		return
	time_stop_remaining_sec -= delta
	if time_stop_remaining_sec <= 0.0:
		is_time_stopped = false
		time_stop_instigator = null
		time_stop_ended.emit()
#endregion
