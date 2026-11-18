shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D detail_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_detail_normal = false;

uniform vec4 albedo_tint : source_color = vec4(0.95, 0.95, 0.96, 1.0);
uniform float detail_scale : hint_range(0.1, 8.0) = 1.8;
uniform float detail_normal_strength : hint_range(0.0, 1.5) = 0.65;
uniform float base_roughness : hint_range(0.2, 0.95) = 0.56;
uniform float specular_level : hint_range(0.0, 1.0) = 0.36;
uniform float wear_variation : hint_range(0.0, 0.4) = 0.22;
uniform float quality_detail : hint_range(0.0, 1.0) = 1.0;

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 tex_col = texture(albedo_tex, UV).rgb * albedo_tint.rgb;

	// World-space tarmac grain & worn sheen pockets (preserves road lane markings 100%)
	float n_macro = value_noise(v_world_pos.xz * 0.11);
	float n_mid = value_noise(v_world_pos.xz * 0.45);
	float n_fine = value_noise(v_world_pos.xz * 5.2);
	float macro_mix = mix(n_macro, n_mid, 0.42);

	// Subtle aggregate tonal breakup so tarmac doesn't look flat or chalky
	float micro_shade = mix(0.93, 1.03, n_fine) * mix(0.94, 1.02, macro_mix);
	tex_col *= mix(1.0, micro_shade, clamp(quality_detail * 0.85, 0.2, 1.0));

	// Worn rubber/polished tire lanes vs coarser outer shoulder (smooth satin pockets, never plastic wet)
	float rough_delta = (macro_mix - 0.5) * 2.0 * wear_variation;
	float rough = clamp(base_roughness + rough_delta + (n_fine - 0.5) * 0.08, 0.36, 0.88);
	// Low preset uses clean glare-free matte roughness
	rough = mix(0.84, rough, quality_detail);

	if (has_detail_normal && quality_detail > 0.15) {
		vec2 w_uv = v_world_pos.xz * detail_scale;
		vec3 dn1 = texture(detail_normal_tex, w_uv).xyz * 2.0 - 1.0;
		vec3 dn2 = texture(detail_normal_tex, w_uv * 3.17 + vec2(0.37, 0.71)).xyz * 2.0 - 1.0;
		vec3 dn = normalize(dn1 * 0.65 + dn2 * 0.35);
		float s = detail_normal_strength * quality_detail;
		NORMAL = normalize(NORMAL + TANGENT * (dn.x * s) + BINORMAL * (dn.y * s));
	}

	ALBEDO = tex_col;
	METALLIC = 0.0;
	ROUGHNESS = rough;
	SPECULAR = mix(0.16, specular_level, quality_detail);
}
