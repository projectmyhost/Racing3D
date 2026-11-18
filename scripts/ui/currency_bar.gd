@tool
class_name CurrencyBar
extends Control

## CurrencyBar: 100% Procedural native motorsport currency widget.
## Displays coins, gems, and interactive [+ STORE] button without raster crops.

signal store_pressed

@export var coins: int = 29503500:
	set(val):
		coins = val
		queue_redraw()

@export var gems: int = 31250:
	set(val):
		gems = val
		queue_redraw()

var _font_bold: Font
var _coin_tex: Texture2D
var _gem_tex: Texture2D

var _store_hovered: bool = false
var _store_pressed: bool = false

const SKEW: float = 14.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.18, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_STORE_L = Color(1.0, 0.82, 0.12, 1.0)
const COLOR_STORE_R = Color(1.0, 0.52, 0.0, 1.0)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(456, 52)
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	_load_textures()

func _load_textures() -> void:
	var c_img = Image.load_from_file("res://assets/ui/icons/ico_coin.svg")
	if c_img and not c_img.is_empty():
		_coin_tex = ImageTexture.create_from_image(c_img)
	var g_img = Image.load_from_file("res://assets/ui/icons/ico_gem.svg")
	if g_img and not g_img.is_empty():
		_gem_tex = ImageTexture.create_from_image(g_img)

func _gui_input(event: InputEvent) -> void:
	var store_rect = Rect2(size.x - 125, 6, 115, size.y - 12)
	if event is InputEventMouseMotion:
		var was_hov = _store_hovered
		_store_hovered = store_rect.has_point(event.position)
		if _store_hovered != was_hov:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _store_hovered else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if store_rect.has_point(event.position):
					_store_pressed = true
					queue_redraw()
			else:
				if _store_pressed and store_rect.has_point(event.position):
					store_pressed.emit()
				_store_pressed = false
				queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_store_hovered = false
		_store_pressed = false
		queue_redraw()

func _format_number(n: int) -> String:
	var s = str(abs(n))
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return ("-" if n < 0 else "") + res

func _draw() -> void:
	if not _coin_tex or not _gem_tex:
		_load_textures()

	var w = size.x
	var h = size.y
	var s = SKEW
	var font = _font_bold if _font_bold else get_theme_font("font")
	
	# Outer slanted container
	var p0 = Vector2(s, 0)
	var p1 = Vector2(w, 0)
	var p2 = Vector2(w - s, h)
	var p3 = Vector2(0, h)
	
	# Drop shadow
	draw_colored_polygon(PackedVector2Array([
		p0 + Vector2(0, 3), p1 + Vector2(0, 3), p2 + Vector2(0, 3), p3 + Vector2(0, 3)
	]), Color(0, 0, 0, 0.45))
	
	# Carbon dark gradient body
	draw_polygon(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([
		COLOR_BG_TOP, COLOR_BG_TOP, COLOR_BG_BOT, COLOR_BG_BOT
	]))
	
	# Carbon diagonal lines
	for lx in range(0, int(w), 8):
		draw_line(Vector2(lx + s, 0), Vector2(lx, h), Color(1, 1, 1, 0.025), 1.0)
		
	# Top silver highlight & bottom border
	draw_line(p0, p1, COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(p3, p2, COLOR_DARK_BORDER, 1.5)
	
	# 1. Coin Section
	var coin_icon_pos = Vector2(s + 10.0, (h - 28.0) * 0.5)
	if _coin_tex:
		draw_texture_rect(_coin_tex, Rect2(coin_icon_pos, Vector2(28, 28)), false)
	else:
		var c_center = coin_icon_pos + Vector2(14, 14)
		draw_circle(c_center, 13.0, Color(0.95, 0.75, 0.1, 1.0))
		draw_circle(c_center, 11.0, Color(1.0, 0.85, 0.2, 1.0))
		draw_circle(c_center, 8.5, Color(0.9, 0.65, 0.05, 1.0))
		draw_circle(c_center - Vector2(3, 3), 3.0, Color(1, 1, 0.8, 0.8))
		
	var coin_str = _format_number(coins)
	var font_size = 23
	var coin_text_pos = Vector2(coin_icon_pos.x + 36.0, h * 0.5 + 7.5)
	if font:
		draw_string(font, coin_text_pos + Vector2(1, 1.5), coin_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.85))
		draw_string(font, coin_text_pos, coin_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 1))
		
	# Slanted Divider 1
	var div1_x = 188.0
	draw_line(Vector2(div1_x + s * 0.5, 8), Vector2(div1_x - s * 0.5, h - 8), Color(1, 1, 1, 0.15), 1.0)
	
	# 2. Gem Section
	var gem_icon_pos = Vector2(div1_x + 16.0, (h - 26.0) * 0.5)
	if _gem_tex:
		draw_texture_rect(_gem_tex, Rect2(gem_icon_pos, Vector2(26, 26)), false)
	else:
		var g_center = gem_icon_pos + Vector2(13, 13)
		var diamond = PackedVector2Array([
			g_center + Vector2(0, -12), g_center + Vector2(12, 0),
			g_center + Vector2(0, 12), g_center + Vector2(-12, 0)
		])
		draw_colored_polygon(diamond, Color(0.1, 0.75, 1.0, 1.0))
		
	var gem_str = _format_number(gems)
	var gem_text_pos = Vector2(gem_icon_pos.x + 34.0, h * 0.5 + 7.5)
	if font:
		draw_string(font, gem_text_pos + Vector2(1, 1.5), gem_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.85))
		draw_string(font, gem_text_pos, gem_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 1))

	# Slanted Divider 2
	var div2_x = 325.0
	draw_line(Vector2(div2_x + s * 0.5, 8), Vector2(div2_x - s * 0.5, h - 8), Color(1, 1, 1, 0.15), 1.0)
	
	# 3. [+ STORE] Button
	var btn_l = div2_x + 14.0
	var btn_r = w - 8.0
	var btn_top = 7.0
	var btn_bot = h - 7.0
	var bs = 9.0
	var bp0 = Vector2(btn_l + bs, btn_top)
	var bp1 = Vector2(btn_r, btn_top)
	var bp2 = Vector2(btn_r - bs, btn_bot)
	var bp3 = Vector2(btn_l, btn_bot)
	
	var col_l = COLOR_STORE_L
	var col_r = COLOR_STORE_R
	if _store_hovered:
		col_l = col_l.lightened(0.12)
		col_r = col_r.lightened(0.12)
	if _store_pressed:
		col_l = col_l.darkened(0.18)
		col_r = col_r.darkened(0.18)
		
	draw_polygon(PackedVector2Array([bp0, bp1, bp2, bp3]), PackedColorArray([
		col_l, col_r, col_r, col_l
	]))
	draw_line(bp0, bp1, Color(1, 1, 0.85, 0.9), 1.5)
	
	var store_text = "[+ STORE]"
	var store_fs = 20
	if font:
		var st_size = font.get_string_size(store_text, HORIZONTAL_ALIGNMENT_CENTER, -1, store_fs)
		var st_center_x = (bp0.x + bp1.x + bp2.x + bp3.x) * 0.25
		var st_pos = Vector2(st_center_x - st_size.x * 0.5, h * 0.5 + st_size.y * 0.35)
		draw_string(font, st_pos, store_text, HORIZONTAL_ALIGNMENT_LEFT, -1, store_fs, Color(0.08, 0.08, 0.08, 1.0))
