@tool
class_name NewsBannerUI
extends Control

## NewsBannerUI: 100% Procedural native News & Updates ticker banner.

signal pressed

var _font_bold: Font
var _font_reg: Font
var _is_hovered: bool = false
var _is_pressed: bool = false

const SKEW: float = 14.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.19, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(730, 100)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Regular.ttf"):
		_font_reg = load("res://assets/ui/fonts/Rajdhani-Regular.ttf")

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
	
	# Right Slanted Glowing Neon Accent Bar
	var bar_w = 14.0
	var r_p0 = p1 - Vector2(bar_w + 3, 0)
	var r_p1 = p1
	var r_p2 = p2
	var r_p3 = p2 - Vector2(bar_w + 3, 0)
	draw_polygon(PackedVector2Array([r_p0, r_p1, r_p2, r_p3]), PackedColorArray([
		Color(1.0, 0.18, 0.08, 1.0), Color(1.0, 0.65, 0.0, 1.0),
		Color(1.0, 0.65, 0.0, 1.0), Color(1.0, 0.18, 0.08, 1.0)
	]))
	
	# 1. Header Tab: NEWS & UPDATES
	var tab_w = 175.0
	var tab_h = 32.0
	var ts = 8.0
	var tp0 = Vector2(s + 12.0 + ts, 6.0)
	var tp1 = Vector2(s + 12.0 + tab_w, 6.0)
	var tp2 = Vector2(s + 12.0 + tab_w - ts, 6.0 + tab_h)
	var tp3 = Vector2(s + 12.0, 6.0 + tab_h)
	
	draw_colored_polygon(PackedVector2Array([tp0, tp1, tp2, tp3]), Color(0.20, 0.22, 0.28, 0.95))
	draw_line(tp0, tp1, Color(1.0, 0.85, 0.3, 0.9), 1.5)
	draw_line(tp3, tp2, Color(0.1, 0.1, 0.1, 0.8), 1.0)
	
	var hdr_txt = "NEWS & UPDATES"
	if font:
		draw_string(font, Vector2(s + 26.0, 28.0), hdr_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 1))

	# 2. Headline: PATCH 1.4 LIVE: NEW TRACKS & CARS
	var text_y = 74.0
	var part1 = "PATCH 1.4 LIVE: "
	var part2 = "NEW TRACKS & CARS"
	var fs = 27
	
	if font:
		var p1_size = font.get_string_size(part1, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		# Shadow
		draw_string(font, Vector2(s + 26.0 + 1, text_y + 1.5), part1, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(s + 26.0 + p1_size.x + 1, text_y + 1.5), part2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
		# Text colors
		draw_string(font, Vector2(s + 26.0, text_y), part1, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.65, 0.08, 1.0)) # Warning Orange
		draw_string(font, Vector2(s + 26.0 + p1_size.x, text_y), part2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 1.0)) # Crisp White

