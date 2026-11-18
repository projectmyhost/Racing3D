class_name ModernRacingHUD
extends CanvasLayer

# Complete Universal Racing HUD & In-Game GUI System.
# Matches 100% of user reference image:
# - Top Center: Slanted Lap & Timer glass badge (Lap starts from 0/3)
# - Top Left: Slanted Exit Race button
# - Top Right: Settings / Pause button with gear icon, Best Lap, and Position
# - Bottom Left: Minimap with real 3D circuit line, checkpoints, and rotating player arrow
# - Bottom Right: Analog + Digital Speedometer with RPM needle, Gear display, KM/H, and N2O bar
# - In-Game Pause & Settings GUI modal with "Exit to Main Menu"

const ModernMinimapScript = preload("res://scripts/race/ModernMinimap.gd")
const ModernSpeedometerScript = preload("res://scripts/race/ModernSpeedometer.gd")

signal pause_requested
signal exit_to_home_requested
signal restart_requested

var current_lap: int = 0
var max_laps: int = 3
var current_lap_time: float = 0.0
var best_lap_time: float = 99999.0
var current_speed_kmh: float = 0.0
var current_rpm: float = 850.0
var max_rpm: float = 10000.0
var current_gear: int = 1
var is_reverse: bool = false
var nitro_level: float = 0.85
var player_rank: int = 1
var total_racers: int = 12
var is_paused: bool = false

# Child Nodes
var minimap: Control
var speedometer: Control

var _hud_root: Control
var _top_center_panel: Control
var _lap_val_label: Label
var _timer_val_label: Label

var _top_left_btn: Button
var _top_right_btn: Button
var _best_lap_label: Label
var _pos_top_label: Label

# Pause Modal Nodes
var _pause_overlay: ColorRect
var _pause_dialog: PanelContainer

var _font_bold: Font
var _font_regular: Font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	_load_fonts()
	_create_hud_layout()
	_create_pause_modal()

func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-Bold.ttf"):
		_font_bold = load("res://assets/ui/fonts/Rajdhani-Bold.ttf")
	if ResourceLoader.exists("res://assets/ui/fonts/Rajdhani-SemiBold.ttf"):
		_font_regular = load("res://assets/ui/fonts/Rajdhani-SemiBold.ttf")

func setup_vehicle(car: Node3D) -> void:
	if minimap:
		minimap.car_node = car

func _create_hud_layout() -> void:
	_hud_root = Control.new()
	_hud_root.name = "ModernHUDRoot"
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_root)

	# 1. Top Center: Lap & Timer Slanted Badge
	_create_top_center_panel()

	# 2. Top Left: "< EXIT RACE" Button
	_create_top_left_exit_btn()

	# 3. Top Right: Settings / Pause Button & Best Lap / Pos Badge
	_create_top_right_panel()

	# 4. Bottom Left: Real-time Minimap & POS 1 / 12 Badge
	minimap = ModernMinimapScript.new()
	minimap.name = "Minimap"
	minimap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	minimap.offset_left = 25.0
	minimap.offset_top = -250.0
	minimap.offset_right = 235.0
	minimap.offset_bottom = -10.0
	_hud_root.add_child(minimap)

	# 5. Bottom Right: High-tech Speedometer Gauge
	speedometer = ModernSpeedometerScript.new()
	speedometer.name = "Speedometer"
	speedometer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	speedometer.offset_left = -305.0
	speedometer.offset_top = -235.0
	speedometer.offset_right = -25.0
	speedometer.offset_bottom = -15.0
	_hud_root.add_child(speedometer)

