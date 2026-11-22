shader_type canvas_item;

// Precision SDF Skewed & Fading-Edge Motorsport UI Shader
// Renders razor-sharp skewed rounded panels with smooth right/left alpha fade,
// metallic glass sheen, warm champagne-gold borders, outer glow, drop shadow,
// trailing parallel diagonal speed-slashes, and optional checkered flag overlay.

uniform vec2 rect_size = vec2(460.0, 100.0);
uniform vec4 padding = vec4(16.0, 16.0, 44.0, 16.0); // left, top, right, bottom
uniform float skew_slope = 0.34;
uniform float corner_radius = 8.0;

// 4-corner fill gradient
uniform vec4 color_tl : source_color = vec4(0.11, 0.10, 0.11, 0.84);
uniform vec4 color_tr : source_color = vec4(0.08, 0.075, 0.085, 0.72);
uniform vec4 color_bl : source_color = vec4(0.06, 0.055, 0.065, 0.88);
uniform vec4 color_br : source_color = vec4(0.05, 0.048, 0.055, 0.78);

// Horizontal edge fade-out (0 = none, 1 = fade right, -1 = fade left)
uniform int fade_mode = 1;
uniform float fade_start = 0.56;
uniform float fade_end = 0.98;
uniform float fade_power = 1.25;
uniform float fade_min_alpha = 0.0;

// Metallic / Glass diagonal sheen
uniform float sheen_strength = 0.12;
uniform float sheen_pos = 0.42;
uniform float sheen_width = 0.24;
uniform float top_gloss_strength = 0.08;

// Rim border (fades smoothly along trailing edge)
uniform float border_width = 1.6;
uniform vec4 border_color_top : source_color = vec4(0.92, 0.86, 0.74, 0.65);
uniform vec4 border_color_bot : source_color = vec4(0.86, 0.71, 0.40, 0.75);
uniform float border_right_fade_start = 0.45;
uniform float border_right_fade_end = 0.92;
uniform float border_left_boost = 0.15;

// Drop shadow & outer ambient glow
uniform vec2 shadow_offset = vec2(2.0, 6.0);
uniform float shadow_blur = 14.0;
uniform float shadow_alpha = 0.48;
uniform vec4 glow_color : source_color = vec4(1.0, 0.78, 0.28, 0.0);
uniform float glow_size = 14.0;

// Trailing parallel diagonal speed slashes (0 = off, 1 = subtle dark-gold, 2 = bright gold hero)
uniform int slash_mode = 0;
uniform vec4 slash_color_1 : source_color = vec4(0.96, 0.78, 0.30, 0.85);
uniform vec4 slash_color_2 : source_color = vec4(0.92, 0.72, 0.24, 0.50);
uniform float slash_gap = 8.0;
uniform float slash_width = 4.5;

// Optional left checkered flag pattern (for bottom-left slogan strip)
uniform float checker_enabled = 0.0;
uniform float checker_cell_px = 26.0;
uniform float checker_fade_start = 0.16;
uniform float checker_fade_end = 0.36;
uniform vec4 checker_color_a : source_color = vec4(0.46, 0.46, 0.48, 0.55);
uniform vec4 checker_color_b : source_color = vec4(0.10, 0.10, 0.11, 0.60);

// Optional warm bottom accent streak (for slogan strip / promo glow)
uniform float bottom_accent_strength = 0.0;
uniform vec4 bottom_accent_color : source_color = vec4(0.95, 0.76, 0.34, 0.95);
uniform float bottom_accent_start = 0.24;
uniform float bottom_accent_end = 0.82;

// Optional radial warm glow behind promo car
uniform float promo_glow_strength = 0.0;
uniform vec2 promo_glow_uv = vec2(0.76, 0.52);
uniform vec4 promo_glow_color : source_color = vec4(0.98, 0.68, 0.28, 0.35);

// Interactive state uniforms (tweened smoothly on hover / press)
uniform float hover_t = 0.0;
uniform float press_t = 0.0;

float sd_rounded_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float compute_edge_fade(float u) {
	if (fade_mode == 1) {
		float t = 1.0 - smoothstep(fade_start, fade_end, u);
		return mix(fade_min_alpha, 1.0, pow(clamp(t, 0.0, 1.0), fade_power));
	} else if (fade_mode == -1) {
		float t = smoothstep(fade_start, fade_end, u);
		return mix(fade_min_alpha, 1.0, pow(clamp(t, 0.0, 1.0), fade_power));
	}
	return 1.0;
}

void fragment() {
	vec2 px = UV * rect_size;
	vec2 box_min = vec2(padding.x, padding.y);
	vec2 box_max = rect_size - vec2(padding.z, padding.w);
	vec2 box_size = max(box_max - box_min, vec2(4.0));
	vec2 box_center = 0.5 * (box_min + box_max);
	vec2 half_b = 0.5 * box_size;

	// Transform pixel into un-skewed local coordinates (top tilts right)
	vec2 q = px - box_center;
	vec2 q_local = vec2(q.x + q.y * skew_slope, q.y);

	float u = clamp((q_local.x + half_b.x) / box_size.x, 0.0, 1.0);
	float v = clamp((q_local.y + half_b.y) / box_size.y, 0.0, 1.0);

	float r = min(corner_radius, min(half_b.x, half_b.y));
	float d = sd_rounded_box(q_local, half_b, r);
	float aa = 1.15;

	float body_mask = 1.0 - smoothstep(-aa * 0.5, aa * 0.8, d);
	float edge_fade = compute_edge_fade(u);

	// 1. Drop shadow behind body
	vec2 q_sh = px - (box_center + shadow_offset);
	vec2 q_sh_local = vec2(q_sh.x + q_sh.y * skew_slope, q_sh.y);
	float d_sh = sd_rounded_box(q_sh_local, half_b, r);
	float u_sh = clamp((q_sh_local.x + half_b.x) / box_size.x, 0.0, 1.0);
	float sh_fade = compute_edge_fade(u_sh);
	float sh_mask = (1.0 - smoothstep(-2.0, max(shadow_blur, 1.0), d_sh)) * shadow_alpha * sh_fade;

	// 2. Outer warm ambient glow (hero PLAY / hover lift)
	float glow_boost = glow_color.a + hover_t * 0.14;
	float glow_mask = exp(-max(d, 0.0) / max(glow_size, 0.5)) * glow_boost * edge_fade;

	// Composite shadow + outer glow as base behind body
	vec4 out_col = vec4(0.0);
	out_col = vec4(vec3(0.0), sh_mask);
	if (glow_mask > 0.001) {
		vec3 g_rgb = glow_color.rgb;
		float g_a = clamp(glow_mask, 0.0, 0.85);
		out_col.rgb = mix(out_col.rgb, g_rgb, g_a);
		out_col.a = clamp(out_col.a + g_a * (1.0 - out_col.a), 0.0, 1.0);
	}

	// 3. Body fill (4-corner bilinear gradient + gloss + diagonal sheen)
	vec4 top_c = mix(color_tl, color_tr, u);
	vec4 bot_c = mix(color_bl, color_br, u);
	vec4 fill_c = mix(top_c, bot_c, v);

	// Subtle top glass specular band
	float top_gloss = (1.0 - smoothstep(0.0, 0.42, v)) * top_gloss_strength;
	fill_c.rgb += vec3(1.0, 0.98, 0.92) * top_gloss;

	// Diagonal glossy metallic reflection streak
	float diag_coord = u * 0.85 + v * 0.35;
	float sheen_dist = abs(diag_coord - (sheen_pos + hover_t * 0.06));
	float sheen = (1.0 - smoothstep(0.0, max(sheen_width, 0.01), sheen_dist));
	sheen = sheen * sheen * (sheen_strength + hover_t * 0.08);
	fill_c.rgb += vec3(1.0, 0.97, 0.86) * sheen;

	// Optional warm radial glow behind promo supercar
	if (promo_glow_strength > 0.001) {
		vec2 d_uv = (vec2(u, v) - promo_glow_uv) * vec2(1.4, 1.0);
		float p_rad = exp(-dot(d_uv, d_uv) * 7.5) * promo_glow_strength;
		fill_c.rgb += promo_glow_color.rgb * p_rad;
	}

	// Optional checkered racing flag overlay on left side
	if (checker_enabled > 0.5) {
		vec2 ch_pos = (q_local + half_b) / max(checker_cell_px, 4.0);
		float cx = floor(ch_pos.x);
		float cy = floor(ch_pos.y);
		float parity = mod(cx + cy, 2.0);
		float ch_fade = 1.0 - smoothstep(checker_fade_start, checker_fade_end, u);
		vec4 ch_col = mix(checker_color_a, checker_color_b, parity);
		fill_c.rgb = mix(fill_c.rgb, ch_col.rgb, ch_fade * ch_col.a);
		fill_c.a = max(fill_c.a, ch_fade * 0.72);
	}

	// Interactive hover/press feedback
	fill_c.rgb *= (1.0 + hover_t * 0.14 - press_t * 0.14);

	// Apply body horizontal fade
	float final_fill_a = fill_c.a * edge_fade * body_mask;

	// 4. Crisp anti-aliased metallic rim border
	float b_dist = abs(d + border_width * 0.45);
	float border_ring = (1.0 - smoothstep(border_width * 0.45, border_width * 0.45 + aa, b_dist)) * body_mask;
	vec4 b_col = mix(border_color_top, border_color_bot, v);
	// Brighter subtle specular along left edge
	float left_rim = (1.0 - smoothstep(0.0, 0.14, u)) * border_left_boost;
	b_col.rgb += vec3(0.28, 0.25, 0.18) * left_rim;
	b_col.rgb += vec3(0.18, 0.15, 0.08) * hover_t;

	// Fade border along right edge when fade_mode == 1
	float b_fade = 1.0;
	if (fade_mode == 1) {
		b_fade = 1.0 - smoothstep(border_right_fade_start, border_right_fade_end, u);
	} else if (fade_mode == -1) {
		b_fade = smoothstep(border_right_fade_start, border_right_fade_end, u);
	}
	float final_border_a = b_col.a * b_fade * border_ring;

	// Optional golden tapered bottom accent line (for slogan strip)
	if (bottom_accent_strength > 0.001) {
		float line_y = half_b.y - 16.0;
		float dy = abs(q_local.y - line_y);
		float thickness = mix(2.6, 0.5, smoothstep(bottom_accent_start, bottom_accent_end, u));
		float line_m = (1.0 - smoothstep(thickness * 0.45, thickness + 1.1, dy));
		float line_u = smoothstep(bottom_accent_start - 0.03, bottom_accent_start + 0.03, u)
			* (1.0 - smoothstep(bottom_accent_start + 0.10, bottom_accent_end, u));
		float acc_a = line_m * line_u * bottom_accent_strength;
		fill_c.rgb = mix(fill_c.rgb, bottom_accent_color.rgb, clamp(acc_a * 1.25, 0.0, 1.0));
		final_fill_a = max(final_fill_a, acc_a * bottom_accent_color.a);
	}

	// Composite body over shadow/glow
	if (final_fill_a > 0.001) {
		out_col.rgb = (fill_c.rgb * final_fill_a + out_col.rgb * out_col.a * (1.0 - final_fill_a))
			/ max(final_fill_a + out_col.a * (1.0 - final_fill_a), 0.0001);
		out_col.a = final_fill_a + out_col.a * (1.0 - final_fill_a);
	}

	// Composite crisp rim border on top of body
	if (final_border_a > 0.001) {
		out_col.rgb = (b_col.rgb * final_border_a + out_col.rgb * out_col.a * (1.0 - final_border_a))
			/ max(final_border_a + out_col.a * (1.0 - final_border_a), 0.0001);
		out_col.a = final_border_a + out_col.a * (1.0 - final_border_a);
	}

	// 5. Trailing parallel slanted double-slash speed accents (at exact same skew angle!)
	if (slash_mode > 0) {
		float sh_h = half_b.y - 2.0;
		// First slanted bar
		float s1_cx = half_b.x + slash_gap + slash_width * 0.5;
		float d_s1 = sd_rounded_box(q_local - vec2(s1_cx, 0.0), vec2(slash_width * 0.5, sh_h), min(slash_width * 0.45, 2.0));
		float m_s1 = 1.0 - smoothstep(-0.5, 0.9, d_s1);

		// Second thinner slanted bar further right
		float s2_w = max(slash_width * 0.62, 1.8);
		float s2_cx = s1_cx + slash_width + slash_gap * 0.85;
		float d_s2 = sd_rounded_box(q_local - vec2(s2_cx, 0.0), vec2(s2_w * 0.5, sh_h - 1.5), min(s2_w * 0.45, 1.5));
		float m_s2 = 1.0 - smoothstep(-0.5, 0.9, d_s2);

		// Vertical fade on subtle secondary slashes so they look delicate & sleek
		float v_env = (slash_mode == 2) ? 1.0 : (0.65 + 0.35 * sin(v * 3.14159));

		// Soft golden glow on hero slashes (slash_mode == 2)
		if (slash_mode == 2) {
			float sg = exp(-max(min(d_s1, d_s2), 0.0) / 8.0) * (0.28 + hover_t * 0.14);
			out_col.rgb = mix(out_col.rgb, slash_color_1.rgb, sg);
			out_col.a = clamp(out_col.a + sg * (1.0 - out_col.a), 0.0, 1.0);
		}

		float a1 = m_s1 * slash_color_1.a * v_env * (1.0 + hover_t * 0.25);
		float a2 = m_s2 * slash_color_2.a * v_env * (1.0 + hover_t * 0.25);

		if (a1 > 0.001) {
			a1 = clamp(a1, 0.0, 1.0);
			out_col.rgb = mix(out_col.rgb, slash_color_1.rgb, a1);
			out_col.a = a1 + out_col.a * (1.0 - a1);
		}
		if (a2 > 0.001) {
			a2 = clamp(a2, 0.0, 1.0);
			out_col.rgb = mix(out_col.rgb, slash_color_2.rgb, a2);
			out_col.a = a2 + out_col.a * (1.0 - a2);
		}
	}

	COLOR = out_col * COLOR;
}
