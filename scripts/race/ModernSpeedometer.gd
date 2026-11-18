class_name ModernSpeedometer
extends Control

# High-fidelity racing speedometer and tachometer gauge.
# Matches official photo reference 100%:
# - Metallic outer dial bezel with dark carbon face
# - 0-10 RPM tachometer arc (0-5 white, 6-10 bright redline)
# - Sweeping glowing red needle driven by vehicle engine RPM
# - Central gear indicator with drive mode [ D ] / [ R ] / [ N ]
# - Large bold digital speed read-out (KM/H)
# - Curved vertical cyan Nitro/Boost fluid gauge with N2O label

@export var max_display_speed: float = 380.0
@export var max_display_rpm: float = 10000.0

var current_speed_kmh: float = 0.0
var current_rpm: float = 850.0
var max_engine_rpm: float = 10000.0
var current_gear: int = 1
var is_reverse: bool = false
var nitro_level: float = 0.85 # 0.0 to 1.0

var _displayed_speed: float = 0.0
var _displayed_rpm: float = 850.0
var _needle_angle: float = deg_to_rad(135.0)

var _font_bold: Font
var _font_regular: Font
var _mode_sb: StyleBoxFlat
var _nitro_bg_sb: StyleBoxFlat
var _nitro_fill_sb: StyleBoxFlat

const ANGLE_MIN: float = 2.35619 # 135 deg (7 o'clock)
const ANGLE_MAX: float = 7.06858 # 405 deg (4 o'clock, 270 deg sweep)

func _ready() -> void:
	custom_minimum_size = Vector2(280, 220)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_fonts()
	_setup_styleboxes()

func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-SemiBold.ttf"):
		_font_regular = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")

func _setup_styleboxes() -> void:
	_mode_sb = StyleBoxFlat.new()
	_mode_sb.bg_color = Color(0.12, 0.16, 0.22, 0.8)
	_mode_sb.corner_radius_top_left = 3
	_mode_sb.corner_radius_top_right = 3
	_mode_sb.corner_radius_bottom_right = 3
	_mode_sb.corner_radius_bottom_left = 3
	
	_nitro_bg_sb = StyleBoxFlat.new()
	_nitro_bg_sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	_nitro_bg_sb.border_width_left = 1
	_nitro_bg_sb.border_width_top = 1
	_nitro_bg_sb.border_width_right = 1
	_nitro_bg_sb.border_width_bottom = 1
	_nitro_bg_sb.border_color = Color(0.25, 0.35, 0.50, 0.8)
	_nitro_bg_sb.corner_radius_top_left = 6
	_nitro_bg_sb.corner_radius_top_right = 6
	_nitro_bg_sb.corner_radius_bottom_right = 6
	_nitro_bg_sb.corner_radius_bottom_left = 6
	
	_nitro_fill_sb = StyleBoxFlat.new()
	_nitro_fill_sb.bg_color = Color(0.15, 0.65, 1.0, 0.95)
	_nitro_fill_sb.corner_radius_top_left = 4
	_nitro_fill_sb.corner_radius_top_right = 4
	_nitro_fill_sb.corner_radius_bottom_right = 4
	_nitro_fill_sb.corner_radius_bottom_left = 4

func update_car_data(speed_kmh: float, rpm: float, p_max_rpm: float, gear: int, reverse: bool, nitro: float = 0.85) -> void:
	current_speed_kmh = maxf(speed_kmh, 0.0)
	current_rpm = maxf(rpm, 0.0)
	if p_max_rpm > 1000.0:
		max_engine_rpm = p_max_rpm
	current_gear = gear
	is_reverse = reverse
	nitro_level = clampf(nitro, 0.0, 1.0)

func _process(delta: float) -> void:
	# Frame-rate independent exponential smoothing for 30/60/120 FPS consistency
	var safe_delta = clampf(delta, 0.0001, 0.05)
	_displayed_speed = lerpf(_displayed_speed, current_speed_kmh, 1.0 - exp(-14.0 * safe_delta))
	_displayed_rpm = lerpf(_displayed_rpm, current_rpm, 1.0 - exp(-16.0 * safe_delta))
	
	var rpm_ratio = clampf(_displayed_rpm / maxf(max_engine_rpm, 1000.0), 0.0, 1.0)
	var target_angle = lerpf(ANGLE_MIN, ANGLE_MAX, rpm_ratio)
	_needle_angle = lerpf(_needle_angle, target_angle, 1.0 - exp(-18.0 * safe_delta))
	queue_redraw()

