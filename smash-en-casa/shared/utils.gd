# ==============================================================================
# Utils — Funciones Auxiliares de Formato y Conversión
# ==============================================================================
# Métodos estáticos puros reutilizados por la interfaz (HUD) y sistemas 2D/3D.
# ==============================================================================
class_name Utils
extends RefCounted

## Convierte segundos flotantes al formato de reloj "MM:SS" (ej. 125.0 -> "02:05").
static func format_time(seconds: float) -> String:
	var clamped: int = maxi(0, int(seconds))
	var mins: int = clamped / 60
	var secs: int = clamped % 60
	return "%02d:%02d" % [mins, secs]

## Formatea el porcentaje de daño acumulado como texto entero (ej. 42.7 -> "42%").
static func format_percentage(value: float) -> String:
	return "%d%%" % int(value)

## Convierte una posición física 2D (píxeles, Y+ hacia abajo) a coordenadas visuales 3D (metros, Y+ hacia arriba).
static func pos_2d_to_3d(pos_2d: Vector2, z: float = 0.0) -> Vector3:
	return Vector3(
		pos_2d.x / Constants.UNIT_SIZE,
		-pos_2d.y / Constants.UNIT_SIZE,
		z
	)
