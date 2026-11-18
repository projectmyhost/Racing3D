@tool
class_name SeasonPassUI
extends Control

## SeasonPassUI: 100% Procedural native Season Pass widget with Lv. 15 unlock badge.

signal pressed

var _font_bold: Font
var _font_reg: Font
var _car_tex: Texture2D
var _is_hovered: bool = false
var _is_pressed: bool = false

const SKEW: float = 14.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.19, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_GOLD_HIGHLIGHT = Color(1.0, 0.85, 0.35, 0.9)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(380, 112)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Regular.ttf"):
		_font_reg = load("res://assets/ui/fonts/Rajdhani-Regular.ttf")
	_load_textures()

func _load_textures() -> void:
	var img = Image.load_from_file("res://assets/ui/textures/season_pass_mission_x.png")
	if img and not img.is_empty():
		_car_tex = ImageTexture.create_from_image(img)

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
	var font_reg = _font_reg if _font_reg else font
	
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
		
	# Top Gold Highlight & bottom border
	draw_line(p0, p1, COLOR_GOLD_HIGHLIGHT, 1.5)
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
	
	# 1. Left Text: SEASON PASS
	var txt_x = s + 18.0
	if font:
		draw_string(font, Vector2(txt_x, 44.0), "SEASON", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.85, 0.25, 1.0))
		draw_string(font, Vector2(txt_x, 78.0), "PASS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, 1.0))
		
	# 2. Center Car Graphic & Golden Speed Light Streaks
	var car_cx = 205.0
	var car_cy = 62.0
	# Golden speed aura
	draw_circle(Vector2(car_cx, car_cy), 36.0, Color(1.0, 0.8, 0.1, 0.18))
	for i in range(5):
		var ly = car_cy - 12.0 + i * 7.0
		draw_line(Vector2(car_cx - 45.0, ly), Vector2(car_cx + 45.0, ly), Color(1.0, 0.85, 0.2, 0.25), 1.5)
		
	if not _car_tex:
		_load_textures()
		
	if _car_tex:
		var cw = 145.0
		var ch = 87.0
		draw_texture_rect(_car_tex, Rect2(car_cx - cw * 0.5, car_cy - ch * 0.5 + 4.0, cw, ch), false)

	# 3. Right Badge: Lv. 15 UNLOCK
	var b_x = 285.0
	var b_y = 12.0
	var b_w = 68.0
	var b_h = h - 24.0
	var bs = 6.0
	var bp0 = Vector2(b_x + bs, b_y)
	var bp1 = Vector2(b_x + b_w, b_y)
	var bp2 = Vector2(b_x + b_w - bs, b_y + b_h)
	var bp3 = Vector2(b_x, b_y + b_h)
	
	draw_polygon(PackedVector2Array([bp0, bp1, bp2, bp3]), PackedColorArray([
		Color(0.85, 0.45, 0.05, 1.0), Color(0.95, 0.65, 0.10, 1.0),
		Color(0.95, 0.65, 0.10, 1.0), Color(0.85, 0.45, 0.05, 1.0)
	]))
	draw_line(bp0, bp1, Color(1.0, 1.0, 0.85, 0.9), 1.5)
	
	if font:
		# Lv. 15
		draw_string(font, Vector2(b_x + 8.0, b_y + 36.0), "Lv.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.95))
		draw_string(font, Vector2(b_x + 28.0, b_y + 40.0), "15", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1, 1, 1, 1.0))
		# UNLOCK
		draw_string(font, Vector2(b_x + 12.0, b_y + 68.0), "UNLOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.95))