func _draw() -> void:
	var center = Vector2(size.x - 110.0, size.y - 105.0)
	var radius = 95.0
	
	# 1. Outer Metallic Bezel Ring
	draw_circle(center, radius + 8.0, Color(0.12, 0.15, 0.20, 0.95))
	draw_arc(center, radius + 7.0, 0.0, TAU, 64, Color(0.35, 0.45, 0.55, 0.9), 2.5, true)
	draw_arc(center, radius + 4.0, 0.0, TAU, 64, Color(0.18, 0.22, 0.28, 1.0), 4.0, true)
	
	# 2. Dial Face Inner Gradient
	draw_circle(center, radius + 2.0, Color(0.05, 0.07, 0.10, 0.92))
	draw_circle(center, radius - 4.0, Color(0.08, 0.10, 0.14, 0.96))
	
	# 3. Outer RPM Arc Track
	draw_arc(center, radius - 8.0, ANGLE_MIN, ANGLE_MAX, 64, Color(0.22, 0.26, 0.32, 0.8), 2.5, true)
	# Redline arc (from tick 6 to 10)
	var redline_start = lerpf(ANGLE_MIN, ANGLE_MAX, 0.6)
	draw_arc(center, radius - 8.0, redline_start, ANGLE_MAX, 32, Color(0.95, 0.20, 0.15, 0.95), 3.5, true)
	
	# 4. RPM Tick Marks and Numbers (0 to 10)
	for i in range(11):
		var frac = float(i) / 10.0
		var ang = lerpf(ANGLE_MIN, ANGLE_MAX, frac)
		var dir = Vector2(cos(ang), sin(ang))
		
		var is_red = (i >= 6)
		var tick_col = Color(0.95, 0.22, 0.18, 1.0) if is_red else Color(0.92, 0.94, 0.96, 0.95)
		
		# Major tick
		var t_outer = center + dir * (radius - 8.0)
		var t_inner = center + dir * (radius - 17.0)
		draw_line(t_inner, t_outer, tick_col, 2.0, true)
		
		# Number label (0 to 10)
		var num_pos = center + dir * (radius - 28.0) + Vector2(-4.0, 5.0)
		if _font_bold:
			draw_string(_font_bold, num_pos, str(i), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, tick_col)
			
		# Minor intermediate ticks (between major ticks)
		if i < 10:
			for sub in range(1, 4):
				var sub_frac = frac + (float(sub) / 40.0)
				var sub_ang = lerpf(ANGLE_MIN, ANGLE_MAX, sub_frac)
				var sub_dir = Vector2(cos(sub_ang), sin(sub_ang))
				var s_outer = center + sub_dir * (radius - 8.0)
				var s_inner = center + sub_dir * (radius - 13.0)
				var s_col = Color(0.95, 0.22, 0.18, 0.6) if sub_frac >= 0.6 else Color(0.5, 0.55, 0.62, 0.6)
				draw_line(s_inner, s_outer, s_col, 1.2, true)
				
	# 5. Glowing Red RPM Needle
	var needle_dir = Vector2(cos(_needle_angle), sin(_needle_angle))
	var needle_len = radius - 12.0
	var needle_tip = center + needle_dir * needle_len
	var needle_perp = Vector2(-needle_dir.y, needle_dir.x)
	var needle_base_l = center + needle_perp * 3.5 - needle_dir * 8.0
	var needle_base_r = center - needle_perp * 3.5 - needle_dir * 8.0
	
	# Needle glow shadow
	draw_line(center, needle_tip, Color(1.0, 0.2, 0.1, 0.35), 6.0, true)
	# Needle solid polygon
	var needle_pts = PackedVector2Array([needle_base_l, needle_tip, needle_base_r])
	draw_colored_polygon(needle_pts, Color(0.98, 0.22, 0.15, 1.0))
	draw_polyline(needle_pts, Color(1.0, 0.6, 0.4, 0.9), 1.0, true)
	
	# 6. Center Gear Pod
	draw_circle(center, 28.0, Color(0.04, 0.05, 0.08, 0.98))
	draw_arc(center, 28.0, 0.0, TAU, 32, Color(0.25, 0.35, 0.50, 0.85), 2.0, true)
	draw_circle(center, 24.0, Color(0.08, 0.10, 0.14, 0.95))
	
	# Gear Number / Mode
	var gear_str = "R" if is_reverse else str(current_gear)
	if current_speed_kmh < 1.0 and current_gear == 1 and not is_reverse:
		gear_str = "1"
	if _font_bold:
		# Large Yellow Gear
		var g_col = Color(0.98, 0.82, 0.15, 1.0)
		draw_string(_font_bold, center + Vector2(-15.0, 8.0), gear_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 26, g_col)
		# Drive Mode Badge [ D ] or [ R ]
		var mode_str = "R" if is_reverse else "D"
		var mode_col = Color(0.95, 0.25, 0.2) if is_reverse else Color(0.85, 0.92, 1.0, 0.9)
		if _mode_sb:
			draw_style_box(_mode_sb, Rect2(center.x + 3.0, center.y - 10.0, 16.0, 18.0))
		draw_string(_font_bold, center + Vector2(7.0, 5.0), mode_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, mode_col)

	# 7. Digital Speed Readout (Below center pod)
	var speed_val_str = str(int(round(_displayed_speed)))
	if _font_bold:
		# Huge bold italic white speed text
		draw_string(_font_bold, center + Vector2(-45.0, 50.0), speed_val_str, HORIZONTAL_ALIGNMENT_CENTER, 90, 42, Color(0.98, 0.98, 1.0, 1.0))
		# Unit KM/H text
		draw_string(_font_bold, center + Vector2(-30.0, 68.0), "KM/H", HORIZONTAL_ALIGNMENT_CENTER, 60, 14, Color(0.75, 0.82, 0.90, 0.9))

	# 8. Curved Nitro / N2O Gauge (Left side of dial)
	_draw_nitro_bar(center, radius)

