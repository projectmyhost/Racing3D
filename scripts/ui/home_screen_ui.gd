class_name HomeScreenUI
extends Control

const HomeHudV2Script = preload("res://scripts/ui/home_hud_v2.gd")
const VehicleCatalogScript = preload("res://scripts/core/vehicle_catalog.gd")
const GARAGE_3D_SCENE_PATH = "res://scenes/garage/Garage3D.tscn"
const ProfileCardWidget = preload("res://scripts/ui/profile_card_widget.gd")
const TopNavBar = preload("res://scripts/ui/top_nav_bar.gd")
const CurrencyBar = preload("res://scripts/ui/currency_bar.gd")
const SettingsHexBtn = preload("res://scripts/ui/settings_hex_btn.gd")
const NotifPingWidget = preload("res://scripts/ui/notif_ping_widget.gd")
const EventCardUI = preload("res://scripts/ui/event_card_ui.gd")
const FriendsCardUI = preload("res://scripts/ui/friends_card_ui.gd")
const DailyMissionsUI = preload("res://scripts/ui/daily_missions_ui.gd")
const MailBtnUI = preload("res://scripts/ui/mail_btn_ui.gd")
const NewsBannerUI = preload("res://scripts/ui/news_banner_ui.gd")
const SeasonPassUI = preload("res://scripts/ui/season_pass_ui.gd")

## HomeScreen UI Controller conforming to DESIGN.md and user specifications.
## Implements 4-tab academic settings, multi-car fleet dealership, and motorsport HUD.

signal play_pressed
signal settings_pressed
signal garage_pressed
signal tuning_pressed
signal paint_shop_pressed
signal profile_pressed
signal back_pressed
signal paint_color_selected(color: Color)
signal car_equipped(car_id: String)

# HUD References
@onready var hud_root: Control = %HUD
@onready var profile_card: Control = %ProfileCard
@onready var avatar_rect: TextureRect = %AvatarRect
@onready var nickname_label: Label = %NicknameLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var xp_label: Label = %XPLabel
@onready var currency_pill: Control = %CurrencyPill
@onready var coin_label: Label = %CoinLabel
@onready var gem_label: Label = %GemLabel
@onready var gear_btn: TextureButton = %SettingsGearBtn

# Nav Buttons
@onready var play_btn: Control = %PlayBtn
@onready var settings_btn: Control = %SettingsBtn
@onready var garage_btn: Control = %GarageBtn
@onready var tuning_btn: Control = %TuningBtn
@onready var paint_shop_btn: Control = %PaintShopBtn
@onready var profile_btn: Control = %ProfileBtn

# Pages / Modals
@onready var pages_layer: Control = %PagesLayer
@onready var settings_modal: Control = %SettingsModal
@onready var profile_modal: Control = %ProfileModal
@onready var topup_modal: Control = %TopupModal
@onready var garage_modal: Control = %GarageModal
@onready var tuning_modal: Control = %TuningModal
@onready var paint_shop_modal: Control = %PaintShopModal
@onready var play_modal: Control = %PlayModal
@onready var toast_panel: Panel = %ToastPanel
@onready var toast_label: Label = %ToastLabel

# Profile Modal Inputs
@onready var profile_name_edit: LineEdit = %ProfileNameEdit
@onready var profile_save_btn: Button = %ProfileSaveBtn
@onready var profile_cancel_btn: Button = %ProfileCancelBtn

# Settings Modal Controls
@onready var quality_option: OptionButton = %QualityOption
@onready var fps_option: OptionButton = %FpsOption
@onready var window_option: OptionButton = %WindowOption
@onready var master_slider: HSlider = %MasterSlider
@onready var engine_slider: HSlider = %EngineSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var ambience_slider: HSlider = %AmbienceSlider
@onready var music_slider: HSlider = %MusicSlider

# Settings Tabs
@onready var tab_btn_display: Button = %TabBtnDisplay
@onready var tab_btn_audio: Button = %TabBtnAudio
@onready var tab_btn_assists: Button = %TabBtnAssists
@onready var tab_btn_project: Button = %TabBtnProject
@onready var tab_panel_display: Control = %TabPanelDisplay
@onready var tab_panel_audio: Control = %TabPanelAudio
@onready var tab_panel_assists: Control = %TabPanelAssists
@onready var tab_panel_project: Control = %TabPanelProject

