@tool
class_name MailBtnUI
extends Control

## MailBtnUI: 100% Procedural native Mail widget with envelope icon & unread badge.

signal pressed

@export var unread_count: int = 2:
	set(val):
		unread_count = val
		queue_redraw()

var _font_bold: Font
var _envelope_tex: Texture2D
var _is_hovered: bool = false
var _is_pressed: bool = false

const SKEW: float = 12.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.19, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(120, 110)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	_load_textures()

func _load_textures() -> void:
	var e_img = Image.load_from_file("res://assets/ui/icons/ico_envelope.png")
	if e_img and not e_img.is_empty():
		_envelope_tex = ImageTexture.create_from_image(e_img)

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
	if not _envelope_tex:
		_load_textures()

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
		col_top = col_top.lightened(0.12)
		col_bot = col_bot.lightened(0.12)
	if _is_pressed:
		col_top = col_top.darkened(0.18)
		col_bot = col_bot.darkened(0.18)
		
	draw_polygon(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([
		col_top, col_top, col_bot, col_bot
	]))
	
	# Top silver highlight & bottom border
	draw_line(p0, p1, COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(p3, p2, COLOR_DARK_BORDER, 1.5)
	
	# Right Slanted Glowing Neon Accent Bar
	var bar_w = 10.0
	var r_p0 = p1 - Vector2(bar_w + 2, 0)
	var r_p1 = p1
	var r_p2 = p2
	var r_p3 = p2 - Vector2(bar_w + 2, 0)
	draw_polygon(PackedVector2Array([r_p0, r_p1, r_p2, r_p3]), PackedColorArray([
		Color(1.0, 0.18, 0.08, 1.0), Color(1.0, 0.65, 0.0, 1.0),
		Color(1.0, 0.65, 0.0, 1.0), Color(1.0, 0.18, 0.08, 1.0)
	]))
	
	# Text: MAIL
	var mail_txt = "MAIL"
	var fs = 22
	if font:
		var mt_size = font.get_string_size(mail_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var center_x = (p0.x + p1.x + p2.x + p3.x) * 0.25 - 6.0
		var mt_pos = Vector2(center_x - mt_size.x * 0.5, 34.0)
		draw_string(font, mt_pos + Vector2(1, 1.5), mail_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
		draw_string(font, mt_pos, mail_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 1))

	# Envelope Icon
	var env_w = 48.0
	var env_h = 32.0
	var env_cx = (w - s) * 0.5 - 2.0
	var env_cy = h * 0.5 + 18.0
	var env_rect = Rect2(Vector2(env_cx - env_w * 0.5, env_cy - env_h * 0.5), Vector2(env_w, env_h))
	
	# Procedural Native Vector Envelope Icon
	var ep0 = env_rect.position
	var ep1 = ep0 + Vector2(env_w, 0)
	var ep2 = ep0 + Vector2(env_w, env_h)
	var ep3 = ep0 + Vector2(0, env_h)
	# Envelope Drop Shadow
	draw_colored_polygon(PackedVector2Array([
		ep0 + Vector2(0, 2), ep1 + Vector2(0, 2), ep2 + Vector2(0, 2), ep3 + Vector2(0, 2)
	]), Color(0, 0, 0, 0.4))
	# White Envelope Body
	draw_colored_polygon(PackedVector2Array([ep0, ep1, ep2, ep3]), Color(0.96, 0.97, 1.0, 1.0))
	# Inner flap shading
	var flap_mid = ep0 + Vector2(env_w * 0.5, env_h * 0.60)
	draw_polygon(PackedVector2Array([ep0, ep1, flap_mid]), PackedColorArray([
		Color(0.88, 0.90, 0.94, 1.0), Color(0.88, 0.90, 0.94, 1.0), Color(0.80, 0.83, 0.88, 1.0)
	]))
	# Flap Border Lines
	draw_line(ep0, flap_mid, Color(0.15, 0.18, 0.22, 0.85), 1.5)
	draw_line(ep1, flap_mid, Color(0.15, 0.18, 0.22, 0.85), 1.5)
	# Outer border lines
	draw_line(ep0, ep1, Color(0.15, 0.18, 0.22, 0.9), 1.5)
	draw_line(ep1, ep2, Color(0.15, 0.18, 0.22, 0.9), 1.5)
	draw_line(ep2, ep3, Color(0.15, 0.18, 0.22, 0.9), 1.5)
	draw_line(ep3, ep0, Color(0.15, 0.18, 0.22, 0.9), 1.5)
		
	# Red Circular Notification Badge '2'
	if unread_count > 0:
		var badge_pos = Vector2(w - 18.0, 16.0)
		draw_circle(badge_pos + Vector2(0, 1.5), 12.0, Color(0, 0, 0, 0.45))
		draw_circle(badge_pos, 12.0, Color(0.88, 0.12, 0.12, 1.0))
		draw_arc(badge_pos, 12.0, 0, TAU, 16, Color(1, 1, 1, 0.85), 1.0)
		if font:
			var cnt_str = str(unread_count)
			var cs = font.get_string_size(cnt_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
			draw_string(font, badge_pos - Vector2(cs.x * 0.5, -cs.y * 0.35), cnt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 1))
