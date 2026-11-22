class_name HomeHudV2
extends Control

## Precision-engineered HomeScreen HUD V2 rebuilt 100% from scratch using
## SDF fading-edge GPU shaders, native ThorVG vector SVG icons, italic
## motorsport FontVariation typography, and in-engine 3D supercar artwork.

signal play_pressed
signal garage_pressed
signal settings_pressed
signal shop_pressed
signal leaderboard_pressed
signal profile_pressed
signal topup_pressed
signal mail_pressed
signal stats_pressed
signal gift_pressed
signal exit_pressed

const PANEL_SHADER := preload("res://assets/shaders/ui_fade_skew_panel.gdshader")
const FONT_BOLD_PATH := "res://assets/ui/fonts/Rajdhani-Bold.ttf"
const FONT_SEMI_PATH := "res://assets/ui/fonts/Rajdhani-SemiBold.ttf"

# Cached typography variations
var _font_hero: FontVariation
var _font_nav: FontVariation
var _font_label: FontVariation
var _font_sub: FontVariation

# Dynamic HUD refs
var _lbl_nickname: Label
var _lbl_level: Label
var _lbl_xp: Label
var _xp_fill: ColorRect
var _xp_track_width: float = 182.0
var _lbl_coins: Label
var _lbl_gems: Label
var _promo_car_rect: TextureRect

# Nav buttons list for keyboard Up/Down navigation
var nav_buttons: Array[Control] = []
var play_button: Control

# Exit confirmation popup
var _exit_dialog: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_fonts()
	_build_profile_card()
	_build_top_right_bar()
	_build_promo_banner()
	_build_left_menu_stack()
	_build_bottom_left_slogan()
	_build_bottom_right_tiles()
	_build_exit_dialog()

func _build_fonts() -> void:
	var base_bold: Font = load(FONT_BOLD_PATH) as Font
	var base_semi: Font = load(FONT_SEMI_PATH) as Font
	if not base_semi:
		base_semi = base_bold

	_font_hero = FontVariation.new()
	_font_hero.base_font = base_bold
	_font_hero.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.22, 1.0), Vector2.ZERO)
	_font_hero.variation_embolden = 0.36
	_font_hero.spacing_glyph = 2

	_font_nav = FontVariation.new()
	_font_nav.base_font = base_bold
	_font_nav.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.21, 1.0), Vector2.ZERO)
	_font_nav.variation_embolden = 0.18
	_font_nav.spacing_glyph = 1

	_font_label = FontVariation.new()
	_font_label.base_font = base_bold
	_font_label.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.18, 1.0), Vector2.ZERO)
	_font_label.variation_embolden = 0.10

	_font_sub = FontVariation.new()
	_font_sub.base_font = base_semi
	_font_sub.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.18, 1.0), Vector2.ZERO)
	_font_sub.variation_embolden = 0.05

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _make_shader_rect(rect_size_px: Vector2, params: Dictionary) -> ColorRect:
	var cr := ColorRect.new()
	cr.size = rect_size_px
	cr.color = Color.WHITE
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = PANEL_SHADER
	mat.set_shader_parameter("rect_size", rect_size_px)
	mat.set_shader_parameter("hover_t", 0.0)
	mat.set_shader_parameter("press_t", 0.0)
	for k in params.keys():
		mat.set_shader_parameter(k, params[k])
	cr.material = mat
	return cr

func _wire_interactive_control(ctrl: Control, bg_rect: ColorRect, slide_x: float, on_click: Callable) -> void:
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.focus_mode = Control.FOCUS_ALL
	ctrl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var base_pos_x: float = ctrl.position.x
	var state := {"hovered": false, "pressed": false, "hover_val": 0.0, "press_val": 0.0, "tween": null}

	var update_visual := func():
		var mat := bg_rect.material as ShaderMaterial
		if not mat:
			return
		var target_h: float = 1.0 if state["hovered"] else 0.0
		var target_p: float = 1.0 if state["pressed"] else 0.0
		var target_x: float = base_pos_x + (slide_x if target_h > 0.5 else 0.0)
		var prev_tw = state["tween"]
		if prev_tw is Tween and prev_tw.is_valid():
			prev_tw.kill()
		var tw := ctrl.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(v: float):
			state["hover_val"] = v
			mat.set_shader_parameter("hover_t", v)
		, float(state["hover_val"]), target_h, 0.12)
		tw.tween_method(func(v: float):
			state["press_val"] = v
			mat.set_shader_parameter("press_t", v)
		, float(state["press_val"]), target_p, 0.08)
		if absf(slide_x) > 0.01:
			tw.tween_property(ctrl, "position:x", target_x, 0.12)
		state["tween"] = tw

	ctrl.mouse_entered.connect(func():
		state["hovered"] = true
		update_visual.call()
	)
	ctrl.mouse_exited.connect(func():
		state["hovered"] = false
		state["pressed"] = false
		update_visual.call()
	)
	ctrl.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				state["pressed"] = true
				update_visual.call()
			else:
				var was_pressed: bool = state["pressed"]
				state["pressed"] = false
				update_visual.call()
				if was_pressed and Rect2(Vector2.ZERO, ctrl.size).has_point(event.position):
					on_click.call()
					ctrl.accept_event()
		elif event.is_action_pressed("ui_accept"):
			on_click.call()
			ctrl.accept_event()
	)