# Garage Modal Controls
@onready var garage_car_list: VBoxContainer = %GarageCarList
@onready var garage_car_title: Label = %GarageCarTitle
@onready var garage_car_class: Label = %GarageCarClass
@onready var garage_car_desc: Label = %GarageCarDesc
@onready var garage_bar_top_speed: ProgressBar = %GarageBarTopSpeed
@onready var garage_bar_top_speed_val: Label = %GarageBarTopSpeedVal
@onready var garage_bar_accel: ProgressBar = %GarageBarAccel
@onready var garage_bar_accel_val: Label = %GarageBarAccelVal
@onready var garage_bar_power: ProgressBar = %GarageBarPower
@onready var garage_bar_power_val: Label = %GarageBarPowerVal
@onready var garage_bar_handling: ProgressBar = %GarageBarHandling
@onready var garage_bar_handling_val: Label = %GarageBarHandlingVal
@onready var garage_spec_details: Label = %GarageSpecDetails
@onready var garage_status_label: Label = %GarageStatusLabel
@onready var garage_action_btn: Button = %GarageActionBtn

var _nav_buttons: Array[Control] = []
var _current_focus_index: int = 0
var _active_modal: Control = null
var _profile_autoload: Node
var _toast_tween: Tween
var _profile_widget: ProfileCardWidget = null
var _currency_widget: CurrencyBar = null
var _hud_v2: HomeHudV2 = null

# Active selected car in garage preview
var _garage_selected_car_id: String = "sedan"
var _garage_transitioning: bool = false

const GARAGE_FLEET_DATA = VehicleCatalogScript.FLEET_DATA

func _get_profile() -> Node:
	if not _profile_autoload and has_node("/root/PlayerProfile"):
		_profile_autoload = get_node("/root/PlayerProfile")
	return _profile_autoload

func _ready() -> void:
	# Ensure UI containers allow mouse drags through to 3D orbit camera
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hud_root:
		hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if toast_panel:
		toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if profile_card:
		profile_card.visible = false

	var left_grad = get_node_or_null("LeftLegibilityGradient")
	if left_grad:
		left_grad.visible = false
	var bot_grad = get_node_or_null("BottomGradient")
	if bot_grad:
		bot_grad.visible = false

	_nav_buttons = [play_btn, settings_btn, garage_btn, tuning_btn, paint_shop_btn, profile_btn]
	_connect_hud_signals()
	_connect_modal_buttons()
	_apply_fps_index(_selected_fps_index)
	_connect_settings_tabs()
	_connect_garage_system()
	_setup_reference_widgets()
	_bind_player_profile()
	if avatar_rect and not avatar_rect.texture and ResourceLoader.exists("res://assets/ui/icons/avatar_pilot_racing.png"):
		avatar_rect.texture = load("res://assets/ui/icons/avatar_pilot_racing.png")
	
	var prof = _get_profile()
	if prof:
		prof.connect("profile_updated", _on_profile_updated)
		prof.connect("currency_changed", _on_currency_changed)
		
	_on_profile_updated()
	_close_all_modals()
	
	if _hud_v2 and _hud_v2.play_button:
		_hud_v2.play_button.grab_focus()
	elif play_btn:
		play_btn.grab_focus()

func _exit_tree() -> void:
	var prof = _get_profile()
	if prof:
		if prof.is_connected("profile_updated", _on_profile_updated):
			prof.disconnect("profile_updated", _on_profile_updated)
		if prof.is_connected("currency_changed", _on_currency_changed):
			prof.disconnect("currency_changed", _on_currency_changed)

func _open_garage_3d() -> void:
	if _garage_transitioning:
		return
	if not ResourceLoader.exists(GARAGE_3D_SCENE_PATH):
		_refresh_garage_ui()
		open_modal(garage_modal)
		return
	_garage_transitioning = true
	var fade := ColorRect.new()
	fade.name = "GarageFadeTransition"
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade.z_index = 100
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_inside_tree():
			get_tree().change_scene_to_file(GARAGE_3D_SCENE_PATH)
	)

