extends Control

# Header references
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var category_desc_label: Label = %CategoryDescLabel

# Tab Button references
@onready var audio_tab_btn: Button = %AudioTabBtn
@onready var display_tab_btn: Button = %DisplayTabBtn
@onready var gameplay_tab_btn: Button = %GameplayTabBtn
@onready var access_tab_btn: Button = %AccessTabBtn
@onready var data_tab_btn: Button = %DataTabBtn

# Panel containers for categories
@onready var audio_panel: Control = %AudioPanel
@onready var display_panel: Control = %DisplayPanel
@onready var gameplay_panel: Control = %GameplayPanel
@onready var access_panel: Control = %AccessPanel
@onready var data_panel: Control = %DataPanel

# Audio Controls
@onready var master_slider: HSlider = %MasterSlider
@onready var master_val_label: Label = %MasterValLabel
@onready var music_slider: HSlider = %MusicSlider
@onready var music_val_label: Label = %MusicValLabel
@onready var sfx_slider: HSlider = %SfxSlider
@onready var sfx_val_label: Label = %SfxValLabel
@onready var mute_all_check: CheckButton = %MuteAllCheck
@onready var music_check: CheckButton = %MusicCheck
@onready var sfx_check: CheckButton = %SfxCheck
@onready var test_sound_btn: Button = %TestSoundBtn

# Display Controls
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var vsync_check: CheckButton = %VsyncCheck
@onready var fps_limit_option: OptionButton = %FpsLimitOption
@onready var quality_option: OptionButton = %QualityOption
@onready var ui_scale_slider: HSlider = %UiScaleSlider
@onready var ui_scale_val_label: Label = %UiScaleValLabel
@onready var screen_shake_check: CheckButton = %ScreenShakeCheck
@onready var reduced_motion_check: CheckButton = %ReducedMotionCheck

# Gameplay Controls
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_val_label: Label = %SensitivityValLabel
@onready var control_scheme_option: OptionButton = %ControlSchemeOption
@onready var tutorial_check: CheckButton = %TutorialCheck
@onready var auto_accel_check: CheckButton = %AutoAccelCheck
@onready var confirm_leave_check: CheckButton = %ConfirmLeaveCheck

# Accessibility & Language Controls
@onready var language_option: OptionButton = %LanguageOption
@onready var high_contrast_check: CheckButton = %HighContrastCheck
@onready var color_assist_option: OptionButton = %ColorAssistOption
@onready var text_size_option: OptionButton = %TextSizeOption

# Data & Support Controls
@onready var restore_defaults_btn: Button = %RestoreDefaultsBtn
@onready var reset_save_btn: Button = %ResetSaveBtn
@onready var credits_btn: Button = %CreditsBtn

# Credits Modal Overlay
@onready var credits_modal: Control = %CreditsModal
@onready var credits_title_label: Label = %CreditsTitleLabel
@onready var credits_content_label: Label = %CreditsContentLabel
@onready var credits_close_btn: Button = %CreditsCloseBtn

var _active_tab: int = 0
var _tab_buttons: Array[Button] = []
var _tab_panels: Array[Control] = []
var _suppress_signals: bool = false

func _ready() -> void:
	_tab_buttons = [audio_tab_btn, display_tab_btn, gameplay_tab_btn, access_tab_btn, data_tab_btn]
	_tab_panels = [audio_panel, display_panel, gameplay_panel, access_panel, data_panel]

	_connect_signals()
	_populate_option_buttons()
	_load_and_apply_all_settings()
	_switch_tab(0)
	_update_localization()

	# Connect Localization language changes
	if has_node("/root/Localization"):
		var loc = get_node("/root/Localization")
		if loc.has_signal("language_changed"):
			loc.language_changed.connect(_on_language_changed)

	if credits_modal:
		credits_modal.visible = false

