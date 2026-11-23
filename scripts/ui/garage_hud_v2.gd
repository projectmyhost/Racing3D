class_name GarageHudV2
extends Control

## AAA Need For Speed x HomeScreen HUD V2 Garage Overlay.
## 100% visual design parity with HomeHudV2:
## - ui_fade_skew_panel.gdshader SDF skewed fading-edge panels & specular gloss
## - Rajdhani-Bold / Rajdhani-SemiBold italic FontVariation typography
## - Hero Gold CTA buttons (slash_mode: 2) + Dark Smoked Translucent panels with champagne-gold borders
## - Open car-first 1920x1080 NFS Heat layout with Preview-Before-Equip 16-car carousel

signal back_pressed
signal car_preview_selected(car_id: String)
signal primary_cta_pressed
signal race_now_pressed
signal paint_swatch_selected(color: Color, swatch_name: String)
signal camera_preset_selected(preset_id: String)
signal reset_camera_pressed
signal view_mode_toggled(clean_mode: bool)

const PANEL_SHADER: Shader = preload("res://assets/shaders/ui_fade_skew_panel.gdshader")
const VehicleCatalogScript = preload("res://scripts/core/vehicle_catalog.gd")

const FONT_BOLD_PATH: String = "res://assets/ui/fonts/Rajdhani-Bold.ttf"
const FONT_SEMI_PATH: String = "res://assets/ui/fonts/Rajdhani-SemiBold.ttf"

const ICO_BACK: String = "res://assets/ui/icons/hud_v2_back.svg"
const ICO_COIN: String = "res://assets/ui/icons/hud_v2_coin.svg"
const ICO_GEM: String = "res://assets/ui/icons/hud_v2_gem.svg"
const ICO_EYE: String = "res://assets/ui/icons/hud_v2_eye.svg"
const ICO_RESET: String = "res://assets/ui/icons/hud_v2_reset.svg"
const ICO_PLAY: String = "res://assets/ui/icons/hud_v2_play.svg"
const ICO_GARAGE: String = "res://assets/ui/icons/hud_v2_garage.svg"
const ICO_CHECK: String = "res://assets/ui/icons/hud_v2_check.svg"
const ICO_LOCK: String = "res://assets/ui/icons/hud_v2_lock.svg"

const CAMERA_PRESETS_UI: Array[Dictionary] = [
	{"id": "hero_34", "label": "3/4 HERO"},
	{"id": "front", "label": "DEPAN"},
	{"id": "side", "label": "SAMPING"},
	{"id": "rear", "label": "BELAKANG"},
	{"id": "wheel", "label": "VELG"},
]

var _font_hero: FontVariation
var _font_nav: FontVariation
var _font_sub: FontVariation
var _font_clean: FontFile

var _hud_container: Control = null
var _view_exit_pill: Control = null
var _view_mode_active: bool = false
var _hud_fade_tween: Tween = null

# Top-left / Top-right refs
var _lbl_status_badge: Label = null
var _status_badge_bg: ColorRect = null
var _lbl_coins: Label = null
var _lbl_gems: Label = null

# Left telemetry card refs
var _lbl_tier: Label = null
var _lbl_car_name: Label = null
var _lbl_car_class: Label = null
var _lbl_car_desc: Label = null
var _lbl_specs: Label = null
var _lbl_paint_name: Label = null
var _stat_bars: Dictionary = {}
var _stat_bar_tweens: Dictionary = {}
var _paint_swatches_ui: Array[Dictionary] = []

# Right camera pills
var _cam_preset_ui: Dictionary = {}
var _active_cam_preset: String = "hero_34"

# Bottom carousel & CTA
var _carousel_scroll: ScrollContainer = null
var _carousel_hbox: HBoxContainer = null
var _carousel_cards: Dictionary = {}
var _cta_btn: Control = null
var _cta_bg: ColorRect = null
var _cta_icon: TextureRect = null
var _cta_label: Label = null
var _cta_sub_label: Label = null
var _equipped_chip: Control = null
var _loading_pill: Control = null
var _toast_box: Control = null
var _toast_label: Label = null
var _toast_tween: Tween = null

var _current_preview_id: String = "sedan"
var _current_equipped_id: String = "sedan"
var _current_unlocked: Array[String] = []
var _current_paint: Color = Color.WHITE

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_init_fonts()

	_hud_container = Control.new()
	_hud_container.name = "GarageHudContainer"
	_hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_container)

	_build_top_left_header()
	_build_top_right_controls()
	_build_left_telemetry_panel()
	_build_right_camera_presets()
	_build_bottom_carousel()
	_build_bottom_right_cta()
	_build_bottom_control_legend()
	_build_loading_and_toast()
	_build_view_mode_exit_pill()
	set_active_camera_preset("hero_34")

func _init_fonts() -> void:
	var bold_f := load(FONT_BOLD_PATH) as FontFile
	var semi_f := load(FONT_SEMI_PATH) as FontFile
	_font_clean = semi_f if semi_f else bold_f

	_font_hero = FontVariation.new()
	_font_hero.base_font = bold_f
	_font_hero.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.20, 1.0), Vector2.ZERO)
	_font_hero.variation_embolden = 0.28

	_font_nav = FontVariation.new()
	_font_nav.base_font = bold_f
	_font_nav.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.18, 1.0), Vector2.ZERO)
	_font_nav.variation_embolden = 0.14

	_font_sub = FontVariation.new()
	_font_sub.base_font = semi_f if semi_f else bold_f
	_font_sub.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.12, 1.0), Vector2.ZERO)
	_font_sub.variation_embolden = 0.04

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _make_shader_rect(total_size: Vector2, params: Dictionary) -> ColorRect:
	var cr := ColorRect.new()
	cr.size = total_size
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = PANEL_SHADER
	mat.set_shader_parameter("rect_size", total_size)
	for k in params.keys():
		mat.set_shader_parameter(String(k), params[k])
	cr.material = mat
	return cr

