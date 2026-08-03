# Explicación de `resources/character_data.gd`

## Resumen
Resource central que define toda la información de un personaje (nombre, velocidad de movimiento, salto, peso, color de malla/sprite, icono y su `MoveSet`). Este es el corazón de la arquitectura Data-Driven.

## Explicación Línea por Línea
```gdscript
1: class_name CharacterData
2: extends Resource

4: @export var character_name: String = "Luchador"
5: @export var move_speed: float = 8.0
6: @export var jump_velocity: float = 14.0
7: @export var weight: float = 100.0 # Peso medio (Mewtwo ~79, Mario ~98, Bowser ~135)
8: @export var icon: Texture2D
9: @export var character_color: Color = Color.WHITE
10: @export var moveset: MoveSet
```
- Define las características físicas y visuales editables de un personaje.
- `weight`: Utilizado directamente en la fórmula de Knockback.
- `moveset`: Referencia al Resource `MoveSet`.

## Comunicación e Interacciones
- **Leído por**: `Character.gd` en `load_character(data)` para configurar el luchador dinámicamente sin duplicar código de escenas.
- **Asignado en**: `CharacterSelect.gd` y `GameManager.gd`.
