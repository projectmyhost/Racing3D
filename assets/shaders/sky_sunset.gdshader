shader_type sky;

// AAA Golden Hour Sunset Sky Shader for Forward+ HDR + Sky IBL Reflections
uniform vec3 color_zenith : source_color = vec3(0.09, 0.15, 0.34);     // Rich twilight sapphire
uniform vec3 color_mid : source_color = vec3(0.32, 0.25, 0.45);        // Soft atmospheric violet
uniform vec3 color_pink : source_color = vec3(0.84, 0.40, 0.36);       // Warm coral-rose belt
uniform vec3 color_horizon : source_color = vec3(1.0, 0.60, 0.26);     // Radiant golden-amber horizon
uniform vec3 color_sun : source_color = vec3(1.0, 0.94, 0.80);         // HDR golden-white solar disc
uniform vec3 color_sun_glow : source_color = vec3(1.0, 0.64, 0.24);    // Mie forward-scattering corona
uniform vec3 color_ground : source_color = vec3(0.09, 0.09, 0.12);     // Urban tarmac ground bounce
uniform float hdr_sky_intensity : hint_range(0.5, 4.0) = 1.45;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.48;

// Matches SunLight (+Z) direction in home_screen.tscn & RaceTrack3D.tscn (~23 deg elevation)
uniform vec3 sun_dir = vec3(0.7217, 0.3909, 0.5713);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8));
	for (int i = 0; i < 5; i++) {
		v += amp * noise2(p);
		p = rot * p * 2.05 + vec2(13.7, 9.2);
		amp *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 s_dir = normalize(sun_dir);
	float y = dir.y;
	float sun_dot = max(dot(dir, s_dir), 0.0);

	vec3 col = color_ground;

	if (y >= 0.0) {
		// 1. Multi-layer Rayleigh/Mie sunset atmospheric gradient
		if (y < 0.14) {
			float t = smoothstep(0.0, 0.14, y);
			col = mix(color_horizon, color_pink, t);
		} else if (y < 0.42) {
			float t = smoothstep(0.14, 0.42, y);
			col = mix(color_pink, color_mid, t);
		} else {
			float t = smoothstep(0.42, 0.95, y);
			col = mix(color_mid, color_zenith, t);
		}

		// Warm horizon haze band + sun-side atmospheric scattering
		float horizon_band = pow(1.0 - clamp(y, 0.0, 1.0), 5.0);
		col += color_horizon * horizon_band * 0.42;

		float mie_wide = pow(sun_dot, 4.0) * (0.45 + 0.55 * (1.0 - clamp(y, 0.0, 1.0)));
		col += color_sun_glow * mie_wide * 0.72;

		// 2. Procedural FBM Golden-Hour Altocumulus & Cirrus Clouds
		if (y > 0.015) {
			vec2 cloud_uv = dir.xz / (y + 0.16) * 0.85 + vec2(0.18, -0.12);
			float n1 = fbm(cloud_uv * 1.4);
			float n2 = fbm(cloud_uv * 3.1 + vec2(n1 * 0.7, -n1 * 0.5));
			float density = mix(n1, n2, 0.45);
			float mask = smoothstep(1.0 - cloud_coverage - 0.18, 1.0 - cloud_coverage + 0.25, density);
			float horizon_fade = smoothstep(0.015, 0.12, y) * (1.0 - smoothstep(0.75, 0.98, y));
			mask *= horizon_fade;

			// Cloud lighting: silver-gold sunward rims vs shaded twilight tops
			float sun_scatter = pow(sun_dot, 3.0);
			vec3 cloud_dark = mix(color_mid * 0.85, color_pink * 1.05, 0.45);
			vec3 cloud_lit = mix(color_pink * 1.35, color_sun * 2.1, clamp(sun_scatter * 1.15 + (1.0 - density) * 0.4, 0.0, 1.0));
			float light_factor = clamp((1.0 - n2) * 0.7 + sun_scatter * 0.65, 0.0, 1.0);
			vec3 cloud_col = mix(cloud_dark, cloud_lit, light_factor);
			col = mix(col, cloud_col, mask * 0.68);
		}

		// 3. HDR Solar Corona & Crisp Sun Disc (drives specular reflections & bloom)
		float corona = pow(sun_dot, 36.0) * 1.85;
		col += color_sun_glow * corona;

		float halo = pow(sun_dot, 180.0) * 3.2;
		col += color_sun * halo;

		if (sun_dot > 0.9982) {
			float disc = smoothstep(0.9982, 0.9993, sun_dot);
			col = mix(col, color_sun * 8.5, disc);
		}
	} else {
		// Smooth ground-horizon blend for lower hemisphere reflections
		float t = clamp(-y * 8.0, 0.0, 1.0);
		col = mix(color_horizon * 0.45, color_ground, t);
	}

	COLOR = col * hdr_sky_intensity;
}