func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)

	audio_tab_btn.pressed.connect(func(): _switch_tab(0))
	display_tab_btn.pressed.connect(func(): _switch_tab(1))
	gameplay_tab_btn.pressed.connect(func(): _switch_tab(2))
	access_tab_btn.pressed.connect(func(): _switch_tab(3))
	data_tab_btn.pressed.connect(func(): _switch_tab(4))

	# Audio signals
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	mute_all_check.toggled.connect(_on_mute_all_toggled)
	music_check.toggled.connect(_on_music_toggled)
	sfx_check.toggled.connect(_on_sfx_toggled)
	test_sound_btn.pressed.connect(_on_test_sound_pressed)

	# Display signals
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	vsync_check.toggled.connect(_on_vsync_toggled)
	fps_limit_option.item_selected.connect(_on_fps_limit_selected)
	quality_option.item_selected.connect(_on_quality_selected)
	ui_scale_slider.value_changed.connect(_on_ui_scale_slider_changed)
	screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	reduced_motion_check.toggled.connect(_on_reduced_motion_toggled)

	# Gameplay signals
	sensitivity_slider.value_changed.connect(_on_sensitivity_slider_changed)
	control_scheme_option.item_selected.connect(_on_control_scheme_selected)
	tutorial_check.toggled.connect(_on_tutorial_toggled)
	auto_accel_check.toggled.connect(_on_auto_accel_toggled)
	confirm_leave_check.toggled.connect(_on_confirm_leave_toggled)

	# Accessibility signals
	language_option.item_selected.connect(_on_language_selected)
	high_contrast_check.toggled.connect(_on_high_contrast_toggled)
	color_assist_option.item_selected.connect(_on_color_assist_selected)
	text_size_option.item_selected.connect(_on_text_size_selected)

	# Data & Support signals
	restore_defaults_btn.pressed.connect(_on_restore_defaults_pressed)
	reset_save_btn.pressed.connect(_on_reset_save_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	credits_close_btn.pressed.connect(_on_credits_close_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if credits_modal and credits_modal.visible:
			credits_modal.visible = false
			get_viewport().set_input_as_handled()
			return
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _switch_tab(tab_index: int) -> void:
	_active_tab = tab_index
	for i in range(_tab_panels.size()):
		_tab_panels[i].visible = (i == tab_index)

	for i in range(_tab_buttons.size()):
		var btn = _tab_buttons[i]
		if i == tab_index:
			btn.modulate = Color(1.0, 0.85, 0.3, 1.0)
			btn.custom_minimum_size.x = 220
		else:
			btn.modulate = Color(0.8, 0.8, 0.85, 1.0)
			btn.custom_minimum_size.x = 200

	_update_category_description()

func _populate_option_buttons() -> void:
	_suppress_signals = true

	# Window Mode
	window_mode_option.clear()
	window_mode_option.add_item(_loc("OPT_WINDOWED"), 0)
	window_mode_option.add_item(_loc("OPT_FULLSCREEN"), 1)
	window_mode_option.add_item(_loc("OPT_BORDERLESS"), 2)

	# Resolution
	resolution_option.clear()
	resolution_option.add_item("1280x720 (16:9)", 0)
	resolution_option.add_item("1366x768 (16:9)", 1)
	resolution_option.add_item("1600x900 (16:9)", 2)
	resolution_option.add_item("1920x1080 (16:9)", 3)

	# FPS Limit
	fps_limit_option.clear()
	fps_limit_option.add_item(_loc("OPT_FPS_30"), 0)
	fps_limit_option.add_item(_loc("OPT_FPS_60"), 1)
	fps_limit_option.add_item(_loc("OPT_FPS_120"), 2)
	fps_limit_option.add_item(_loc("OPT_FPS_UNLIMITED"), 3)

	# Graphics Quality
	quality_option.clear()
	quality_option.add_item(_loc("OPT_LOW"), 0)
	quality_option.add_item(_loc("OPT_MEDIUM"), 1)
	quality_option.add_item(_loc("OPT_HIGH"), 2)

	# Control Scheme
	control_scheme_option.clear()
	control_scheme_option.add_item(_loc("OPT_KEYBOARD"), 0)
	control_scheme_option.add_item(_loc("OPT_MOUSE"), 1)

	# Language
	language_option.clear()
	language_option.add_item(_loc("OPT_LANG_EN"), 0)
	language_option.add_item(_loc("OPT_LANG_ID"), 1)

	# Color Assist
	color_assist_option.clear()
	color_assist_option.add_item(_loc("OPT_OFF"), 0)
	color_assist_option.add_item(_loc("OPT_PROTANOPIA"), 1)
	color_assist_option.add_item(_loc("OPT_DEUTERANOPIA"), 2)

	# Text Size
	text_size_option.clear()
	text_size_option.add_item(_loc("OPT_NORMAL"), 0)
	text_size_option.add_item(_loc("OPT_LARGE"), 1)

	_suppress_signals = false

func _load_and_apply_all_settings() -> void:
	_suppress_signals = true

	# AUDIO
	var master_vol = float(_get_setting("master_volume", 1.0))
	var music_vol = float(_get_setting("music_volume", 0.7))
	var sfx_vol = float(_get_setting("sfx_volume", 0.85))
	var mute_all = bool(_get_setting("mute_all", false))
	var music_en = bool(_get_setting("music_enabled", true))
	var sfx_en = bool(_get_setting("ui_sfx_enabled", true))

	master_slider.value = master_vol
	master_val_label.text = "%d%%" % int(master_vol * 100.0)
	music_slider.value = music_vol
	music_val_label.text = "%d%%" % int(music_vol * 100.0)
	sfx_slider.value = sfx_vol
	sfx_val_label.text = "%d%%" % int(sfx_vol * 100.0)
	mute_all_check.button_pressed = mute_all
	music_check.button_pressed = music_en
	sfx_check.button_pressed = sfx_en

	_apply_audio_values(master_vol, music_vol, sfx_vol, mute_all, music_en, sfx_en)

	# DISPLAY
	var win_mode = str(_get_setting("window_mode", "windowed"))
	match win_mode:
		"fullscreen":
			window_mode_option.selected = 1
		"borderless":
			window_mode_option.selected = 2
		_:
			window_mode_option.selected = 0
	_apply_window_mode(win_mode)

	var res_str = str(_get_setting("resolution", "1600x900"))
	match res_str:
		"1280x720":
			resolution_option.selected = 0
		"1366x768":
			resolution_option.selected = 1
		"1600x900":
			resolution_option.selected = 2
		"1920x1080":
			resolution_option.selected = 3
		_:
			resolution_option.selected = 2
	_apply_resolution(res_str)

	var vsync = bool(_get_setting("vsync", true))
	vsync_check.button_pressed = vsync
	_apply_vsync(vsync)

	var fps_limit = int(_get_setting("fps_limit", 60))
	match fps_limit:
		30:
			fps_limit_option.selected = 0
		60:
			fps_limit_option.selected = 1
		120:
			fps_limit_option.selected = 2
		0:
			fps_limit_option.selected = 3
		_:
			fps_limit_option.selected = 1
	_apply_fps_limit(fps_limit)

	var quality = str(_get_setting("graphics_quality", "high"))
	match quality:
		"low":
			quality_option.selected = 0
		"medium":
			quality_option.selected = 1
		"high":
			quality_option.selected = 2
		_:
			quality_option.selected = 2
	_apply_graphics_quality(quality)

	var ui_scale = float(_get_setting("ui_scale", 1.0))
	ui_scale_slider.value = ui_scale
	ui_scale_val_label.text = "%d%%" % int(ui_scale * 100.0)
	_apply_ui_scale(ui_scale)

	var screen_shake = bool(_get_setting("screen_shake", true))
	screen_shake_check.button_pressed = screen_shake

	var reduced_motion = bool(_get_setting("reduced_motion", false))
	reduced_motion_check.button_pressed = reduced_motion

	# GAMEPLAY
	var sens = int(_get_setting("steering_sensitivity", 5))
	sensitivity_slider.value = sens
	sensitivity_val_label.text = "%d / 10" % sens

	var control_scheme = str(_get_setting("control_scheme", "keyboard"))
	control_scheme_option.selected = 1 if control_scheme == "mouse" else 0

	var tutorial = bool(_get_setting("show_race_tutorial", true))
	tutorial_check.button_pressed = tutorial

	var auto_accel = bool(_get_setting("auto_accelerate", false))
	auto_accel_check.button_pressed = auto_accel

	var confirm_leave = bool(_get_setting("confirm_before_leaving_race", true))
	confirm_leave_check.button_pressed = confirm_leave

	# ACCESSIBILITY
	var lang = str(_get_setting("language", "en"))
	language_option.selected = 1 if lang == "id" else 0

	var high_contrast = bool(_get_setting("high_contrast", false))
	high_contrast_check.button_pressed = high_contrast
	_apply_high_contrast(high_contrast)

	var color_assist = str(_get_setting("color_assist", "off"))
	match color_assist:
		"protanopia":
			color_assist_option.selected = 1
		"deuteranopia":
			color_assist_option.selected = 2
		_:
			color_assist_option.selected = 0
	_apply_color_assist(color_assist)

	var text_size = str(_get_setting("text_size", "normal"))
	text_size_option.selected = 1 if text_size == "large" else 0
	_apply_text_size(text_size)

	_suppress_signals = false

# ==================== AUDIO CALLBACKS ====================
func _on_master_slider_changed(val: float) -> void:
	if _suppress_signals:
		return
	master_val_label.text = "%d%%" % int(val * 100.0)
	_set_setting("master_volume", val)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_master_volume(val)

func _on_music_slider_changed(val: float) -> void:
	if _suppress_signals:
		return
	music_val_label.text = "%d%%" % int(val * 100.0)
	_set_setting("music_volume", val)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_music_volume(val)

func _on_sfx_slider_changed(val: float) -> void:
	if _suppress_signals:
		return
	sfx_val_label.text = "%d%%" % int(val * 100.0)
	_set_setting("sfx_volume", val)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_sfx_volume(val)

func _on_mute_all_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("mute_all", toggled_on)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_mute_all(toggled_on)

func _on_music_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("music_enabled", toggled_on)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_music_enabled(toggled_on)

func _on_sfx_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("ui_sfx_enabled", toggled_on)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_sfx_enabled(toggled_on)

func _on_test_sound_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").test_sound()

func _apply_audio_values(master_v: float, music_v: float, sfx_v: float, mute: bool, music_e: bool, sfx_e: bool) -> void:
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.set_master_volume(master_v)
		am.set_music_volume(music_v)
		am.set_sfx_volume(sfx_v)
		am.set_mute_all(mute)
		am.set_music_enabled(music_e)
		am.set_sfx_enabled(sfx_e)

# ==================== DISPLAY CALLBACKS ====================
func _on_window_mode_selected(index: int) -> void:
	if _suppress_signals:
		return
	var mode = "windowed"
	if index == 1:
		mode = "fullscreen"
	elif index == 2:
		mode = "borderless"
	_set_setting("window_mode", mode)
	_apply_window_mode(mode)

func _apply_window_mode(mode: String) -> void:
	match mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func _on_resolution_selected(index: int) -> void:
	if _suppress_signals:
		return
	var res_map = ["1280x720", "1366x768", "1600x900", "1920x1080"]
	var res_str = res_map[clampi(index, 0, res_map.size() - 1)]
	_set_setting("resolution", res_str)
	_apply_resolution(res_str)

func _apply_resolution(res_str: String) -> void:
	var parts = res_str.split("x")
	if parts.size() == 2:
		var w = int(parts[0])
		var h = int(parts[1])
		if w > 0 and h > 0:
			DisplayServer.window_set_size(Vector2i(w, h))
			var screen_size = DisplayServer.screen_get_size()
			var target_pos = (screen_size - Vector2i(w, h)) / 2
			if target_pos.x >= 0 and target_pos.y >= 0:
				DisplayServer.window_set_position(target_pos)

func _on_vsync_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("vsync", toggled_on)
	_apply_vsync(toggled_on)

func _apply_vsync(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)

func _on_fps_limit_selected(index: int) -> void:
	if _suppress_signals:
		return
	var fps_map = [30, 60, 120, 0]
	var limit = fps_map[clampi(index, 0, fps_map.size() - 1)]
	_set_setting("fps_limit", limit)
	_apply_fps_limit(limit)

func _apply_fps_limit(limit: int) -> void:
	Engine.max_fps = limit

func _on_quality_selected(index: int) -> void:
	if _suppress_signals:
		return
	var q_map = ["low", "medium", "high"]
	var quality = q_map[clampi(index, 0, q_map.size() - 1)]
	_set_setting("graphics_quality", quality)
	_apply_graphics_quality(quality)

func _apply_graphics_quality(quality: String) -> void:
	var msaa = RenderingServer.VIEWPORT_MSAA_DISABLED
	if quality == "medium":
		msaa = RenderingServer.VIEWPORT_MSAA_2X
	elif quality == "high":
		msaa = RenderingServer.VIEWPORT_MSAA_4X
	RenderingServer.viewport_set_msaa_2d(get_viewport().get_viewport_rid(), msaa)

func _on_ui_scale_slider_changed(val: float) -> void:
	if _suppress_signals:
		return
	ui_scale_val_label.text = "%d%%" % int(val * 100.0)
	_set_setting("ui_scale", val)
	_apply_ui_scale(val)

func _apply_ui_scale(scale_val: float) -> void:
	get_tree().root.content_scale_factor = clampf(scale_val, 0.8, 1.2)

func _on_screen_shake_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("screen_shake", toggled_on)

func _on_reduced_motion_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("reduced_motion", toggled_on)

# ==================== GAMEPLAY CALLBACKS ====================
func _on_sensitivity_slider_changed(val: float) -> void:
	if _suppress_signals:
		return
	var sens = int(val)
	sensitivity_val_label.text = "%d / 10" % sens
	_set_setting("steering_sensitivity", sens)

func _on_control_scheme_selected(index: int) -> void:
	if _suppress_signals:
		return
	var scheme = "mouse" if index == 1 else "keyboard"
	_set_setting("control_scheme", scheme)

func _on_tutorial_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("show_race_tutorial", toggled_on)

func _on_auto_accel_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("auto_accelerate", toggled_on)

func _on_confirm_leave_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("confirm_before_leaving_race", toggled_on)

# ==================== ACCESSIBILITY CALLBACKS ====================
func _on_language_selected(index: int) -> void:
	if _suppress_signals:
		return
	var lang = "id" if index == 1 else "en"
	if has_node("/root/Localization"):
		get_node("/root/Localization").set_language(lang)
	else:
		_set_setting("language", lang)
		_update_localization()

func _on_language_changed(_new_lang: String) -> void:
	_populate_option_buttons()
	_update_localization()

func _on_high_contrast_toggled(toggled_on: bool) -> void:
	if _suppress_signals:
		return
	_set_setting("high_contrast", toggled_on)
	_apply_high_contrast(toggled_on)

func _apply_high_contrast(enabled: bool) -> void:
	var border_col = Color(1.0, 1.0, 1.0, 1.0) if enabled else Color(0.204, 0.212, 0.306, 1.0)
	var bg_col = Color(0.04, 0.04, 0.07, 0.98) if enabled else Color(0.141, 0.149, 0.227, 0.95)
	
	# Apply styling update to category panels
	for panel in _tab_panels:
		if panel is PanelContainer:
			var sb = panel.get_theme_stylebox("panel")
			if sb and sb is StyleBoxFlat:
				var new_sb = sb.duplicate()
				new_sb.border_color = border_col
				new_sb.bg_color = bg_col
				new_sb.border_width_left = 3 if enabled else 1
				new_sb.border_width_top = 3 if enabled else 1
				new_sb.border_width_right = 3 if enabled else 1
				new_sb.border_width_bottom = 3 if enabled else 1
				panel.add_theme_stylebox_override("panel", new_sb)

func _on_color_assist_selected(index: int) -> void:
	if _suppress_signals:
		return
	var c_map = ["off", "protanopia", "deuteranopia"]
	var assist = c_map[clampi(index, 0, c_map.size() - 1)]
	_set_setting("color_assist", assist)
	_apply_color_assist(assist)

func _apply_color_assist(assist: String) -> void:
	match assist:
		"protanopia":
			# Use accessible blue/amber highlight
			title_label.modulate = Color(0.3, 0.7, 1.0, 1.0)
		"deuteranopia":
			# Use accessible cyan/magenta highlight
			title_label.modulate = Color(0.4, 0.8, 1.0, 1.0)
		_:
			# Standard racing yellow
			title_label.modulate = Color(1.0, 0.71, 0.11, 1.0)

func _on_text_size_selected(index: int) -> void:
	if _suppress_signals:
		return
	var size_str = "large" if index == 1 else "normal"
	_set_setting("text_size", size_str)
	_apply_text_size(size_str)

func _apply_text_size(size_str: String) -> void:
	var is_large = (size_str == "large")
	var base_size = 20 if is_large else 16
	title_label.add_theme_font_size_override("font_size", 34 if is_large else 28)
	category_desc_label.add_theme_font_size_override("font_size", 16 if is_large else 14)

	# Update all section labels
	for lbl in get_tree().get_nodes_in_group("setting_labels"):
		if lbl is Label:
			lbl.add_theme_font_size_override("font_size", base_size)

# ==================== DATA & SUPPORT CALLBACKS ====================
func _on_restore_defaults_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	var dialog_scene = load("res://scenes/common/ConfirmDialog.tscn")
	if dialog_scene:
		var dialog = dialog_scene.instantiate()
		add_child(dialog)
		dialog.setup(
			_loc("RESTORE_DEFAULTS_CONFIRM_TITLE"),
			_loc("RESTORE_DEFAULTS_CONFIRM_MSG"),
			_loc("RESTORE_DEFAULTS"),
			_loc("CANCEL"),
			false,
			false
		)
		dialog.confirmed.connect(_do_restore_defaults)

func _do_restore_defaults() -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").reset_to_defaults()
	
	_load_and_apply_all_settings()
	_update_localization()

	if has_node("/root/ToastManager"):
		get_node("/root/ToastManager").show_success(_loc("TOAST_DEFAULTS_RESTORED"))

func _on_reset_save_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	var dialog_scene = load("res://scenes/common/ConfirmDialog.tscn")
	if dialog_scene:
		var dialog = dialog_scene.instantiate()
		add_child(dialog)
		dialog.setup(
			_loc("RESET_SAVE_CONFIRM_TITLE"),
			_loc("RESET_SAVE_CONFIRM_MSG"),
			"RESET ALL DATA",
			_loc("CANCEL"),
			true,
			true
		)
		dialog.confirmed.connect(_do_reset_save_data)

func _do_reset_save_data() -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").reset_all_save_data()

	_load_and_apply_all_settings()
	_update_localization()

	if has_node("/root/ToastManager"):
		get_node("/root/ToastManager").show_warning(_loc("TOAST_SAVE_RESET"))

func _on_credits_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if credits_modal:
		credits_modal.visible = true
		credits_close_btn.grab_focus()

func _on_credits_close_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if credits_modal:
		credits_modal.visible = false
		credits_btn.grab_focus()

func _on_back_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

# ==================== LOCALIZATION & HELPERS ====================
func _update_localization() -> void:
	title_label.text = _loc("SETTINGS_TITLE")
	back_button.text = "← " + _loc("BACK")

	# Tabs
	audio_tab_btn.text = "🔊 " + _loc("AUDIO")
	display_tab_btn.text = "🖥 " + _loc("DISPLAY")
	gameplay_tab_btn.text = "🎮 " + _loc("GAMEPLAY")
	access_tab_btn.text = "♿ " + _loc("ACCESSIBILITY")
	data_tab_btn.text = "💾 " + _loc("DATA")

	# Audio Labels
	%MasterTitleLabel.text = _loc("MASTER_VOLUME")
	%MusicTitleLabel.text = _loc("MUSIC_VOLUME")
	%SfxTitleLabel.text = _loc("SFX_VOLUME")
	mute_all_check.text = _loc("MUTE_ALL")
	music_check.text = _loc("MUSIC_ENABLED")
	sfx_check.text = _loc("SFX_ENABLED")
	test_sound_btn.text = _loc("TEST_SOUND")

	# Display Labels
	%WindowModeLabel.text = _loc("WINDOW_MODE")
	%ResolutionLabel.text = _loc("RESOLUTION")
	vsync_check.text = _loc("VSYNC")
	%FpsLimitLabel.text = _loc("FPS_LIMIT")
	%QualityLabel.text = _loc("GRAPHICS_QUALITY")
	%UiScaleLabel.text = _loc("UI_SCALE")
	screen_shake_check.text = _loc("SCREEN_SHAKE")
	reduced_motion_check.text = _loc("REDUCED_MOTION")

	# Gameplay Labels
	%SensitivityLabel.text = _loc("STEERING_SENSITIVITY")
	%ControlSchemeLabel.text = _loc("CONTROL_SCHEME")
	tutorial_check.text = _loc("SHOW_RACE_TUTORIAL")
	auto_accel_check.text = _loc("AUTO_ACCELERATE")
	confirm_leave_check.text = _loc("CONFIRM_LEAVING_RACE")

	# Accessibility Labels
	%LanguageLabel.text = _loc("LANGUAGE")
	high_contrast_check.text = _loc("HIGH_CONTRAST")
	%ColorAssistLabel.text = _loc("COLOR_ASSIST")
	%TextSizeLabel.text = _loc("TEXT_SIZE")

	# Data Labels
	restore_defaults_btn.text = _loc("RESTORE_DEFAULTS")
	reset_save_btn.text = _loc("RESET_SAVE_DATA")
	credits_btn.text = _loc("CREDITS")

	# Credits
	credits_title_label.text = _loc("CREDITS_TITLE")
	credits_content_label.text = _loc("CREDITS_CONTENT")
	credits_close_btn.text = _loc("CLOSE")

	_update_category_description()

func _update_category_description() -> void:
	match _active_tab:
		0:
			category_desc_label.text = "Audio: Master, music, and sound effects volume and channel controls."
		1:
			category_desc_label.text = "Display: Window mode, screen resolution, frame rate cap, and 2D fidelity."
		2:
			category_desc_label.text = "Gameplay: Vehicle handling sensitivity, controller scheme, and race assists."
		3:
			category_desc_label.text = "Accessibility: Dual-language translation, high contrast, and color assist."
		4:
			category_desc_label.text = "Data & Support: Manage settings defaults, offline save file, and game credits."

func _loc(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

func _get_setting(key: String, default_val = null):
	if has_node("/root/SaveManager"):
		return get_node("/root/SaveManager").get_setting(key, default_val)
	return default_val

func _set_setting(key: String, value) -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").set_setting(key, value)
