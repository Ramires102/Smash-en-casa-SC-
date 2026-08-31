shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float shockwave_radius : hint_range(0.0, 2.0) = 0.0;
uniform float shockwave_width : hint_range(0.01, 0.5) = 0.12;
uniform float shockwave_force : hint_range(0.0, 0.2) = 0.08;
uniform vec2 shockwave_center = vec2(0.5, 0.5);
uniform float grayscale_mix : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.0;
uniform vec4 stasis_tint : source_color = vec4(0.5, 0.55, 0.75, 1.0);
uniform float highlight_threshold : hint_range(0.4, 1.0) = 0.68;
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 diff = uv - shockwave_center;
	float dist = length(diff);

	// 1. Deformación espacial expansiva (Onda de distorsión)
	if (shockwave_radius > 0.0 && dist > 0.0) {
		float ring_dist = abs(dist - shockwave_radius);
		if (ring_dist < shockwave_width) {
			float wave_factor = (1.0 - ring_dist / shockwave_width);
			vec2 dir = diff / dist;
			uv += dir * sin(wave_factor * 3.14159) * shockwave_force;
		}
	}

	// 2. Aberración cromática (separación de colores en la onda)
	vec4 col;
	if (chromatic_aberration > 0.0005) {
		vec2 ca_offset = normalize(diff + vec2(0.0001)) * chromatic_aberration;
		float r = texture(screen_texture, uv + ca_offset).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - ca_offset).b;
		col = vec4(r, g, b, 1.0);
	} else {
		col = texture(screen_texture, uv);
	}

	// 3. Conversión a escala de grises con tinte de vacío temporal
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	vec3 gray_col = mix(vec3(gray), vec3(gray) * stasis_tint.rgb * 1.6, 0.5);

	// 4. Preservación y realce de elementos luminosos (cuchillos, brillos, auras)
	float luminance = max(max(col.r, col.g), col.b);
	float highlight_mask = smoothstep(highlight_threshold, 1.0, luminance);
	vec3 final_rgb = mix(mix(col.rgb, gray_col, grayscale_mix), col.rgb * 1.4, highlight_mask * grayscale_mix);

	// 5. Destello inicial de parada / reanudación
	final_rgb = mix(final_rgb, vec3(1.0), flash_intensity);

	COLOR = vec4(final_rgb, 1.0);
}
