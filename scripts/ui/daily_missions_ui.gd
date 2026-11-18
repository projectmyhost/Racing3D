@tool
class_name DailyMissionsUI
extends Control

## DailyMissionsUI: 100% Procedural native Daily Missions card with progress bar.

signal pressed

@export var current_progress: int = 3:
	set(val):
		current_progress = val
		queue_redraw()

@export var max_progress: int = 5:
	set(val):
		max_progress = val
		queue_redraw()

var _font_bold: Font
var _is_hovered: bool = false
var _is_pressed: bool = false

const SKEW: float = 14.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.19, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(325, 94)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var was_hov = _is_hovered
		_is_hovered = Rect2(Vector2.ZERO, size).has_point(event.position)
		if _is_hovered != was_hov:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _is_hovered else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				queue_redraw()
			else:
				if _is_pressed:
					pressed.emit()
				_is_pressed = false
				queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_is_hovered = false
		_is_pressed = false
		queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var s = SKEW
	var font = _font_bold if _font_bold else get_theme_font("font")
	
	# Parallelogram points
	var p0 = Vector2(s, 0)
	var p1 = Vector2(w, 0)
	var p2 = Vector2(w - s, h)
	var p3 = Vector2(0, h)
	
	# Drop Shadow
	draw_colored_polygon(PackedVector2Array([
		p0 + Vector2(0, 4), p1 + Vector2(0, 4), p2 + Vector2(0, 4), p3 + Vector2(0, 4)
	]), Color(0, 0, 0, 0.45))
	
	# Body fill
	var col_top = COLOR_BG_TOP
	var col_bot = COLOR_BG_BOT
	if _is_hovered:
		col_top = col_top.lightened(0.1)
		col_bot = col_bot.lightened(0.1)
	if _is_pressed:
		col_top = col_top.darkened(0.15)
		col_bot = col_bot.darkened(0.15)
		
	draw_polygon(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([
		col_top, col_top, col_bot, col_bot
	]))
	
	# Carbon stripes
	for lx in range(0, int(w), 8):
		draw_line(Vector2(lx + s * 0.5, 0), Vector2(lx - s * 0.5, h), Color(1, 1, 1, 0.025), 1.0)
		
	# Top silver highlight & bottom border
	draw_line(p0, p1, COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(p3, p2, COLOR_DARK_BORDER, 1.5)
	
	# Right Slanted Glowing Neon Accent Bar (Orange-Red)
	var neon_w = 12.0
	var r_p0 = p1 - Vector2(neon_w + 2, 0)
	var r_p1 = p1
	var r_p2 = p2
	var r_p3 = p2 - Vector2(neon_w + 2, 0)
	draw_colored_polygon(PackedVector2Array([
		r_p0 - Vector2(3, 0), r_p1 + Vector2(2, 0), r_p2 + Vector2(2, 0), r_p3 - Vector2(3, 0)
	]), Color(1.0, 0.35, 0.05, 0.25))
	draw_polygon(PackedVector2Array([r_p0, r_p1, r_p2, r_p3]), PackedColorArray([
		Color(1.0, 0.18, 0.08, 1.0), Color(1.0, 0.65, 0.0, 1.0),
		Color(1.0, 0.65, 0.0, 1.0), Color(1.0, 0.18, 0.08, 1.0)
	]))
	
	# Header Text: DAILY MISSIONS (3/5)
	var header_txt = "DAILY MISSIONS (%d/%d)" % [current_progress, max_progress]
	var fs = 23
	var text_pos = Vector2(s + 20.0, 36.0)
	if font:
		draw_string(font, text_pos + Vector2(1, 1.5), header_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
		draw_string(font, text_pos, header_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 1))
		
	# Progress Bar Slot
	var bar_x = s + 18.0
	var bar_y = 50.0
	var bar_w = w - s * 2.0 - 45.0
	var bar_h = 24.0
	var bs = 4.0
	
	var bp0 = Vector2(bar_x + bs, bar_y)
	var bp1 = Vector2(bar_x + bar_w, bar_y)
	var bp2 = Vector2(bar_x + bar_w - bs, bar_y + bar_h)
	var bp3 = Vector2(bar_x, bar_y + bar_h)
	draw_colored_polygon(PackedVector2Array([bp0, bp1, bp2, bp3]), Color(0.04, 0.05, 0.06, 0.98))
	draw_line(bp0, bp1, Color(0.2, 0.22, 0.26, 0.9), 1.0)
	draw_line(bp3, bp2, Color(0.02, 0.02, 0.03, 0.9), 1.0)
	
	# Fill Bar
	var pct = clamp(float(current_progress) / float(max(max_progress, 1)), 0.0, 1.0)
	var fill_w = bar_w * pct
	if fill_w > 4.0:
		var fp0 = bp0
		var fp1 = Vector2(bar_x + fill_w, bar_y)
		var fp2 = Vector2(bar_x + fill_w - bs, bar_y + bar_h)
		var fp3 = bp3
		draw_polygon(PackedVector2Array([fp0, fp1, fp2, fp3]), PackedColorArray([
			Color(1.0, 0.85, 0.15, 1.0), Color(1.0, 0.55, 0.0, 1.0),
			Color(1.0, 0.55, 0.0, 1.0), Color(1.0, 0.85, 0.15, 1.0)
		]))
		draw_line(fp0, fp1, Color(1.0, 1.0, 0.85, 0.9), 1.0)
