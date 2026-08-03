# Explicación de `shared/utils.gd`

## Resumen
Contiene funciones estáticas utilitarias para dar formato visual a textos de temporizador (`MM:SS`) y porcentaje de daño (`X%`).

## Explicación Línea por Línea
```gdscript
1: class_name Utils
2: extends RefCounted
```
- Registra el nombre de clase estático `Utils`.

```gdscript
4: static func format_time(seconds: float) -> String:
5: 	var mins: int = int(seconds) / 60
6: 	var secs: int = int(seconds) % 60
7: 	return "%02d:%02d" % [mins, secs]
```
- `format_time`: Convierte segundos flotantes (ej. 480.0) en formato textual con dos dígitos para minutos y segundos (ej. `"08:00"`).

```gdscript
9: static func format_percentage(value: float) -> String:
10: 	return "%d%%" % int(value)
```
- `format_percentage`: Convierte el flotante de daño a entero con el símbolo `%` (ej. `124%`).

## Comunicación e Interacciones
- **Consumido por**: `HUD.gd` para formatear los textos del HUD durante la partida.
