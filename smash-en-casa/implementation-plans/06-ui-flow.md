# Plan 06 - UI del flujo principal

## Objetivo

Cerrar interfaz minima del loop de juego sin meterse aun en features secundarias.

## Alcance

- Incluye:
- MainMenu, CharacterSelect, HUD, Pause, Victory.
- Actualizacion de porcentaje, vidas y timer en HUD.
- Navegacion clara entre escenas principales.

- No incluye:
- Gacha como parte obligatoria del loop MVP.
- UI cosmetica avanzada de coleccionables.

## Dependencias

- BattleManager con estados de partida (Plan 04).
- Señales/eventos de daño/stock/timer disponibles.

## Tareas

- [ ] Ajustar flujo menu -> select -> battle -> victory.
- [ ] Conectar HUD a fuentes de verdad (porcentaje/vidas/timer).
- [ ] Implementar pausa funcional con resume/exit.
- [ ] Revisar que Gacha quede etiquetado Post-MVP.

## Entregables

- Loop completo navegable por un usuario final.
- Feedback claro de estado de combate en pantalla.

## Criterio de terminado

- UI reacciona a eventos de partida, no hace polling acoplado sobre Character.