func _create_top_center_panel() -> void:
	_top_center_panel = Control.new()
	_top_center_panel.name = "TopCenterLapTimer"
	_top_center_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_top_center_panel.custom_minimum_size = Vector2(340, 68)
	_top_center_panel.offset_left = -170.0
	_top_center_panel.offset_top = 16.0
	_top_center_panel.offset_right = 170.0
	_top_center_panel.offset_bottom = 84.0
	_top_center_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(_top_center_panel)

	# Draw slanted background
	var bg_panel = Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.12, 0.88)
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.3, 0.55, 0.85, 0.9)
	sb.corner_radius_top_left = 6
	sb.corner_radius_bottom_right = 6
	bg_panel.add_theme_stylebox_override("panel", sb)
	_top_center_panel.add_child(bg_panel)

	# Content Layout
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_center_panel.add_child(hbox)

	# Left Half: LAP
	var lap_box = VBoxContainer.new()
	lap_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lap_box.alignment = BoxContainer.ALIGNMENT_CENTER
	lap_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lap_box)

	var lap_hdr = Label.new()
	lap_hdr.text = "LAP"
	lap_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_regular:
		lap_hdr.add_theme_font_override("font", _font_regular)
	lap_hdr.add_theme_font_size_override("font_size", 13)
	lap_hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.85))
	lap_box.add_child(lap_hdr)

	_lap_val_label = Label.new()
	_lap_val_label.text = "0/3"
	_lap_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		_lap_val_label.add_theme_font_override("font", _font_bold)
	_lap_val_label.add_theme_font_size_override("font_size", 28)
	_lap_val_label.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	lap_box.add_child(_lap_val_label)

	# Slanted Divider Line
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(2, 44)
	div.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	div.color = Color(0.35, 0.5, 0.7, 0.6)
	hbox.add_child(div)

	# Right Half: TIMER
	var timer_box = VBoxContainer.new()
	timer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(timer_box)

	var timer_hdr = Label.new()
	timer_hdr.text = "TIMER"
	timer_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_regular:
		timer_hdr.add_theme_font_override("font", _font_regular)
	timer_hdr.add_theme_font_size_override("font_size", 13)
	timer_hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.85))
	timer_box.add_child(timer_hdr)

	_timer_val_label = Label.new()
	_timer_val_label.text = "00:00.00"
	_timer_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		_timer_val_label.add_theme_font_override("font", _font_bold)
	_timer_val_label.add_theme_font_size_override("font_size", 28)
	_timer_val_label.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	timer_box.add_child(_timer_val_label)

func _create_top_left_exit_btn() -> void:
	_top_left_btn = Button.new()
	_top_left_btn.name = "TopLeftExitBtn"
	_top_left_btn.text = "<  EXIT RACE"
	_top_left_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_left_btn.offset_left = 24.0
	_top_left_btn.offset_top = 18.0
	_top_left_btn.offset_right = 172.0
	_top_left_btn.offset_bottom = 62.0
	_top_left_btn.custom_minimum_size = Vector2(148, 44)
	if _font_bold:
		_top_left_btn.add_theme_font_override("font", _font_bold)
	_top_left_btn.add_theme_font_size_override("font_size", 18)
	_top_left_btn.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.04, 0.07, 0.12, 0.88)
	sb_norm.border_width_left = 4
	sb_norm.border_color = Color(0.95, 0.22, 0.18, 1.0) # Red accent stripe on left
	sb_norm.border_width_top = 1
	sb_norm.border_width_right = 1
	sb_norm.border_width_bottom = 1
	sb_norm.corner_radius_top_left = 6
	sb_norm.corner_radius_bottom_right = 6
	_top_left_btn.add_theme_stylebox_override("normal", sb_norm)
	
	var sb_hov = sb_norm.duplicate() as StyleBoxFlat
	sb_hov.bg_color = Color(0.12, 0.18, 0.28, 0.95)
	sb_hov.border_color = Color(1.0, 0.4, 0.35, 1.0)
	_top_left_btn.add_theme_stylebox_override("hover", sb_hov)
	
	_top_left_btn.pressed.connect(_open_pause_menu)
	_hud_root.add_child(_top_left_btn)