func _setup_reference_widgets() -> void:
	if not hud_root: return

	# Hide legacy HUD controls while keeping nodes intact for @onready & tests
	for legacy_ctrl in [profile_card, currency_pill, gear_btn, play_btn, settings_btn, garage_btn, tuning_btn, paint_shop_btn, profile_btn]:
		if legacy_ctrl:
			legacy_ctrl.visible = false

	# Clean any old spawned widgets from HUD
	for old_name in ["TopNavBar", "CurBG", "NotifPill", "MSPingLabel", "LimitedTimeEventCard",
			"OnlineFriendsCard", "DailyMissionsCard", "MailCard", "NewsBanner", "VersionLabel", "SeasonPassCard",
			"NativeEventCard", "NativeFriendsCard", "NativeProfileCard", "NativeTopNavBar", "NativeCurrencyBar",
			"NativeHexGear", "NativeNotifPing", "NativeDailyMissions", "NativeMailBtn", "NativeNewsBanner", "NativeSeasonPass"]:
		var old_node = hud_root.get_node_or_null(old_name)
		if old_node:
			old_node.queue_free()

	_profile_widget = null
	_currency_widget = null

	# Mount clean rebuilt HomeHudV2 (100% procedural SDF shaders + vector SVGs + 3D car art)
	_hud_v2 = hud_root.get_node_or_null("HomeHudV2") as HomeHudV2
	if not _hud_v2:
		_hud_v2 = HomeHudV2Script.new()
		_hud_v2.name = "HomeHudV2"
		hud_root.add_child(_hud_v2)
		_hud_v2.play_pressed.connect(func():
			play_pressed.emit()
			open_modal(play_modal)
		)
		_hud_v2.garage_pressed.connect(func():
			garage_pressed.emit()
			_open_garage_3d()
		)
		_hud_v2.settings_pressed.connect(func():
			settings_pressed.emit()
			open_modal(settings_modal)
		)
		_hud_v2.shop_pressed.connect(func():
			open_modal(topup_modal)
		)
		_hud_v2.leaderboard_pressed.connect(func():
			show_toast("Leaderboard Global Musim Ini — Segera Hadir!")
		)
		_hud_v2.profile_pressed.connect(func():
			profile_pressed.emit()
			open_modal(profile_modal)
		)
		_hud_v2.topup_pressed.connect(func():
			open_modal(topup_modal)
		)
		_hud_v2.mail_pressed.connect(func():
			show_toast("Kotak Masuk: 1 pesan belum dibaca.")
		)
		_hud_v2.stats_pressed.connect(func():
			open_modal(profile_modal)
		)
		_hud_v2.gift_pressed.connect(func():
			show_toast("Hadiah Harian: Bonus Login tersedia!")
		)
		_hud_v2.exit_pressed.connect(func():
			get_tree().quit()
		)

	if _hud_v2 and not _hud_v2.nav_buttons.is_empty():
		_nav_buttons = _hud_v2.nav_buttons

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img = Image.load_from_file(path)
	if img and not img.is_empty():
		return ImageTexture.create_from_image(img)
	return null

func _connect_hud_signals() -> void:
	if play_btn:
		play_btn.pressed.connect(func(): open_modal(play_modal))
	if settings_btn:
		settings_btn.pressed.connect(func(): open_modal(settings_modal))
	if garage_btn:
		garage_btn.pressed.connect(func():
			garage_pressed.emit()
			_open_garage_3d()
		)
	if tuning_btn:
		tuning_btn.pressed.connect(func(): open_modal(tuning_modal))
	if paint_shop_btn:
		paint_shop_btn.pressed.connect(func(): open_modal(paint_shop_modal))
	if profile_btn:
		profile_btn.pressed.connect(func(): open_modal(profile_modal))
		
	# Clicking profile card in HUD opens profile page
	if profile_card and profile_card.has_signal("gui_input"):
		profile_card.gui_input.connect(_on_profile_card_input)
		
	# Clicking currency pill in HUD opens topup store
	if currency_pill and currency_pill.has_signal("gui_input"):
		currency_pill.gui_input.connect(_on_currency_pill_input)
		
	if gear_btn:
		gear_btn.pressed.connect(func(): open_modal(settings_modal))

func _on_profile_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open_modal(profile_modal)

func _on_currency_pill_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open_modal(topup_modal)

func _find_all_buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if not node:
		return result
	if node is Button:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_buttons(child))
	return result

static var _selected_fps_index: int = 1

