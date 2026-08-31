class_name ImpactData
extends RefCounted

## Payload canónico de impacto 2D.
## Se genera una sola vez al momento de la colisión Hitbox(Area2D) → Hurtbox(Area2D)
## y viaja inmutable por todo el pipeline de combate.

# ── Identidad del impacto ──
var swing_id: int = -1               ## ID único de la activación de hitbox
var attacker: Node                   ## Referencia al Character atacante
var attacker_id: int = -1             ## player_id del atacante
var target: Node                     ## Referencia al Character defensor
var target_id: int = -1               ## player_id del defensor

# ── Datos del ataque (referencia al AttackData fuente) ──
var attack_data: AttackData           ## Referencia al AttackData original
var damage: float = 0.0               ## Daño que aplica este impacto
var attack_name: String = ""          ## Nombre del ataque para debug/logging

# ── Datos calculados en 2D ──
var knockback_vector: Vector2 = Vector2.ZERO  ## Vector 2D de empuje final calculado (px/s)
var knockback_magnitude: float = 0.0          ## Magnitud escalar del knockback (KB de SND)
var hitstun_frames: int = 0                   ## Frames de hitstun = floor(KB * 1.33333)
var hitlag_frames: int = 0                    ## Frames de hitlag = floor(dmg * 0.65 + 6) / mod
var target_percent_after: float = 0.0         ## % del target DESPUÉS del golpe

# ── Datos de Splash N Dash (per-component decay y angle flipper) ──
var hdecay: float = 0.0                       ## Decay horizontal por frame (Hitboxes.gd:108-112)
var vdecay: float = 0.0                       ## Decay vertical por frame (Hitboxes.gd:114-118)
var angle_flipper: int = 0                    ## Modo de angle flipper (0-7)
var attack_type: String = "normal"            ## Tipo de efecto visual/mecánico ("normal", "slash", "Flip", etc.)
var hitlag_modifier: float = 1.0              ## Modificador de hitlag

# ── Contexto espacial 2D ──
var hit_position: Vector2 = Vector2.ZERO      ## Posición del impacto en 2D world space
var attacker_facing: float = 1.0              ## Dirección que mira el atacante (-1 o 1)
