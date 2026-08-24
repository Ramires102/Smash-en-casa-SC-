class_name ImpactData
extends RefCounted

## Payload canónico de impacto.
## Se genera una sola vez al momento de la colisión hitbox→hurtbox
## y viaja inmutable por todo el pipeline de combate.

# ── Identidad del impacto ──
var swing_id: int = -1               ## ID único de la activación de hitbox
var attacker: Node3D                  ## Referencia al Character atacante
var attacker_id: int = -1             ## player_id del atacante
var target: Node3D                    ## Referencia al Character defensor
var target_id: int = -1               ## player_id del defensor

# ── Datos del ataque (referencia al AttackData fuente) ──
var attack_data: AttackData           ## Referencia al AttackData original
var damage: float = 0.0               ## Daño que aplica este impacto
var attack_name: String = ""          ## Nombre del ataque para debug/logging

# ── Datos calculados ──
var knockback_vector: Vector3 = Vector3.ZERO  ## Vector de empuje final calculado
var knockback_magnitude: float = 0.0          ## Magnitud escalar del knockback
var hitstun_frames: int = 0                   ## Frames de hitstun (floor(KB * 0.4))
var hitlag_frames: int = 0                    ## Frames de hitlag (floor(dmg * 0.65 + 6))
var target_percent_after: float = 0.0         ## % del target DESPUÉS del golpe

# ── Contexto espacial ──
var hit_position: Vector3 = Vector3.ZERO      ## Posición del impacto en world space
var attacker_facing: float = 1.0              ## Dirección que mira el atacante (-1 o 1)