func _connect_modal_buttons() -> void:
	# Profile Save / Cancel
	if profile_save_btn:
		profile_save_btn.pressed.connect(_on_profile_save_pressed)
	if profile_cancel_btn:
		profile_cancel_btn.pressed.connect(_on_profile_cancel_pressed)
		
	# Settings Quality & Display
	if quality_option:
		if has_node("/root/QualitySettings"):
			var qs = get_node("/root/QualitySettings")
			var tier_idx: int = clampi(int(qs.current_tier), 0, quality_option.item_count - 1)
			quality_option.select(tier_idx)
			qs.tier_changed.connect(func(new_tier):
				if is_instance_valid(quality_option):
					var clamped := clampi(int(new_tier), 0, quality_option.item_count - 1)
					if quality_option.selected != clamped:
						quality_option.select(clamped)
			)
		quality_option.item_selected.connect(_on_quality_selected)
	if fps_option:
		if _selected_fps_index >= 0 and _selected_fps_index < fps_option.item_count:
			fps_option.select(_selected_fps_index)
		fps_option.item_selected.connect(_on_fps_selected)
	if window_option:
		window_option.item_selected.connect(_on_window_mode_selected)
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)

	# Settings Audio Sliders
	if music_slider:
		music_slider.value_changed.connect(func(val):
			var bus_idx = AudioServer.get_bus_index("Music")
			if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
		)
	if sfx_slider:
		sfx_slider.value_changed.connect(func(val):
			var bus_idx = AudioServer.get_bus_index("SFX")
			if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
		)
	if engine_slider:
		engine_slider.value_changed.connect(func(val):
			var bus_idx = AudioServer.get_bus_index("SFX")
			if bus_idx != -1: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))
		)

	# Wire all Close Buttons across all modals: [X] CLOSE
	if pages_layer:
		for b in _find_all_buttons(pages_layer):
			var txt = b.text.to_upper()
			if txt.contains("CLOSE") or txt.contains("[X]") or b.name.to_lower().contains("close"):
				if not b.pressed.is_connected(close_modal):
					b.pressed.connect(close_modal)

	# Play Modal Race Modes
	if play_modal:
		for b in _find_all_buttons(play_modal):
			if b.text.contains("GRAND PRIX"):
				b.pressed.connect(func():
					show_toast("[OK] Initializing Grand Prix 3D Circuit...")
					get_tree().change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")
				)
			elif b.text.contains("TIME TRIAL"):
				b.pressed.connect(func():
					show_toast("[OK] Loading Ghost Telemetry for Time Trial...")
					get_tree().change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")
				)
			elif b.text.contains("SPRINT RACE") or b.text.contains("STREET"):
				b.pressed.connect(func():
					show_toast("[OK] Starting Waterfront Street Sprint...")
					get_tree().change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")
				)

	# Topup Modal Packages
	if topup_modal:
		for b in _find_all_buttons(topup_modal):
			if b.text.contains("+10K"):
				b.pressed.connect(func(): perform_topup(10000, 0, "STARTER PACK"))
			elif b.text.contains("+50K"):
				b.pressed.connect(func(): perform_topup(50000, 50, "RACER PACK"))
			elif b.text.contains("+250K"):
				b.pressed.connect(func(): perform_topup(250000, 250, "PRO MOTORSPORT"))
			elif b.text.contains("+100 GEMS"):
				b.pressed.connect(func(): perform_topup(0, 100, "GEM POUCH"))
			elif b.text.contains("+500 GEMS"):
				b.pressed.connect(func(): perform_topup(0, 500, "GEM CHEST"))
			elif b.text.contains("+1M"):
				b.pressed.connect(func(): perform_topup(1000000, 1000, "ULTIMATE VAULT"))

	# Tuning Modal Apply
	if tuning_modal:
		for b in _find_all_buttons(tuning_modal):
			if b.text.contains("APPLY"):
				b.pressed.connect(func():
					show_toast("[OK] Telemetry & Downforce Setup Saved!")
					close_modal()
				)

	# Paint Shop Modal Swatches
	if paint_shop_modal:
		for b in _find_all_buttons(paint_shop_modal):
			if b.text == "APPLY":
				var swatch_col: Color = Color(0.063, 0.094, 0.157, 1.0)
				var parent_node = b.get_parent()
				if parent_node:
					for child in parent_node.get_children():
						if child is ColorRect:
							swatch_col = child.color
							break
				b.pressed.connect(func(): select_paint_color(swatch_col))

# =============================================================================
# SETTINGS TABS SWITCHING
# =============================================================================
func _connect_settings_tabs() -> void:
	if tab_btn_display:
		tab_btn_display.pressed.connect(func(): _switch_settings_tab(0))
	if tab_btn_audio:
		tab_btn_audio.pressed.connect(func(): _switch_settings_tab(1))
	if tab_btn_assists:
		tab_btn_assists.pressed.connect(func(): _switch_settings_tab(2))
	if tab_btn_project:
		tab_btn_project.pressed.connect(func(): _switch_settings_tab(3))

func _switch_settings_tab(tab_index: int) -> void:
	if tab_panel_display: tab_panel_display.visible = (tab_index == 0)
	if tab_panel_audio: tab_panel_audio.visible = (tab_index == 1)
	if tab_panel_assists: tab_panel_assists.visible = (tab_index == 2)
	if tab_panel_project: tab_panel_project.visible = (tab_index == 3)

