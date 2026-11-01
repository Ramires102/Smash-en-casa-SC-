# ==============================================================================
# CharacterData — Ficha de Atributos, Modelo 3D y MoveSet de un Luchador
# ==============================================================================
# Cada personaje jugable (Gogeta, Sakuya, Hornet, Sans, Lego Batman, Miyabi, John)
# se define mediante un recurso .tres de esta clase en resources/instances/.
# La escena base Character lee este recurso al spawnear y se configura sola.
# ==============================================================================
class_name CharacterData
extends Resource

#region Identidad e Iconografía UI
@export var character_name: String = "Luchador"
@export var icon: Texture2D
@export var logo_texture: Texture2D
@export var character_color: Color = Color.WHITE
#endregion

#region Parámetros Físicos (Escala Interna Estilo Smash)
@export var weight: float = 100.0            ## Peso: a mayor peso, menor Knockback recibido
@export var run_speed: float = 1.76          ## Velocidad máxima de carrera en tierra
@export var walk_speed: float = 1.05         ## Velocidad base de desplazamiento suave
@export var initial_dash_speed: float = 1.98 ## Impulso inicial al arrancar
@export var traction: float = 0.08           ## Fricción terrestre al frenar
@export var jump_velocity: float = 14.0      ## Impulso vertical del salto completo
@export var short_hop_velocity: float = 10.5 ## Impulso del salto corto (Short Hop)
@export var air_speed: float = 1.0           ## Velocidad horizontal máxima en el aire
@export var air_acceleration: float = 0.05   ## Aceleración horizontal aérea
@export var air_friction: float = 0.01       ## Resistencia horizontal en el aire
@export var gravity: float = 0.09            ## Gravedad vertical aplicada en caída
@export var fall_speed: float = 1.60         ## Velocidad terminal de caída normal
@export var fast_fall_speed: float = 2.56    ## Velocidad terminal en caída rápida (Fast-Fall)
@export var pushbox_radius: float = 0.5      ## Radio de separación suave cuerpo a cuerpo
@export var jumpsquat_frames: int = 3        ## Frames de preparación antes de despegar del suelo
@export var instant_run: bool = false
#endregion

#region Modelo 3D, Orientación y Repertorio de Ataques
@export var model_scene: PackedScene
@export var model_offset: Vector3 = Vector3(0.0, -0.9, 0.0)
@export var model_scale: float = 1.0
@export var facing_angle_degrees: float = 75.6
@export var use_mirror_facing: bool = false
@export var animation_library: AnimationLibrary
@export var moveset: MoveSet
#endregion