func _draw_nitro_bar(center: Vector2, radius: float) -> void:
	var n_cx = center.x - radius - 16.0
	var n_top = center.y - 50.0
	var n_h = 75.0
	var n_w = 14.0
	
	# Background track (pill shaped)
	var bg_rect = Rect2(n_cx, n_top, n_w, n_h)
	if _nitro_bg_sb:
		draw_style_box(_nitro_bg_sb, bg_rect)
	
	# Fluid Level (Cyan glowing fill)
	var fill_h = n_h * nitro_level
	if fill_h > 2.0:
		var fill_rect = Rect2(n_cx + 2.0, n_top + n_h - fill_h + 2.0, n_w - 4.0, fill_h - 4.0)
		if _nitro_fill_sb:
			draw_style_box(_nitro_fill_sb, fill_rect)
		# Glowing top highlight
		draw_line(
			Vector2(n_cx + 2.0, n_top + n_h - fill_h + 2.0),
			Vector2(n_cx + n_w - 2.0, n_top + n_h - fill_h + 2.0),
			Color(0.7, 0.95, 1.0, 0.9),
			2.0,
			true
		)
		
	# N2O Bottle Icon & Text at bottom
	var icon_center = Vector2(n_cx + n_w * 0.5, n_top + n_h + 16.0)
	# Little bottle capsule
	draw_rect(Rect2(icon_center.x - 4.0, icon_center.y - 6.0, 8.0, 11.0), Color(0.2, 0.6, 1.0, 0.95))
	draw_rect(Rect2(icon_center.x - 2.0, icon_center.y - 9.0, 4.0, 3.0), Color(0.7, 0.85, 1.0, 0.95))
	if _font_bold:
		draw_string(_font_bold, Vector2(icon_center.x + 8.0, icon_center.y + 4.0), "N2O", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.9, 1.0, 0.9))