# =============================================================================
# GARAGE DEALERSHIP & FLEET SYSTEM
# =============================================================================
func _connect_garage_system() -> void:
	if not garage_modal: return
	
	if garage_car_list:
		for child in garage_car_list.get_children():
			child.queue_free()
			
		var font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
		var font_semi = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")
		
		for car_id in GARAGE_FLEET_DATA.keys():
			var car_info = GARAGE_FLEET_DATA[car_id]
			var btn = Button.new()
			btn.name = "CarSelect_" + car_id
			btn.custom_minimum_size = Vector2(360, 84)
			btn.flat = true
			
			var s_norm = StyleBoxFlat.new()
			s_norm.bg_color = Color(0.04, 0.08, 0.16, 0.85)
			s_norm.border_width_left = 4
			s_norm.border_color = Color(0.2, 0.5, 0.9, 0.6)
			s_norm.corner_radius_top_left = 6
			s_norm.corner_radius_top_right = 6
			s_norm.corner_radius_bottom_right = 6
			s_norm.corner_radius_bottom_left = 6
			btn.add_theme_stylebox_override("normal", s_norm)
			
			var s_hov = s_norm.duplicate()
			s_hov.bg_color = Color(0.08, 0.16, 0.32, 0.95)
			s_hov.border_color = Color(0.3, 0.7, 1.0, 1.0)
			s_hov.border_width_left = 6
			btn.add_theme_stylebox_override("hover", s_hov)
			
			var s_press = s_norm.duplicate()
			s_press.bg_color = Color(0.12, 0.24, 0.48, 0.95)
			btn.add_theme_stylebox_override("pressed", s_press)
			
			var name_lbl = Label.new()
			name_lbl.name = "NameLabel"
			name_lbl.text = car_info["name"]
			name_lbl.position = Vector2(16, 8)
			if font_bold: name_lbl.add_theme_font_override("font", font_bold)
			name_lbl.add_theme_font_size_override("font_size", 18)
			name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			btn.add_child(name_lbl)
			
			var class_lbl = Label.new()
			class_lbl.name = "ClassLabel"
			class_lbl.text = car_info["class"]
			class_lbl.position = Vector2(16, 32)
			if font_semi: class_lbl.add_theme_font_override("font", font_semi)
			class_lbl.add_theme_font_size_override("font_size", 12)
			class_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85, 0.8))
			btn.add_child(class_lbl)
			
			var ptag = Label.new()
			ptag.name = "PriceTag"
			ptag.text = car_info["price"]
			ptag.position = Vector2(16, 54)
			if font_bold: ptag.add_theme_font_override("font", font_bold)
			ptag.add_theme_font_size_override("font_size", 13)
			ptag.add_theme_color_override("font_color", Color(1.0, 0.788, 0.157, 1.0))
			btn.add_child(ptag)
			
			var target_id = car_id
			btn.pressed.connect(func():
				_garage_selected_car_id = target_id
				var showcase = _get_showcase_car()
				if showcase and showcase.has_method("load_car_model"):
					showcase.load_car_model(target_id)
				_refresh_garage_ui()
			)
			garage_car_list.add_child(btn)
			
	if garage_action_btn:
		garage_action_btn.pressed.connect(_on_garage_action_pressed)

func _refresh_garage_ui() -> void:
	var prof = _get_profile()
	var p: PlayerProfileData = prof.get("data") if prof else null
	if not p and ResourceLoader.exists("res://data/player_profile.tres"):
		p = load("res://data/player_profile.tres") as PlayerProfileData
	
	var equipped = p.equipped_car if p else "sedan"
	var unlocked = p.unlocked_cars if p else ["sedan"]
	
	# Update left list badges
	for car_id in GARAGE_FLEET_DATA.keys():
		var btn = garage_modal.find_child("CarSelect_" + car_id, true, false) as Button
		if btn:
			var ptag = btn.find_child("PriceTag", true, false) as Label
			if ptag:
				if car_id == equipped:
					ptag.text = "[EQUIPPED]"
					ptag.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1.0))
				elif unlocked.has(car_id):
					ptag.text = "[OWNED]"
					ptag.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0, 1.0))
				else:
					var cd = GARAGE_FLEET_DATA[car_id]
					ptag.text = cd.get("price", "LOCKED")
					ptag.add_theme_color_override("font_color", Color(1.0, 0.788, 0.157, 1.0))
					
	# Update right panel details for _garage_selected_car_id
	if not GARAGE_FLEET_DATA.has(_garage_selected_car_id):
		_garage_selected_car_id = "sedan"
	var car = GARAGE_FLEET_DATA[_garage_selected_car_id]
	
	if garage_car_title: garage_car_title.text = car["name"]
	if garage_car_class: garage_car_class.text = car["class"]
	if garage_car_desc: garage_car_desc.text = car["desc"]
	if garage_bar_top_speed: garage_bar_top_speed.value = car["ratio_speed"]
	if garage_bar_top_speed_val: garage_bar_top_speed_val.text = car["top_speed"]
	if garage_bar_accel: garage_bar_accel.value = car["ratio_accel"]
	if garage_bar_accel_val: garage_bar_accel_val.text = car["accel"]
	if garage_bar_power: garage_bar_power.value = car["ratio_power"]
	if garage_bar_power_val: garage_bar_power_val.text = car["power"]
	if garage_bar_handling: garage_bar_handling.value = car["ratio_handling"]
	if garage_bar_handling_val: garage_bar_handling_val.text = car["handling"]
	if garage_spec_details: garage_spec_details.text = car["specs"]
	
	# Status & Action Button State
	if _garage_selected_car_id == equipped:
		if garage_status_label:
			garage_status_label.text = "STATUS: [CURRENTLY EQUIPPED FOR RACE]"
			garage_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1.0))
		if garage_action_btn:
			garage_action_btn.text = "[EQUIPPED]"
			garage_action_btn.disabled = true
	elif unlocked.has(_garage_selected_car_id):
		if garage_status_label:
			garage_status_label.text = "STATUS: [OWNED | READY TO EQUIP]"
			garage_status_label.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0, 1.0))
		if garage_action_btn:
			garage_action_btn.text = "[EQUIP THIS VEHICLE]"
			garage_action_btn.disabled = false
	else:
		if garage_status_label:
			garage_status_label.text = "STATUS: [LOCKED | REQUIRES PURCHASE]"
			garage_status_label.add_theme_color_override("font_color", Color(1.0, 0.788, 0.157, 1.0))
		if garage_action_btn:
			if car["cost_coins"] > 0:
				garage_action_btn.text = "[PURCHASE - %s COINS]" % _format_number(car["cost_coins"])
			else:
				garage_action_btn.text = "[PURCHASE - %d GEMS]" % car["cost_gems"]
			garage_action_btn.disabled = false

