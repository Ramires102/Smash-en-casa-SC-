class_name Constants
extends RefCounted

# Configuración de combate
const MAX_PERCENTAGE: float = 999.0

# ── Constantes de Knockback (Splash N Dash - Hitboxes.gd:178-188) ──
# KB = ((kb_scaling/100) * ((14 * (p+d) * (d+2)) / (w+100) + 18) + base_kb) / 10
const KB_VELOCITY_SCALE: float = 30.0       ## InitialVelocity = KB * 30.0 (px/s en 2D)
const KB_DECAY_BASE: float = 0.051          ## Decay trigonométrico base (Hitboxes.gd:109-118)
const KB_DECAY_H_FACTOR: float = 0.4        ## hdecay aplicado * 0.4 por frame (CharacterSM.gd:866-870)
const KB_DECAY_V_FACTOR: float = 0.5        ## vdecay aplicado * 0.5 por frame (CharacterSM.gd:862-864)

# ── Escala Visual 2D a 3D (Globals.gd) ──
const UNIT_SIZE: float = 28.0               ## 28 píxeles 2D = 1 unidad/metro en el mundo 3D

# ── Ángulo Sakurai (Hitboxes.gd:190-213) ──
const SAKURAI_ANGLE: float = 361.0          ## Ángulo Sakurai estándar
const SAKURAI_ANGLE_NEG: float = -181.0     ## Ángulo Sakurai invertido
const SAKURAI_KB_THRESHOLD: float = 28.0    ## Umbral de KB para bifurcación de ángulo
const SAKURAI_HIGH_GROUND: float = 38.0     ## Ángulo suelo con KB alto
const SAKURAI_HIGH_AIR: float = 40.0        ## Ángulo aire con KB alto
const SAKURAI_LOW_GROUND: float = 25.0      ## Ángulo suelo con KB bajo
const SAKURAI_LOW_AIR: float = 40.0         ## Ángulo aire con KB bajo

# ── Hitstun y Hitlag (Hitboxes.gd:90-100) ──
# Hitstun = floor(KB / 0.3 * 0.4) = floor(KB * 1.33333)
const HITSTUN_MULTIPLIER: float = 1.33333   ## floor(KB * this) = hitstun frames
# Hitlag = floor((floor(damage) * 0.65 + 6.0) / hitlag_modifier)
const HITLAG_DAMAGE_MULT: float = 0.65      ## Factor de daño en hitlag
const HITLAG_BASE_FRAMES: float = 6.0       ## Frames base de hitlag
const HITLAG_DI_ANGLE_INFLUENCE: float = 0.17 ## PlatformFighter: ajuste angular en hitlag (rad * input_x)
const HITLAG_DI_SPEED_INFLUENCE: float = 0.09 ## PlatformFighter: ajuste de velocidad en hitlag (input_y)
const HITLAG_DI_DEADZONE: float = 0.18        ## Deadzone para ignorar micro-ruido analógico

# ── Defensa de Escudo (inspirado en PlatformFighter) ──
const SHIELD_STUN_DAMAGE_MULT: float = 0.8      ## shieldstun frames += damage * 0.8
const SHIELD_STUN_BASE_FRAMES: float = 2.0      ## base de shieldstun en frames
const SHIELD_PUSHBACK_BASE: float = 70.0        ## pushback mínimo en bloqueo (px/s)
const SHIELD_PUSHBACK_KB_MULT: float = 9.0      ## pushback extra por knockback escalar
const SHIELD_PUSHBACK_MAX: float = 260.0        ## tope de pushback en escudo
const SHIELD_ATTACKER_PUSHBACK_MULT: float = 0.38 ## recoil aplicado al atacante tras bloqueo

# ── Impact Feel (pegada al conectar) ──
const ATTACKER_HITLAG_MIN_MULT: float = 0.55    ## hitlag mínimo del atacante en golpes débiles
const ATTACKER_HITLAG_MAX_MULT: float = 0.90    ## hitlag máximo del atacante en golpes fuertes
const ATTACKER_HITLAG_KB_REFERENCE: float = 40.0 ## KB de referencia para escalar hitlag atacante
const HIT_SHAKE_BASE: float = 1.6               ## base de intensidad de shake en impactos
const HIT_SHAKE_DAMAGE_MULT: float = 0.22       ## aporte del daño al shake
const HIT_SHAKE_KB_MULT: float = 0.16           ## aporte del knockback escalar al shake
const HIT_SHAKE_MIN: float = 2.0                ## mínimo de shake en hit conectado
const HIT_SHAKE_MAX: float = 11.5               ## máximo de shake en hit conectado
const SHIELD_HIT_SHAKE_MULT: float = 0.62       ## bloqueo sacude menos que hit limpio

# ── Bounce y Tumble (CharacterSM.gd:848-879) ──
const BOUNCE_KB_THRESHOLD: float = 18.0     ## KB >= 18 → Wall/Floor Bounce activo
const BOUNCE_ELASTICITY: float = 0.6        ## velocity.bounce(normal) * 0.6
const TUMBLE_KB_THRESHOLD: float = 24.0     ## KB >= 24 → Tumble al salir de Hitstun

# ── Teching / Ukemi (CharacterSM.gd:896-908) ──
const TECH_WINDOW_FRAMES: int = 20          ## Ventana de tech frames (tech_frames < 20)
const TECH_COOLDOWN_FRAMES: int = 40        ## Cooldown tras presionar shield para tech
const MISSED_TECH_LANDING_LAG: int = 7      ## lag_frames = 7 al fallar tech
const UKEMI_BUFFER_FRAMES: int = 20         ## Alias para tech window
const UKEMI_INVULN_SECONDS: float = 0.18    ## Invulnerabilidad durante tech
const UKEMI_ROLL_SPEED: float = 300.0       ## Velocidad 2D de tech roll en px/s

# ── Movimiento Aéreo (CharacterSM.gd:1978-2014) ──
const FASTFALL_MIN_VY: float = -150.0       ## Solo fastfall si velocity.y > -150
const AIR_NEUTRAL_FRICTION_DIV: float = 5.0 ## Fricción neutral aérea = AIR_ACCEL / 5
const NORMAL_LANDING_LAG_FRAMES: int = 3    ## Landing lag base al caer (Splash/PlatformFighter)
const AIRDODGE_LANDING_LAG_FRAMES: int = 6  ## Landing lag de airdodge/waveland compartido
