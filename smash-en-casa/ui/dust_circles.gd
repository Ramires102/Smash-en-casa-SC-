class_name DustCircles
extends Control

# Tipo: "victory" = dorado | "defeat" = negro-a-rojo
@export var dust_type: String = "victory"

const CIRCLE_RADIUS: float = 14.0
const SPACING: float = 36.0

func _draw() -> void:
	var start_x: float = CIRCLE_RADIUS + 10.0
	var center_y: float = (size.y * 0.5) if size.y > 0 else 16.0
	for i in range(3):
		var center := Vector2(start_x + i * SPACING, center_y)
		if dust_type == "victory":
			# Relleno dorado cálido
			draw_circle(center, CIRCLE_RADIUS, Color(1.0, 0.82, 0.1))
			# Borde brillante
			draw_arc(center, CIRCLE_RADIUS, 0, TAU, 32, Color(1.0, 0.95, 0.4), 2.5, true)
			# Brillo interior pequeño
			draw_circle(center + Vector2(-4, -4), CIRCLE_RADIUS * 0.3, Color(1.0, 1.0, 0.8, 0.6))
		else:
			# Relleno negro con degradado simulado a rojo oscuro
			draw_circle(center, CIRCLE_RADIUS, Color(0.08, 0.0, 0.0))
			# Arco exterior rojo oscuro
			draw_arc(center, CIRCLE_RADIUS, 0, TAU, 32, Color(0.7, 0.0, 0.0), 3.0, true)
			# Mancha roja interna (degradado simulado)
			draw_circle(center + Vector2(3, 3), CIRCLE_RADIUS * 0.55, Color(0.45, 0.0, 0.0, 0.7))
