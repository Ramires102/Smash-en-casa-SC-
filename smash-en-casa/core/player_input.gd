# ==============================================================================
# PlayerInput (Estructura de Intenciones de Jugador)
# Responsabilidad: Representar de forma pura y desacoplada las intenciones de entrada
# de un jugador en un frame específico, aislando la física y FSM de teclas o hardware.
# ==============================================================================
class_name PlayerInput
extends RefCounted

## Vector direccional normalizado o analógico:
## x: [-1.0 (Izquierda) .. 1.0 (Derecha)]
## y: [-1.0 (Abajo / Agacharse) .. 1.0 (Arriba)]
var movement: Vector2 = Vector2.ZERO

## Intención de carrera rápida (detectada por doble toque o tilt fuerte)
var is_dash: bool = false

## Intención de salto iniciado en este frame
var jump_pressed: bool = false

## Intención de salto sostenido (diferenciación entre Short Hop y Full Hop)
var jump_held: bool = false

## Intención de ataque normal / estándar
var attack_pressed: bool = false

## Intención de ataque especial
var special_pressed: bool = false

## Intención de activación o mantenimiento de escudo
var shield_pressed: bool = false

## Helpers de consulta de intención
func has_movement() -> bool:
	return movement.length_squared() > 0.01

func is_moving_horizontal() -> bool:
	return abs(movement.x) > 0.1

func is_crouch_intent() -> bool:
	return movement.y < -0.5

func has_attack_intent() -> bool:
	return attack_pressed or special_pressed
