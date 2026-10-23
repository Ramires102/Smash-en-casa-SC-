class_name Constants
extends RefCounted

# Configuración de combate
const MAX_PERCENTAGE: float = 999.0

# ── Constantes de Knockback y Física de Lanzamiento ─────────────────────
const KB_VELOCITY_SCALE: float = 28.5       ## Escala de velocidad inicial 2D (px/s por unidad de KB)
const KB_MINIMUM_LAUNCH: float = 4.2        ## Piso mínimo de KB para evitar golpes que no empujan a 0%
const KB_DECAY_BASE: float = 0.051          ## Decay trigonométrico base de Smash
const KB_DECAY_H_FACTOR: float = 0.36       ## Frenado horizontal por frame en Hitstun (permite parábolas amplias)
const KB_DECAY_V_FACTOR: float = 0.42       ## Frenado vertical por frame en Hitstun

# ── Escala Visual 2D a 3D ───────────────────────────────────────────────
const UNIT_SIZE: float = 28.0               ## 28 píxeles 2D = 1 unidad/metro en el mundo 3D

# ── Ángulo Sakurai (S-Angle) ────────────────────────────────────────────
const SAKURAI_ANGLE: float = 361.0          ## Ángulo Sakurai estándar
const SAKURAI_ANGLE_NEG: float = -181.0     ## Ángulo Sakurai invertido
const SAKURAI_KB_THRESHOLD: float = 11.5    ## Umbral de KB (en escala /10) para levantar del suelo
const SAKURAI_HIGH_GROUND: float = 42.0     ## Ángulo suelo con KB medio/alto (levanta para combos)
const SAKURAI_HIGH_AIR: float = 42.0        ## Ángulo aire con KB alto
const SAKURAI_LOW_GROUND: float = 28.0      ## Ángulo suelo con KB bajo (semi-tumble, evita castigo en hit)
const SAKURAI_LOW_AIR: float = 38.0         ## Ángulo aire con KB bajo

# ── Hitstun y Hitlag (Ritmo de Combate) ─────────────────────────────────
const HITSTUN_MULTIPLIER: float = 1.65      ## Multiplicador de hitstun para permitir combos reales a bajo %
const HITSTUN_MIN_FRAMES: int = 12          ## Mínimo absoluto de hitstun en golpes limpios (evita negative on hit)

# Hitlag ágil estilo Smash: golpes rápidos = 4-6 frames, golpes pesados = 10-14 frames
const HITLAG_DAMAGE_MULT: float = 0.38      ## Factor de daño en hitlag
const HITLAG_BASE_FRAMES: float = 3.0       ## Frames base de hitlag
const HITLAG_MAX_FRAMES: int = 16           ## Tope para evitar congelamientos excesivos

# ── Directional Influence (DI) ──────────────────────────────────────────
const HITLAG_DI_ANGLE_INFLUENCE: float = 0.31 ## ~18 grados máximos de rotación de DI (estándar competitivo)
const HITLAG_DI_SPEED_INFLUENCE: float = 0.08 ## Influencia sobre velocidad (Survival / Combo DI)
const HITLAG_DI_DEADZONE: float = 0.18        ## Deadzone para ignorar micro-ruido analógico

# ── Defensa de Escudo ───────────────────────────────────────────────────
const SHIELD_STUN_DAMAGE_MULT: float = 0.72
const SHIELD_STUN_BASE_FRAMES: float = 3.0
const SHIELD_PUSHBACK_BASE: float = 85.0
const SHIELD_PUSHBACK_KB_MULT: float = 10.5
const SHIELD_PUSHBACK_MAX: float = 280.0
const SHIELD_ATTACKER_PUSHBACK_MULT: float = 0.42

# ── Impact Feel (Pegada al conectar) ────────────────────────────────────
const ATTACKER_HITLAG_MIN_MULT: float = 0.75    ## Atacante y defensor salen casi juntos del hitlag
const ATTACKER_HITLAG_MAX_MULT: float = 0.95
const ATTACKER_HITLAG_KB_REFERENCE: float = 32.0
const HIT_SHAKE_BASE: float = 1.8
const HIT_SHAKE_DAMAGE_MULT: float = 0.25
const HIT_SHAKE_KB_MULT: float = 0.18
const HIT_SHAKE_MIN: float = 2.2
const HIT_SHAKE_MAX: float = 12.0
const SHIELD_HIT_SHAKE_MULT: float = 0.55

# ── Bounce y Tumble ─────────────────────────────────────────────────────
const BOUNCE_KB_THRESHOLD: float = 11.0
const BOUNCE_ELASTICITY: float = 0.68
const TUMBLE_KB_THRESHOLD: float = 12.5

# ── Teching / Ukemi ─────────────────────────────────────────────────────
const TECH_WINDOW_FRAMES: int = 20
const TECH_COOLDOWN_FRAMES: int = 40
const MISSED_TECH_LANDING_LAG: int = 10
const UKEMI_BUFFER_FRAMES: int = 20
const UKEMI_INVULN_SECONDS: float = 0.22
const UKEMI_ROLL_SPEED: float = 330.0

# ── Movimiento Aéreo y Terrestre ────────────────────────────────────────
const FASTFALL_MIN_VY: float = -90.0            ## Permite iniciar Fast-Fall apenas cerca del ápice del salto
const AIR_NEUTRAL_FRICTION_DIV: float = 6.5     ## Menos freno aéreo en neutral para conservar momentum del salto
const NORMAL_LANDING_LAG_FRAMES: int = 3
const AIRDODGE_LANDING_LAG_FRAMES: int = 5      ## Waveland más fluido