func _make_label(text: String, font: Font, font_size: int, color: Color, shadow_alpha: float = 0.72) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	if shadow_alpha > 0.0:
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, shadow_alpha))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.add_theme_constant_override("shadow_outline_size", 2)
	return lbl

func _make_notif_badge(text: String, diameter: float, font_size: int) -> Control:
	var badge := Control.new()
	badge.size = Vector2(diameter, diameter)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.89, 0.15, 0.15, 1.0)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 0.65, 0.60, 0.85)
	var r := int(diameter * 0.5)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_right = r
	sb.corner_radius_bottom_left = r
	sb.shadow_color = Color(0.85, 0.1, 0.1, 0.55)
	sb.shadow_size = 4
	panel.add_theme_stylebox_override("panel", sb)
	badge.add_child(panel)

	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font_label:
		lbl.add_theme_font_override("font", _font_label)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(lbl)
	return badge

# =============================================================================
# 1. TOP-LEFT PROFILE CARD (Upright avatar + right-fading smoked bar)
# =============================================================================
func _build_profile_card() -> void:
	var card := Control.new()
	card.name = "ProfileCardV2"
	card.position = Vector2(44.0, 32.0)
	card.size = Vector2(525.0, 102.0)
	add_child(card)

	var pad := Vector4(12.0, 12.0, 20.0, 14.0)
	var bg_sz := Vector2(card.size.x + pad.x + pad.z, card.size.y + pad.y + pad.w)
	var bg := _make_shader_rect(bg_sz, {
		"padding": pad,
		"skew_slope": 0.0,
		"corner_radius": 10.0,
		"color_tl": Color(0.10, 0.095, 0.10, 0.82),
		"color_tr": Color(0.08, 0.075, 0.08, 0.72),
		"color_bl": Color(0.06, 0.055, 0.06, 0.86),
		"color_br": Color(0.05, 0.045, 0.05, 0.72),
		"fade_mode": 1,
		"fade_start": 0.44,
		"fade_end": 0.98,
		"fade_power": 1.35,
		"sheen_strength": 0.06,
		"top_gloss_strength": 0.06,
		"border_width": 1.6,
		"border_color_top": Color(0.92, 0.86, 0.76, 0.75),
		"border_color_bot": Color(0.84, 0.73, 0.52, 0.68),
		"border_right_fade_start": 0.34,
		"border_right_fade_end": 0.86,
		"shadow_alpha": 0.45,
		"shadow_offset": Vector2(2.0, 5.0),
		"shadow_blur": 12.0,
	})
	bg.position = Vector2(-pad.x, -pad.y)
	card.add_child(bg)

	# Avatar frame (flush rounded square on left of bar, crisp metallic silver-champagne rim)
	var av_pad := Vector4(6.0, 6.0, 6.0, 6.0)
	var av_size := Vector2(102.0, 102.0)
	var av_bg := _make_shader_rect(av_size + Vector2(av_pad.x + av_pad.z, av_pad.y + av_pad.w), {
		"padding": av_pad,
		"skew_slope": 0.0,
		"corner_radius": 10.0,
		"color_tl": Color(0.16, 0.15, 0.16, 0.90),
		"color_tr": Color(0.12, 0.115, 0.12, 0.90),
		"color_bl": Color(0.07, 0.065, 0.07, 0.95),
		"color_br": Color(0.08, 0.075, 0.08, 0.95),
		"fade_mode": 0,
		"sheen_strength": 0.08,
		"top_gloss_strength": 0.10,
		"border_width": 2.0,
		"border_color_top": Color(0.94, 0.90, 0.82, 0.95),
		"border_color_bot": Color(0.78, 0.69, 0.54, 0.90),
		"shadow_alpha": 0.35,
		"shadow_offset": Vector2(1.0, 3.0),
		"shadow_blur": 8.0,
	})
	av_bg.position = Vector2(-av_pad.x, -av_pad.y)
	card.add_child(av_bg)

	var av_icon := TextureRect.new()
	av_icon.texture = _load_tex("res://assets/ui/icons/hud_v2_avatar.svg")
	av_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_icon.position = Vector2(10.0, 12.0)
	av_icon.size = Vector2(82.0, 84.0)
	av_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(av_icon)

	# Nickname
	_lbl_nickname = _make_label("Player_001", _font_nav, 36, Color(1.0, 0.99, 0.97, 1.0), 0.78)
	_lbl_nickname.position = Vector2(128.0, 10.0)
	_lbl_nickname.size = Vector2(360.0, 44.0)
	card.add_child(_lbl_nickname)

	# Level
	_lbl_level = _make_label("Lv. 1", _font_label, 24, Color(0.95, 0.94, 0.92, 0.96), 0.75)
	_lbl_level.position = Vector2(128.0, 58.0)
	_lbl_level.size = Vector2(72.0, 30.0)
	card.add_child(_lbl_level)

	# Sleek XP Track
	var xp_track := Panel.new()
	xp_track.position = Vector2(206.0, 68.0)
	xp_track.size = Vector2(_xp_track_width, 11.0)
	xp_track.clip_contents = true
	xp_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr_sb := StyleBoxFlat.new()
	tr_sb.bg_color = Color(0.05, 0.05, 0.06, 0.88)
	tr_sb.border_width_left = 1
	tr_sb.border_width_top = 1
	tr_sb.border_width_right = 1
	tr_sb.border_width_bottom = 1
	tr_sb.border_color = Color(0.75, 0.70, 0.60, 0.28)
	tr_sb.corner_radius_top_left = 4
	tr_sb.corner_radius_top_right = 4
	tr_sb.corner_radius_bottom_right = 4
	tr_sb.corner_radius_bottom_left = 4
	xp_track.add_theme_stylebox_override("panel", tr_sb)
	card.add_child(xp_track)

	_xp_fill = ColorRect.new()
	_xp_fill.position = Vector2(1.0, 1.0)
	_xp_fill.size = Vector2(0.0, 9.0)
	_xp_fill.color = Color(0.94, 0.78, 0.34, 0.95)
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_track.add_child(_xp_fill)

	# XP Text (0 / 1000)
	_lbl_xp = _make_label("0 / 1000", _font_sub, 19, Color(0.90, 0.89, 0.87, 0.92), 0.75)
	_lbl_xp.position = Vector2(398.0, 60.0)
	_lbl_xp.size = Vector2(124.0, 26.0)
	card.add_child(_lbl_xp)

	_wire_interactive_control(card, bg, 0.0, func(): profile_pressed.emit())

