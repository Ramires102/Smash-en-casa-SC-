# Explicación de los Componentes del Personaje (`characters/`)

## Resumen
Refactorización del nodo `Character` a una arquitectura modular basada en componentes desacoplados.

---

## 1. `attack_controller.gd`
- **Ubicación en árbol**: `Character/AttackController`
- **Responsabilidad**: Actúa como intermediario entre la entrada del personaje y el módulo de combate (`Hitbox`).
  - Elige qué `AttackData` corresponde según los inputs (Neutral, Tilt, Air, Special).
  - Gestiona la activación y desactivación de la `Hitbox`.
  - Emite señales de ejecución de ataques.

---

## 2. `character_stats.gd`
- **Ubicación en árbol**: `Character/Stats`
- **Responsabilidad**: Almacena y gestiona las estadísticas individuales del luchador (porcentaje acumulado de daño %, peso `weight`).
  - Método `add_damage(amount)`: incrementa y limita el porcentaje acumulativo.

---

## 3. `character_controller.gd`
- **Ubicación en árbol**: `Character/Controller`
- **Responsabilidad**: Maneja la física de movimiento horizontal y salto, consultando al `InputManager`.
  - Propiedad `@export var facing_angle: float = 75.0`: Ángulo de perspectiva 3/4 para peleas 2.5D.
  - Método `set_facing_direction(dir)`: Ajusta la orientación en $Y$ a $+75.0^\circ$ al mirar a la derecha ($+1.0$) y a $-105.0^\circ$ al mirar a la izquierda ($-1.0$), asegurando que el cuerpo y las Hitboxes apunten correctamente hacia el adversario.

## Comunicación e Interacciones
- Todos estos componentes son instanciados en `Character.tscn` y se configuran automáticamente desde el Resource `CharacterData` mediante `load_character()`.
