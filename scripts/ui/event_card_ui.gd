@tool
class_name EventCardUI
extends Control

## EventCardUI: 100% Procedural native Limited Time Event widget.
## Displays Night Speedrun banner, countdown timer, and interactive JOIN button.

signal join_pressed

var _font_bold: Font
var _font_reg: Font
var _car_tex: Texture2D
var _join_hovered: bool = false
var _join_pressed: bool = false

const COLOR_BG_TOP = Color(0.12, 0.13, 0.16, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(358, 312)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Regular.ttf"):
		_font_reg = load("res://assets/ui/fonts/Rajdhani-Regular.ttf")
	_load_textures()

func _load_textures() -> void:
	var c_img = Image.load_from_file("res://assets/models/cars/previews/lamb.png")
	if not c_img or c_img.is_empty():
		c_img = Image.load_from_file("res://assets/models/cars/previews/fenyr.png")
	if c_img and not c_img.is_empty():
		c_img.flip_x()
		_car_tex = ImageTexture.create_from_image(c_img)

func _gui_input(event: InputEvent) -> void:
	var join_rect = Rect2(12, size.y - 64, size.x - 24, 52)
	if event is InputEventMouseMotion:
		var was_jh = _join_hovered
		_join_hovered = join_rect.has_point(event.position)
		if _join_hovered != was_jh:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _join_hovered else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if join_rect.has_point(event.position):
					_join_pressed = true
					queue_redraw()
			else:
				if _join_pressed and join_rect.has_point(event.position):
					join_pressed.emit()
				_join_pressed = false
				queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_join_hovered = false
		_join_pressed = false
		queue_redraw()

func _draw() -> void:
	if not _car_tex:
		_load_textures()

	var w = size.x
	var h = size.y
	var font = _font_bold if _font_bold else get_theme_font("font")
	var font_reg = _font_reg if _font_reg else font
	
	# 1. Main Outer Box
	var r = Rect2(Vector2.ZERO, size)
	# Drop Shadow
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 4), Vector2(w, 4), Vector2(w, h + 4), Vector2(0, h + 4)
	]), Color(0, 0, 0, 0.45))
	
	# Card Body
	draw_rect(r, COLOR_BG_BOT)
	# Top Silver Highlight & Borders
	draw_line(Vector2(0, 0), Vector2(w, 0), COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(Vector2(w, 0), Vector2(w, h), COLOR_DARK_BORDER, 1.0)
	draw_line(Vector2(0, h), Vector2(w, h), COLOR_DARK_BORDER, 1.5)
	draw_line(Vector2(0, 0), Vector2(0, h), COLOR_DARK_BORDER, 1.0)
	
	# 2. Header Bar: LIMITED TIME EVENT
	var hdr_h = 32.0
	draw_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(w, 0), Vector2(w, hdr_h), Vector2(0, hdr_h)
	]), PackedColorArray([
		Color(0.85, 0.70, 0.18, 1.0), Color(0.55, 0.40, 0.08, 1.0),
		Color(0.40, 0.28, 0.04, 1.0), Color(0.65, 0.50, 0.12, 1.0)
	]))
	draw_line(Vector2(0, hdr_h), Vector2(w, hdr_h), Color(1.0, 0.85, 0.3, 0.8), 1.0)
	
	var hdr_txt = "LIMITED TIME EVENT"
	if font:
		var ht_size = font.get_string_size(hdr_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		var ht_pos = Vector2((w - ht_size.x) * 0.5, 21.0)
		draw_string(font, ht_pos, hdr_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 1))

	# 3. Fiery Banner Graphic Section
	var ban_y = hdr_h
	var ban_h = 120.0
	# Fiery dark background
	draw_polygon(PackedVector2Array([
		Vector2(0, ban_y), Vector2(w, ban_y), Vector2(w, ban_y + ban_h), Vector2(0, ban_y + ban_h)
	]), PackedColorArray([
		Color(0.25, 0.08, 0.02, 1.0), Color(0.55, 0.18, 0.02, 1.0),
		Color(0.35, 0.10, 0.01, 1.0), Color(0.12, 0.04, 0.01, 1.0)
	]))
	
	# Fiery energy glow & speed fire streaks
	var car_cx = w * 0.5 - 6.0
	var car_cy = ban_y + ban_h * 0.52
	draw_circle(Vector2(car_cx + 20, car_cy), 55.0, Color(1.0, 0.45, 0.05, 0.40))
	draw_circle(Vector2(car_cx + 40, car_cy - 10), 38.0, Color(1.0, 0.25, 0.0, 0.35))
	draw_circle(Vector2(car_cx - 20, car_cy + 10), 35.0, Color(1.0, 0.65, 0.1, 0.30))
	
	# Intense flame speed lines behind car (trailing right)
	for i in range(14):
		var sy = ban_y + 8.0 + i * 8.0
		var sl = 10.0 + (i * 27) % 80
		var sr = w - 4.0
		var a = 0.25 + 0.35 * sin(float(i) * 0.8)
		draw_line(Vector2(sl, sy), Vector2(sr, sy), Color(1.0, 0.55 + i * 0.03, 0.05, a), 2.2)
		
	# High-res supercar render
	if _car_tex:
		var c_w = 215.0
		var c_h = 135.0
		var c_rect = Rect2(Vector2(car_cx - c_w * 0.5, car_cy - c_h * 0.5 + 4.0), Vector2(c_w, c_h))
		draw_texture_rect(_car_tex, c_rect, false)
		
	# Fiery sparks & ember particles in front/over car
	var embers = [
		Vector2(car_cx - 60, car_cy + 22), Vector2(car_cx - 40, car_cy - 18),
		Vector2(car_cx + 50, car_cy - 24), Vector2(car_cx + 80, car_cy + 15),
		Vector2(car_cx + 20, car_cy + 30), Vector2(car_cx - 80, car_cy + 10)
	]
	for ep in embers:
		draw_circle(ep, 2.0, Color(1.0, 0.90, 0.3, 0.85))
		draw_circle(ep, 1.0, Color(1.0, 1.0, 0.8, 0.95))
		
	# 4. Title: NIGHT SPEEDRUN
	var title_txt = "NIGHT SPEEDRUN"
	var t_fs = 26
	if font:
		var tt_size = font.get_string_size(title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, t_fs)
		var tt_pos = Vector2((w - tt_size.x) * 0.5, ban_y + ban_h + 30.0)
		draw_string(font, tt_pos + Vector2(1, 2), title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, t_fs, Color(0.7, 0.25, 0.0, 0.9))
		draw_string(font, tt_pos, title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, t_fs, Color(1.0, 0.92, 0.85, 1.0))
		
	# 5. Timer: Clock icon + 03d 12h 45m
	var timer_y = ban_y + ban_h + 56.0
	var timer_cx = w * 0.5 - 55.0
	draw_arc(Vector2(timer_cx, timer_y - 5.0), 7.0, 0, TAU, 16, Color(1, 1, 1, 0.85), 1.5)
	draw_line(Vector2(timer_cx, timer_y - 5.0), Vector2(timer_cx, timer_y - 9.0), Color(1, 1, 1, 0.85), 1.5)
	draw_line(Vector2(timer_cx, timer_y - 5.0), Vector2(timer_cx + 3.5, timer_y - 5.0), Color(1, 1, 1, 0.85), 1.5)
	
	var timer_txt = "03d 12h 45m"
	if font:
		draw_string(font, Vector2(timer_cx + 14.0, timer_y), timer_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.92))
		
	# 6. Action Button: JOIN
	var btn_l = 14.0
	var btn_r = w - 14.0
	var btn_top = h - 64.0
	var btn_bot = h - 14.0
	var bs = 12.0
	var bp0 = Vector2(btn_l + bs, btn_top)
	var bp1 = Vector2(btn_r, btn_top)
	var bp2 = Vector2(btn_r - bs, btn_bot)
	var bp3 = Vector2(btn_l, btn_bot)
	
	var col_l = Color(0.95, 0.15, 0.08, 1.0)
	var col_r = Color(1.0, 0.55, 0.05, 1.0)
	if _join_hovered:
		col_l = col_l.lightened(0.15)
		col_r = col_r.lightened(0.15)
	if _join_pressed:
		col_l = col_l.darkened(0.2)
		col_r = col_r.darkened(0.2)
		
	draw_colored_polygon(PackedVector2Array([
		bp0 + Vector2(0, 3), bp1 + Vector2(0, 3), bp2 + Vector2(0, 3), bp3 + Vector2(0, 3)
	]), Color(0, 0, 0, 0.45))
	
	draw_polygon(PackedVector2Array([bp0, bp1, bp2, bp3]), PackedColorArray([
		col_l, col_r, col_r, col_l
	]))
	draw_line(bp0, bp1, Color(1, 1, 0.85, 0.9), 1.5)
	
	var join_txt = "JOIN"
	var j_fs = 26
	if font:
		var jt_size = font.get_string_size(join_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, j_fs)
		var jt_center_x = (bp0.x + bp1.x + bp2.x + bp3.x) * 0.25
		var jt_pos = Vector2(jt_center_x - jt_size.x * 0.5, (btn_top + btn_bot) * 0.5 + jt_size.y * 0.35)
		draw_string(font, jt_pos + Vector2(1, 2), join_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, j_fs, Color(0, 0, 0, 0.7))
		draw_string(font, jt_pos, join_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, j_fs, Color(1, 1, 1, 1))