# =============================================================================
# 2. TOP-RIGHT CURRENCY PILLS & MAIL TILE
# =============================================================================
func _build_top_right_bar() -> void:
	# Coin Pill
	var coin_pill := _build_currency_pill(
		"CoinPillV2",
		Vector2(1246.0, 34.0),
		Vector2(284.0, 64.0),
		"res://assets/ui/icons/hud_v2_coin.svg",
		"50,000",
		true
	)
	add_child(coin_pill)

	# Gem Pill
	var gem_pill := _build_currency_pill(
		"GemPillV2",
		Vector2(1544.0, 34.0),
		Vector2(236.0, 64.0),
		"res://assets/ui/icons/hud_v2_gem.svg",
		"0",
		false
	)
	add_child(gem_pill)

	# Mail Tile
	var mail_tile := Control.new()
	mail_tile.name = "MailTileV2"
	mail_tile.position = Vector2(1794.0, 34.0)
	mail_tile.size = Vector2(92.0, 64.0)
	add_child(mail_tile)

	var mpad := Vector4(14.0, 12.0, 14.0, 14.0)
	var mbg := _make_shader_rect(mail_tile.size + Vector2(mpad.x + mpad.z, mpad.y + mpad.w), {
		"padding": mpad,
		"skew_slope": 0.28,
		"corner_radius": 9.0,
		"color_tl": Color(0.14, 0.13, 0.14, 0.82),
		"color_tr": Color(0.11, 0.10, 0.11, 0.82),
		"color_bl": Color(0.07, 0.065, 0.07, 0.88),
		"color_br": Color(0.06, 0.055, 0.06, 0.88),
		"fade_mode": 0,
		"sheen_strength": 0.10,
		"top_gloss_strength": 0.08,
		"border_width": 1.7,
		"border_color_top": Color(0.90, 0.84, 0.72, 0.82),
		"border_color_bot": Color(0.84, 0.70, 0.42, 0.82),
		"shadow_alpha": 0.45,
		"shadow_offset": Vector2(2.0, 5.0),
		"shadow_blur": 10.0,
	})
	mbg.position = Vector2(-mpad.x, -mpad.y)
	mail_tile.add_child(mbg)

	var mail_ico := TextureRect.new()
	mail_ico.texture = _load_tex("res://assets/ui/icons/hud_v2_mail.svg")
	mail_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mail_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mail_ico.position = Vector2(24.0, 13.0)
	mail_ico.size = Vector2(44.0, 38.0)
	mail_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mail_tile.add_child(mail_ico)

	var mail_badge := _make_notif_badge("1", 19.0, 12)
	mail_badge.position = Vector2(78.0, -5.0)
	mail_tile.add_child(mail_badge)

	_wire_interactive_control(mail_tile, mbg, 0.0, func(): mail_pressed.emit())

