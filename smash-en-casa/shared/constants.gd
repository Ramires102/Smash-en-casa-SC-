# ==============================================================================
# Constants — Constantes Globales de Física y Combate
# ==============================================================================
# Centraliza todos los factores numéricos compartidos entre la simulación 2D
# y la representación visual 3D del juego (estilo Super Smash Bros).
# ==============================================================================
class_name Constants
extends RefCounted

#region Escala Espacio 2D -> Mundo 3D
## Conversión maestro del motor híbrido 2.5D: 28 píxeles en física 2D equivalen a 1 metro en 3D.
const UNIT_SIZE: float = 28.0
#endregion

#region Reglas de Daño y Knockback
## Tope máximo de daño acumulado (%) que puede recibir un luchador.
const MAX_PERCENTAGE: float = 999.0

## Factor trigonométrico base de desaceleración por frame durante el vuelo por golpe (Hitstun).
const KB_DECAY_BASE: float = 0.051
#endregion

#region Ángulo Sakurai (361°)
## Código especial de ángulo heredado de Smash: adapta el lanzamiento según si el rival
## está en tierra o aire y según la potencia del golpe.
const SAKURAI_ANGLE: float = 361.0
const SAKURAI_ANGLE_NEG: float = -181.0
const SAKURAI_KB_THRESHOLD: float = 11.5
const SAKURAI_HIGH_GROUND: float = 42.0
const SAKURAI_HIGH_AIR: float = 42.0
const SAKURAI_LOW_GROUND: float = 28.0
const SAKURAI_LOW_AIR: float = 38.0
#endregion

#region Hitlag Asimétrico (Congelamiento de Impacto)
## El atacante sufre un poco menos de pausa de impacto que el defensor para conservar ventaja de turno.
const ATTACKER_HITLAG_MIN_MULT: float = 0.75
const ATTACKER_HITLAG_MAX_MULT: float = 0.95
const ATTACKER_HITLAG_KB_REFERENCE: float = 32.0
#endregion

#region Defensa de Escudo (Shield Stun y Pushback)
const SHIELD_STUN_DAMAGE_MULT: float = 0.72
const SHIELD_STUN_BASE_FRAMES: float = 3.0
const SHIELD_PUSHBACK_BASE: float = 85.0
const SHIELD_PUSHBACK_KB_MULT: float = 10.5
const SHIELD_PUSHBACK_MAX: float = 280.0
const SHIELD_ATTACKER_PUSHBACK_MULT: float = 0.42
#endregion

#region Aterrizaje (Landing Lag)
const NORMAL_LANDING_LAG_FRAMES: int = 3
const AIRDODGE_LANDING_LAG_FRAMES: int = 5
#endregion