func _on_garage_action_pressed() -> void:
	var prof = _get_profile()
	if not prof: return
	var p: PlayerProfileData = prof.data
	if not p: return
	
	var car = GARAGE_FLEET_DATA.get(_garage_selected_car_id)
	if not car: return
	
	if p.equipped_car == _garage_selected_car_id:
		return
	elif p.unlocked_cars.has(_garage_selected_car_id):
		prof.equip_car(_garage_selected_car_id)
		if has_node("/root/SaveManager"):
			var sm = get_node("/root/SaveManager")
			if sm.has_method("select_car"):
				sm.select_car(_garage_selected_car_id)
		var showcase = _get_showcase_car()
		if showcase and showcase.has_method("load_car_model") and showcase.get("current_model") != _garage_selected_car_id:
			showcase.load_car_model(_garage_selected_car_id)
		car_equipped.emit(_garage_selected_car_id)
		show_toast("[OK] Equipped " + car["name"] + " for race!")
		_refresh_garage_ui()
	else:
		var cost_c = car["cost_coins"]
		var cost_g = car["cost_gems"]
		if p.coins >= cost_c and p.gems >= cost_g:
			var success = prof.buy_car(_garage_selected_car_id, cost_c, cost_g)
			if success:
				if has_node("/root/SaveManager"):
					var sm = get_node("/root/SaveManager")
					if sm.has_method("unlock_car"):
						sm.unlock_car(_garage_selected_car_id)
					if sm.has_method("select_car"):
						sm.select_car(_garage_selected_car_id)
				var showcase = _get_showcase_car()
				if showcase and showcase.has_method("load_car_model"):
					showcase.load_car_model(_garage_selected_car_id)
				car_equipped.emit(_garage_selected_car_id)
				show_toast("[OK] Purchased and equipped " + car["name"] + "!")
				_refresh_garage_ui()
		else:
			var missing = ""
			if p.coins < cost_c: missing = str(cost_c - p.coins) + " Coins"
			if p.gems < cost_g:
				if not missing.is_empty(): missing += " and "
				missing += str(cost_g - p.gems) + " Gems"
			show_toast("[!] Insufficient funds! Need " + missing + ". Visit Top-Up.")

