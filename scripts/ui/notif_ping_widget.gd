@tool
class_name NotifPingWidget
extends Control

## NotifPingWidget: 100% Procedural native notification pill & MS ping display.

signal pressed

var _font_bold: Font
var _bell_tex: Texture2D
var _is_hovered: bool = false
var _is_pressed: bool = false

const SKEW: float = 12.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.18, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(315, 44)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	_load_textures()

func _load_textures() -> void:
	var b_img = Image.load_from_file("res://assets/ui/icons/ico_bell.png")
	if b_img and not b_img.is_empty():
		_bell_tex = ImageTexture.create_from_image(b_img)

func _gui_input(event: InputEvent) -> void:
	var pill_rect = Rect2(0, 0, 215, size.y)
	if event is InputEventMouseMotion:
		var was_hov = _is_hovered
		_is_hovered = pill_rect.has_point(event.position)
		if _is_hovered != was_hov:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _is_hovered else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if pill_rect.has_point(event.position):
					_is_pressed = true
					queue_redraw()
			else:
				if _is_pressed and pill_rect.has_point(event.position):
					pressed.emit()
				_is_pressed = false
				queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_is_hovered = false
		_is_pressed = false
		queue_redraw()

func _draw() -> void:
	if not _bell_tex:
		_load_textures()

	var h = size.y
	var pill_w = 215.0
	var s = SKEW
	var font = _font_bold if _font_bold else get_theme_font("font")
	
	# 1. Slanted Notification Pill
	var p0 = Vector2(s, 0)
	var p1 = Vector2(pill_w, 0)
	var p2 = Vector2(pill_w - s, h)
	var p3 = Vector2(0, h)
	
	# Drop Shadow
	draw_colored_polygon(PackedVector2Array([
		p0 + Vector2(0, 3), p1 + Vector2(0, 3), p2 + Vector2(0, 3), p3 + Vector2(0, 3)
	]), Color(0, 0, 0, 0.40))
	
	# Carbon dark gradient body
	var col_top = COLOR_BG_TOP
	var col_bot = COLOR_BG_BOT
	if _is_hovered:
		col_top = col_top.lightened(0.12)
		col_bot = col_bot.lightened(0.12)
	if _is_pressed:
		col_top = col_top.darkened(0.2)
		col_bot = col_bot.darkened(0.2)
		
	draw_polygon(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([
		col_top, col_top, col_bot, col_bot
	]))
	
	# Top silver highlight & bottom border
	draw_line(p0, p1, COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(p3, p2, COLOR_DARK_BORDER, 1.5)
	
	# Procedural Native Vector Bell Icon (Golden Motorsport Notification)
	var bell_pos = Vector2(s + 12.0, (h - 22.0) * 0.5)
	var bc = bell_pos + Vector2(10.0, 11.0)
	var col_bell = Color(1.0, 0.82, 0.12, 1.0)
	var col_bell_glow = Color(1.0, 0.65, 0.05, 1.0)
	# Top hanger ring
	draw_arc(bc - Vector2(0, 7.5), 3.0, PI, TAU, 12, col_bell, 1.5)
	# Bell flare polygon
	var bell_pts = PackedVector2Array([
		bc + Vector2(-3, -7),
		bc + Vector2(3, -7),
		bc + Vector2(6, 1),
		bc + Vector2(9, 5),
		bc + Vector2(-9, 5),
		bc + Vector2(-6, 1)
	])
	draw_polygon(bell_pts, PackedColorArray([
		col_bell, col_bell, col_bell_glow, col_bell_glow, col_bell_glow, col_bell
	]))
	# Bottom rim line
	draw_line(bc + Vector2(-9, 5), bc + Vector2(9, 5), col_bell, 2.0)
	# Clapper
	draw_circle(bc + Vector2(0, 7.5), 2.5, col_bell)
		
	# Text: NOTIFICATIONS
	var notif_text = "NOTIFICATIONS"
	var font_size = 20
	var text_pos = Vector2(bell_pos.x + 30.0, h * 0.5 + 7.0)
	if font:
		draw_string(font, text_pos + Vector2(1, 1.5), notif_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.8))
		draw_string(font, text_pos, notif_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.95, 0.98, 0.95))
		
	# 2. MS: 24 Ping Label (Placed cleanly to the right)
	var ping_text = "MS: 24"
	var ping_fs = 22
	var ping_pos = Vector2(pill_w + 18.0, h * 0.5 + 7.5)
	if font:
		draw_string(font, ping_pos + Vector2(1, 1.5), ping_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ping_fs, Color(0.0, 0.25, 0.08, 0.9))
		draw_string(font, ping_pos, ping_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ping_fs, Color(0.0, 0.95, 0.45, 1.0))
