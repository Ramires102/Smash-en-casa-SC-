class_name CSAudioSynth
extends RefCounted

static func create_sfx_bank() -> Dictionary:
	return {
		"move": synth_tone(780.0, 0.045, 0.3),
		"select": synth_dual_tone(600.0, 1100.0, 0.12, 0.4),
		"cancel": synth_sweep(400.0, 180.0, 0.08, 0.35),
		"ready": synth_chord([440.0, 554.37, 659.25], 0.35, 0.45)
	}

static func synth_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples := int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / 22050.0
		var env: float = 1.0 - (float(i) / float(samples))
		var v: float = sin(t * freq * TAU) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

static func synth_dual_tone(f1: float, f2: float, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples := int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / 22050.0
		var env: float = 1.0 - (float(i) / float(samples))
		var v: float = (sin(t * f1 * TAU) * 0.5 + sin(t * f2 * TAU) * 0.5) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

static func synth_sweep(f_start: float, f_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples := int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var norm: float = float(i) / float(samples)
		var freq: float = lerpf(f_start, f_end, norm)
		var t: float = float(i) / 22050.0
		var env: float = 1.0 - norm
		var v: float = sin(t * freq * TAU) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

static func synth_chord(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var samples := int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / 22050.0
		var env: float = 1.0 - (float(i) / float(samples))
		var acc: float = 0.0
		for f in freqs:
			acc += sin(t * float(f) * TAU)
		var v: float = (acc / float(freqs.size())) * env * volume
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav

