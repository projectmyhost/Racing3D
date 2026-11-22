@tool
extends SceneTree

## Pre-bakes the static atmospheric gradient + 5-octave FBM cloud deck from sky_sunset.gdshader
## into a 1024x512 HDR EXR texture so runtime sky rendering avoids 10-octave per-pixel noise.

const OUT_PATH := "res://assets/textures/environments/sky_sunset_clouds.exr"

const COLOR_ZENITH := Color(0.09, 0.15, 0.34)
const COLOR_MID := Color(0.32, 0.25, 0.45)
const COLOR_PINK := Color(0.84, 0.40, 0.36)
const COLOR_HORIZON := Color(1.0, 0.60, 0.26)
const COLOR_SUN := Color(1.0, 0.94, 0.80)
const COLOR_SUN_GLOW := Color(1.0, 0.64, 0.24)
const COLOR_GROUND := Color(0.09, 0.09, 0.12)
const CLOUD_COV := 0.48
const SUN_DIR_RAW := Vector3(0.7217, 0.3909, 0.5713)
var _sun_dir: Vector3 = SUN_DIR_RAW.normalized()

func _fract_f(x: float) -> float:
	return x - floorf(x)

func _hash21(px: float, py: float) -> float:
	var hx := _fract_f(px * 123.34)
	var hy := _fract_f(py * 456.21)
	var d := hx * (hx + 45.32) + hy * (hy + 45.32)
	hx += d
	hy += d
	return _fract_f(hx * hy)

func _noise2(p: Vector2) -> float:
	var ix := floorf(p.x)
	var iy := floorf(p.y)
	var fx := p.x - ix
	var fy := p.y - iy
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	var a := _hash21(ix, iy)
	var b := _hash21(ix + 1.0, iy)
	var c := _hash21(ix, iy + 1.0)
	var d := _hash21(ix + 1.0, iy + 1.0)
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy)

func _fbm(p: Vector2) -> float:
	var v := 0.0
	var amp := 0.5
	var cur := p
	for i in range(5):
		v += amp * _noise2(cur)
		# GLSL mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * p -> col0=(0.8,-0.6), col1=(0.6,0.8)
		var rx := 0.8 * cur.x + 0.6 * cur.y
		var ry := -0.6 * cur.x + 0.8 * cur.y
		cur = Vector2(rx * 2.05 + 13.7, ry * 2.05 + 9.2)
		amp *= 0.5
	return v

func _eval_col(dir: Vector3) -> Color:
	var y := dir.y
	var sun_dot := maxf(dir.dot(_sun_dir), 0.0)
	var col := COLOR_GROUND
	if y >= 0.0:
		if y < 0.14:
			col = COLOR_HORIZON.lerp(COLOR_PINK, smoothstep(0.0, 0.14, y))
		elif y < 0.42:
			col = COLOR_PINK.lerp(COLOR_MID, smoothstep(0.14, 0.42, y))
		else:
			col = COLOR_MID.lerp(COLOR_ZENITH, smoothstep(0.42, 0.95, y))

		var horizon_band := pow(1.0 - clampf(y, 0.0, 1.0), 5.0)
		col += COLOR_HORIZON * horizon_band * 0.42

		var mie_wide := pow(sun_dot, 4.0) * (0.45 + 0.55 * (1.0 - clampf(y, 0.0, 1.0)))
		col += COLOR_SUN_GLOW * mie_wide * 0.72

		if y > 0.015:
			var cloud_uv := Vector2(dir.x, dir.z) / (y + 0.16) * 0.85 + Vector2(0.18, -0.12)
			var n1 := _fbm(cloud_uv * 1.4)
			var n2 := _fbm(cloud_uv * 3.1 + Vector2(n1 * 0.7, -n1 * 0.5))
			var density := lerpf(n1, n2, 0.45)
			var mask := smoothstep(1.0 - CLOUD_COV - 0.18, 1.0 - CLOUD_COV + 0.25, density)
			var horizon_fade := smoothstep(0.015, 0.12, y) * (1.0 - smoothstep(0.75, 0.98, y))
			mask *= horizon_fade

			var sun_scatter := pow(sun_dot, 3.0)
			var cloud_dark := (COLOR_MID * 0.85).lerp(COLOR_PINK * 1.05, 0.45)
			var cloud_lit := (COLOR_PINK * 1.35).lerp(COLOR_SUN * 2.1, clampf(sun_scatter * 1.15 + (1.0 - density) * 0.4, 0.0, 1.0))
			var light_factor := clampf((1.0 - n2) * 0.7 + sun_scatter * 0.65, 0.0, 1.0)
			var cloud_col := cloud_dark.lerp(cloud_lit, light_factor)
			col = col.lerp(cloud_col, mask * 0.68)
	else:
		var t := clampf(-y * 8.0, 0.0, 1.0)
		col = (COLOR_HORIZON * 0.45).lerp(COLOR_GROUND, t)
	return col

func _init() -> void:
	var w := 1024
	var h := 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBAF)
	for py in range(h):
		var v := (float(py) + 0.5) / float(h)
		var theta := v * PI
		var sin_t := sin(theta)
		var cos_t := cos(theta)
		for px in range(w):
			var u := (float(px) + 0.5) / float(w)
			var phi := u * TAU
			var dir := Vector3(-sin_t * sin(phi), cos_t, -sin_t * cos(phi)).normalized()
			var c := _eval_col(dir)
			img.set_pixel(px, py, Color(c.r, c.g, c.b, 1.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/textures/environments"))
	var err := img.save_exr(OUT_PATH, false)
	print("Baked sky EXR -> ", OUT_PATH, " err=", err)
	quit(0 if err == OK else 1)