func _build_currency_pill(node_name: String, pos: Vector2, sz: Vector2, icon_path: String, initial_txt: String, is_coin: bool) -> Control:
	var pill := Control.new()
	pill.name = node_name
	pill.position = pos
	pill.size = sz

	var pad := Vector4(16.0, 12.0, 16.0, 14.0)
	var bg := _make_shader_rect(sz + Vector2(pad.x + pad.z, pad.y + pad.w), {
		"padding": pad,
		"skew_slope": 0.28,
		"corner_radius": 9.0,
		"color_tl": Color(0.14, 0.13, 0.14, 0.82),
		"color_tr": Color(0.11, 0.10, 0.11, 0.82),
		"color_bl": Color(0.07, 0.065, 0.07, 0.88),
		"color_br": Color(0.06, 0.055, 0.06, 0.88),
		"fade_mode": 0,
		"sheen_strength": 0.10,
		"top_gloss_strength": 0.08,
		"border_width": 1.7,
		"border_color_top": Color(0.88, 0.80, 0.62, 0.82),
		"border_color_bot": Color(0.86, 0.70, 0.38, 0.86),
		"shadow_alpha": 0.45,
		"shadow_offset": Vector2(2.0, 5.0),
		"shadow_blur": 10.0,
	})
	bg.position = Vector2(-pad.x, -pad.y)
	pill.add_child(bg)

	# Icon
	var ico := TextureRect.new()
	ico.texture = _load_tex(icon_path)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.position = Vector2(18.0, 10.0)
	ico.size = Vector2(44.0, 44.0)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(ico)

	# Amount label
	var lbl := _make_label(initial_txt, _font_nav, 31, Color(1.0, 0.99, 0.97, 1.0), 0.80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(68.0, 6.0)
	lbl.size = Vector2(sz.x - 134.0, 52.0)
	pill.add_child(lbl)
	if is_coin:
		_lbl_coins = lbl
	else:
		_lbl_gems = lbl

	# Gold-bordered '+' square box on right
	var plus_sz := Vector2(40.0, 40.0)
	var plus_pad := Vector4(6.0, 6.0, 6.0, 6.0)
	var plus_bg := _make_shader_rect(plus_sz + Vector2(plus_pad.x + plus_pad.z, plus_pad.y + plus_pad.w), {
		"padding": plus_pad,
		"skew_slope": 0.22,
		"corner_radius": 6.0,
		"color_tl": Color(0.32, 0.25, 0.12, 0.78),
		"color_tr": Color(0.24, 0.18, 0.08, 0.78),
		"color_bl": Color(0.18, 0.13, 0.06, 0.86),
		"color_br": Color(0.16, 0.12, 0.05, 0.86),
		"fade_mode": 0,
		"sheen_strength": 0.16,
		"border_width": 1.6,
		"border_color_top": Color(0.98, 0.86, 0.54, 0.92),
		"border_color_bot": Color(0.86, 0.66, 0.28, 0.92),
		"shadow_alpha": 0.25,
		"shadow_blur": 4.0,
	})
	plus_bg.position = Vector2(sz.x - 52.0 - plus_pad.x, 12.0 - plus_pad.y)
	pill.add_child(plus_bg)

	var plus_lbl := _make_label("+", _font_hero, 32, Color(0.98, 0.94, 0.82, 1.0), 0.70)
	plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_lbl.position = Vector2(sz.x - 54.0, 9.0)
	plus_lbl.size = Vector2(42.0, 42.0)
	pill.add_child(plus_lbl)

	_wire_interactive_control(pill, bg, 0.0, func(): topup_pressed.emit())
	return pill

# =============================================================================
# 3. UPPER-RIGHT PROMO BANNER: TOP UP NOW! / Get More Coins! + 3D Red Supercar
# =============================================================================
func _build_promo_banner() -> void:
	var card := Control.new()
	card.name = "TopupPromoV2"
	card.position = Vector2(1454.0, 156.0)
	card.size = Vector2(432.0, 178.0)
	add_child(card)

	var pad := Vector4(36.0, 18.0, 36.0, 22.0)
	var bg := _make_shader_rect(card.size + Vector2(pad.x + pad.z, pad.y + pad.w), {
		"padding": pad,
		"skew_slope": 0.28,
		"corner_radius": 16.0,
		"color_tl": Color(0.10, 0.10, 0.13, 0.86),
		"color_tr": Color(0.13, 0.11, 0.13, 0.85),
		"color_bl": Color(0.06, 0.06, 0.08, 0.92),
		"color_br": Color(0.08, 0.065, 0.075, 0.90),
		"fade_mode": 0,
		"sheen_strength": 0.12,
		"sheen_pos": 0.36,
		"top_gloss_strength": 0.08,
		"border_width": 1.8,
		"border_color_top": Color(0.92, 0.86, 0.72, 0.88),
		"border_color_bot": Color(0.88, 0.72, 0.42, 0.84),
		"promo_glow_strength": 0.42,
		"promo_glow_uv": Vector2(0.74, 0.48),
		"promo_glow_color": Color(1.0, 0.64, 0.24, 0.38),
		"glow_color": Color(0.95, 0.74, 0.36, 0.12),
		"glow_size": 12.0,
		"shadow_alpha": 0.52,
		"shadow_offset": Vector2(3.0, 8.0),
		"shadow_blur": 16.0,
	})
	bg.position = Vector2(-pad.x, -pad.y)
	card.add_child(bg)

	# Genuine 3D rendered deep crimson red supercar PNG nestled cleanly inside card
	_promo_car_rect = TextureRect.new()
	_promo_car_rect.name = "PromoCarArt"
	_promo_car_rect.texture = _load_tex("res://assets/ui/textures/topup_banner_car.png")
	_promo_car_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_promo_car_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_promo_car_rect.position = Vector2(186.0, 14.0)
	_promo_car_rect.size = Vector2(246.0, 140.0)
	_promo_car_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_promo_car_rect)

	# Left Promotional Typography
	var lbl_top := _make_label("TOP UP", _font_hero, 40, Color(1.0, 0.99, 0.97, 1.0), 0.85)
	lbl_top.position = Vector2(46.0, 22.0)
	lbl_top.size = Vector2(170.0, 44.0)
	card.add_child(lbl_top)

	var lbl_now := _make_label("NOW!", _font_hero, 46, Color(0.97, 0.87, 0.58, 1.0), 0.85)
	lbl_now.position = Vector2(36.0, 62.0)
	lbl_now.size = Vector2(165.0, 50.0)
	card.add_child(lbl_now)

	var lbl_sub := _make_label("Get More Coins!", _font_sub, 21, Color(0.92, 0.91, 0.89, 0.96), 0.80)
	lbl_sub.position = Vector2(24.0, 118.0)
	lbl_sub.size = Vector2(200.0, 30.0)
	card.add_child(lbl_sub)

	# 4 Crisp Circular Bottom-Right Pagination Dots
	var dots_row := HBoxContainer.new()
	dots_row.position = Vector2(304.0, 154.0)
	dots_row.size = Vector2(88.0, 12.0)
	dots_row.add_theme_constant_override("separation", 10)
	dots_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dots_row)
	for i in range(4):
		var dot := Panel.new()
		var d_sz: float = 9.0 if i == 0 else 8.0
		dot.custom_minimum_size = Vector2(d_sz, d_sz)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color(0.98, 0.96, 0.92, 0.95) if i == 0 else Color(0.85, 0.85, 0.88, 0.36)
		dsb.corner_radius_top_left = 5
		dsb.corner_radius_top_right = 5
		dsb.corner_radius_bottom_right = 5
		dsb.corner_radius_bottom_left = 5
		dot.add_theme_stylebox_override("panel", dsb)
		dots_row.add_child(dot)

	_wire_interactive_control(card, bg, 0.0, func(): topup_pressed.emit())

