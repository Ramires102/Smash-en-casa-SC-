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
  - Controla la orientación de mirada (`facing_direction`: 1.0 derecha, -1.0 izquierda).

## Comunicación e Interacciones
- Todos estos componentes son instanciados en `Character.tscn` y se configuran automáticamente desde el Resource `CharacterData` mediante `load_character()`.
