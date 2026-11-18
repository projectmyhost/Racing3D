@tool
class_name FriendsCardUI
extends Control

## FriendsCardUI: 100% Procedural native Online Friends widget.
## Displays friend status rows and interactive CHAT & INVITE buttons.

signal chat_pressed
signal invite_pressed

var _font_bold: Font
var _font_reg: Font
var _av1_tex: Texture2D
var _av2_tex: Texture2D

var _chat_hovered: bool = false
var _chat_pressed: bool = false
var _invite_hovered: bool = false
var _invite_pressed: bool = false

const COLOR_BG_TOP = Color(0.12, 0.14, 0.18, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(360, 298)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Regular.ttf"):
		_font_reg = load("res://assets/ui/fonts/Rajdhani-Regular.ttf")
	_load_textures()

func _load_textures() -> void:
	var img1 = Image.load_from_file("res://assets/ui/icons/avatar_friend_1.png")
	if img1 and not img1.is_empty():
		_av1_tex = ImageTexture.create_from_image(img1)
	var img2 = Image.load_from_file("res://assets/ui/icons/avatar_friend_2.png")
	if img2 and not img2.is_empty():
		_av2_tex = ImageTexture.create_from_image(img2)

func _gui_input(event: InputEvent) -> void:
	var chat_rect = Rect2(14, size.y - 56, (size.x - 36) * 0.5, 44)
	var inv_rect = Rect2(14 + (size.x - 36) * 0.5 + 8, size.y - 56, (size.x - 36) * 0.5, 44)
	
	if event is InputEventMouseMotion:
		var was_ch = _chat_hovered
		var was_ih = _invite_hovered
		_chat_hovered = chat_rect.has_point(event.position)
		_invite_hovered = inv_rect.has_point(event.position)
		if _chat_hovered != was_ch or _invite_hovered != was_ih:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if (_chat_hovered or _invite_hovered) else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if chat_rect.has_point(event.position):
					_chat_pressed = true
				if inv_rect.has_point(event.position):
					_invite_pressed = true
				queue_redraw()
			else:
				if _chat_pressed and chat_rect.has_point(event.position):
					chat_pressed.emit()
				if _invite_pressed and inv_rect.has_point(event.position):
					invite_pressed.emit()
				_chat_pressed = false
				_invite_pressed = false
				queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_chat_hovered = false
		_chat_pressed = false
		_invite_hovered = false
		_invite_pressed = false
		queue_redraw()

func _draw() -> void:
	if not _av1_tex or not _av2_tex:
		_load_textures()

	var w = size.x
	var h = size.y
	var font = _font_bold if _font_bold else get_theme_font("font")
	var font_reg = _font_reg if _font_reg else font
	
	# 1. Main Outer Box
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 4), Vector2(w, 4), Vector2(w, h + 4), Vector2(0, h + 4)
	]), Color(0, 0, 0, 0.45))
	
	draw_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)
	]), PackedColorArray([
		COLOR_BG_TOP, COLOR_BG_TOP, COLOR_BG_BOT, COLOR_BG_BOT
	]))
	
	for lx in range(0, int(w), 8):
		draw_line(Vector2(lx, 0), Vector2(lx - 20, h), Color(1, 1, 1, 0.02), 1.0)
		
	draw_line(Vector2(0, 0), Vector2(w, 0), COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(Vector2(w, 0), Vector2(w, h), COLOR_DARK_BORDER, 1.0)
	draw_line(Vector2(0, h), Vector2(w, h), COLOR_DARK_BORDER, 1.5)
	draw_line(Vector2(0, 0), Vector2(0, h), COLOR_DARK_BORDER, 1.0)
	
	# 2. Header: ONLINE FRIENDS (5/12)
	var hdr_txt = "ONLINE FRIENDS (5/12)"
	if font:
		draw_string(font, Vector2(16.0, 30.0), hdr_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.95, 0.95, 0.98, 1.0))
	draw_line(Vector2(14, 42), Vector2(w - 14, 42), Color(1, 1, 1, 0.1), 1.0)
	
	# 3. Friend Row 1: Aktif // In Lobby
	var r1_y = 95.0
	var av1_pos = Vector2(44.0, r1_y)
	draw_circle(av1_pos, 22.0, Color(0.1, 0.9, 0.25, 1.0)) # Green outer glowing ring
	draw_circle(av1_pos, 19.5, Color(0.10, 0.12, 0.16, 1.0)) # Inner bevel
	
	# Procedural Vector Portrait 1
	var r_av = 18.0
	draw_circle(av1_pos, r_av, Color(0.20, 0.24, 0.30, 1.0)) # Studio backdrop
	# Torso / Jersey
	draw_colored_polygon(PackedVector2Array([
		av1_pos + Vector2(-15, 18), av1_pos + Vector2(15, 18),
		av1_pos + Vector2(11, 8), av1_pos + Vector2(-11, 8)
	]), Color(0.12, 0.14, 0.18, 1.0))
	# Green collar detail
	draw_line(av1_pos + Vector2(-6, 9), av1_pos + Vector2(6, 9), Color(0.1, 0.9, 0.25, 0.9), 1.5)
	# Neck
	draw_colored_polygon(PackedVector2Array([
		av1_pos + Vector2(-4, 2), av1_pos + Vector2(4, 2),
		av1_pos + Vector2(5, 9), av1_pos + Vector2(-5, 9)
	]), Color(0.85, 0.65, 0.52, 1.0))
	# Face Head
	draw_circle(av1_pos - Vector2(0, 1.5), 8.5, Color(0.90, 0.70, 0.56, 1.0))
	# Stylish Beard
	draw_colored_polygon(PackedVector2Array([
		av1_pos + Vector2(-6, 1), av1_pos + Vector2(6, 1),
		av1_pos + Vector2(5, 6), av1_pos + Vector2(0, 7.5), av1_pos + Vector2(-5, 6)
	]), Color(0.18, 0.14, 0.12, 0.95))
	# Dark Wavy Hair
	draw_colored_polygon(PackedVector2Array([
		av1_pos + Vector2(-7, 0), av1_pos + Vector2(-8, -6),
		av1_pos + Vector2(-5, -11), av1_pos + Vector2(0, -12),
		av1_pos + Vector2(6, -11), av1_pos + Vector2(8, -6),
		av1_pos + Vector2(7, 0), av1_pos + Vector2(5, -5),
		av1_pos + Vector2(-4, -5)
	]), Color(0.14, 0.11, 0.10, 1.0))
	# Eyes
	draw_circle(av1_pos + Vector2(-3, -2), 1.0, Color(0.15, 0.15, 0.15, 1.0))
	draw_circle(av1_pos + Vector2(3, -2), 1.0, Color(0.15, 0.15, 0.15, 1.0))

	# Green status dot
	draw_circle(Vector2(84.0, r1_y - 8.0), 4.5, Color(0.1, 0.95, 0.3, 1.0))
	if font:
		draw_string(font, Vector2(96.0, r1_y - 2.0), "Aktif", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 1))
	if font_reg:
		draw_string(font_reg, Vector2(82.0, r1_y + 19.0), "In Lobby", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.9, 0.35, 1.0))
		
	draw_line(Vector2(20, 142), Vector2(w - 20, 142), Color(1, 1, 1, 0.06), 1.0)
	
	# 4. Friend Row 2: Aktif // In Race
	var r2_y = 185.0
	var av2_pos = Vector2(44.0, r2_y)
	draw_circle(av2_pos, 22.0, Color(1.0, 0.82, 0.15, 1.0)) # Gold outer glowing ring
	draw_circle(av2_pos, 19.5, Color(0.10, 0.12, 0.16, 1.0)) # Inner bevel
	
	# Procedural Vector Portrait 2
	draw_circle(av2_pos, r_av, Color(0.25, 0.22, 0.24, 1.0)) # Warm backdrop
	# Torso / Jersey
	draw_colored_polygon(PackedVector2Array([
		av2_pos + Vector2(-15, 18), av2_pos + Vector2(15, 18),
		av2_pos + Vector2(11, 8), av2_pos + Vector2(-11, 8)
	]), Color(0.16, 0.16, 0.19, 1.0))
	# Gold collar detail
	draw_line(av2_pos + Vector2(-6, 9), av2_pos + Vector2(6, 9), Color(1.0, 0.82, 0.15, 0.9), 1.5)
	# Neck
	draw_colored_polygon(PackedVector2Array([
		av2_pos + Vector2(-4, 2), av2_pos + Vector2(4, 2),
		av2_pos + Vector2(5, 9), av2_pos + Vector2(-5, 9)
	]), Color(0.88, 0.68, 0.54, 1.0))
	# Face Head
	draw_circle(av2_pos - Vector2(0, 1.5), 8.5, Color(0.92, 0.72, 0.58, 1.0))
	# Short Athletic Hair
	draw_colored_polygon(PackedVector2Array([
		av2_pos + Vector2(-7, -2), av2_pos + Vector2(-7, -8),
		av2_pos + Vector2(-4, -11), av2_pos + Vector2(2, -11),
		av2_pos + Vector2(7, -8), av2_pos + Vector2(7, -2),
		av2_pos + Vector2(4, -6), av2_pos + Vector2(-4, -6)
	]), Color(0.16, 0.13, 0.11, 1.0))
	# Eyes & clean jaw
	draw_circle(av2_pos + Vector2(-3, -2), 1.0, Color(0.15, 0.15, 0.15, 1.0))
	draw_circle(av2_pos + Vector2(3, -2), 1.0, Color(0.15, 0.15, 0.15, 1.0))
	draw_line(av2_pos + Vector2(-3, 4.5), av2_pos + Vector2(3, 4.5), Color(0.7, 0.45, 0.35, 0.9), 1.0)
	# Green status dot
	draw_circle(Vector2(84.0, r2_y - 8.0), 4.5, Color(0.1, 0.95, 0.3, 1.0))
	if font:
		draw_string(font, Vector2(96.0, r2_y - 2.0), "Aktif", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 1))
	if font_reg:
		draw_string(font_reg, Vector2(82.0, r2_y + 19.0), "In Race", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.3, 1.0))

	# 5. Bottom Buttons: CHAT and INVITE
	var btn_w = (w - 38.0) * 0.5
	var btn_top = h - 54.0
	var btn_bot = h - 10.0
	var bs = 9.0
	
	# --- CHAT Button ---
	var c_l = 14.0
	var c_r = c_l + btn_w
	var cp0 = Vector2(c_l + bs, btn_top)
	var cp1 = Vector2(c_r, btn_top)
	var cp2 = Vector2(c_r - bs, btn_bot)
	var cp3 = Vector2(c_l, btn_bot)
	
	var c_fill = Color(0.22, 0.24, 0.30, 0.95) if _chat_hovered else Color(0.14, 0.15, 0.19, 0.95)
	if _chat_pressed: c_fill = c_fill.darkened(0.25)
	draw_colored_polygon(PackedVector2Array([cp0, cp1, cp2, cp3]), c_fill)
	draw_line(cp0, cp1, COLOR_SILVER_HIGHLIGHT, 1.2)
	draw_line(cp3, cp2, COLOR_DARK_BORDER, 1.0)
	
	if font:
		var ct_size = font.get_string_size("CHAT", HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		var ct_center_x = (cp0.x + cp1.x + cp2.x + cp3.x) * 0.25
		draw_string(font, Vector2(ct_center_x - ct_size.x * 0.5, (btn_top + btn_bot) * 0.5 + 7.0), "CHAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 1))
		
	# --- INVITE Button ---
	var i_l = c_r + 10.0
	var i_r = w - 14.0
	var ip0 = Vector2(i_l + bs, btn_top)
	var ip1 = Vector2(i_r, btn_top)
	var ip2 = Vector2(i_r - bs, btn_bot)
	var ip3 = Vector2(i_l, btn_bot)
	
	var i_fill = Color(0.22, 0.24, 0.30, 0.95) if _invite_hovered else Color(0.14, 0.15, 0.19, 0.95)
	if _invite_pressed: i_fill = i_fill.darkened(0.25)
	draw_colored_polygon(PackedVector2Array([ip0, ip1, ip2, ip3]), i_fill)
	draw_line(ip0, ip1, COLOR_SILVER_HIGHLIGHT, 1.2)
	draw_line(ip3, ip2, COLOR_DARK_BORDER, 1.0)
	
	if font:
		var it_size = font.get_string_size("INVITE", HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		var it_center_x = (ip0.x + ip1.x + ip2.x + ip3.x) * 0.25
		draw_string(font, Vector2(it_center_x - it_size.x * 0.5, (btn_top + btn_bot) * 0.5 + 7.0), "INVITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 1))
