@tool
class_name SkewedNavButton
extends Control

## High-fidelity skewed parallelogram navigation button matching reference 1:1.

signal pressed

@export var is_play_button: bool = false:
	set(val):
		is_play_button = val
		queue_redraw()

@export var button_text: String = "NAV BUTTON":
	set(val):
		button_text = val
		queue_redraw()

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		queue_redraw()

@export var skew_px: float = 18.0:
	set(val):
		skew_px = val
		queue_redraw()

@export var has_new_badge: bool = false:
	set(val):
		has_new_badge = val
		queue_redraw()

@export var is_paint_shop: bool = false:
	set(val):
		is_paint_shop = val
		queue_redraw()

var _is_hovered: bool = false
var _is_focused: bool = false
var _is_pressed: bool = false
var _shift_x: float = 0.0
var _tween: Tween

const COLOR_PLAY_LEFT = Color(1.0, 0.82, 0.12, 1.0)    # #ffd11f
const COLOR_PLAY_RIGHT = Color(1.0, 0.52, 0.0, 1.0)    # #ff8400
const COLOR_PLAY_HOVER_L = Color(1.0, 0.88, 0.25, 1.0)
const COLOR_PLAY_HOVER_R = Color(1.0, 0.60, 0.1, 1.0)

const COLOR_PANEL_TOP = Color(0.12, 0.14, 0.19, 0.96)
const COLOR_PANEL_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_PANEL_HOVER_TOP = Color(0.18, 0.20, 0.26, 0.98)
const COLOR_PANEL_HOVER_BOT = Color(0.09, 0.11, 0.14, 0.98)

const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.75)
const COLOR_DARK_BORDER = Color(0.04, 0.05, 0.07, 0.90)

const COLOR_TEXT_WHITE = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_TEXT_DARK = Color(0.08, 0.08, 0.08, 1.0)

var _font_bold: Font

func _ready() -> void:
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			queue_redraw()
		else:
			if _is_pressed:
				_is_pressed = false
				queue_redraw()
				pressed.emit()
				accept_event()
	elif event.is_action_pressed("ui_accept"):
		pressed.emit()
		accept_event()

func _on_mouse_entered() -> void:
	_is_hovered = true
	_animate_shift(8.0 if not is_play_button else 6.0)
	queue_redraw()

func _on_mouse_exited() -> void:
	_is_hovered = false
	if not _is_focused:
		_animate_shift(0.0)
	queue_redraw()

func _on_focus_entered() -> void:
	_is_focused = true
	_animate_shift(8.0 if not is_play_button else 6.0)
	queue_redraw()

func _on_focus_exited() -> void:
	_is_focused = false
	if not _is_hovered:
		_animate_shift(0.0)
	queue_redraw()

