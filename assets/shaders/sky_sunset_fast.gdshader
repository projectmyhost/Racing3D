shader_type sky;

// Fast HDR Sunset Sky Shader: samples pre-baked 10-octave FBM cloud panorama
// while keeping the solar disc & Mie corona mathematically razor-sharp.
uniform sampler2D baked_sky_tex : source_color, filter_linear, repeat_enable;
uniform vec3 color_sun : source_color = vec3(1.0, 0.94, 0.80);
uniform vec3 color_sun_glow : source_color = vec3(1.0, 0.64, 0.24);
uniform float hdr_sky_intensity : hint_range(0.5, 4.0) = 1.45;
uniform vec3 sun_dir = vec3(0.7217, 0.3909, 0.5713);

const float INV_TAU = 0.15915494;
const float INV_PI = 0.31830989;

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 s_dir = normalize(sun_dir);

	float u = fract(atan(-dir.x, -dir.z) * INV_TAU);
	float v = acos(clamp(dir.y, -1.0, 1.0)) * INV_PI;
	vec3 col = textureLod(baked_sky_tex, vec2(u, v), 0.0).rgb;

	if (dir.y >= -0.02) {
		float sun_dot = max(dot(dir, s_dir), 0.0);
		float corona = pow(sun_dot, 36.0) * 1.85;
		float halo = pow(sun_dot, 180.0) * 3.2;
		col += color_sun_glow * corona + color_sun * halo;
		if (sun_dot > 0.9982) {
			float disc = smoothstep(0.9982, 0.9993, sun_dot);
			col = mix(col, color_sun * 8.5, disc);
		}
	}

	COLOR = col * hdr_sky_intensity;
}
