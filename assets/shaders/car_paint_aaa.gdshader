shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(0.85, 0.85, 0.85, 1.0);
uniform bool has_albedo_tex = false;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform bool has_normal_tex = false;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic;
uniform float normal_scale : hint_range(0.0, 2.0) = 1.0;

uniform float metallic_base : hint_range(0.0, 1.0) = 0.45;
uniform float base_roughness : hint_range(0.04, 0.8) = 0.18;
uniform float clearcoat_strength : hint_range(0.0, 1.0) = 1.0;
uniform float clearcoat_roughness : hint_range(0.005, 0.25) = 0.02;

uniform float flake_intensity : hint_range(0.0, 1.0) = 0.24;
uniform float flake_scale : hint_range(20.0, 500.0) = 210.0;
uniform float orange_peel : hint_range(0.0, 0.06) = 0.012;
uniform float fresnel_richness : hint_range(0.0, 0.6) = 0.28;
uniform float ao_sill_strength : hint_range(0.0, 0.6) = 0.26;
uniform float quality_detail : hint_range(0.0, 1.0) = 1.0;

varying vec3 v_obj_pos;
varying vec3 v_obj_norm;
varying float v_model_scale;

float hash31(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

vec3 hash33(vec3 p) {
	p = vec3(
		dot(p, vec3(127.1, 311.7, 74.7)),
		dot(p, vec3(269.5, 183.3, 246.1)),
		dot(p, vec3(113.5, 271.9, 124.6))
	);
	return fract(sin(p) * 43758.5453123);
}

void vertex() {
	v_obj_pos = VERTEX;
	v_obj_norm = NORMAL;
	v_model_scale = length(MODEL_MATRIX[0].xyz);
}

void fragment() {
	vec4 tex = has_albedo_tex ? texture(albedo_tex, UV) : vec4(1.0);
	vec3 paint_rgb = albedo_color.rgb * tex.rgb;

	// Fresnel pigment richness: slightly deeper metallic saturation at grazing angles
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel_curve = pow(1.0 - ndotv, 2.5);
	paint_rgb = mix(paint_rgb, paint_rgb * vec3(0.76, 0.78, 0.82), fresnel_curve * fresnel_richness);

	// Subtle ground-facing panel cavity occlusion for heavy automotive grounding
	float down_facing = clamp(dot(normalize(v_obj_norm), vec3(0.0, -1.0, 0.0)), 0.0, 1.0);
	float sill_ao = 1.0 - down_facing * ao_sill_strength;

	// Object-fixed meter-space micro metallic flakes + orange-peel undulation
	vec3 meter_pos = v_obj_pos * max(v_model_scale, 0.001);
	float rough = base_roughness;
	float metal = metallic_base;

	if (quality_detail > 0.05) {
		vec3 flake_cell = floor(meter_pos * flake_scale);
		vec3 flake_rand = hash33(flake_cell);
		float flake_sparkle = smoothstep(0.62, 0.99, flake_rand.x);

		// Subtle clearcoat micro-wave (automotive orange peel) in tangent plane
		vec3 peel_p = meter_pos * 34.0;
		float px = sin(peel_p.x * 6.283 + cos(peel_p.z * 4.1));
		float pz = cos(peel_p.z * 6.283 + sin(peel_p.x * 3.7));
		vec3 pert = (TANGENT * px + BINORMAL * pz) * (orange_peel * quality_detail);
		vec3 flake_tilt = (TANGENT * (flake_rand.y - 0.5) + BINORMAL * (flake_rand.z - 0.5)) * (0.045 * flake_intensity * quality_detail * flake_sparkle);
		NORMAL = normalize(NORMAL + pert + flake_tilt);

		paint_rgb *= mix(0.97, 1.06, flake_sparkle * flake_intensity * quality_detail);
		metal = clamp(metallic_base + flake_sparkle * 0.22 * flake_intensity * quality_detail, 0.0, 1.0);
		rough = clamp(base_roughness + (flake_rand.y - 0.5) * 0.06 * flake_intensity * quality_detail, 0.03, 0.75);
	}

	if (has_normal_tex) {
		vec3 nm = texture(normal_tex, UV).xyz * 2.0 - 1.0;
		NORMAL = normalize(NORMAL + TANGENT * (nm.x * normal_scale) + BINORMAL * (nm.y * normal_scale));
	}

	ALBEDO = paint_rgb;
	METALLIC = metal;
	ROUGHNESS = rough;
	SPECULAR = 0.85;
	CLEARCOAT = clearcoat_strength * mix(0.65, 1.0, quality_detail);
	CLEARCOAT_ROUGHNESS = mix(0.055, clearcoat_roughness, quality_detail);
	AO = sill_ao;
}