func _animate_shift(target_x: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_shift_x", target_x, 0.12)
	_tween.parallel().tween_method(func(_val): queue_redraw(), 0.0, 1.0, 0.12)

func _draw() -> void:
	var w = size.x
	var h = size.y
	var sx = _shift_x
	var s = skew_px
	var font = _font_bold if _font_bold else get_theme_font("font")
	
	# Parallelogram points
	var p0 = Vector2(s + sx, 0)
	var p1 = Vector2(w + sx, 0)
	var p2 = Vector2(w - s + sx, h)
	var p3 = Vector2(sx, h)
	
	if is_play_button:
		# Main Yellow Body with gradient
		var col_l = COLOR_PLAY_HOVER_L if (_is_hovered or _is_focused) else COLOR_PLAY_LEFT
		var col_r = COLOR_PLAY_HOVER_R if (_is_hovered or _is_focused) else COLOR_PLAY_RIGHT
		if _is_pressed:
			col_l = col_l.darkened(0.15)
			col_r = col_r.darkened(0.15)
			
		# Drop Shadow
		var shadow_points = PackedVector2Array([
			p0 + Vector2(0, 5), p1 + Vector2(0, 5), p2 + Vector2(0, 5), p3 + Vector2(0, 5)
		])
		draw_colored_polygon(shadow_points, Color(0, 0, 0, 0.45))
		
		# Main Body with Gradient
		var main_points = PackedVector2Array([p0, p1, p2, p3])
		var main_colors = PackedColorArray([col_l, col_r, col_r, col_l])
		draw_polygon(main_points, main_colors)
		
		# Checkered Flag Pattern on the right slant
		var checker_start_x = w - 160.0 + sx
		var cols = 7
		var rows = 4
		var sq_w = 18.0
		var sq_h = h / float(rows)
		for r in range(rows):
			for c in range(cols):
				var is_dark = ((r + c) % 2 == 0)
				if is_dark:
					var progress = float(c) / float(cols) # 0 to 1
					var alpha = lerp(0.15, 0.85, progress)
					var slant_offset = s * (1.0 - (float(r) + 0.5) / float(rows))
					var cx0 = checker_start_x + c * sq_w + slant_offset
					var cy0 = r * sq_h
					var cp0 = Vector2(cx0 + s * (sq_h / h), cy0)
					var cp1 = Vector2(cx0 + sq_w + s * (sq_h / h), cy0)
					var cp2 = Vector2(cx0 + sq_w, cy0 + sq_h)
					var cp3 = Vector2(cx0, cy0 + sq_h)
					# clip right edge
					var max_right = w + sx - s * (float(r) / float(rows))
					if cp0.x < max_right:
						draw_colored_polygon(PackedVector2Array([cp0, cp1, cp2, cp3]), Color(0.08, 0.08, 0.08, alpha))
		
		# Trailing yellow accent slash
		var slash_w = 22.0
		var slash_gap = 12.0 + (4.0 if (_is_hovered or _is_focused) else 0.0)
		var sp0 = Vector2(w + slash_gap + s + sx, 0)
		var sp1 = Vector2(w + slash_gap + slash_w + s + sx, 0)
		var sp2 = Vector2(w + slash_gap + slash_w - s + sx, h)
		var sp3 = Vector2(w + slash_gap - s + sx, h)
		draw_colored_polygon(PackedVector2Array([sp0, sp1, sp2, sp3]), col_r)
		
		# Top highlight line
		draw_line(p0, p1, Color(1.0, 1.0, 0.8, 0.85), 2.0)
		# Sparkle/Glint on top right
		var spark_pos = p1 - Vector2(10, 0)
		draw_circle(spark_pos, 4.0, Color(1, 1, 1, 0.9))
		draw_line(spark_pos - Vector2(10, 0), spark_pos + Vector2(10, 0), Color(1, 1, 1, 0.7), 1.5)
		draw_line(spark_pos - Vector2(0, 10), spark_pos + Vector2(0, 10), Color(1, 1, 1, 0.7), 1.5)
		
		# Flag Icon
		if icon_texture:
			var icon_size = 54.0
			var icon_rect = Rect2(s + sx + 20.0, (h - icon_size) * 0.5, icon_size, icon_size)
			draw_texture_rect(icon_texture, icon_rect, false, COLOR_TEXT_DARK)
			
		# Text: "PLAY" Heavy Italic
		var font_size = 46
		var text_pos = Vector2(s + sx + 104.0, h * 0.5 + 16.0)
		if font:
			draw_string(font, text_pos, button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_TEXT_DARK)
			
	else:
		# Standard Dark Nav Button
		var col_top = COLOR_PANEL_HOVER_TOP if (_is_hovered or _is_focused) else COLOR_PANEL_TOP
		var col_bot = COLOR_PANEL_HOVER_BOT if (_is_hovered or _is_focused) else COLOR_PANEL_BOT
		if _is_pressed:
			col_top = col_top.darkened(0.2)
			col_bot = col_bot.darkened(0.2)
			
		# Shadow
		var shadow_points = PackedVector2Array([
			p0 + Vector2(0, 4), p1 + Vector2(0, 4), p2 + Vector2(0, 4), p3 + Vector2(0, 4)
		])
		draw_colored_polygon(shadow_points, Color(0, 0, 0, 0.40))
		
		# Main Bar with Gradient
		var main_points = PackedVector2Array([p0, p1, p2, p3])
		var main_colors = PackedColorArray([col_top, col_top, col_bot, col_bot])
		draw_polygon(main_points, main_colors)
		
		# Subtle Carbon diagonal lines
		var step = 8.0
		for lx in range(int(sx), int(w + sx), int(step)):
			var lp0 = Vector2(lx, 0)
			var lp1 = Vector2(lx - 20, h)
			# clamp inside
			draw_line(lp0, lp1, Color(1, 1, 1, 0.025), 1.0)
			
		# Top Silver Edge Highlight
		draw_line(p0, p1, COLOR_SILVER_HIGHLIGHT, 1.5)
		# Bottom Dark Border Line
		draw_line(p3, p2, COLOR_DARK_BORDER, 1.5)
		
		# Left Icon Container Divider
		var div_x = s + sx + 70.0
		var div_top = Vector2(div_x, 1)
		var div_bot = Vector2(div_x - s, h - 1)
		draw_line(div_top, div_bot, Color(1, 1, 1, 0.08), 1.0)
		
		# Right Slanted Glowing Accent Bar (Orange-Red Neon)
		var bar_w = 14.0
		var r_p0 = p1 - Vector2(bar_w + 3, 0)
		var r_p1 = p1
		var r_p2 = p2
		var r_p3 = p2 - Vector2(bar_w + 3, 0)
		# Outer soft glow
		var glow_p0 = r_p0 - Vector2(4, 0)
		var glow_p1 = r_p1 + Vector2(2, 0)
		var glow_p2 = r_p2 + Vector2(2, 0)
		var glow_p3 = r_p3 - Vector2(4, 0)
		draw_colored_polygon(PackedVector2Array([glow_p0, glow_p1, glow_p2, glow_p3]), Color(1.0, 0.35, 0.05, 0.25))
		# Inner gradient bar: red on left, orange on right
		var col_neon_l = Color(1.0, 0.18, 0.08, 1.0)
		var col_neon_r = Color(1.0, 0.65, 0.0, 1.0)
		draw_polygon(PackedVector2Array([r_p0, r_p1, r_p2, r_p3]), PackedColorArray([col_neon_l, col_neon_r, col_neon_r, col_neon_l]))
		
		# Top-right corner star sparkle on SETTINGS and GARAGE
		if button_text == "SETTINGS" or button_text == "GARAGE":
			var spark_p = p1 - Vector2(7, -1)
			draw_circle(spark_p, 3.5, Color(1.0, 0.85, 0.4, 0.95))
			draw_line(spark_p - Vector2(8, 0), spark_p + Vector2(8, 0), Color(1.0, 0.9, 0.6, 0.8), 1.5)
			draw_line(spark_p - Vector2(0, 8), spark_p + Vector2(0, 8), Color(1.0, 0.9, 0.6, 0.8), 1.5)

		# Left yellow accent stripe on hover/focus
		if _is_hovered or _is_focused:
			var stripe_w = 5.0
			var st0 = p0
			var st1 = p0 + Vector2(stripe_w, 0)
			var st2 = p3 + Vector2(stripe_w, 0)
			var st3 = p3
			draw_colored_polygon(PackedVector2Array([st0, st1, st2, st3]), Color(1.0, 0.8, 0.15, 1.0))
			
		# Icon
		if icon_texture:
			var icon_size = 38.0
			var icon_rect = Rect2(s + sx + 17.0, (h - icon_size) * 0.5, icon_size, icon_size)
			draw_texture_rect(icon_texture, icon_rect, false, COLOR_TEXT_WHITE)
			
		# Paint Shop Cyan Spray Effect
		if is_paint_shop:
			var spray_origin = Vector2(s + sx + 15.0, (h) * 0.5 - 6.0)
			var sp_col_center = Color(0.0, 0.95, 1.0, 0.75)
			draw_circle(spray_origin, 14.0, Color(0.0, 0.9, 1.0, 0.25))
			draw_line(spray_origin, spray_origin + Vector2(-12, -8), sp_col_center, 2.5)
			draw_line(spray_origin, spray_origin + Vector2(-16, 0), sp_col_center, 2.0)
			draw_line(spray_origin, spray_origin + Vector2(-12, 8), sp_col_center, 2.5)
			
			# Lens flare star at bottom
			var flare_pos = Vector2(w * 0.50 + sx, h - 2.0)
			draw_circle(flare_pos, 3.5, Color(1, 0.7, 0.2, 0.95))
			draw_line(flare_pos - Vector2(8, 0), flare_pos + Vector2(8, 0), Color(1, 0.75, 0.3, 0.85), 1.5)
			draw_line(flare_pos - Vector2(0, 8), flare_pos + Vector2(0, 8), Color(1, 0.75, 0.3, 0.85), 1.5)

		# Text: Bold Uppercase Italic
		var font_size = 32
		var text_pos = Vector2(s + sx + 84.0, h * 0.5 + 11.0)
		if font:
			# Text shadow
			draw_string(font, text_pos + Vector2(1, 2), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.8))
			draw_string(font, text_pos, button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_TEXT_WHITE)
			
		# NEW! Badge (slanted red badge)
		if has_new_badge:
			var badge_w = 68.0
			var badge_h = 24.0
			var badge_skew = 8.0
			var bx = w + sx - 98.0
			var by = (h - badge_h) * 0.5
			var b0 = Vector2(bx + badge_skew, by)
			var b1 = Vector2(bx + badge_w + badge_skew, by)
			var b2 = Vector2(bx + badge_w, by + badge_h)
			var b3 = Vector2(bx, by + badge_h)
			# Red fill
			draw_colored_polygon(PackedVector2Array([b0, b1, b2, b3]), Color(0.85, 0.10, 0.10, 1.0))
			draw_line(b0, b1, Color(1.0, 0.45, 0.45, 0.9), 1.0)
			draw_line(b3, b2, Color(0.5, 0.05, 0.05, 0.9), 1.0)
			if font:
				var b_text_pos = Vector2(bx + 14.0, by + badge_h - 5.0)
				draw_string(font, b_text_pos, "NEW!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 1))
