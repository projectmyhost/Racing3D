extends Button
class_name RaceButton

@export var is_primary: bool = false : set = set_primary
@export var corner_radius: int = 4
@export var play_sfx_on_press: bool = true
@export var play_sfx_on_hover: bool = true

var _tween: Tween
var _is_hovered: bool = false

func _ready() -> void:
	# Update center pivot for scale animations
	pivot_offset = size * 0.5
	resized.connect(_on_resized)

	# Connect interaction signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)

	_setup_styles()

func _on_resized() -> void:
	pivot_offset = size * 0.5

func set_primary(val: bool) -> void:
	is_primary = val
	_setup_styles()

func _setup_styles() -> void:
	# Colors based on design.md
	# BG_NIGHT: #171827, PANEL: #24263A, PANEL_LIGHT: #34364E
	# RACE_YELLOW: #FFB51B, RACE_ORANGE: #F36A3D, RACE_RED: #C83B43
	# TEXT: #F4F2F2, MUTED: #A8A9B8

	# Normal style
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = corner_radius
	style_normal.corner_radius_top_right = corner_radius
	style_normal.corner_radius_bottom_right = corner_radius
	style_normal.corner_radius_bottom_left = corner_radius
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8

	# Hover style
	var style_hover = style_normal.duplicate()
	# Pressed style
	var style_pressed = style_normal.duplicate()
	# Disabled style
	var style_disabled = style_normal.duplicate()
	# Focus style
	var style_focus = StyleBoxFlat.new()
	style_focus.draw_center = false
	style_focus.border_width_left = 2
	style_focus.border_width_top = 2
	style_focus.border_width_right = 2
	style_focus.border_width_bottom = 2
	style_focus.border_color = Color(1.0, 0.71, 0.11, 1.0) # RACE_YELLOW
	style_focus.corner_radius_top_left = corner_radius + 1
	style_focus.corner_radius_top_right = corner_radius + 1
	style_focus.corner_radius_bottom_right = corner_radius + 1
	style_focus.corner_radius_bottom_left = corner_radius + 1

	if is_primary:
		# Primary CTA style (Race Yellow)
		style_normal.bg_color = Color(1.0, 0.709, 0.106, 1.0) # RACE_YELLOW
		style_normal.border_color = Color(0.953, 0.416, 0.239, 1.0) # RACE_ORANGE
		style_hover.bg_color = Color(1.0, 0.78, 0.25, 1.0)
		style_hover.border_color = Color(1.0, 1.0, 1.0, 1.0)
		style_pressed.bg_color = Color(0.85, 0.58, 0.05, 1.0)
		style_pressed.border_color = Color(0.953, 0.416, 0.239, 1.0)
		add_theme_color_override("font_color", Color(0.06, 0.07, 0.11, 1.0))
		add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0, 1.0))
		add_theme_color_override("font_pressed_color", Color(0.06, 0.07, 0.11, 1.0))
	else:
		# Secondary/Navy Panel style
		style_normal.bg_color = Color(0.141, 0.149, 0.227, 0.95) # PANEL
		style_normal.border_color = Color(0.204, 0.212, 0.306, 1.0) # PANEL_LIGHT
		style_hover.bg_color = Color(0.188, 0.20, 0.30, 1.0)
		style_hover.border_color = Color(1.0, 0.709, 0.106, 1.0) # RACE_YELLOW
		style_pressed.bg_color = Color(0.11, 0.118, 0.18, 1.0)
		style_pressed.border_color = Color(0.953, 0.416, 0.239, 1.0) # RACE_ORANGE
		add_theme_color_override("font_color", Color(0.956, 0.949, 0.949, 1.0))
		add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.8, 1.0))

	# Disabled styling
	style_disabled.bg_color = Color(0.10, 0.11, 0.16, 0.7)
	style_disabled.border_color = Color(0.15, 0.16, 0.22, 0.5)
	add_theme_color_override("font_disabled_color", Color(0.45, 0.46, 0.52, 0.8))

	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("disabled", style_disabled)
	add_theme_stylebox_override("focus", style_focus)

func _on_mouse_entered() -> void:
	if disabled:
		return
	_is_hovered = true
	
	if play_sfx_on_hover and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_hover_sfx()

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	_is_hovered = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_down() -> void:
	if disabled:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(0.98, 0.98), 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_up() -> void:
	if disabled:
		return
	var target = Vector2(1.025, 1.025) if _is_hovered else Vector2(1.0, 1.0)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", target, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_pressed() -> void:
	if disabled:
		return
	if play_sfx_on_press and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
