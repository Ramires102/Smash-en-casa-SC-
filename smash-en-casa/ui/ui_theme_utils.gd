# ==============================================================================
# UIThemeUtils (Utilidades Estáticas de Interfaz y Audio Procedural)
# ==============================================================================
# Reúne herramientas reutilizables por todas las pantallas de interfaz (UI):
#   1. Fábrica de cajas de estilo (`StyleBoxFlat`) para evitar código repetitivo.
#   2. Sintetizador procedural de efectos de sonido WAV (tonos, barridos y acordes)
#      para los menús arcade sin depender de archivos externos.
#   3. Conversor ligero de Markdown a BBCode para el visor de créditos.
# ==============================================================================
class_name UIThemeUtils
extends RefCounted

#region Estilos Visuales (StyleBoxFlat)
## Crea y configura un `StyleBoxFlat` en una sola llamada limpia.
static func make_stylebox(
	bg_color: Color,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 0,
	corner_radius: int = 0,
	margin_h: float = -1.0,
	margin_v: float = -1.0
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	if border_width > 0:
		sb.border_color = border_color
		sb.set_border_width_all(border_width)
	if corner_radius > 0:
		sb.set_corner_radius_all(corner_radius)
	if margin_h >= 0.0:
		sb.content_margin_left = margin_h
		sb.content_margin_right = margin_h
	if margin_v >= 0.0:
		sb.content_margin_top = margin_v
		sb.content_margin_bottom = margin_v
	return sb
#endregion

#region Sintetizador Procedural de Audio UI (WAV 16-bit)
const MIX_RATE: int = 22050

## Genera un tono senoidal simple con decaimiento lineal (ideal para mover el cursor).
static func synth_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var samples: int = maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = 1.0 - (float(i) / float(samples))
		var v: float = sin(t * freq * TAU) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _build_wav(data)

## Genera dos tonos simultáneos (ideal para confirmar selección).
static func synth_dual_tone(f1: float, f2: float, duration: float, volume: float) -> AudioStreamWAV:
	var samples: int = maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = 1.0 - (float(i) / float(samples))
		var v: float = (sin(t * f1 * TAU) + sin(t * f2 * TAU)) * 0.5 * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _build_wav(data)

## Genera un barrido de frecuencia de `f_start` a `f_end` (ideal para cancelar/volver).
static func synth_sweep(f_start: float, f_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var samples: int = maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var norm: float = float(i) / float(samples)
		var freq: float = lerpf(f_start, f_end, norm)
		var t: float = float(i) / float(MIX_RATE)
		var env: float = 1.0 - norm
		var v: float = sin(t * freq * TAU) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _build_wav(data)

## Genera un acorde de múltiples frecuencias (ideal para "¡Todos Listos!").
static func synth_chord(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var samples: int = maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(samples * 2)
	var count: float = maxf(1.0, float(freqs.size()))
	for i in range(samples):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = 1.0 - (float(i) / float(samples))
		var sum_osc: float = 0.0
		for f in freqs:
			sum_osc += sin(t * float(f) * TAU)
		var v: float = (sum_osc / count) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _build_wav(data)

static func _build_wav(pcm_data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = pcm_data
	return wav
#endregion

#region Conversor Markdown a BBCode
## Convierte encabezados, separadores, viñetas, negritas y enlaces Markdown a BBCode de Godot.
static func markdown_to_bbcode(md: String) -> String:
	var bold_rx := RegEx.new()
	bold_rx.compile("\\*\\*(.*?)\\*\\*")
	var quote_rx := RegEx.new()
	quote_rx.compile("\"([^\"]+)\"")
	var url_rx := RegEx.new()
	url_rx.compile("(https?://[^\\s\\)]+)")

	var lines: PackedStringArray = md.split("\n")
	var result_lines: Array[String] = []

	for line in lines:
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with("### "):
			result_lines.append("\n[color=#e5c07b][font_size=13][b]%s[/b][/font_size][/color]" % trimmed.substr(4))
		elif trimmed.begins_with("## "):
			result_lines.append("\n[color=#61afef][font_size=15][b]%s[/b][/font_size][/color]" % trimmed.substr(3))
		elif trimmed.begins_with("# "):
			result_lines.append("\n[center][color=#98c379][font_size=19][b]%s[/b][/font_size][/color][/center]\n" % trimmed.substr(2))
		elif trimmed == "---":
			result_lines.append("[color=#3e4451]────────────────────────────────────────────────────────────────────────[/color]")
		elif trimmed.begins_with("- "):
			var item: String = _parse_inline_markdown(trimmed.substr(2), bold_rx, quote_rx, url_rx)
			result_lines.append("  [color=#61afef]•[/color] %s" % item)
		else:
			result_lines.append(_parse_inline_markdown(line, bold_rx, quote_rx, url_rx))

	return "\n".join(result_lines)

static func _parse_inline_markdown(text: String, bold_rx: RegEx, quote_rx: RegEx, url_rx: RegEx) -> String:
	var s: String = bold_rx.sub(text, "[b]$1[/b]", true)
	s = quote_rx.sub(s, "[color=#e5c07b]\"$1\"[/color]", true)
	s = url_rx.sub(s, "[color=#56b6c2][u]$1[/u][/color]", true)
	return s
#endregion
