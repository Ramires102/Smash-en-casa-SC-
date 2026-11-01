# ==============================================================================
# HitboxData — Sub-Burbuja de Impacto (Sweetspot / Sourspot)
# ==============================================================================
# Permite que un mismo ataque tenga zonas con propiedades distintas (por ejemplo:
# la punta de la espada pega más fuerte que el mango). La sub-burbuja con mayor
# prioridad entre las que tocan al rival gana el impacto.
# ==============================================================================
class_name HitboxData
extends Resource

@export var name: String = "Hitbox"
@export var offset: Vector3 = Vector3(0.8, 0.0, 0.0) ## Offset en metros relativo al personaje
@export var radius: float = 0.55                     ## Radio de la burbuja en metros
@export var damage: float = 8.0                      ## Daño específico de esta zona
@export var base_knockback: float = 15.0             ## Knockback base
@export var knockback_scaling: float = 1.0           ## Crecimiento de Knockback por %
@export var angle_degrees: float = 45.0              ## Ángulo de lanzamiento en grados
@export var priority: int = 0                        ## Mayor número = mayor prioridad
@export var bonus_shield_damage: float = 0.0         ## Daño extra contra escudos
