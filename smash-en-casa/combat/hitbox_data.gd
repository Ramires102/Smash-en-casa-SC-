class_name HitboxData
extends Resource

## Definición de una burbuja de impacto individual para ataques con múltiples zonas (Sweetspots/Sourspots).
## Permite tener daños, ángulos y propiedades distintas en la punta vs la base de un golpe.

@export var name: String = "Hitbox"
@export var offset: Vector3 = Vector3(0.8, 0.0, 0.0)    ## Offset relativo al personaje (X se invierte según facing)
@export var radius: float = 0.55                         ## Radio de la esfera de colisión
@export var damage: float = 8.0                          ## Daño específico de esta burbuja
@export var base_knockback: float = 15.0                 ## Knockback base
@export var knockback_scaling: float = 1.0               ## Escalado de knockback
@export var angle_degrees: float = 45.0                  ## Ángulo de lanzamiento en grados
@export var priority: int = 0                            ## Prioridad de impacto (mayor valor conecta primero)
@export var bonus_shield_damage: float = 0.0             ## Daño adicional al escudo
