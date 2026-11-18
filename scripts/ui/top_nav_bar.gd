@tool
class_name TopNavBar
extends Control

## TopNavBar: 100% Procedural native 5-tab motorsport navigation bar.
## Conforms to reference screenshot layout: HOME, CAREER, MULTIPLAYER, SHOP, COMMUNITY.

signal tab_selected(tab_name: String)

@export var current_tab: int = 0:
	set(val):
		current_tab = val
		queue_redraw()

var tabs = ["HOME", "CAREER", "MULTIPLAYER", "SHOP", "COMMUNITY"]
var tab_widths = [135.0, 145.0, 165.0, 130.0, 160.0]
var hovered_tab: int = -1
var pressed_tab: int = -1

var _font_bold: Font

const SKEW: float = 16.0
const COLOR_BG_TOP = Color(0.12, 0.14, 0.18, 0.96)
const COLOR_BG_BOT = Color(0.06, 0.07, 0.09, 0.96)
const COLOR_ORANGE_L = Color(1.0, 0.82, 0.12, 1.0)
const COLOR_ORANGE_R = Color(1.0, 0.48, 0.0, 1.0)
const COLOR_SILVER_HIGHLIGHT = Color(0.85, 0.90, 0.98, 0.85)
const COLOR_DARK_BORDER = Color(0.03, 0.04, 0.05, 0.95)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(735, 49)
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var prev_hover = hovered_tab
		hovered_tab = _get_tab_at_pos(event.position)
		if hovered_tab != prev_hover:
			if hovered_tab >= 0:
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed_tab = _get_tab_at_pos(event.position)
				queue_redraw()
			else:
				if pressed_tab >= 0 and pressed_tab == _get_tab_at_pos(event.position):
					var sel = tabs[pressed_tab]
					current_tab = pressed_tab
					tab_selected.emit(sel)
				pressed_tab = -1
				queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hovered_tab = -1
		pressed_tab = -1
		queue_redraw()

func _get_tab_at_pos(pos: Vector2) -> int:
	var cur_x = 0.0
	for i in range(tabs.size()):
		var tw = tab_widths[i]
		if pos.x >= cur_x and pos.x < cur_x + tw:
			return i
		cur_x += tw
	return -1

func _draw() -> void:
	var w = size.x
	var h = size.y
	var s = SKEW
	var font = _font_bold if _font_bold else get_theme_font("font")
	
	# 1. Main outer slanted bar background
	var p0 = Vector2(s, 0)
	var p1 = Vector2(w, 0)
	var p2 = Vector2(w - s, h)
	var p3 = Vector2(0, h)
	
	# Drop shadow
	draw_colored_polygon(PackedVector2Array([
		p0 + Vector2(0, 3), p1 + Vector2(0, 3), p2 + Vector2(0, 3), p3 + Vector2(0, 3)
	]), Color(0, 0, 0, 0.4))
	
	# Base dark fill
	draw_polygon(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([
		COLOR_BG_TOP, COLOR_BG_TOP, COLOR_BG_BOT, COLOR_BG_BOT
	]))
	
	# Carbon texture subtle diagonal stripes
	var step = 8.0
	for lx in range(0, int(w), int(step)):
		var lp0 = Vector2(lx + s, 0)
		var lp1 = Vector2(lx, h)
		draw_line(lp0, lp1, Color(1, 1, 1, 0.025), 1.0)
		
	# 2. Render each Tab
	var cur_x = 0.0
	for i in range(tabs.size()):
		var t_name = tabs[i]
		var tw = tab_widths[i]
		var is_active = (i == current_tab)
		var is_hov = (i == hovered_tab)
		var is_prs = (i == pressed_tab)
		
		var tp0 = Vector2(cur_x + s, 0)
		var tp1 = Vector2(cur_x + tw + s, 0)
		var tp2 = Vector2(cur_x + tw, h)
		var tp3 = Vector2(cur_x, h)
		if i == 0:
			tp0 = p0
			tp3 = p3
		if i == tabs.size() - 1:
			tp1 = p1
			tp2 = p2
			
		if is_active:
			# Active Tab: Fiery Orange-Yellow Gradient
			var col_l = COLOR_ORANGE_L
			var col_r = COLOR_ORANGE_R
			if is_hov:
				col_l = col_l.lightened(0.1)
				col_r = col_r.lightened(0.1)
			if is_prs:
				col_l = col_l.darkened(0.15)
				col_r = col_r.darkened(0.15)
			draw_polygon(PackedVector2Array([tp0, tp1, tp2, tp3]), PackedColorArray([
				col_l, col_r, col_r, col_l
			]))
			# Top flare highlight on active tab
			draw_line(tp0, tp1, Color(1, 1, 0.85, 0.95), 1.5)
			# Sparkle glint on top
			var spark_x = tp0.x + 14.0
			draw_circle(Vector2(spark_x, 0), 2.5, Color(1, 1, 1, 0.95))
		else:
			# Inactive Tab
			if is_hov:
				draw_colored_polygon(PackedVector2Array([tp0, tp1, tp2, tp3]), Color(1, 1, 1, 0.08))
				# Bottom yellow indicator line on hover
				draw_line(tp3, tp2, Color(1.0, 0.75, 0.1, 0.9), 2.0)
				
		# Slanted divider between tabs
		if i > 0:
			var div_t = tp0
			var div_b = tp3
			draw_line(div_t, div_b, Color(1, 1, 1, 0.14), 1.0)
			draw_line(div_t + Vector2(1, 0), div_b + Vector2(1, 0), Color(0, 0, 0, 0.5), 1.0)
			
		# Text
		var font_size = 21
		var t_color = Color(0.08, 0.08, 0.08, 1.0) if is_active else (
			Color(1.0, 0.88, 0.3, 1.0) if is_hov else Color(0.92, 0.94, 0.98, 0.95)
		)
		var txt_size = font.get_string_size(t_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size) if font else Vector2(80, 20)
		var tab_center_x = (tp0.x + tp1.x + tp2.x + tp3.x) * 0.25
		var txt_pos = Vector2(tab_center_x - txt_size.x * 0.5, h * 0.5 + txt_size.y * 0.35)
		
		if font:
			if not is_active:
				# Drop shadow for white text
				draw_string(font, txt_pos + Vector2(1, 1.5), t_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.85))
			draw_string(font, txt_pos, t_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, t_color)
			
		cur_x += tw

	# 3. Outer Borders
	draw_line(p0, p1, COLOR_SILVER_HIGHLIGHT, 1.5)
	draw_line(p3, p2, COLOR_DARK_BORDER, 1.5)
