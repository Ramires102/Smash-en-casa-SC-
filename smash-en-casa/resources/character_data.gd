class_name CharacterData
extends Resource

@export var character_name: String = "Luchador"
# Smash Ultimate physics (internal units, 1 unit ≈ 1 Smash unit scaled to 3D)
@export var run_speed: float = 1.76       # Velocidad de carrera sostenida
@export var walk_speed: float = 1.05      # Velocidad de caminata
@export var initial_dash_speed: float = 1.98 # Impulso instantáneo del Dash
@export var traction: float = 0.08        # Fricción terrestre (frenado por frame)
@export var jump_velocity: float = 14.0   # Impulso vertical del salto
@export var short_hop_velocity: float = 10.5 # Impulso del Short Hop (75%)
@export var air_speed: float = 1.0        # Control horizontal en aire
@export var air_acceleration: float = 0.05 # Aceleración horizontal aérea por frame
@export var air_friction: float = 0.01    # Resistencia aérea
@export var weight: float = 100.0         # Peso (Mewtwo ~79, Mario ~98, Bowser ~135)
@export var gravity: float = 0.09         # Aceleración vertical por frame
@export var fall_speed: float = 1.60      # Terminal velocity (caída normal)
@export var fast_fall_speed: float = 2.56  # Terminal velocity (caída rápida)
@export var pushbox_radius: float = 0.5
@export var icon: Texture2D
@export var character_color: Color = Color.WHITE
@export var model_scene: PackedScene
@export var model_offset: Vector3 = Vector3(0.0, -0.9, 0.0)
@export var model_scale: float = 1.0
@export var moveset: MoveSet
