# Explicación de `combat/damage_calculator.gd`

## Resumen
Utilidad estática encargada exclusivamente de sumar el daño recibido al porcentaje actual del objetivo respetando el límite máximo (`MAX_PERCENTAGE`).

## Explicación Línea por Línea
```gdscript
1: class_name DamageCalculator
2: extends RefCounted

4: static func apply_damage(current_percentage: float, damage: float) -> float:
5: 	return clamp(current_percentage + damage, 0.0, Constants.MAX_PERCENTAGE)
```
- `apply_damage`: Suma `damage` al `current_percentage` y aplica `clamp` entre 0.0 y 999.0%.

## Comunicación e Interacciones
- **Consumido por**: `Character.gd` al ser golpeado.