# =============================================================================
# 4. LEFT MAIN MENU STACK (PLAY Hero + GARASI / SETTING / TOKO / LEADERBOARD)
# =============================================================================
func _build_left_menu_stack() -> void:
	nav_buttons.clear()

	# Hero PLAY button
	var play_ctrl := Control.new()
	play_ctrl.name = "PlayBtnV2"
	play_ctrl.position = Vector2(44.0, 336.0)
	play_ctrl.size = Vector2(446.0, 114.0)
	add_child(play_ctrl)

	var ppad := Vector4(28.0, 24.0, 74.0, 26.0)
	var pbg := _make_shader_rect(play_ctrl.size + Vector2(ppad.x + ppad.z, ppad.y + ppad.w), {
		"padding": ppad,
		"skew_slope": 0.33,
		"corner_radius": 9.0,
		"color_tl": Color(0.99, 0.87, 0.36, 0.99),
		"color_tr": Color(0.94, 0.74, 0.24, 0.92),
		"color_bl": Color(0.92, 0.66, 0.12, 0.99),
		"color_br": Color(0.82, 0.54, 0.10, 0.84),
		"fade_mode": 1,
		"fade_start": 0.68,
		"fade_end": 1.00,
		"fade_power": 1.35,
		"fade_min_alpha": 0.10,
		"sheen_strength": 0.28,
		"sheen_pos": 0.45,
		"sheen_width": 0.28,
		"top_gloss_strength": 0.16,
		"border_width": 2.4,
		"border_color_top": Color(1.00, 0.97, 0.82, 0.96),
		"border_color_bot": Color(1.00, 0.84, 0.42, 0.90),
		"border_right_fade_start": 0.70,
		"border_right_fade_end": 0.98,
		"border_left_boost": 0.22,
		"glow_color": Color(1.00, 0.76, 0.20, 0.40),
		"glow_size": 16.0,
		"shadow_alpha": 0.45,
		"shadow_offset": Vector2(3.0, 8.0),
		"shadow_blur": 16.0,
		"slash_mode": 2,
		"slash_color_1": Color(0.98, 0.80, 0.30, 0.92),
		"slash_color_2": Color(0.94, 0.72, 0.22, 0.64),
		"slash_gap": 6.5,
		"slash_width": 5.5,
	})
	pbg.position = Vector2(-ppad.x, -ppad.y)
	play_ctrl.add_child(pbg)

	var play_ico := TextureRect.new()
	play_ico.texture = _load_tex("res://assets/ui/icons/hud_v2_play.svg")
	play_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	play_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	play_ico.position = Vector2(56.0, 27.0)
	play_ico.size = Vector2(58.0, 60.0)
	play_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_ctrl.add_child(play_ico)

	var play_lbl := _make_label("PLAY", _font_hero, 68, Color(0.11, 0.095, 0.075, 1.0), 0.14)
	play_lbl.position = Vector2(150.0, 18.0)
	play_lbl.size = Vector2(250.0, 78.0)
	play_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	play_ctrl.add_child(play_lbl)

	_wire_interactive_control(play_ctrl, pbg, 8.0, func(): play_pressed.emit())
	play_button = play_ctrl
	nav_buttons.append(play_ctrl)

	# 4 Dark Translucent Fading-Edge Navigation Buttons
	var menu_defs := [
		{"name": "GarageBtnV2", "label": "GARASI", "icon": "res://assets/ui/icons/hud_v2_garage.svg", "icon_sz": 50.0, "cb": func(): garage_pressed.emit()},
		{"name": "SettingBtnV2", "label": "SETTING", "icon": "res://assets/ui/icons/hud_v2_setting.svg", "icon_sz": 44.0, "cb": func(): settings_pressed.emit()},
		{"name": "ShopBtnV2", "label": "TOKO", "icon": "res://assets/ui/icons/hud_v2_shop.svg", "icon_sz": 45.0, "cb": func(): shop_pressed.emit()},
		{"name": "LeaderboardBtnV2", "label": "LEADERBOARD", "icon": "res://assets/ui/icons/hud_v2_leaderboard.svg", "icon_sz": 46.0, "cb": func(): leaderboard_pressed.emit()},
	]

	var start_y: float = 482.0
	var pitch_y: float = 90.0
	for i in range(menu_defs.size()):
		var item: Dictionary = menu_defs[i]
		var btn := _build_secondary_nav_btn(
			item["name"],
			Vector2(44.0, start_y + float(i) * pitch_y),
			Vector2(424.0, 70.0),
			item["label"],
			item["icon"],
			float(item["icon_sz"]),
			item["cb"]
		)
		add_child(btn)
		nav_buttons.append(btn)

