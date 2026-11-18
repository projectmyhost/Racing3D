@tool
class_name ProfileCardWidget
extends Control

## ProfileCardWidget: 100% Procedural native motorsport player profile card.
## Renders avatar, credentials, XP bar, and hanging tier badge with razor-sharp vectors.

signal pressed

@export var nickname: String = "rawrrr":
	set(val):
		nickname = val
		queue_redraw()

@export var level: int = 0:
	set(val):
		level = val
		queue_redraw()

@export var current_xp: int = 236:
	set(val):
		current_xp = val
		queue_redraw()

@export var max_xp: int = 250:
	set(val):
		max_xp = val
		queue_redraw()

var _font_bold: Font
var _font_reg: Font
var _avatar_tex: Texture2D
var _flag_tex: Texture2D

var _is_hovered: bool = false
var _is_pressed: bool = false

const SKEW: float = 16.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.19, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(505, 180)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Regular.ttf"):
		_font_reg = load("res://assets/ui/fonts/Rajdhani-Regular.ttf")
	_load_textures()

func _load_textures() -> void:
	var av_img = Image.load_from_file("res://assets/ui/icons/avatar_pilot_racing.png")
	if av_img and not av_img.is_empty():
		_avatar_tex = ImageTexture.create_from_image(av_img)
	var flag_img = Image.load_from_file("res://assets/ui/icons/ico_play_flag.svg")
	if flag_img and not flag_img.is_empty():
		_flag_tex = ImageTexture.create_from_image(flag_img)

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
	if not _avatar_tex or not _flag_tex:
		_load_textures()

	var w = 490.0
	var card_h = 142.0
	var s = SKEW
	var font = _font_bold if _font_bold else get_theme_font("font")
	var font_reg = _font_reg if _font_reg else font
	
	# 1. Main Card Parallelogram
	var p0 = Vector2(s + 4, 0)
	var p1 = Vector2(w, 0)
	var p2 = Vector2(w - s, card_h)
	var p3 = Vector2(4, card_h)
	
	# Drop Shadow
	draw_colored_polygon(PackedVector2Array([
		p0 + Vector2(0, 4), p1 + Vector2(0, 4), p2 + Vector2(0, 4), p3 + Vector2(0, 4)
	]), Color(0, 0, 0, 0.45))
	
	# Carbon gradient fill
	var col_top = COLOR_BG_TOP
	var col_bot = COLOR_BG_BOT
	if _is_hovered:
		col_top = col_top.lightened(0.08)
		col_bot = col_bot.lightened(0.08)
	if _is_pressed:
		col_top = col_top.darkened(0.15)
		col_bot = col_bot.darkened(0.15)
		
	draw_polygon(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([
		col_top, col_top, col_bot, col_bot
	]))
	
	# Carbon diagonal stripes
	for lx in range(4, int(w), 8):
		draw_line(Vector2(lx + s * 0.5, 0), Vector2(lx - s * 0.5, card_h), Color(1, 1, 1, 0.025), 1.0)
		
	# Top silver highlight & bottom border
	draw_line(p0, p1, COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(p3, p2, COLOR_DARK_BORDER, 1.5)
	
	# 2. Avatar with Dual Chrome & Red Racing Rings
	var av_center = Vector2(58.0, 68.0)
	var r_outer = 44.0
	var r_red = 40.0
	var r_inner = 37.0
	
	# Outer drop shadow
	draw_circle(av_center + Vector2(0, 2), r_outer, Color(0, 0, 0, 0.4))
	# Chrome ring
	draw_circle(av_center, r_outer, Color(0.75, 0.80, 0.88, 1.0))
	# Inner dark bevel
	draw_circle(av_center, r_outer - 2.0, Color(0.2, 0.22, 0.26, 1.0))
	# Red glowing ring
	draw_circle(av_center, r_red, Color(0.95, 0.15, 0.12, 1.0))
	# Avatar background
	draw_circle(av_center, r_inner, Color(0.08, 0.09, 0.12, 1.0))
	
	# Procedural Native Vector Racing Helmet (Facing 3/4 Right)
	var hc = av_center + Vector2(1.0, 0.0)
	
	# Base shadow / neck hans collar
	draw_colored_polygon(PackedVector2Array([
		hc + Vector2(-22, 18), hc + Vector2(16, 22),
		hc + Vector2(12, 28), hc + Vector2(-18, 26)
	]), Color(0.05, 0.06, 0.08, 0.95))
	
	# Aerodynamic rear spoiler on helmet
	draw_colored_polygon(PackedVector2Array([
		hc + Vector2(-24, 0), hc + Vector2(-29, 7),
		hc + Vector2(-22, 15), hc + Vector2(-15, 7)
	]), Color(0.18, 0.20, 0.26, 1.0))
	
	# Helmet Main Shell (Pearlescent White / Silver Metallic)
	var shell_pts = PackedVector2Array([
		hc + Vector2(-24, 6),
		hc + Vector2(-24, -11),
		hc + Vector2(-18, -23),
		hc + Vector2(-4, -27),
		hc + Vector2(14, -23),
		hc + Vector2(24, -11),
		hc + Vector2(26, 4),
		hc + Vector2(24, 18),
		hc + Vector2(16, 23),
		hc + Vector2(-6, 24),
		hc + Vector2(-20, 18)
	])
	draw_colored_polygon(shell_pts, Color(0.92, 0.94, 0.98, 1.0))
	
	# Shell lower bevel shading (dark graphite carbon)
	draw_colored_polygon(PackedVector2Array([
		hc + Vector2(-24, 6), hc + Vector2(-20, 18),
		hc + Vector2(-6, 24), hc + Vector2(16, 23),
		hc + Vector2(24, 18), hc + Vector2(20, 14),
		hc + Vector2(0, 16), hc + Vector2(-18, 10)
	]), Color(0.18, 0.20, 0.26, 0.9))
	
	# Red Motorsport Racing Stripe
	draw_colored_polygon(PackedVector2Array([
		hc + Vector2(-22, -6), hc + Vector2(-12, -22),
		hc + Vector2(-4, -20), hc + Vector2(-14, -4),
		hc + Vector2(2, 6), hc + Vector2(18, 12),
		hc + Vector2(16, 17), hc + Vector2(-2, 11)
	]), Color(0.92, 0.15, 0.10, 1.0))
	
	# Visor Opening & Eye Port
	var visor_bg = PackedVector2Array([
		hc + Vector2(-4, -14),
		hc + Vector2(18, -12),
		hc + Vector2(26, 0),
		hc + Vector2(22, 10),
		hc + Vector2(8, 11),
		hc + Vector2(-2, 2)
	])
	draw_colored_polygon(visor_bg, Color(0.06, 0.07, 0.09, 1.0))
	
	# Tinted Golden-Amber Curved Visor
	var visor_pts = PackedVector2Array([
		hc + Vector2(-2, -12),
		hc + Vector2(17, -10),
		hc + Vector2(25, 0),
		hc + Vector2(21, 9),
		hc + Vector2(9, 10),
		hc + Vector2(0, 2)
	])
	draw_polygon(visor_pts, PackedColorArray([
		Color(1.0, 0.75, 0.15, 1.0), Color(1.0, 0.50, 0.05, 1.0),
		Color(0.85, 0.35, 0.05, 1.0), Color(0.95, 0.60, 0.10, 1.0),
		Color(1.0, 0.75, 0.15, 1.0), Color(1.0, 0.85, 0.25, 1.0)
	]))
	
	# Glossy White Specular Reflection Stripe on Visor
	draw_line(hc + Vector2(0, -9), hc + Vector2(18, -2), Color(1, 1, 1, 0.9), 2.5)
	draw_line(hc + Vector2(2, -4), hc + Vector2(16, 2), Color(1, 1, 1, 0.5), 1.5)
	
	# Pivot Screw (Silver metallic circle with center pin)
	draw_circle(hc + Vector2(-4, -2), 3.5, Color(0.75, 0.80, 0.88, 1.0))
	draw_circle(hc + Vector2(-4, -2), 1.5, Color(0.15, 0.18, 0.22, 1.0))
	
	# Aerodynamic Chin Vent
	draw_line(hc + Vector2(12, 18), hc + Vector2(20, 15), Color(0.1, 0.12, 0.16, 0.9), 2.0)
		
	# Top shine on chrome ring
	draw_arc(av_center, r_outer - 1.0, deg_to_rad(200), deg_to_rad(340), 16, Color(1, 1, 1, 0.9), 1.5)
	
	# 3. Text Info Section
	var txt_left = 114.0
	
	# Category header
	var cat_text = "FIA SUPER LICENSE // CATEGORY S1"
	if font_reg:
		draw_string(font_reg, Vector2(txt_left, 24.0), cat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.82, 0.98, 0.85))
		
	# Nickname (Large Bold Italic)
	if font:
		draw_string(font, Vector2(txt_left + 1, 62.0), nickname, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.04, 0.08, 0.2, 0.85))
		draw_string(font, Vector2(txt_left, 60.0), nickname, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 1, 1, 1))
		
	# Subtag
	var subtag = "PILOT ID #44-DR // RED BULL ACADEMY"
	if font_reg:
		draw_string(font_reg, Vector2(txt_left, 80.0), subtag, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.85, 0.98, 0.85))
		
	# 4. Level Badge (Right side of card)
	var lvl_x = 395.0
	var lvl_y = 38.0
	var lvl_w = 80.0
	var lvl_h = 36.0
	var ls = 7.0
	var lp0 = Vector2(lvl_x + ls, lvl_y)
	var lp1 = Vector2(lvl_x + lvl_w, lvl_y)
	var lp2 = Vector2(lvl_x + lvl_w - ls, lvl_y + lvl_h)
	var lp3 = Vector2(lvl_x, lvl_y + lvl_h)
	
	draw_colored_polygon(PackedVector2Array([lp0, lp1, lp2, lp3]), Color(0.18, 0.20, 0.25, 0.95))
	draw_line(lp0, lp1, Color(1.0, 0.85, 0.3, 0.9), 1.5)
	draw_line(lp3, lp2, Color(0.3, 0.35, 0.4, 0.8), 1.0)
	
	# Flag in level badge
	if _flag_tex:
		draw_texture_rect(_flag_tex, Rect2(Vector2(lvl_x + 8.0, lvl_y + 8.0), Vector2(20, 20)), false, Color(1.0, 0.82, 0.12, 1.0))
	var lvl_str = "Lv. " + str(level)
	if font:
		draw_string(font, Vector2(lvl_x + 32.0, lvl_y + 25.0), lvl_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 1))
		
	# 5. XP Progress Bar
	var bar_x = txt_left
	var bar_y = 96.0
	var bar_w = 230.0
	var bar_h = 16.0
	var bs = 4.0
	
	# Background groove
	var bp0 = Vector2(bar_x + bs, bar_y)
	var bp1 = Vector2(bar_x + bar_w, bar_y)
	var bp2 = Vector2(bar_x + bar_w - bs, bar_y + bar_h)
	var bp3 = Vector2(bar_x, bar_y + bar_h)
	draw_colored_polygon(PackedVector2Array([bp0, bp1, bp2, bp3]), Color(0.04, 0.05, 0.07, 0.95))
	draw_line(bp0, bp1, Color(0.2, 0.22, 0.26, 0.8), 1.0)
	
	# Filled portion
	var pct = clamp(float(current_xp) / float(max(max_xp, 1)), 0.0, 1.0)
	var fill_w = bar_w * pct
	if fill_w > 4.0:
		var fp0 = bp0
		var fp1 = Vector2(bar_x + fill_w, bar_y)
		var fp2 = Vector2(bar_x + fill_w - bs, bar_y + bar_h)
		var fp3 = bp3
		draw_polygon(PackedVector2Array([fp0, fp1, fp2, fp3]), PackedColorArray([
			Color(1.0, 0.85, 0.2, 1.0), Color(1.0, 0.55, 0.0, 1.0),
			Color(1.0, 0.55, 0.0, 1.0), Color(1.0, 0.85, 0.2, 1.0)
		]))
		draw_line(fp0, fp1, Color(1.0, 1.0, 0.85, 0.9), 1.0)
		
	# XP Text on the right
	var xp_str = "%d / %d XP" % [current_xp, max_xp]
	if font_reg:
		draw_string(font_reg, Vector2(bar_x + bar_w + 14.0, bar_y + 13.0), xp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.92, 0.94, 0.98, 0.9))

	# 6. Hanging Badge below (AMATEUR TIER I)
	var bg_x = 75.0
	var bg_y = card_h + 3.0
	var bg_w = 145.0
	var bg_h = 28.0
	var bgs = 6.0
	var h0 = Vector2(bg_x + bgs, bg_y)
	var h1 = Vector2(bg_x + bg_w, bg_y)
	var h2 = Vector2(bg_x + bg_w - bgs, bg_y + bg_h)
	var h3 = Vector2(bg_x, bg_y + bg_h)
	
	draw_colored_polygon(PackedVector2Array([
		h0 + Vector2(0, 2), h1 + Vector2(0, 2), h2 + Vector2(0, 2), h3 + Vector2(0, 2)
	]), Color(0, 0, 0, 0.4))
	draw_colored_polygon(PackedVector2Array([h0, h1, h2, h3]), Color(0.14, 0.16, 0.20, 0.96))
	draw_line(h0, h1, Color(1.0, 0.82, 0.15, 0.9), 1.5)
	draw_line(h3, h2, Color(0.04, 0.05, 0.06, 0.9), 1.0)
	
	# Trophy Icon
	var tr_x = bg_x + 10.0
	var tr_y = bg_y + 6.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(tr_x, tr_y), Vector2(tr_x + 12, tr_y),
		Vector2(tr_x + 9, tr_y + 10), Vector2(tr_x + 3, tr_y + 10)
	]), Color(1.0, 0.82, 0.15, 1.0))
	draw_line(Vector2(tr_x + 6, tr_y + 10), Vector2(tr_x + 6, tr_y + 15), Color(1.0, 0.82, 0.15, 1.0), 2.0)
	draw_line(Vector2(tr_x + 3, tr_y + 15), Vector2(tr_x + 9, tr_y + 15), Color(1.0, 0.82, 0.15, 1.0), 2.0)
	
	if font:
		draw_string(font, Vector2(bg_x + 28.0, bg_y + 19.0), "AMATEUR TIER I", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 1))
