# Explicación de `core/audio_manager.gd`

## Resumen
Autoload (Singleton) para la gestión centralizada de música de fondo (BGM) y efectos de sonido (SFX) con un pool de reproductores de audio.

## Explicación Línea por Línea
```gdscript
1: extends Node
2: var bgm_player: AudioStreamPlayer
3: var sfx_players: Array[AudioStreamPlayer] = []
4: const MAX_SFX_CHANNELS: int = 12
```
- Declara el canal principal para música `bgm_player` y una lista de 12 canales secundarios de efectos `sfx_players`.

```gdscript
6: func _ready() -> void:
7: 	bgm_player = AudioStreamPlayer.new()
8: 	bgm_player.bus = &"Master"
9: 	add_child(bgm_player)
10: 	for i in range(MAX_SFX_CHANNELS):
11: 		var player := AudioStreamPlayer.new()
12: 		player.bus = &"Master"
13: 		add_child(player)
14: 		sfx_players.append(player)
```
- `_ready()`: Crea e instancian los nodos `AudioStreamPlayer` en tiempo de ejecución conectándolos al bus de sonido `Master`.

```gdscript
16: func play_bgm(stream: AudioStream) -> void:
17: 	if bgm_player.stream == stream and bgm_player.playing:
18: 		return
19: 	bgm_player.stream = stream
20: 	bgm_player.play()
```
- Reproduce música sin reiniciarla si ya se está reproduciendo la misma pista.

```gdscript
22: func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
23: 	if stream == null: return
24: 	for player in sfx_players:
25: 		if not player.playing:
26: 			player.stream = stream
27: 			player.pitch_scale = pitch_scale
28: 			player.play()
29: 			return
```
- Busca el primer canal de audio libre en el pool de 12 canales y reproduce el efecto de sonido inmediatamente.

## Comunicación e Interacciones
- **Llamado por**: `Character.gd` (al recibir/dar golpes usando `attack_data.hit_sfx`), interfaces UI.
