# Explicación de `resources/character_data.gd`

## Resumen
Resource central que define toda la información física y matemática de un personaje según el estándar de *Super Smash Bros. Ultimate* (`ft_kind_*`): velocidades terrestres/aéreas, tracción/fricción, peso, gravedad por frame, velocidades terminales de caída, radio de Pushbox, color, icono y `MoveSet`. Este es el corazón de la arquitectura Data-Driven.

## Explicación Línea por Línea
```gdscript
class_name CharacterData
extends Resource

@export var character_name: String = "Luchador"
@export var run_speed: float = 1.76          # Velocidad de carrera sostenida (Smash units)
@export var walk_speed: float = 1.05         # Velocidad de caminata (Smash units)
@export var initial_dash_speed: float = 1.98 # Impulso instantáneo de Dash en Frame 1
@export var traction: float = 0.08           # Fricción/desaceleración terrestre por frame
@export var jump_velocity: float = 14.0      # Impulso de salto Full Hop
@export var short_hop_velocity: float = 10.5 # Impulso de salto Short Hop
@export var air_speed: float = 1.0           # Control horizontal en el aire
@export var air_acceleration: float = 0.05    # Aceleración aérea horizontal por frame
@export var air_friction: float = 0.01       # Fricción aérea
@export var weight: float = 100.0            # Peso de Smash (Mewtwo ~79, Sonic ~86, Bowser ~135)
@export var gravity: float = 0.09            # Aceleración vertical por frame
@export var fall_speed: float = 1.60         # Velocidad límite de caída (Terminal velocity)
@export var fast_fall_speed: float = 2.56     # Velocidad límite de caída rápida (+60%)
@export var pushbox_radius: float = 0.5
@export var icon: Texture2D
@export var character_color: Color = Color.WHITE
@export var moveset: MoveSet
```

## Comunicación e Interacciones
- **Leído por**: `CharacterController.gd` y `Character.gd` en `setup(data)` / `load_character(data)` para convertir de unidades internas de Smash a físicas 3D de Godot.
- **Instancias**: `john_placeholder_data.tres` (Estadísticas exactas de Sonic), `miyabi_data.tres`, `gogeta_data.tres`, `sakuya_data.tres`.