# =============================================================================
# PROFILE & HUD BINDINGS
# =============================================================================
func _bind_player_profile() -> void:
	var prof = _get_profile()
	var p: PlayerProfileData = prof.get("data") if prof else null
	if not p and ResourceLoader.exists("res://data/player_profile.tres"):
		p = load("res://data/player_profile.tres") as PlayerProfileData
	if not p:
		if avatar_rect and ResourceLoader.exists("res://assets/ui/icons/avatar_pilot_racing.png"):
			avatar_rect.texture = load("res://assets/ui/icons/avatar_pilot_racing.png")
		return
		
	var font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	var font_semi = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")

	if nickname_label:
		nickname_label.text = p.nickname
		if font_bold: nickname_label.add_theme_font_override("font", font_bold)
		nickname_label.add_theme_font_size_override("font_size", 32)
		nickname_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		nickname_label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.22, 1.0))
		nickname_label.add_theme_constant_override("outline_size", 4)
	if level_label:
		level_label.text = "Lv. " + str(p.level)
		if font_bold: level_label.add_theme_font_override("font", font_bold)
		level_label.add_theme_font_size_override("font_size", 26)
		level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		level_label.add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.32, 1.0))
		level_label.add_theme_constant_override("outline_size", 4)
	if coin_label:
		coin_label.text = _format_number(p.coins)
	if gem_label:
		gem_label.text = _format_number(p.gems)
	if xp_bar:
		xp_bar.max_value = p.max_xp
		xp_bar.value = 0.0
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(xp_bar, "value", float(p.current_xp), 0.6)
	if xp_label:
		xp_label.text = "%s / %s XP" % [_format_number(p.current_xp), _format_number(p.max_xp)]
		if font_bold: xp_label.add_theme_font_override("font", font_bold)
		xp_label.add_theme_font_size_override("font_size", 14)
		xp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		
	if _hud_v2:
		_hud_v2.update_profile(p.nickname, p.level, p.current_xp, p.max_xp)
		_hud_v2.update_currency(p.coins, p.gems)
	if _profile_widget:
		_profile_widget.nickname = p.nickname
		_profile_widget.level = p.level
		_profile_widget.current_xp = p.current_xp
		_profile_widget.max_xp = p.max_xp
		_profile_widget.queue_redraw()
	if _currency_widget:
		_currency_widget.coins = p.coins
		_currency_widget.gems = p.gems
		_currency_widget.queue_redraw()
	if xp_label:
		xp_label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.22, 1.0))
		xp_label.add_theme_constant_override("outline_size", 2)
	if avatar_rect:
		if ResourceLoader.exists(p.avatar_path):
			avatar_rect.texture = load(p.avatar_path)
		elif ResourceLoader.exists("res://assets/ui/icons/avatar_pilot_racing.png"):
			avatar_rect.texture = load("res://assets/ui/icons/avatar_pilot_racing.png")
		
	if profile_name_edit:
		profile_name_edit.text = p.nickname

func _on_profile_updated() -> void:
	_bind_player_profile()
	if avatar_rect and not avatar_rect.texture and ResourceLoader.exists("res://assets/ui/icons/avatar_pilot_racing.png"):
		avatar_rect.texture = load("res://assets/ui/icons/avatar_pilot_racing.png")

func _on_currency_changed(coins: int, gems: int) -> void:
	if coin_label:
		coin_label.text = _format_number(coins)
	if gem_label:
		gem_label.text = _format_number(gems)
	if _hud_v2:
		_hud_v2.update_currency(coins, gems)
	if _currency_widget:
		_currency_widget.coins = coins
		_currency_widget.gems = gems
		_currency_widget.queue_redraw()

## Modal Management
func open_modal(modal: Control) -> void:
	if not modal: return
	_close_all_modals()
	if pages_layer:
		pages_layer.visible = true
	_active_modal = modal
	modal.visible = true
	modal.modulate.a = 0.0
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "modulate:a", 1.0, 0.2)
	
	# If profile modal, fill current nickname in input
	if modal == profile_modal and profile_name_edit:
		var prof = _get_profile()
		if prof and prof.data:
			profile_name_edit.text = prof.data.nickname
	elif modal == garage_modal:
		var prof = _get_profile()
		if prof and prof.data:
			_garage_selected_car_id = prof.data.equipped_car
		var showcase = _get_showcase_car()
		if showcase:
			if "garage_open" in showcase:
				showcase.garage_open = true
			if showcase.has_method("warm_garage_fleet"):
				showcase.warm_garage_fleet(GARAGE_FLEET_DATA.keys())
		_refresh_garage_ui()

func close_modal() -> void:
	if _active_modal == garage_modal:
		var prof = _get_profile()
		var eq = prof.data.equipped_car if prof and prof.data else "sedan"
		var showcase = _get_showcase_car()
		if showcase:
			if "garage_open" in showcase:
				showcase.garage_open = false
			if showcase.has_method("load_car_model") and showcase.get("current_model") != eq:
				showcase.load_car_model(eq)
	if pages_layer:
		pages_layer.visible = false
	if _active_modal:
		var target = _active_modal
		_active_modal = null
		target.visible = false
	if _hud_v2 and _hud_v2.play_button:
		_hud_v2.play_button.grab_focus()
	elif play_btn:
		play_btn.grab_focus()

