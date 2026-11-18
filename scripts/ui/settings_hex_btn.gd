@tool
class_name SettingsHexBtn
extends Control

## SettingsHexBtn: 100% Procedural native hexagonal settings button.
## Conforms to reference screenshot with metallic beveled edges and gear cog.

signal pressed

var _is_hovered: bool = false
var _is_pressed: bool = false
var _gear_tex: Texture2D

func _ready() -> void:
	custom_minimum_size = Vector2(74, 74)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_load_textures()

func _load_textures() -> void:
	var g_img = Image.load_from_file("res://assets/ui/icons/ico_settings_gear.svg")
	if g_img and not g_img.is_empty():
		_gear_tex = ImageTexture.create_from_image(g_img)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var center = size * 0.5
		var was_hov = _is_hovered
		_is_hovered = (event.position.distance_to(center) <= 34.0)
		if _is_hovered != was_hov:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _is_hovered else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.position.distance_to(size * 0.5) <= 34.0:
					_is_pressed = true
					queue_redraw()
			else:
				if _is_pressed and event.position.distance_to(size * 0.5) <= 34.0:
					pressed.emit()
				_is_pressed = false
				queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_is_hovered = false
		_is_pressed = false
		queue_redraw()

func _get_hex_points(center: Vector2, radius: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _draw() -> void:
	if not _gear_tex:
		_load_textures()

	var center = size * 0.5
	var r_outer = 33.0
	var r_inner = 28.0
	
	# Drop Shadow
	var shadow_pts = _get_hex_points(center + Vector2(0, 3), r_outer)
	draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.45))
	
	# Outer Metallic Hexagon Bevel
	var outer_pts = _get_hex_points(center, r_outer)
	var bevel_col_top = Color(0.88, 0.92, 0.98, 0.95) if _is_hovered else Color(0.70, 0.74, 0.82, 0.95)
	var bevel_col_bot = Color(0.18, 0.20, 0.24, 0.95)
	draw_polygon(outer_pts, PackedColorArray([
		bevel_col_top, bevel_col_top, bevel_col_bot, bevel_col_bot, bevel_col_bot, bevel_col_top
	]))
	
	# Inner Dark Metallic Hexagon
	var inner_pts = _get_hex_points(center, r_inner)
	var inner_top = Color(0.16, 0.18, 0.22, 1.0)
	var inner_bot = Color(0.08, 0.09, 0.12, 1.0)
	if _is_pressed:
		inner_top = inner_top.darkened(0.25)
		inner_bot = inner_bot.darkened(0.25)
	draw_polygon(inner_pts, PackedColorArray([
		inner_top, inner_top, inner_bot, inner_bot, inner_bot, inner_top
	]))
	
	# Inner border ring
	for i in range(6):
		var p_a = inner_pts[i]
		var p_b = inner_pts[(i + 1) % 6]
		draw_line(p_a, p_b, Color(0.35, 0.40, 0.48, 0.6), 1.0)
		
	# Gear Icon
	var gear_size = 34.0
	var icon_rect = Rect2(center - Vector2(gear_size, gear_size) * 0.5, Vector2(gear_size, gear_size))
	var icon_color = Color(1, 1, 1, 1.0) if _is_hovered else Color(0.92, 0.94, 0.98, 0.95)
	if _gear_tex:
		draw_texture_rect(_gear_tex, icon_rect, false, icon_color)
		
	# Sparkle glint on top-left bevel
	if _is_hovered:
		var glint_p = outer_pts[0]
		draw_circle(glint_p, 3.0, Color(1, 1, 1, 0.95))
		draw_line(glint_p - Vector2(6, 0), glint_p + Vector2(6, 0), Color(1, 1, 1, 0.8), 1.5)
		draw_line(glint_p - Vector2(0, 6), glint_p + Vector2(0, 6), Color(1, 1, 1, 0.8), 1.5)
