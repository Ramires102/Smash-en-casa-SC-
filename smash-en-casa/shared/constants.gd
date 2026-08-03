class_name Constants
extends RefCounted

# Configuración de combate
const MAX_PERCENTAGE: float = 999.0
const DEFAULT_LIVES: int = 3
const DEFAULT_TIMER: float = 480.0 # 8 minutos

# Física y juego 2.5D
const GRAVITY_MULTIPLIER: float = 1.0
const BLAST_ZONE_PADDING: float = 5.0
const Z_PLANE: float = 0.0 # Plano de movimiento 2.5D

# Modos de juego
enum GameMode { TIME, STOCK, STAMINA }