func _get_showcase_car() -> Node3D:
	if get_tree() and get_tree().current_scene:
		var car = get_tree().current_scene.get_node_or_null("ShowcaseCar") as Node3D
		if car: return car
	var parent_node = get_parent()
	while parent_node:
		var car = parent_node.get_node_or_null("ShowcaseCar") as Node3D
		if car: return car
		parent_node = parent_node.get_parent()
	if get_tree() and get_tree().root:
		return get_tree().root.find_child("ShowcaseCar", true, false) as Node3D
	return null

func _close_all_modals() -> void:
	var showcase = _get_showcase_car()
	if showcase and "garage_open" in showcase:
		showcase.garage_open = false
	if pages_layer:
		pages_layer.visible = false
	var modals = [settings_modal, profile_modal, topup_modal, garage_modal, tuning_modal, paint_shop_modal, play_modal]
	for m in modals:
		if m:
			m.visible = false
			m.modulate.a = 1.0
	_active_modal = null

## Profile Actions
func _on_profile_save_pressed() -> void:
	var new_name = profile_name_edit.text.strip_edges()
	if new_name.is_empty():
		show_toast("[!] Nickname cannot be empty!")
		return
	var prof = _get_profile()
	if prof and prof.data:
		prof.data.nickname = new_name
		prof.save_profile()
		prof.profile_updated.emit()
	show_toast("[OK] Pilot callsign updated to " + new_name + "!")
	close_modal()

func _on_profile_cancel_pressed() -> void:
	var prof = _get_profile()
	if prof and prof.data and profile_name_edit:
		profile_name_edit.text = prof.data.nickname
	close_modal()

## Topup Purchases (Offline Demo)
func perform_topup(coin_amount: int, gem_amount: int, package_name: String) -> void:
	var prof = _get_profile()
	if prof:
		prof.add_currency(coin_amount, gem_amount)
	var msg = "+" + _format_number(coin_amount) + " Coins" if coin_amount > 0 else ""
	if gem_amount > 0:
		if not msg.is_empty(): msg += " & "
		msg += "+" + str(gem_amount) + " Gems"
	show_toast("[OK] Top-up credited: " + msg)

## Paint Shop Color Swatch
func select_paint_color(color: Color) -> void:
	paint_color_selected.emit(color)
	var prof = _get_profile()
	if prof and prof.data:
		prof.data.custom_paint_color = color
		prof.save_profile()
	var car = _get_showcase_car()
	if car and car.has_method("set_paint_color"):
		car.set_paint_color(color)
	show_toast("[OK] Custom livery paint coat applied!")

func apply_paint_color(color: Color) -> void:
	select_paint_color(color)

## Settings Actions
func _on_quality_selected(index: int) -> void:
	if has_node("/root/QualitySettings"):
		var qs = get_node("/root/QualitySettings")
		qs.set_tier_by_index(index)
	show_toast("[OK] Graphics profile set to " + quality_option.get_item_text(index))

func _apply_fps_index(index: int) -> void:
	_selected_fps_index = clampi(index, 0, 1)
	Engine.physics_jitter_fix = 0.0
	var screen_hz: float = DisplayServer.screen_get_refresh_rate()
	if _selected_fps_index == 0:
		# 30 FPS: disable VSync so software limiter paces cleanly at 33.33ms without double-vblank judder
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 30
	else:
		# 60 FPS hard release ceiling: native VSync on 60Hz panels, explicit 60 FPS cap on 120Hz/144Hz+ panels
		if screen_hz > 0.0 and absf(screen_hz - 60.0) <= 2.0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 60

func _on_fps_selected(index: int) -> void:
	_apply_fps_index(index)
	if fps_option and fps_option.selected != _selected_fps_index:
		fps_option.select(_selected_fps_index)
	if fps_option and _selected_fps_index < fps_option.item_count:
		show_toast("[OK] Frame Rate Target locked to " + fps_option.get_item_text(_selected_fps_index))

func _on_window_mode_selected(index: int) -> void:
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_master_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val / 100.0))

## Toast Notification System
func show_toast(text: String) -> void:
	if not toast_panel or not toast_label: return
	toast_label.text = text
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
		
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(func(): toast_panel.visible = false)

func _format_number(val: int) -> String:
	var s = str(abs(val))
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return ("-" if val < 0 else "") + res

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _active_modal:
			close_modal()
			get_viewport().set_input_as_handled()
		else:
			back_pressed.emit()
	elif not _active_modal:
		if event.is_action_pressed("ui_down"):
			_move_focus(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_move_focus(-1)
			get_viewport().set_input_as_handled()

func _move_focus(dir: int) -> void:
	_current_focus_index = posmod(_current_focus_index + dir, _nav_buttons.size())
	var target = _nav_buttons[_current_focus_index]
	if target:
		target.grab_focus()
