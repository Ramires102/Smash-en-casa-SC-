# 00 - Architecture Guardrails (Reglas Innegociables)

## Objetivo

Evitar que cualquier implementacion rompa la arquitectura definida en ARCHITECTURE.md.

## Regla principal

Ningun implementation plan puede contradecir, bypass-ear o debilitar la arquitectura base.
Si una tarea entra en conflicto, se corrige el plan, no la arquitectura.

## Limites de arquitectura

- resources = datos (CharacterData, MoveSet, AttackData).
- assets = contenido artistico (modelos, texturas, audio, VFX).
- characters = comportamiento en runtime (FSM, movimiento, ataque).
- combat resuelve impactos, dano y knockback.
- battle resuelve reglas de partida (stocks, timer, winner).
- autoloads minimos: GameManager, AudioManager, InputManager.

## Separacion de responsabilidades obligatoria

- AttackData define que es un ataque; AttackState ejecuta el ataque.
- FSM decide estado actual; no calcula dano ni knockback.
- Character representa instancia viva; CharacterData representa configuracion.
- Stage define espacio; BattleManager define reglas.

## Prohibiciones (anti-patrones)

- Meter logica de combate dentro de resources.
- Input directo de teclas dentro de Character para gameplay principal.
- Multiplicar singletons/globales por comodidad.
- Agregar sistemas fuera de alcance del loop principal.

## Checklist de validacion arquitectonica

- [ ] Respeta boundaries de carpetas y modulos.
- [ ] No introduce acoplamiento global nuevo.
- [ ] No mueve reglas de Battle a Character.
- [ ] No mueve logica de Combat a FSM.
- [ ] No mezcla assets con resources.
- [ ] Mantiene flujo principal: select -> battle -> KO -> victory.

## Politica para issues

Todo issue debe incluir una seccion "Architecture Check" con esta frase:

"Este issue no rompe la arquitectura definida en ARCHITECTURE.md y mantiene responsabilidades por modulo."
