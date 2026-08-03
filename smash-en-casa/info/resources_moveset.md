# Explicación de `resources/moveset.gd`

## Resumen
Resource contenedor que agrupa las instancias de `AttackData` de un personaje según la dirección de entrada (Neutral, Lateral, Superior, Inferior, Aéreo, Especial).

## Explicación Línea por Línea
```gdscript
1: class_name MoveSet
2: extends Resource

4: @export var neutral_attack: AttackData
5: @export var side_tilt: AttackData
6: @export var up_tilt: AttackData
7: @export var down_tilt: AttackData
8: @export var neutral_air: AttackData
9: @export var special_neutral: AttackData
```
- Define las variables exportadas tipo `AttackData` para que cada personaje tenga su lista de movimientos asignable desde el inspector de Godot.

## Comunicación e Interacciones
- **Pertenece a**: `CharacterData.gd`.
- **Leído por**: `Character.gd` en `get_current_attack()`.