func _create_top_right_panel() -> void:
	var tr_cont = VBoxContainer.new()
	tr_cont.name = "TopRightContainer"
	tr_cont.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr_cont.offset_left = -215.0
	tr_cont.offset_top = 18.0
	tr_cont.offset_right = -25.0
	tr_cont.offset_bottom = 103.0
	tr_cont.custom_minimum_size = Vector2(190, 85)
	_hud_root.add_child(tr_cont)

	# Settings / Pause Button
	_top_right_btn = Button.new()
	_top_right_btn.name = "SettingsPauseBtn"
	_top_right_btn.text = "⚙  SETTINGS / PAUSE"
	_top_right_btn.custom_minimum_size = Vector2(190, 42)
	if _font_bold:
		_top_right_btn.add_theme_font_override("font", _font_bold)
	_top_right_btn.add_theme_font_size_override("font_size", 16)
	_top_right_btn.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.04, 0.07, 0.12, 0.88)
	sb_btn.border_width_left = 2
	sb_btn.border_width_top = 2
	sb_btn.border_width_right = 2
	sb_btn.border_width_bottom = 2
	sb_btn.border_color = Color(0.35, 0.6, 0.9, 0.9)
	sb_btn.corner_radius_top_left = 6
	sb_btn.corner_radius_bottom_right = 6
	_top_right_btn.add_theme_stylebox_override("normal", sb_btn)
	
	var sb_btn_hov = sb_btn.duplicate() as StyleBoxFlat
	sb_btn_hov.bg_color = Color(0.12, 0.20, 0.32, 0.95)
	sb_btn_hov.border_color = Color(0.6, 0.85, 1.0, 1.0)
	_top_right_btn.add_theme_stylebox_override("hover", sb_btn_hov)
	
	_top_right_btn.pressed.connect(_open_pause_menu)
	tr_cont.add_child(_top_right_btn)

	# Best Lap & Position sub-strip
	var sub_strip = PanelContainer.new()
	sub_strip.custom_minimum_size = Vector2(190, 32)
	var sb_sub = StyleBoxFlat.new()
	sb_sub.bg_color = Color(0.02, 0.04, 0.08, 0.82)
	sb_sub.border_width_left = 1
	sb_sub.border_width_bottom = 1
	sb_sub.border_width_right = 1
	sb_sub.border_color = Color(0.2, 0.3, 0.45, 0.7)
	sub_strip.add_theme_stylebox_override("panel", sb_sub)
	tr_cont.add_child(sub_strip)

	var sub_hbox = HBoxContainer.new()
	sub_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_strip.add_child(sub_hbox)

	var bl_box = VBoxContainer.new()
	bl_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_hbox.add_child(bl_box)

	var bl_hdr = Label.new()
	bl_hdr.text = "BEST LAP"
	bl_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_regular:
		bl_hdr.add_theme_font_override("font", _font_regular)
	bl_hdr.add_theme_font_size_override("font_size", 10)
	bl_hdr.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.8))
	bl_box.add_child(bl_hdr)

	_best_lap_label = Label.new()
	_best_lap_label.text = "--:--:--"
	_best_lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		_best_lap_label.add_theme_font_override("font", _font_bold)
	_best_lap_label.add_theme_font_size_override("font_size", 13)
	_best_lap_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.95))
	bl_box.add_child(_best_lap_label)

	var sub_div = ColorRect.new()
	sub_div.custom_minimum_size = Vector2(1, 22)
	sub_div.color = Color(0.3, 0.4, 0.55, 0.6)
	sub_hbox.add_child(sub_div)

	var pos_box = VBoxContainer.new()
	pos_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pos_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_hbox.add_child(pos_box)

	var pos_hdr = Label.new()
	pos_hdr.text = "POS"
	pos_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_regular:
		pos_hdr.add_theme_font_override("font", _font_regular)
	pos_hdr.add_theme_font_size_override("font_size", 10)
	pos_hdr.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.8))
	pos_box.add_child(pos_hdr)

	_pos_top_label = Label.new()
	_pos_top_label.text = "1 / 12"
	_pos_top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		_pos_top_label.add_theme_font_override("font", _font_bold)
	_pos_top_label.add_theme_font_size_override("font_size", 13)
	_pos_top_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.15, 1.0))
	pos_box.add_child(_pos_top_label)