func _make_label(txt: String, font: Font, font_size: int, col: Color, shadow_alpha: float = 0.72) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", col)
	if shadow_alpha > 0.0:
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, shadow_alpha))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _wire_interactive(ctrl: Control, bg_rect: ColorRect, hover_shift_x: float, on_click: Callable) -> void:
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var base_x: float = ctrl.position.x
	var mat := bg_rect.material as ShaderMaterial if bg_rect else null

	ctrl.mouse_entered.connect(func():
		var tw := ctrl.create_tween().set_parallel(true)
		if mat:
			tw.tween_method(func(v: float): mat.set_shader_parameter("hover_t", v), 0.0, 1.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if absf(hover_shift_x) > 0.01:
			tw.tween_property(ctrl, "position:x", base_x + hover_shift_x, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	ctrl.mouse_exited.connect(func():
		var tw := ctrl.create_tween().set_parallel(true)
		if mat:
			tw.tween_method(func(v: float): mat.set_shader_parameter("hover_t", v), 1.0, 0.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if absf(hover_shift_x) > 0.01:
			tw.tween_property(ctrl, "position:x", base_x, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	ctrl.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					if mat:
						mat.set_shader_parameter("press_t", 1.0)
					ctrl.accept_event()
				else:
					if mat:
						mat.set_shader_parameter("press_t", 0.0)
					if ctrl.get_rect().has_point(ctrl.position + mb.position):
						on_click.call()
					ctrl.accept_event()
	)

# =============================================================================
# TOP-LEFT: KEMBALI + GARASI // SHOWCASE + LIVE OWNERSHIP BADGE
# =============================================================================
func _build_top_left_header() -> void:
	# Skewed KEMBALI button
	var back_btn := Control.new()
	back_btn.name = "BackBtnV2"
	back_btn.position = Vector2(36.0, 26.0)
	back_btn.size = Vector2(182.0, 56.0)
	_hud_container.add_child(back_btn)

	var bpad := Vector4(18.0, 14.0, 22.0, 16.0)
	var bbg := _make_shader_rect(back_btn.size + Vector2(bpad.x + bpad.z, bpad.y + bpad.w), {
		"padding": bpad,
		"skew_slope": 0.28,
		"corner_radius": 8.0,
		"color_tl": Color(0.15, 0.14, 0.15, 0.88),
		"color_tr": Color(0.10, 0.095, 0.105, 0.86),
		"color_bl": Color(0.07, 0.065, 0.075, 0.92),
		"color_br": Color(0.055, 0.052, 0.06, 0.90),
		"fade_mode": 0,
		"sheen_strength": 0.12,
		"top_gloss_strength": 0.08,
		"border_width": 1.7,
		"border_color_top": Color(0.92, 0.86, 0.72, 0.82),
		"border_color_bot": Color(0.84, 0.68, 0.36, 0.84),
		"glow_color": Color(0.95, 0.76, 0.34, 0.0),
		"glow_size": 10.0,
		"shadow_alpha": 0.50,
		"shadow_offset": Vector2(2.0, 5.0),
		"shadow_blur": 11.0,
	})
	bbg.position = Vector2(-bpad.x, -bpad.y)
	back_btn.add_child(bbg)

	var bico := TextureRect.new()
	bico.texture = _load_tex(ICO_BACK)
	bico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bico.position = Vector2(18.0, 14.0)
	bico.size = Vector2(28.0, 28.0)
	bico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.add_child(bico)

	var blbl := _make_label("KEMBALI", _font_nav, 26, Color(0.98, 0.97, 0.94, 1.0), 0.75)
	blbl.position = Vector2(54.0, 12.0)
	blbl.size = Vector2(120.0, 34.0)
	back_btn.add_child(blbl)
	_wire_interactive(back_btn, bbg, 4.0, func(): back_pressed.emit())

	# Header title chip: GARASI // SHOWCASE
	var title_box := Control.new()
	title_box.name = "HeaderChipV2"
	title_box.position = Vector2(236.0, 26.0)
	title_box.size = Vector2(362.0, 56.0)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_container.add_child(title_box)

	var tpad := Vector4(16.0, 12.0, 24.0, 14.0)
	var tbg := _make_shader_rect(title_box.size + Vector2(tpad.x + tpad.z, tpad.y + tpad.w), {
		"padding": tpad,
		"skew_slope": 0.28,
		"corner_radius": 8.0,
		"color_tl": Color(0.12, 0.115, 0.13, 0.84),
		"color_tr": Color(0.08, 0.08, 0.095, 0.35),
		"color_bl": Color(0.06, 0.058, 0.07, 0.88),
		"color_br": Color(0.045, 0.045, 0.055, 0.30),
		"fade_mode": 1,
		"fade_start": 0.62,
		"fade_end": 1.0,
		"border_width": 1.5,
		"border_color_top": Color(0.92, 0.82, 0.56, 0.72),
		"border_color_bot": Color(0.84, 0.65, 0.28, 0.68),
		"slash_mode": 1,
		"slash_color": Color(0.95, 0.76, 0.32, 0.90),
		"shadow_alpha": 0.44,
		"shadow_blur": 10.0,
	})
	tbg.position = Vector2(-tpad.x, -tpad.y)
	title_box.add_child(tbg)

	var gico := TextureRect.new()
	gico.texture = _load_tex(ICO_GARAGE)
	gico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gico.position = Vector2(20.0, 12.0)
	gico.size = Vector2(32.0, 32.0)
	gico.modulate = Color(0.98, 0.82, 0.34, 1.0)
	gico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.add_child(gico)

	var hlbl := _make_label("GARASI // SHOWCASE", _font_hero, 25, Color(1.0, 0.96, 0.88, 1.0), 0.82)
	hlbl.position = Vector2(60.0, 12.0)
	hlbl.size = Vector2(292.0, 34.0)
	title_box.add_child(hlbl)

	# Live Ownership Status Pill (clean spacing after skewed header chip)
	var sbox := Control.new()
	sbox.name = "OwnershipBadgeV2"
	sbox.position = Vector2(616.0, 34.0)
	sbox.size = Vector2(184.0, 40.0)
	sbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_container.add_child(sbox)

	var spad := Vector4(12.0, 10.0, 14.0, 12.0)
	_status_badge_bg = _make_shader_rect(sbox.size + Vector2(spad.x + spad.z, spad.y + spad.w), {
		"padding": spad,
		"skew_slope": 0.26,
		"corner_radius": 7.0,
		"color_tl": Color(0.08, 0.24, 0.16, 0.88),
		"color_tr": Color(0.05, 0.16, 0.11, 0.82),
		"color_bl": Color(0.04, 0.14, 0.09, 0.92),
		"color_br": Color(0.03, 0.10, 0.07, 0.88),
		"fade_mode": 0,
		"border_width": 1.6,
		"border_color_top": Color(0.32, 0.96, 0.58, 0.90),
		"border_color_bot": Color(0.18, 0.72, 0.42, 0.85),
		"shadow_alpha": 0.40,
		"shadow_blur": 8.0,
	})
	_status_badge_bg.position = Vector2(-spad.x, -spad.y)
	sbox.add_child(_status_badge_bg)

	_lbl_status_badge = _make_label("● TERPASANG", _font_nav, 19, Color(0.45, 1.0, 0.68, 1.0), 0.72)
	_lbl_status_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_status_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_status_badge.position = Vector2(6.0, 2.0)
	_lbl_status_badge.size = Vector2(172.0, 36.0)
	sbox.add_child(_lbl_status_badge)

# =============================================================================
# TOP-RIGHT: LIVE COIN/GEM PILLS + VIEW CAR (V) & RESET (R)
# =============================================================================
func _build_top_right_controls() -> void:
	# Coin & Gem smoked glass bar (matching HomeHudV2)
	var cur := Control.new()
	cur.name = "CurrencyBarV2"
	cur.position = Vector2(1272.0, 26.0)
	cur.size = Vector2(382.0, 56.0)
	cur.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_container.add_child(cur)

	var cpad := Vector4(16.0, 12.0, 16.0, 14.0)
	var cbg := _make_shader_rect(cur.size + Vector2(cpad.x + cpad.z, cpad.y + cpad.w), {
		"padding": cpad,
		"skew_slope": 0.24,
		"corner_radius": 10.0,
		"color_tl": Color(0.14, 0.13, 0.14, 0.86),
		"color_tr": Color(0.10, 0.095, 0.105, 0.84),
		"color_bl": Color(0.065, 0.06, 0.07, 0.92),
		"color_br": Color(0.055, 0.05, 0.06, 0.90),
		"fade_mode": 0,
		"sheen_strength": 0.10,
		"border_width": 1.6,
		"border_color_top": Color(0.90, 0.84, 0.68, 0.80),
		"border_color_bot": Color(0.84, 0.68, 0.36, 0.82),
		"shadow_alpha": 0.48,
		"shadow_blur": 11.0,
	})
	cbg.position = Vector2(-cpad.x, -cpad.y)
	cur.add_child(cbg)

	var coin_ico := TextureRect.new()
	coin_ico.texture = _load_tex(ICO_COIN)
	coin_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_ico.position = Vector2(18.0, 11.0)
	coin_ico.size = Vector2(34.0, 34.0)
	coin_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cur.add_child(coin_ico)

	_lbl_coins = _make_label("250,000", _font_hero, 27, Color(1.0, 0.94, 0.72, 1.0), 0.78)
	_lbl_coins.position = Vector2(60.0, 11.0)
	_lbl_coins.size = Vector2(148.0, 34.0)
	cur.add_child(_lbl_coins)

	var sep := ColorRect.new()
	sep.position = Vector2(216.0, 12.0)
	sep.size = Vector2(2.0, 32.0)
	sep.color = Color(0.86, 0.74, 0.44, 0.36)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cur.add_child(sep)

	var gem_ico := TextureRect.new()
	gem_ico.texture = _load_tex(ICO_GEM)
	gem_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_ico.position = Vector2(232.0, 11.0)
	gem_ico.size = Vector2(34.0, 34.0)
	gem_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cur.add_child(gem_ico)

	_lbl_gems = _make_label("500", _font_hero, 27, Color(0.68, 0.94, 1.0, 1.0), 0.78)
	_lbl_gems.position = Vector2(274.0, 11.0)
	_lbl_gems.size = Vector2(96.0, 34.0)
	cur.add_child(_lbl_gems)

	# VIEW CAR (V) tile
	var view_tile := _create_top_action_tile("ViewCarTileV2", Vector2(1672.0, 26.0), Vector2(102.0, 56.0), ICO_EYE, "VIEW", func():
		set_view_mode(not _view_mode_active)
	)
	_hud_container.add_child(view_tile)

	# RESET (R) tile
	var reset_tile := _create_top_action_tile("ResetCamTileV2", Vector2(1786.0, 26.0), Vector2(98.0, 56.0), ICO_RESET, "RESET", func():
		reset_camera_pressed.emit()
	)
	_hud_container.add_child(reset_tile)

func _create_top_action_tile(node_name: String, pos: Vector2, sz: Vector2, icon_path: String, caption: String, cb: Callable) -> Control:
	var tile := Control.new()
	tile.name = node_name
	tile.position = pos
	tile.size = sz

	var tpad := Vector4(14.0, 12.0, 14.0, 14.0)
	var tbg := _make_shader_rect(sz + Vector2(tpad.x + tpad.z, tpad.y + tpad.w), {
		"padding": tpad,
		"skew_slope": 0.24,
		"corner_radius": 10.0,
		"color_tl": Color(0.15, 0.14, 0.15, 0.86),
		"color_tr": Color(0.10, 0.095, 0.105, 0.86),
		"color_bl": Color(0.065, 0.06, 0.07, 0.92),
		"color_br": Color(0.055, 0.05, 0.06, 0.92),
		"fade_mode": 0,
		"sheen_strength": 0.12,
		"border_width": 1.6,
		"border_color_top": Color(0.88, 0.82, 0.68, 0.82),
		"border_color_bot": Color(0.84, 0.68, 0.36, 0.84),
		"shadow_alpha": 0.46,
		"shadow_blur": 10.0,
	})
	tbg.position = Vector2(-tpad.x, -tpad.y)
	tile.add_child(tbg)

	var ico := TextureRect.new()
	ico.texture = _load_tex(icon_path)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.position = Vector2(12.0, 14.0)
	ico.size = Vector2(26.0, 26.0)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(ico)

	var lbl := _make_label(caption, _font_nav, 18, Color(0.96, 0.94, 0.88, 1.0), 0.72)
	lbl.position = Vector2(40.0, 16.0)
	lbl.size = Vector2(sz.x - 44.0, 26.0)
	tile.add_child(lbl)

	_wire_interactive(tile, tbg, 0.0, cb)
	return tile

# =============================================================================
# LEFT COMPACT TELEMETRY & QUICK PAINT PANEL (~390px wide, open center preserved)
# =============================================================================
func _build_left_telemetry_panel() -> void:
	var panel := Control.new()
	panel.name = "VehicleSpecPanelV2"
	panel.position = Vector2(36.0, 126.0)
	panel.size = Vector2(394.0, 668.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_container.add_child(panel)

	var ppad := Vector4(20.0, 18.0, 24.0, 22.0)
	var pbg := _make_shader_rect(panel.size + Vector2(ppad.x + ppad.z, ppad.y + ppad.w), {
		"padding": ppad,
		"skew_slope": 0.06,
		"corner_radius": 12.0,
		"color_tl": Color(0.11, 0.105, 0.12, 0.86),
		"color_tr": Color(0.08, 0.078, 0.09, 0.72),
		"color_bl": Color(0.055, 0.052, 0.062, 0.90),
		"color_br": Color(0.045, 0.045, 0.055, 0.76),
		"fade_mode": 0,
		"sheen_strength": 0.08,
		"top_gloss_strength": 0.06,
		"border_width": 1.6,
		"border_color_top": Color(0.92, 0.84, 0.62, 0.78),
		"border_color_bot": Color(0.84, 0.66, 0.30, 0.76),
		"slash_mode": 1,
		"slash_color": Color(0.96, 0.76, 0.28, 0.92),
		"shadow_alpha": 0.56,
		"shadow_offset": Vector2(4.0, 8.0),
		"shadow_blur": 16.0,
	})
	pbg.position = Vector2(-ppad.x, -ppad.y)
	panel.add_child(pbg)

	# Tier pill
	_lbl_tier = _make_label("HYPER // CLASS", _font_nav, 15, Color(0.98, 0.78, 0.30, 1.0), 0.70)
	_lbl_tier.position = Vector2(26.0, 18.0)
	_lbl_tier.size = Vector2(342.0, 22.0)
	panel.add_child(_lbl_tier)

	# Car Title
	_lbl_car_name = _make_label("PORSCHE MISSION X", _font_hero, 33, Color(1.0, 0.98, 0.94, 1.0), 0.85)
	_lbl_car_name.position = Vector2(26.0, 40.0)
	_lbl_car_name.size = Vector2(346.0, 44.0)
	_lbl_car_name.clip_text = true
	panel.add_child(_lbl_car_name)

	# Class / Engine Subtitle
	_lbl_car_class = _make_label("Next-Gen Hypercar Concept | 900V EV", _font_sub, 14, Color(0.88, 0.84, 0.74, 0.94), 0.65)
	_lbl_car_class.position = Vector2(26.0, 82.0)
	_lbl_car_class.size = Vector2(342.0, 34.0)
	_lbl_car_class.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_car_class.clip_text = true
	panel.add_child(_lbl_car_class)

	# Short Description (3 lines max)
	_lbl_car_desc = _make_label("", _font_clean, 13, Color(0.80, 0.82, 0.86, 0.88), 0.55)
	_lbl_car_desc.position = Vector2(26.0, 118.0)
	_lbl_car_desc.size = Vector2(342.0, 62.0)
	_lbl_car_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_car_desc.clip_text = true
	panel.add_child(_lbl_car_desc)

	_add_gold_divider(panel, 184.0, 344.0)

	# 4 Animated Telemetry Stat Bars
	var stats_meta: Array[Dictionary] = [
		{"key": "speed", "title": "TOP SPEED"},
		{"key": "accel", "title": "AKSELERASI"},
		{"key": "power", "title": "TENAGA (BHP)"},
		{"key": "handling", "title": "HANDLING"},
	]
	var y_bar: float = 198.0
	for sm in stats_meta:
		var k: String = String(sm["key"])
		var t_lbl := _make_label(String(sm["title"]), _font_nav, 15, Color(0.86, 0.84, 0.78, 0.92), 0.60)
		t_lbl.position = Vector2(26.0, y_bar)
		t_lbl.size = Vector2(180.0, 20.0)
		panel.add_child(t_lbl)

		var v_lbl := _make_label("0", _font_hero, 17, Color(1.0, 0.90, 0.58, 1.0), 0.72)
		v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v_lbl.position = Vector2(206.0, y_bar - 1.0)
		v_lbl.size = Vector2(162.0, 22.0)
		panel.add_child(v_lbl)

		var track := ColorRect.new()
		track.position = Vector2(26.0, y_bar + 24.0)
		track.size = Vector2(342.0, 9.0)
		track.color = Color(0.06, 0.065, 0.08, 0.92)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(track)

		var fill := ColorRect.new()
		fill.position = Vector2(1.0, 1.0)
		fill.size = Vector2(220.0, 7.0)
		fill.color = Color(0.98, 0.76, 0.24, 1.0)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)

		var gloss := ColorRect.new()
		gloss.position = Vector2(0.0, 0.0)
		gloss.size = Vector2(220.0, 2.5)
		gloss.color = Color(1.0, 0.95, 0.72, 0.55)
		gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.add_child(gloss)

		_stat_bars[k] = {
			"val_lbl": v_lbl,
			"fill": fill,
			"gloss": gloss,
			"max_w": 340.0,
		}
		y_bar += 47.0

	_add_gold_divider(panel, 392.0, 344.0)

	# Compact Tech Specs
	var spec_hdr := _make_label("SPESIFIKASI TEKNIS", _font_nav, 14, Color(0.95, 0.78, 0.36, 0.95), 0.60)
	spec_hdr.position = Vector2(26.0, 404.0)
	spec_hdr.size = Vector2(342.0, 20.0)
	panel.add_child(spec_hdr)

	_lbl_specs = _make_label("", _font_clean, 13, Color(0.78, 0.81, 0.86, 0.90), 0.50)
	_lbl_specs.position = Vector2(26.0, 426.0)
	_lbl_specs.size = Vector2(342.0, 62.0)
	_lbl_specs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_specs.clip_text = true
	panel.add_child(_lbl_specs)

	_add_gold_divider(panel, 496.0, 344.0)

	# Quick Metallic Paint Swatches (ORIGINAL + 8 colors)
	var paint_hdr := _make_label("WARNA CAT // LIVERY", _font_nav, 15, Color(0.95, 0.78, 0.36, 0.95), 0.65)
	paint_hdr.position = Vector2(26.0, 508.0)
	paint_hdr.size = Vector2(200.0, 22.0)
	panel.add_child(paint_hdr)

	_lbl_paint_name = _make_label("ORIGINAL", _font_sub, 15, Color(0.94, 0.94, 0.92, 0.92), 0.60)
	_lbl_paint_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_paint_name.position = Vector2(220.0, 508.0)
	_lbl_paint_name.size = Vector2(148.0, 22.0)
	panel.add_child(_lbl_paint_name)

	_paint_swatches_ui.clear()
	var sw_idx: int = 0
	for sw in VehicleCatalogScript.PAINT_SWATCHES:
		var col_i: int = sw_idx % 5
		var row_i: int = sw_idx / 5
		var sw_btn := Control.new()
		sw_btn.name = "PaintSwatch_" + String(sw["id"])
		sw_btn.position = Vector2(26.0 + float(col_i) * 69.0, 540.0 + float(row_i) * 54.0)
		sw_btn.size = Vector2(60.0, 42.0)
		sw_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		sw_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.add_child(sw_btn)

		var ring := ColorRect.new()
		ring.position = Vector2(0.0, 0.0)
		ring.size = sw_btn.size
		ring.color = Color(0.84, 0.74, 0.48, 0.42)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sw_btn.add_child(ring)

		var chip := ColorRect.new()
		chip.position = Vector2(3.0, 3.0)
		chip.size = sw_btn.size - Vector2(6.0, 6.0)
		chip.color = sw["swatch"]
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sw_btn.add_child(chip)

		if String(sw["id"]) == "original":
			var o_lbl := _make_label("ORIG", _font_nav, 13, Color(0.10, 0.10, 0.12, 1.0), 0.0)
			o_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			o_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			o_lbl.size = chip.size
			chip.add_child(o_lbl)

		var target_col: Color = sw["color"]
		var target_nm: String = String(sw["name"])
		sw_btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton:
				var mb := ev as InputEventMouseButton
				if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
					paint_swatch_selected.emit(target_col, target_nm)
					sw_btn.accept_event()
		)
		_paint_swatches_ui.append({
			"color": target_col,
			"name": target_nm,
			"ring": ring,
		})
		sw_idx += 1

func _add_gold_divider(parent_ctrl: Control, y_pos: float, width: float) -> void:
	var line := ColorRect.new()
	line.position = Vector2(26.0, y_pos)
	line.size = Vector2(width, 1.5)
	line.color = Color(0.88, 0.74, 0.40, 0.34)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_ctrl.add_child(line)

# =============================================================================
# FAR-RIGHT FLOATING CAMERA ANGLE PILLS (3/4, DEPAN, SAMPING, BELAKANG, VELG)
# =============================================================================
func _build_right_camera_presets() -> void:
	var col_box := Control.new()
	col_box.name = "CameraPresetsV2"
	col_box.position = Vector2(1736.0, 300.0)
	col_box.size = Vector2(148.0, 320.0)
	col_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_container.add_child(col_box)

	var hdr := _make_label("KAMERA", _font_nav, 15, Color(0.95, 0.78, 0.36, 0.92), 0.75)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hdr.position = Vector2(0.0, 0.0)
	hdr.size = Vector2(142.0, 22.0)
	col_box.add_child(hdr)

	var y_off: float = 28.0
	for p in CAMERA_PRESETS_UI:
		var pid: String = String(p["id"])
		var plbl: String = String(p["label"])
		var btn := Control.new()
		btn.name = "CamPreset_" + pid
		btn.position = Vector2(0.0, y_off)
		btn.size = Vector2(148.0, 44.0)
		col_box.add_child(btn)

		var pad := Vector4(12.0, 8.0, 12.0, 10.0)
		var bg := _make_shader_rect(btn.size + Vector2(pad.x + pad.z, pad.y + pad.w), {
			"padding": pad,
			"skew_slope": 0.24,
			"corner_radius": 7.0,
			"color_tl": Color(0.13, 0.125, 0.14, 0.84),
			"color_tr": Color(0.09, 0.088, 0.10, 0.84),
			"color_bl": Color(0.06, 0.058, 0.068, 0.90),
			"color_br": Color(0.05, 0.048, 0.058, 0.90),
			"fade_mode": 0,
			"border_width": 1.5,
			"border_color_top": Color(0.84, 0.78, 0.64, 0.65),
			"border_color_bot": Color(0.76, 0.62, 0.36, 0.65),
			"shadow_alpha": 0.42,
			"shadow_blur": 8.0,
		})
		bg.position = Vector2(-pad.x, -pad.y)
		btn.add_child(bg)

		var txt := _make_label(plbl, _font_nav, 18, Color(0.94, 0.92, 0.88, 0.95), 0.70)
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		txt.size = btn.size
		btn.add_child(txt)

		_wire_interactive(btn, bg, -4.0, func(): camera_preset_selected.emit(pid))
		_cam_preset_ui[pid] = {"btn": btn, "bg": bg, "lbl": txt}
		y_off += 54.0

func set_active_camera_preset(preset_id: String) -> void:
	_active_cam_preset = preset_id
	for pid in _cam_preset_ui.keys():
		var item: Dictionary = _cam_preset_ui[pid]
		var mat := (item["bg"] as ColorRect).material as ShaderMaterial
		var lbl := item["lbl"] as Label
		var active: bool = (String(pid) == preset_id)
		if mat:
			if active:
				mat.set_shader_parameter("color_tl", Color(0.96, 0.80, 0.28, 0.96))
				mat.set_shader_parameter("color_tr", Color(0.90, 0.68, 0.18, 0.92))
				mat.set_shader_parameter("color_bl", Color(0.88, 0.60, 0.10, 0.96))
				mat.set_shader_parameter("color_br", Color(0.78, 0.50, 0.08, 0.92))
				mat.set_shader_parameter("border_color_top", Color(1.0, 0.96, 0.76, 0.98))
				mat.set_shader_parameter("border_color_bot", Color(0.98, 0.76, 0.24, 0.96))
			else:
				mat.set_shader_parameter("color_tl", Color(0.13, 0.125, 0.14, 0.84))
				mat.set_shader_parameter("color_tr", Color(0.09, 0.088, 0.10, 0.84))
				mat.set_shader_parameter("color_bl", Color(0.06, 0.058, 0.068, 0.90))
				mat.set_shader_parameter("color_br", Color(0.05, 0.048, 0.058, 0.90))
				mat.set_shader_parameter("border_color_top", Color(0.84, 0.78, 0.64, 0.65))
				mat.set_shader_parameter("border_color_bot", Color(0.76, 0.62, 0.36, 0.65))
		if lbl:
			lbl.add_theme_color_override("font_color", Color(0.10, 0.09, 0.07, 1.0) if active else Color(0.94, 0.92, 0.88, 0.95))

# =============================================================================
# BOTTOM NFS HORIZONTAL 16-CAR CAROUSEL (PREVIEW-BEFORE-EQUIP)
# =============================================================================
func _build_bottom_carousel() -> void:
	var dock := Control.new()
	dock.name = "BottomCarouselV2"
	dock.position = Vector2(36.0, 868.0)
	dock.size = Vector2(1414.0, 148.0)
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_container.add_child(dock)

	# Prev arrow button
	var prev_btn := _create_carousel_arrow_btn("CarouselPrevBtn", Vector2(0.0, 18.0), "<", func():
		var idx: int = VehicleCatalogScript.get_index_of(_current_preview_id)
		var target: String = VehicleCatalogScript.ORDER[posmod(idx - 1, VehicleCatalogScript.ORDER.size())]
		car_preview_selected.emit(target)
	)
	dock.add_child(prev_btn)

	# Horizontal ScrollContainer
	_carousel_scroll = ScrollContainer.new()
	_carousel_scroll.name = "FleetScrollV2"
	_carousel_scroll.position = Vector2(54.0, 4.0)
	_carousel_scroll.size = Vector2(1306.0, 140.0)
	_carousel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_carousel_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_carousel_scroll.follow_focus = false
	dock.add_child(_carousel_scroll)

	_carousel_hbox = HBoxContainer.new()
	_carousel_hbox.name = "FleetHBoxV2"
	_carousel_hbox.add_theme_constant_override("separation", 14)
	_carousel_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_carousel_scroll.add_child(_carousel_hbox)

	_carousel_cards.clear()
	for car_id in VehicleCatalogScript.ORDER:
		var cdata: Dictionary = VehicleCatalogScript.get_car_data(car_id)
		var card_wrap := Control.new()
		card_wrap.name = "CardWrap_" + car_id
		card_wrap.custom_minimum_size = Vector2(196.0, 132.0)
		card_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_carousel_hbox.add_child(card_wrap)

		var card := Control.new()
		card.name = "Card_" + car_id
		card.position = Vector2(4.0, 14.0)
		card.size = Vector2(188.0, 108.0)
		card_wrap.add_child(card)

		var cpad := Vector4(12.0, 10.0, 12.0, 12.0)
		var cbg := _make_shader_rect(card.size + Vector2(cpad.x + cpad.z, cpad.y + cpad.w), {
			"padding": cpad,
			"skew_slope": 0.14,
			"corner_radius": 9.0,
			"color_tl": Color(0.14, 0.135, 0.15, 0.88),
			"color_tr": Color(0.10, 0.095, 0.11, 0.86),
			"color_bl": Color(0.065, 0.06, 0.072, 0.94),
			"color_br": Color(0.052, 0.05, 0.062, 0.92),
			"fade_mode": 0,
			"sheen_strength": 0.10,
			"border_width": 1.6,
			"border_color_top": Color(0.76, 0.72, 0.62, 0.64),
			"border_color_bot": Color(0.68, 0.56, 0.34, 0.62),
			"glow_color": Color(0.98, 0.76, 0.24, 0.0),
			"glow_size": 10.0,
			"shadow_alpha": 0.48,
			"shadow_blur": 10.0,
		})
		cbg.position = Vector2(-cpad.x, -cpad.y)
		card.add_child(cbg)

		var stripe := ColorRect.new()
		stripe.position = Vector2(12.0, 0.0)
		stripe.size = Vector2(164.0, 3.0)
		stripe.color = Color(0.84, 0.68, 0.32, 0.45)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(stripe)

		var tier_lbl := _make_label(String(cdata.get("tier", "STREET")), _font_nav, 13, Color(0.96, 0.78, 0.32, 0.95), 0.60)
		tier_lbl.position = Vector2(14.0, 10.0)
		tier_lbl.size = Vector2(82.0, 18.0)
		card.add_child(tier_lbl)

		var status_lbl := _make_label("DIMILIKI", _font_nav, 12, Color(0.42, 0.84, 1.0, 0.95), 0.60)
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_lbl.position = Vector2(86.0, 10.0)
		status_lbl.size = Vector2(90.0, 18.0)
		card.add_child(status_lbl)

		var lock_ico := TextureRect.new()
		lock_ico.texture = _load_tex(ICO_LOCK)
		lock_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_ico.position = Vector2(158.0, 36.0)
		lock_ico.size = Vector2(18.0, 18.0)
		lock_ico.modulate = Color(1.0, 0.82, 0.32, 0.90)
		lock_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_ico.visible = false
		card.add_child(lock_ico)

		var nm_lbl := _make_label(String(cdata.get("short_name", cdata["name"])), _font_hero, 21, Color(0.99, 0.98, 0.95, 1.0), 0.78)
		nm_lbl.position = Vector2(14.0, 33.0)
		nm_lbl.size = Vector2(150.0, 28.0)
		nm_lbl.clip_text = true
		card.add_child(nm_lbl)

		var stat_micro := _make_label(
			"%s  •  %s" % [String(cdata["top_speed"]), String(cdata["power"])],
			_font_clean, 13, Color(0.76, 0.79, 0.85, 0.88), 0.50
		)
		stat_micro.position = Vector2(14.0, 62.0)
		stat_micro.size = Vector2(162.0, 18.0)
		card.add_child(stat_micro)

		var price_lbl := _make_label(String(cdata["price"]), _font_nav, 13, Color(0.98, 0.82, 0.34, 0.95), 0.60)
		price_lbl.position = Vector2(14.0, 82.0)
		price_lbl.size = Vector2(162.0, 18.0)
		card.add_child(price_lbl)

		var target_id: String = car_id
		_wire_interactive(card, cbg, 0.0, func(): car_preview_selected.emit(target_id))

		_carousel_cards[car_id] = {
			"wrap": card_wrap,
			"card": card,
			"bg": cbg,
			"stripe": stripe,
			"status_lbl": status_lbl,
			"price_lbl": price_lbl,
			"lock_ico": lock_ico,
		}

	# Next arrow button
	var next_btn := _create_carousel_arrow_btn("CarouselNextBtn", Vector2(1368.0, 18.0), ">", func():
		var idx: int = VehicleCatalogScript.get_index_of(_current_preview_id)
		var target: String = VehicleCatalogScript.ORDER[posmod(idx + 1, VehicleCatalogScript.ORDER.size())]
		car_preview_selected.emit(target)
	)
	dock.add_child(next_btn)

func _create_carousel_arrow_btn(node_name: String, pos: Vector2, glyph: String, cb: Callable) -> Control:
	var btn := Control.new()
	btn.name = node_name
	btn.position = pos
	btn.size = Vector2(44.0, 108.0)

	var pad := Vector4(10.0, 10.0, 10.0, 10.0)
	var bg := _make_shader_rect(btn.size + Vector2(pad.x + pad.z, pad.y + pad.w), {
		"padding": pad,
		"skew_slope": 0.14,
		"corner_radius": 8.0,
		"color_tl": Color(0.15, 0.14, 0.15, 0.88),
		"color_tr": Color(0.10, 0.095, 0.105, 0.88),
		"color_bl": Color(0.065, 0.06, 0.07, 0.92),
		"color_br": Color(0.055, 0.05, 0.06, 0.92),
		"fade_mode": 0,
		"border_width": 1.6,
		"border_color_top": Color(0.90, 0.82, 0.60, 0.78),
		"border_color_bot": Color(0.84, 0.66, 0.30, 0.80),
		"shadow_alpha": 0.45,
		"shadow_blur": 8.0,
	})
	bg.position = Vector2(-pad.x, -pad.y)
	btn.add_child(bg)

	var lbl := _make_label(glyph, _font_hero, 30, Color(0.98, 0.86, 0.44, 1.0), 0.72)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = btn.size
	btn.add_child(lbl)

	_wire_interactive(btn, bg, 0.0, cb)
	return btn

# =============================================================================
# BOTTOM-RIGHT HERO GOLD CTA (MATCHING HomeHudV2 PlayBtnV2)
# =============================================================================
func _build_bottom_right_cta() -> void:
	# Equipped confirmation chip above CTA when already equipped
	_equipped_chip = Control.new()
	_equipped_chip.name = "EquippedChipV2"
	_equipped_chip.position = Vector2(1506.0, 846.0)
	_equipped_chip.size = Vector2(378.0, 34.0)
	_equipped_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equipped_chip.visible = false
	_hud_container.add_child(_equipped_chip)

	var epad := Vector4(10.0, 8.0, 10.0, 8.0)
	var ebg := _make_shader_rect(_equipped_chip.size + Vector2(epad.x + epad.z, epad.y + epad.w), {
		"padding": epad,
		"skew_slope": 0.24,
		"corner_radius": 7.0,
		"color_tl": Color(0.07, 0.26, 0.16, 0.90),
		"color_tr": Color(0.04, 0.16, 0.10, 0.86),
		"color_bl": Color(0.04, 0.14, 0.09, 0.94),
		"color_br": Color(0.03, 0.10, 0.06, 0.90),
		"fade_mode": 0,
		"border_width": 1.5,
		"border_color_top": Color(0.36, 0.98, 0.62, 0.92),
		"border_color_bot": Color(0.18, 0.72, 0.42, 0.88),
		"shadow_alpha": 0.35,
		"shadow_blur": 8.0,
	})
	ebg.position = Vector2(-epad.x, -epad.y)
	_equipped_chip.add_child(ebg)

	var elbl := _make_label("TERPASANG ✓  //  SIAP BALAP", _font_nav, 17, Color(0.52, 1.0, 0.72, 1.0), 0.70)
	elbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	elbl.size = _equipped_chip.size
	_equipped_chip.add_child(elbl)

	# Hero Gold CTA button (identical shader language to PlayBtnV2)
	_cta_btn = Control.new()
	_cta_btn.name = "PrimaryCtaBtnV2"
	_cta_btn.position = Vector2(1476.0, 892.0)
	_cta_btn.size = Vector2(408.0, 96.0)
	_hud_container.add_child(_cta_btn)

	var cpad := Vector4(24.0, 18.0, 26.0, 22.0)
	_cta_bg = _make_shader_rect(_cta_btn.size + Vector2(cpad.x + cpad.z, cpad.y + cpad.w), {
		"padding": cpad,
		"skew_slope": 0.28,
		"corner_radius": 10.0,
		"color_tl": Color(0.99, 0.87, 0.36, 0.99),
		"color_tr": Color(0.94, 0.74, 0.24, 0.96),
		"color_bl": Color(0.92, 0.66, 0.12, 0.99),
		"color_br": Color(0.82, 0.54, 0.10, 0.94),
		"fade_mode": 0,
		"sheen_strength": 0.22,
		"top_gloss_strength": 0.18,
		"border_width": 2.0,
		"border_color_top": Color(1.00, 0.96, 0.78, 0.96),
		"border_color_bot": Color(0.96, 0.76, 0.26, 0.92),
		"slash_mode": 2,
		"slash_color": Color(0.14, 0.11, 0.06, 0.75),
		"glow_color": Color(1.00, 0.76, 0.20, 0.42),
		"glow_size": 16.0,
		"shadow_alpha": 0.58,
		"shadow_offset": Vector2(3.0, 7.0),
		"shadow_blur": 15.0,
	})
	_cta_bg.position = Vector2(-cpad.x, -cpad.y)
	_cta_btn.add_child(_cta_bg)

	_cta_icon = TextureRect.new()
	_cta_icon.texture = _load_tex(ICO_PLAY)
	_cta_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cta_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cta_icon.position = Vector2(30.0, 26.0)
	_cta_icon.size = Vector2(40.0, 40.0)
	_cta_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cta_btn.add_child(_cta_icon)

	_cta_label = _make_label("BALAP SEKARANG", _font_hero, 34, Color(0.11, 0.095, 0.075, 1.0), 0.0)
	_cta_label.position = Vector2(82.0, 17.0)
	_cta_label.size = Vector2(310.0, 42.0)
	_cta_btn.add_child(_cta_label)

	_cta_sub_label = _make_label("Luncurkan mobil terpasang ke sirkuit", _font_sub, 15, Color(0.16, 0.12, 0.06, 0.88), 0.0)
	_cta_sub_label.position = Vector2(82.0, 58.0)
	_cta_sub_label.size = Vector2(310.0, 22.0)
	_cta_btn.add_child(_cta_sub_label)

	_wire_interactive(_cta_btn, _cta_bg, -4.0, func(): primary_cta_pressed.emit())

func _build_bottom_control_legend() -> void:
	var legend := _make_label(
		"DRAG: PUTAR 360°   •   SCROLL: ZOOM   •   ← / →: PILIH MOBIL   •   V: VIEW CAR   •   R: RESET   •   ESC: KEMBALI",
		_font_sub, 14, Color(0.84, 0.86, 0.90, 0.72), 0.75
	)
	legend.position = Vector2(42.0, 1036.0)
	legend.size = Vector2(1100.0, 24.0)
	_hud_container.add_child(legend)

func _build_loading_and_toast() -> void:
	# Subtle loading shimmer pill
	_loading_pill = Control.new()
	_loading_pill.name = "LoadingPillV2"
	_loading_pill.position = Vector2(810.0, 32.0)
	_loading_pill.size = Vector2(300.0, 40.0)
	_loading_pill.visible = false
	_loading_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loading_pill)

	var lpad := Vector4(12.0, 10.0, 12.0, 10.0)
	var lbg := _make_shader_rect(_loading_pill.size + Vector2(lpad.x + lpad.z, lpad.y + lpad.w), {
		"padding": lpad,
		"skew_slope": 0.24,
		"corner_radius": 8.0,
		"color_tl": Color(0.14, 0.12, 0.10, 0.92),
		"color_bl": Color(0.08, 0.07, 0.06, 0.94),
		"fade_mode": 0,
		"border_width": 1.6,
		"border_color_top": Color(0.98, 0.84, 0.36, 0.92),
		"border_color_bot": Color(0.86, 0.64, 0.18, 0.90),
	})
	lbg.position = Vector2(-lpad.x, -lpad.y)
	_loading_pill.add_child(lbg)

	var llbl := _make_label("MEMUAT KENDARAAN...", _font_nav, 18, Color(1.0, 0.88, 0.42, 1.0), 0.72)
	llbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	llbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	llbl.size = _loading_pill.size
	_loading_pill.add_child(llbl)

	# Toast Notification
	_toast_box = Control.new()
	_toast_box.name = "ToastV2"
	_toast_box.position = Vector2(680.0, 96.0)
	_toast_box.size = Vector2(560.0, 46.0)
	_toast_box.visible = false
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)

	var tpad := Vector4(14.0, 10.0, 14.0, 12.0)
	var tbg := _make_shader_rect(_toast_box.size + Vector2(tpad.x + tpad.z, tpad.y + tpad.w), {
		"padding": tpad,
		"skew_slope": 0.22,
		"corner_radius": 9.0,
		"color_tl": Color(0.13, 0.12, 0.14, 0.94),
		"color_tr": Color(0.10, 0.095, 0.11, 0.92),
		"color_bl": Color(0.06, 0.058, 0.07, 0.96),
		"color_br": Color(0.05, 0.048, 0.06, 0.94),
		"fade_mode": 0,
		"border_width": 1.8,
		"border_color_top": Color(0.98, 0.84, 0.36, 0.92),
		"border_color_bot": Color(0.86, 0.64, 0.22, 0.88),
		"shadow_alpha": 0.56,
		"shadow_blur": 12.0,
	})
	tbg.position = Vector2(-tpad.x, -tpad.y)
	_toast_box.add_child(tbg)

	_toast_label = _make_label("", _font_nav, 20, Color(1.0, 0.96, 0.84, 1.0), 0.72)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.size = _toast_box.size
	_toast_box.add_child(_toast_label)

func _build_view_mode_exit_pill() -> void:
	_view_exit_pill = Control.new()
	_view_exit_pill.name = "ExitViewModePillV2"
	_view_exit_pill.position = Vector2(1656.0, 26.0)
	_view_exit_pill.size = Vector2(228.0, 50.0)
	_view_exit_pill.visible = false
	add_child(_view_exit_pill)

	var vpad := Vector4(14.0, 10.0, 14.0, 12.0)
	var vbg := _make_shader_rect(_view_exit_pill.size + Vector2(vpad.x + vpad.z, vpad.y + vpad.w), {
		"padding": vpad,
		"skew_slope": 0.24,
		"corner_radius": 9.0,
		"color_tl": Color(0.14, 0.13, 0.15, 0.82),
		"color_bl": Color(0.06, 0.058, 0.07, 0.88),
		"fade_mode": 0,
		"border_width": 1.6,
		"border_color_top": Color(0.96, 0.82, 0.40, 0.88),
		"border_color_bot": Color(0.84, 0.64, 0.24, 0.84),
		"shadow_alpha": 0.44,
		"shadow_blur": 10.0,
	})
	vbg.position = Vector2(-vpad.x, -vpad.y)
	_view_exit_pill.add_child(vbg)

	var vico := TextureRect.new()
	vico.texture = _load_tex(ICO_EYE)
	vico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vico.position = Vector2(16.0, 12.0)
	vico.size = Vector2(26.0, 26.0)
	vico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view_exit_pill.add_child(vico)

	var vlbl := _make_label("TAMPILKAN HUD (V)", _font_nav, 18, Color(1.0, 0.94, 0.78, 1.0), 0.72)
	vlbl.position = Vector2(48.0, 13.0)
	vlbl.size = Vector2(172.0, 26.0)
	_view_exit_pill.add_child(vlbl)

	_wire_interactive(_view_exit_pill, vbg, 0.0, func(): set_view_mode(false))

# =============================================================================
# PUBLIC DATA BINDING & VIEW MODE API
# =============================================================================
func refresh_state(
	preview_id: String,
	equipped_id: String,
	unlocked: Array[String],
	coins: int,
	gems: int,
	paint_color: Color
) -> void:
	_current_preview_id = preview_id
	_current_equipped_id = equipped_id
	_current_unlocked = unlocked
	_current_paint = paint_color

	update_currency(coins, gems)
	set_active_paint_color(paint_color)

	var cdata: Dictionary = VehicleCatalogScript.get_car_data(preview_id)
	var is_equipped: bool = (preview_id == equipped_id)
	var is_owned: bool = unlocked.has(preview_id)

	# Left Telemetry Panel
	if _lbl_tier:
		_lbl_tier.text = "%s // CLASS" % String(cdata.get("tier", "STREET"))
	if _lbl_car_name:
		var cname: String = String(cdata["name"])
		_lbl_car_name.text = cname
		var nfs: int = 32 if cname.length() <= 15 else (27 if cname.length() <= 19 else 24)
		_lbl_car_name.add_theme_font_size_override("font_size", nfs)
	if _lbl_car_class:
		_lbl_car_class.text = String(cdata["class"])
	if _lbl_car_desc:
		_lbl_car_desc.text = String(cdata["desc"])
	if _lbl_specs:
		_lbl_specs.text = String(cdata["specs"])

	_animate_stat_bar("speed", float(cdata["ratio_speed"]), String(cdata["top_speed"]))
	_animate_stat_bar("accel", float(cdata["ratio_accel"]), String(cdata["accel"]))
	_animate_stat_bar("power", float(cdata["ratio_power"]), String(cdata["power"]))
	_animate_stat_bar("handling", float(cdata["ratio_handling"]), String(cdata["handling"]))

	# Top-Left Ownership Badge
	_update_ownership_badge(is_equipped, is_owned)

	# Bottom-Right Primary CTA
	_update_primary_cta(cdata, is_equipped, is_owned)

	# Bottom 16-Car Carousel highlights
	_update_carousel_cards(preview_id, equipped_id, unlocked)
	_scroll_carousel_to(preview_id)

func _animate_stat_bar(key: String, ratio: float, readout: String) -> void:
	if not _stat_bars.has(key):
		return
	var entry: Dictionary = _stat_bars[key]
	var lbl := entry["val_lbl"] as Label
	var fill := entry["fill"] as ColorRect
	var gloss := entry["gloss"] as ColorRect
	var max_w: float = float(entry["max_w"])
	if lbl:
		lbl.text = readout
	var target_w: float = maxf(6.0, max_w * clampf(ratio, 0.0, 1.0))
	if _stat_bar_tweens.has(key):
		var old_tw: Tween = _stat_bar_tweens[key]
		if old_tw and old_tw.is_valid():
			old_tw.kill()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fill, "size:x", target_w, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(gloss, "size:x", target_w, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_stat_bar_tweens[key] = tw

func _update_ownership_badge(is_equipped: bool, is_owned: bool) -> void:
	if not _lbl_status_badge or not _status_badge_bg:
		return
	var mat := _status_badge_bg.material as ShaderMaterial
	if is_equipped:
		_lbl_status_badge.text = "● TERPASANG"
		_lbl_status_badge.add_theme_color_override("font_color", Color(0.45, 1.0, 0.68, 1.0))
		if mat:
			mat.set_shader_parameter("color_tl", Color(0.08, 0.24, 0.16, 0.88))
			mat.set_shader_parameter("color_bl", Color(0.04, 0.14, 0.09, 0.92))
			mat.set_shader_parameter("border_color_top", Color(0.32, 0.96, 0.58, 0.90))
			mat.set_shader_parameter("border_color_bot", Color(0.18, 0.72, 0.42, 0.85))
	elif is_owned:
		_lbl_status_badge.text = "DIMILIKI"
		_lbl_status_badge.add_theme_color_override("font_color", Color(0.56, 0.88, 1.0, 1.0))
		if mat:
			mat.set_shader_parameter("color_tl", Color(0.08, 0.18, 0.26, 0.88))
			mat.set_shader_parameter("color_bl", Color(0.04, 0.10, 0.16, 0.92))
			mat.set_shader_parameter("border_color_top", Color(0.42, 0.82, 1.0, 0.90))
			mat.set_shader_parameter("border_color_bot", Color(0.24, 0.58, 0.88, 0.85))
	else:
		_lbl_status_badge.text = "TERKUNCI"
		_lbl_status_badge.add_theme_color_override("font_color", Color(1.0, 0.82, 0.36, 1.0))
		if mat:
			mat.set_shader_parameter("color_tl", Color(0.22, 0.15, 0.06, 0.88))
			mat.set_shader_parameter("color_bl", Color(0.14, 0.09, 0.04, 0.92))
			mat.set_shader_parameter("border_color_top", Color(0.98, 0.80, 0.32, 0.90))
			mat.set_shader_parameter("border_color_bot", Color(0.84, 0.58, 0.16, 0.85))

func _update_primary_cta(cdata: Dictionary, is_equipped: bool, is_owned: bool) -> void:
	if not _cta_label or not _cta_sub_label or not _cta_icon:
		return
	if _equipped_chip:
		_equipped_chip.visible = is_equipped
	if is_equipped:
		_cta_icon.texture = _load_tex(ICO_PLAY)
		_cta_label.text = "BALAP SEKARANG"
		_cta_label.add_theme_font_size_override("font_size", 33)
		_cta_sub_label.text = "Langsung tancap gas ke sirkuit kota"
	elif is_owned:
		_cta_icon.texture = _load_tex(ICO_CHECK)
		_cta_label.text = "EQUIP MOBIL"
		_cta_label.add_theme_font_size_override("font_size", 34)
		_cta_sub_label.text = "Preview aktif — klik untuk pasang ke garasi"
	else:
		_cta_icon.texture = _load_tex(ICO_COIN)
		var price_str: String = VehicleCatalogScript.format_price(cdata)
		_cta_label.text = "BELI // " + price_str
		_cta_label.add_theme_font_size_override("font_size", 26 if price_str.length() > 11 else 30)
		_cta_sub_label.text = "Buka & langsung pasang " + String(cdata["short_name"])

func _update_carousel_cards(preview_id: String, equipped_id: String, unlocked: Array[String]) -> void:
	for cid in _carousel_cards.keys():
		var item: Dictionary = _carousel_cards[cid]
		var card := item["card"] as Control
		var bg := item["bg"] as ColorRect
		var mat := bg.material as ShaderMaterial
		var stripe := item["stripe"] as ColorRect
		var st_lbl := item["status_lbl"] as Label
		var pr_lbl := item["price_lbl"] as Label
		var lk_ico := item["lock_ico"] as TextureRect

		var is_prev: bool = (String(cid) == preview_id)
		var is_eq: bool = (String(cid) == equipped_id)
		var is_own: bool = unlocked.has(String(cid))

		# Smooth lift on active preview card
		var target_y: float = 4.0 if is_prev else 14.0
		if absf(card.position.y - target_y) > 0.5:
			var tw := card.create_tween()
			tw.tween_property(card, "position:y", target_y, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		if is_eq:
			st_lbl.text = "TERPASANG"
			st_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.68, 1.0))
			pr_lbl.text = "AKTIF DI GARASI"
			pr_lbl.add_theme_color_override("font_color", Color(0.45, 0.96, 0.68, 0.92))
			lk_ico.visible = false
			stripe.color = Color(0.32, 0.96, 0.58, 0.95)
		elif is_own:
			st_lbl.text = "DIMILIKI"
			st_lbl.add_theme_color_override("font_color", Color(0.54, 0.88, 1.0, 0.95))
			pr_lbl.text = "SIAP DIPASANG"
			pr_lbl.add_theme_color_override("font_color", Color(0.68, 0.84, 0.96, 0.88))
			lk_ico.visible = false
			stripe.color = Color(0.98, 0.78, 0.28, 0.90) if is_prev else Color(0.40, 0.76, 0.98, 0.60)
		else:
			var cdata: Dictionary = VehicleCatalogScript.get_car_data(String(cid))
			st_lbl.text = "TERKUNCI"
			st_lbl.add_theme_color_override("font_color", Color(0.98, 0.78, 0.34, 0.92))
			pr_lbl.text = VehicleCatalogScript.format_price(cdata)
			pr_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32, 0.95))
			lk_ico.visible = true
			stripe.color = Color(0.98, 0.78, 0.28, 0.92) if is_prev else Color(0.70, 0.58, 0.34, 0.42)

		if mat:
			if is_prev:
				mat.set_shader_parameter("color_tl", Color(0.24, 0.20, 0.14, 0.94))
				mat.set_shader_parameter("color_tr", Color(0.18, 0.15, 0.11, 0.92))
				mat.set_shader_parameter("color_bl", Color(0.12, 0.10, 0.08, 0.96))
				mat.set_shader_parameter("color_br", Color(0.09, 0.08, 0.065, 0.94))
				mat.set_shader_parameter("border_width", 2.2)
				mat.set_shader_parameter("border_color_top", Color(1.0, 0.90, 0.52, 0.98))
				mat.set_shader_parameter("border_color_bot", Color(0.96, 0.70, 0.18, 0.96))
				mat.set_shader_parameter("glow_color", Color(0.98, 0.76, 0.22, 0.36))
			else:
				mat.set_shader_parameter("color_tl", Color(0.14, 0.135, 0.15, 0.86))
				mat.set_shader_parameter("color_tr", Color(0.10, 0.095, 0.11, 0.84))
				mat.set_shader_parameter("color_bl", Color(0.065, 0.06, 0.072, 0.92))
				mat.set_shader_parameter("color_br", Color(0.052, 0.05, 0.062, 0.90))
				mat.set_shader_parameter("border_width", 1.5)
				mat.set_shader_parameter("border_color_top", Color(0.76, 0.72, 0.62, 0.60))
				mat.set_shader_parameter("border_color_bot", Color(0.68, 0.56, 0.34, 0.58))
				mat.set_shader_parameter("glow_color", Color(0.98, 0.76, 0.22, 0.0))