func _build_secondary_nav_btn(node_name: String, pos: Vector2, sz: Vector2, text: String, icon_path: String, icon_sz: float, on_click: Callable) -> Control:
	var btn := Control.new()
	btn.name = node_name
	btn.position = pos
	btn.size = sz

	var pad := Vector4(18.0, 14.0, 56.0, 14.0)
	var bg := _make_shader_rect(sz + Vector2(pad.x + pad.z, pad.y + pad.w), {
		"padding": pad,
		"skew_slope": 0.33,
		"corner_radius": 8.0,
		"color_tl": Color(0.14, 0.13, 0.14, 0.84),
		"color_tr": Color(0.09, 0.085, 0.095, 0.76),
		"color_bl": Color(0.07, 0.065, 0.07, 0.90),
		"color_br": Color(0.055, 0.05, 0.06, 0.80),
		"fade_mode": 1,
		"fade_start": 0.56,
		"fade_end": 1.00,
		"fade_power": 1.45,
		"fade_min_alpha": 0.0,
		"sheen_strength": 0.09,
		"sheen_pos": 0.36,
		"sheen_width": 0.25,
		"top_gloss_strength": 0.07,
		"border_width": 1.6,
		"border_color_top": Color(0.90, 0.84, 0.74, 0.64),
		"border_color_bot": Color(0.84, 0.68, 0.38, 0.76),
		"border_right_fade_start": 0.44,
		"border_right_fade_end": 0.90,
		"border_left_boost": 0.20,
		"glow_color": Color(0.95, 0.76, 0.34, 0.0),
		"glow_size": 12.0,
		"shadow_alpha": 0.44,
		"shadow_offset": Vector2(2.0, 5.0),
		"shadow_blur": 12.0,
		"slash_mode": 1,
		"slash_color_1": Color(0.14, 0.125, 0.12, 0.42),
		"slash_color_2": Color(0.12, 0.11, 0.105, 0.22),
		"slash_gap": 3.5,
		"slash_width": 4.2,
	})
	bg.position = Vector2(-pad.x, -pad.y)
	btn.add_child(bg)

	var ico := TextureRect.new()
	ico.texture = _load_tex(icon_path)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.position = Vector2(46.0 - (icon_sz - 44.0) * 0.5, (sz.y - icon_sz) * 0.5)
	ico.size = Vector2(icon_sz, icon_sz)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(ico)

	var lbl := _make_label(text, _font_nav, 34, Color(0.98, 0.97, 0.95, 1.0), 0.84)
	lbl.position = Vector2(138.0, 12.0)
	lbl.size = Vector2(276.0, 46.0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(lbl)

	_wire_interactive_control(btn, bg, 9.0, on_click)
	return btn

# =============================================================================
# 5. BOTTOM-LEFT CHECKERED SLOGAN STRIP: RACE TO BE THE BEST!
# =============================================================================
func _build_bottom_left_slogan() -> void:
	var strip := Control.new()
	strip.name = "SloganStripV2"
	strip.position = Vector2(-24.0, 916.0)
	strip.size = Vector2(548.0, 128.0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

	var pad := Vector4(4.0, 8.0, 20.0, 8.0)
	var bg := _make_shader_rect(strip.size + Vector2(pad.x + pad.z, pad.y + pad.w), {
		"padding": pad,
		"skew_slope": 0.34,
		"corner_radius": 0.0,
		"color_tl": Color(0.08, 0.075, 0.08, 0.82),
		"color_tr": Color(0.06, 0.055, 0.06, 0.65),
		"color_bl": Color(0.06, 0.055, 0.06, 0.88),
		"color_br": Color(0.04, 0.04, 0.045, 0.68),
		"fade_mode": 1,
		"fade_start": 0.38,
		"fade_end": 0.96,
		"fade_power": 1.35,
		"sheen_strength": 0.03,
		"top_gloss_strength": 0.03,
		"border_width": 0.0,
		"shadow_alpha": 0.0,
		"checker_enabled": 1.0,
		"checker_cell_px": 30.0,
		"checker_fade_start": 0.16,
		"checker_fade_end": 0.36,
		"checker_color_a": Color(0.44, 0.44, 0.46, 0.56),
		"checker_color_b": Color(0.08, 0.08, 0.09, 0.70),
		"bottom_accent_strength": 1.0,
		"bottom_accent_color": Color(0.96, 0.80, 0.38, 0.98),
		"bottom_accent_start": 0.28,
		"bottom_accent_end": 0.86,
	})
	bg.position = Vector2(-pad.x, -pad.y)
	strip.add_child(bg)

	var lbl_1 := _make_label("RACE TO BE", _font_hero, 31, Color(0.95, 0.94, 0.92, 0.98), 0.85)
	lbl_1.position = Vector2(188.0, 22.0)
	lbl_1.size = Vector2(280.0, 38.0)
	strip.add_child(lbl_1)

	var lbl_2 := _make_label("THE BEST!", _font_hero, 35, Color(1.0, 0.99, 0.97, 1.0), 0.88)
	lbl_2.position = Vector2(178.0, 56.0)
	lbl_2.size = Vector2(280.0, 42.0)
	strip.add_child(lbl_2)

# =============================================================================
# 6. BOTTOM-RIGHT 3 ACTION ICON TILES (Stats / Gift! / Power)
# =============================================================================
func _build_bottom_right_tiles() -> void:
	var tiles := [
		{"name": "StatsTileV2", "x": 1492.0, "icon": "res://assets/ui/icons/hud_v2_stats.svg", "badge": "", "cb": func(): stats_pressed.emit()},
		{"name": "GiftTileV2", "x": 1634.0, "icon": "res://assets/ui/icons/hud_v2_gift.svg", "badge": "!", "cb": func(): gift_pressed.emit()},
		{"name": "PowerTileV2", "x": 1776.0, "icon": "res://assets/ui/icons/hud_v2_power.svg", "badge": "", "cb": func(): _open_exit_dialog()},
	]

	for t in tiles:
		var tile := Control.new()
		tile.name = t["name"]
		tile.position = Vector2(t["x"], 934.0)
		tile.size = Vector2(110.0, 92.0)
		add_child(tile)

		var tpad := Vector4(16.0, 14.0, 16.0, 16.0)
		var tbg := _make_shader_rect(tile.size + Vector2(tpad.x + tpad.z, tpad.y + tpad.w), {
			"padding": tpad,
			"skew_slope": 0.22,
			"corner_radius": 15.0,
			"color_tl": Color(0.14, 0.13, 0.14, 0.84),
			"color_tr": Color(0.10, 0.095, 0.105, 0.84),
			"color_bl": Color(0.065, 0.06, 0.07, 0.90),
			"color_br": Color(0.055, 0.05, 0.06, 0.90),
			"fade_mode": 0,
			"sheen_strength": 0.12,
			"top_gloss_strength": 0.08,
			"border_width": 1.8,
			"border_color_top": Color(0.88, 0.82, 0.68, 0.84),
			"border_color_bot": Color(0.84, 0.68, 0.38, 0.86),
			"glow_color": Color(0.95, 0.76, 0.34, 0.0),
			"glow_size": 10.0,
			"shadow_alpha": 0.50,
			"shadow_offset": Vector2(2.0, 6.0),
			"shadow_blur": 12.0,
		})
		tbg.position = Vector2(-tpad.x, -tpad.y)
		tile.add_child(tbg)

		var ico := TextureRect.new()
		ico.texture = _load_tex(t["icon"])
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.position = Vector2(28.0, 20.0)
		ico.size = Vector2(54.0, 52.0)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(ico)

		if not String(t["badge"]).is_empty():
			var b := _make_notif_badge(t["badge"], 22.0, 14)
			b.position = Vector2(92.0, -7.0)
			tile.add_child(b)

		_wire_interactive_control(tile, tbg, 0.0, t["cb"])

# =============================================================================
# SLEEK EXIT CONFIRMATION POPUP
# =============================================================================
func _build_exit_dialog() -> void:
	_exit_dialog = Control.new()
	_exit_dialog.name = "ExitConfirmV2"
	_exit_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_exit_dialog.visible = false
	_exit_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_exit_dialog)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.62)
	_exit_dialog.add_child(dimmer)

	var box := Control.new()
	box.position = Vector2(720.0, 410.0)
	box.size = Vector2(480.0, 230.0)
	_exit_dialog.add_child(box)

	var bpad := Vector4(24.0, 24.0, 24.0, 24.0)
	var bbg := _make_shader_rect(box.size + Vector2(bpad.x + bpad.z, bpad.y + bpad.w), {
		"padding": bpad,
		"skew_slope": 0.14,
		"corner_radius": 14.0,
		"color_tl": Color(0.12, 0.11, 0.13, 0.95),
		"color_tr": Color(0.10, 0.095, 0.11, 0.95),
		"color_bl": Color(0.06, 0.055, 0.07, 0.97),
		"color_br": Color(0.05, 0.05, 0.06, 0.97),
		"fade_mode": 0,
		"border_width": 2.0,
		"border_color_top": Color(0.95, 0.84, 0.56, 0.92),
		"border_color_bot": Color(0.84, 0.65, 0.28, 0.90),
		"shadow_alpha": 0.65,
		"shadow_blur": 20.0,
	})
	bbg.position = Vector2(-bpad.x, -bpad.y)
	box.add_child(bbg)

	var title := _make_label("KELUAR DARI GAME?", _font_hero, 34, Color(1.0, 0.96, 0.86, 1.0), 0.8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20.0, 32.0)
	title.size = Vector2(440.0, 44.0)
	box.add_child(title)

	var sub := _make_label("Progres profil dan garasi Anda sudah tersimpan.", _font_sub, 20, Color(0.84, 0.83, 0.80, 0.92), 0.7)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(20.0, 84.0)
	sub.size = Vector2(440.0, 32.0)
	box.add_child(sub)

	var btn_cancel := Button.new()
	btn_cancel.text = "BATAL"
	btn_cancel.position = Vector2(68.0, 144.0)
	btn_cancel.size = Vector2(158.0, 48.0)
	if _font_nav:
		btn_cancel.add_theme_font_override("font", _font_nav)
	btn_cancel.add_theme_font_size_override("font_size", 24)
	btn_cancel.pressed.connect(func(): _exit_dialog.visible = false)
	box.add_child(btn_cancel)

	var btn_quit := Button.new()
	btn_quit.text = "KELUAR"
	btn_quit.position = Vector2(254.0, 144.0)
	btn_quit.size = Vector2(158.0, 48.0)
	if _font_nav:
		btn_quit.add_theme_font_override("font", _font_nav)
	btn_quit.add_theme_font_size_override("font_size", 24)
	btn_quit.pressed.connect(func():
		_exit_dialog.visible = false
		exit_pressed.emit()
	)
	box.add_child(btn_quit)