func _create_pause_modal() -> void:
	_pause_overlay = ColorRect.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.color = Color(0.01, 0.02, 0.04, 0.85)
	_pause_overlay.visible = false
	add_child(_pause_overlay)

	_pause_dialog = PanelContainer.new()
	_pause_dialog.name = "PauseDialog"
	_pause_dialog.set_anchors_preset(Control.PRESET_CENTER)
	_pause_dialog.offset_left = -220.0
	_pause_dialog.offset_top = -180.0
	_pause_dialog.offset_right = 220.0
	_pause_dialog.offset_bottom = 180.0
	_pause_dialog.custom_minimum_size = Vector2(440, 360)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.14, 0.98)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.35, 0.65, 0.95, 0.95)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	_pause_dialog.add_theme_stylebox_override("panel", sb)
	_pause_overlay.add_child(_pause_dialog)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_pause_dialog.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.82, 0.15, 1.0))
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Buttons
	var resume_btn = _create_menu_btn("RESUME RACE", Color(0.2, 0.5, 0.85, 0.95))
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	var restart_btn = _create_menu_btn("RESTART RACE", Color(0.25, 0.35, 0.5, 0.85))
	restart_btn.pressed.connect(func():
		_close_pause_menu()
		restart_requested.emit()
	)
	vbox.add_child(restart_btn)

	var exit_btn = _create_menu_btn("EXIT TO MAIN MENU", Color(0.85, 0.2, 0.15, 0.95))
	exit_btn.pressed.connect(func():
		_close_pause_menu()
		exit_to_home_requested.emit()
	)
	vbox.add_child(exit_btn)

func _create_menu_btn(txt: String, border_col: Color) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 48)
	if _font_bold:
		btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border_col
	sb.corner_radius_top_left = 6
	sb.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_hov = sb.duplicate() as StyleBoxFlat
	sb_hov.bg_color = Color(0.15, 0.22, 0.35, 1.0)
	btn.add_theme_stylebox_override("hover", sb_hov)
	return btn

func _open_pause_menu() -> void:
	is_paused = true
	if _pause_overlay:
		_pause_overlay.visible = true
	get_tree().paused = true
	pause_requested.emit()

func _close_pause_menu() -> void:
	is_paused = false
	if _pause_overlay:
		_pause_overlay.visible = false
	get_tree().paused = false

func update_race_state(lap: int, p_max_laps: int, lap_time: float, p_best_time: float, rank: int, total: int) -> void:
	current_lap = lap
	max_laps = p_max_laps
	current_lap_time = lap_time
	best_lap_time = p_best_time
	player_rank = rank
	total_racers = total
	
	if _lap_val_label:
		_lap_val_label.text = "%d/%d" % [current_lap, max_laps]
	if _timer_val_label:
		_timer_val_label.text = _format_time(current_lap_time)
	if _best_lap_label:
		_best_lap_label.text = "--:--:--" if best_lap_time > 90000.0 else _format_time(best_lap_time)
	if _pos_top_label:
		_pos_top_label.text = "%d / %d" % [player_rank, total_racers]
	if minimap:
		minimap.player_position_rank = player_rank
		minimap.total_racers = total_racers

func update_telemetry(speed: float, rpm: float, p_max_rpm: float, gear: int, rev: bool, nitro: float = 0.85) -> void:
	current_speed_kmh = speed
	current_rpm = rpm
	max_rpm = p_max_rpm
	current_gear = gear
	is_reverse = rev
	nitro_level = nitro
	if speedometer:
		speedometer.update_car_data(speed, rpm, p_max_rpm, gear, rev, nitro)

func _format_time(sec: float) -> String:
	var mins = int(sec) / 60
	var s = int(sec) % 60
	var ms = int((sec - int(sec)) * 100.0)
	return "%02d:%02d.%02d" % [mins, s, ms]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			_close_pause_menu()
		else:
			_open_pause_menu()