func _scroll_carousel_to(car_id: String) -> void:
	if not _carousel_scroll:
		return
	var idx: int = VehicleCatalogScript.get_index_of(car_id)
	var card_stride: float = 210.0
	var target_x: float = maxf(0.0, float(idx) * card_stride - (_carousel_scroll.size.x * 0.5) + (card_stride * 0.5))
	var max_scroll: float = maxf(0.0, float(VehicleCatalogScript.ORDER.size()) * card_stride - _carousel_scroll.size.x)
	target_x = clampf(target_x, 0.0, max_scroll)
	var tw := create_tween()
	tw.tween_property(_carousel_scroll, "scroll_horizontal", int(round(target_x)), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_active_paint_color(color: Color) -> void:
	_current_paint = color
	var matched_name: String = "CUSTOM"
	for item in _paint_swatches_ui:
		var c: Color = item["color"]
		var ring := item["ring"] as ColorRect
		var is_match: bool = c.is_equal_approx(color)
		if is_match:
			matched_name = String(item["name"])
		if ring:
			ring.color = Color(1.0, 0.88, 0.34, 1.0) if is_match else Color(0.84, 0.74, 0.48, 0.36)
	if _lbl_paint_name:
		_lbl_paint_name.text = matched_name

func update_currency(coins: int, gems: int) -> void:
	if _lbl_coins:
		var cs: String = VehicleCatalogScript.format_number(coins)
		_lbl_coins.text = cs
		var fs: int = 27 if cs.length() <= 7 else (23 if cs.length() <= 10 else 19)
		_lbl_coins.add_theme_font_size_override("font_size", fs)
	if _lbl_gems:
		var gs: String = VehicleCatalogScript.format_number(gems)
		_lbl_gems.text = gs

func set_loading_visible(is_loading: bool) -> void:
	if _loading_pill:
		_loading_pill.visible = is_loading

func show_toast(msg: String) -> void:
	if not _toast_box or not _toast_label:
		return
	_toast_label.text = msg
	_toast_box.visible = true
	_toast_box.modulate.a = 0.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_box, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast_box, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_toast_tween.tween_callback(func(): _toast_box.visible = false)

func is_view_mode_active() -> bool:
	return _view_mode_active

func set_view_mode(clean_mode: bool) -> void:
	_view_mode_active = clean_mode
	if _hud_fade_tween and _hud_fade_tween.is_valid():
		_hud_fade_tween.kill()
	_hud_fade_tween = create_tween()
	if clean_mode:
		_hud_fade_tween.tween_property(_hud_container, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_hud_fade_tween.tween_callback(func(): _hud_container.visible = false)
		if _view_exit_pill:
			_view_exit_pill.visible = true
			_view_exit_pill.modulate.a = 0.0
			var ptw := create_tween()
			ptw.tween_property(_view_exit_pill, "modulate:a", 1.0, 0.22)
	else:
		_hud_container.visible = true
		_hud_fade_tween.tween_property(_hud_container, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if _view_exit_pill:
			_view_exit_pill.visible = false
	view_mode_toggled.emit(clean_mode)