func _open_exit_dialog() -> void:
	if _exit_dialog:
		_exit_dialog.visible = true

# =============================================================================
# PUBLIC DATA BINDING API
# =============================================================================
func update_profile(nickname: String, level: int, current_xp: int, max_xp: int) -> void:
	var clean_name := nickname.strip_edges()
	if clean_name.is_empty() or clean_name == "''" or clean_name == "\"\"":
		clean_name = "Player_001"
	if _lbl_nickname:
		_lbl_nickname.text = clean_name
	if _lbl_level:
		_lbl_level.text = "Lv. %d" % max(1, level)
	var safe_max: int = max(1, max_xp)
	if _lbl_xp:
		_lbl_xp.text = "%d / %d" % [current_xp, safe_max]
	if _xp_fill:
		var ratio: float = clampf(float(current_xp) / float(safe_max), 0.0, 1.0)
		_xp_fill.size.x = maxf(0.0, (_xp_track_width - 2.0) * ratio)

func update_currency(coins: int, gems: int) -> void:
	if _lbl_coins:
		var c_str := _format_number(coins)
		_lbl_coins.text = c_str
		var fs := 31 if c_str.length() <= 7 else (26 if c_str.length() <= 10 else 22)
		_lbl_coins.add_theme_font_size_override("font_size", fs)
	if _lbl_gems:
		var g_str := _format_number(gems)
		_lbl_gems.text = g_str
		var fs := 31 if g_str.length() <= 6 else (26 if g_str.length() <= 9 else 22)
		_lbl_gems.add_theme_font_size_override("font_size", fs)

func _format_number(val: int) -> String:
	var s := str(abs(val))
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return ("-" if val < 0 else "") + res
