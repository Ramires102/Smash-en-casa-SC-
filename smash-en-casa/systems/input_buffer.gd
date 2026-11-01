# ==============================================================================
# InputBuffer — Cola Temporal de Intenciones de Entrada
# ==============================================================================
# Guarda durante 150 ms (~9 frames a 60 FPS) las pulsaciones de salto o ataque.
# Esto hace que el control se sienta responsivo: si el jugador pulsa un botón
# un par de frames antes de terminar otra animación, la acción se ejecuta apenas
# el personaje vuelve a estar disponible, sin "tragarse" el botón.
# ==============================================================================
class_name InputBuffer
extends RefCounted

var buffer_window_seconds: float = 0.15
var action_timestamps: Dictionary = {}

## Registra el instante exacto en que se pulsó una acción ("jump", "attack", "special").
func register_action(action_name: String) -> void:
	action_timestamps[action_name] = Time.get_ticks_msec() / 1000.0

## Devuelve true si la acción fue pulsada dentro de la ventana de 150 ms.
func is_action_buffered(action_name: String) -> bool:
	if not action_timestamps.has(action_name):
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	return (now - float(action_timestamps[action_name])) <= buffer_window_seconds

## Consume la acción para evitar que se ejecute dos veces con una sola pulsación.
func consume_action(action_name: String) -> void:
	action_timestamps.erase(action_name)

## Limpia todo el buffer (por ejemplo, al reiniciar al personaje tras un KO).
func clear() -> void:
	action_timestamps.clear()
