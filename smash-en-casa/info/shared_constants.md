# Explicación de `shared/constants.gd`

## Resumen
Este archivo define constantes globales centralizadas para las reglas de combate, límites de porcentaje, configuración del temporizador y constantes de posición para la perspectiva 2.5D.

## Explicación Línea por Línea
```gdscript
1: class_name Constants
```
- Define un nombre de clase global `Constants` registrado en Godot, permitiendo llamar a `Constants.MAX_PERCENTAGE` desde cualquier script sin usar `preload` ni instanciar.

```gdscript
2: extends RefCounted
```
- Hereda de `RefCounted`, la clase base más ligera en Godot para objetos de datos en memoria sin representación en el árbol de nodos (`Node`).

```gdscript
4: # Configuración de combate
5: const MAX_PERCENTAGE: float = 999.0
6: const DEFAULT_LIVES: int = 3
7: const DEFAULT_TIMER: float = 480.0 # 8 minutos
```
- Define las constantes numéricas básicas de una partida estilo Smash Bros: límite máximo de acumulación de daño (999%), 3 vidas de stock por defecto y 8 minutos de límite de tiempo (480 segundos).

```gdscript
9: # Física y juego 2.5D
10: const GRAVITY_MULTIPLIER: float = 1.0
11: const BLAST_ZONE_PADDING: float = 5.0
12: const Z_PLANE: float = 0.0 # Plano de movimiento 2.5D
```
- Multiplicador de gravedad y acolchado de zonas de KO. `Z_PLANE = 0.0` fija el eje Z en cero para que los luchadores se muevan estrictamente en un plano 2D dentro del espacio 3D.

```gdscript
14: # Modos de juego
15: enum GameMode { TIME, STOCK, STAMINA }
```
- Enumeración para soportar futuros modos de juego (Por tiempo, Por vidas/stock o Por barra de vida Stamina).

## Comunicación e Interacciones
- **Consumido por**: `Character.gd` (lee `Z_PLANE`), `DamageCalculator.gd` (usa `MAX_PERCENTAGE`), `BattleManager.gd` (usa `DEFAULT_LIVES` y `DEFAULT_TIMER`).
