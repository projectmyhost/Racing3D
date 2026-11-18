extends Control

@onready var back_button: RaceButton = %BackButton
@onready var track_all_button: Button = %TrackAllButton
@onready var track_sunset_button: Button = %TrackSunsetButton
@onready var track_harbor_button: Button = %TrackHarborButton
@onready var track_neon_button: Button = %TrackNeonButton
@onready var my_records_toggle: Button = %MyRecordsToggle
@onready var records_table: VBoxContainer = %RecordsTable

const CPU_ENTRIES: Array[Dictionary] = [
	{"name": "Apex_Phantom [CPU]", "car": "Phantom Turbo", "track": "sunset_circuit", "track_name": "Sunset Circuit", "time": 46.24, "date": "2026-11-10", "is_player": false},
	{"name": "VelocityViper [CPU]", "car": "Apex Cruiser", "track": "sunset_circuit", "track_name": "Sunset Circuit", "time": 47.85, "date": "2026-11-11", "is_player": false},
	{"name": "GhostRacer [CPU]", "car": "Phantom Turbo", "track": "sunset_circuit", "track_name": "Sunset Circuit", "time": 49.30, "date": "2026-11-09", "is_player": false},
	{"name": "CircuitKing [CPU]", "car": "Apex Cruiser", "track": "sunset_circuit", "track_name": "Sunset Circuit", "time": 52.15, "date": "2026-11-08", "is_player": false},
	{"name": "NitroBlaze [CPU]", "car": "Starter GT", "track": "sunset_circuit", "track_name": "Sunset Circuit", "time": 54.60, "date": "2026-11-05", "is_player": false},

	{"name": "Apex_Phantom [CPU]", "car": "Phantom Turbo", "track": "harbor_run", "track_name": "Harbor Run", "time": 51.80, "date": "2026-11-11", "is_player": false},
	{"name": "VelocityViper [CPU]", "car": "Apex Cruiser", "track": "harbor_run", "track_name": "Harbor Run", "time": 53.45, "date": "2026-11-10", "is_player": false},
	{"name": "GhostRacer [CPU]", "car": "Phantom Turbo", "track": "harbor_run", "track_name": "Harbor Run", "time": 55.90, "date": "2026-11-07", "is_player": false},
	{"name": "RedlineRookie [CPU]", "car": "Starter GT", "track": "harbor_run", "track_name": "Harbor Run", "time": 61.20, "date": "2026-11-06", "is_player": false},

	{"name": "Apex_Phantom [CPU]", "car": "Phantom Turbo", "track": "neon_loop", "track_name": "Neon Loop", "time": 39.50, "date": "2026-11-12", "is_player": false},
	{"name": "GhostRacer [CPU]", "car": "Phantom Turbo", "track": "neon_loop", "track_name": "Neon Loop", "time": 41.10, "date": "2026-11-11", "is_player": false},
	{"name": "VelocityViper [CPU]", "car": "Apex Cruiser", "track": "neon_loop", "track_name": "Neon Loop", "time": 42.80, "date": "2026-11-09", "is_player": false},
	{"name": "NitroBlaze [CPU]", "car": "Starter GT", "track": "neon_loop", "track_name": "Neon Loop", "time": 45.30, "date": "2026-11-04", "is_player": false}
]

var _selected_track: String = "all"
var _show_my_records_only: bool = false

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	track_all_button.pressed.connect(func(): _set_track_filter("all"))
	track_sunset_button.pressed.connect(func(): _set_track_filter("sunset_circuit"))
	track_harbor_button.pressed.connect(func(): _set_track_filter("harbor_run"))
	track_neon_button.pressed.connect(func(): _set_track_filter("neon_loop"))
	
	my_records_toggle.pressed.connect(_on_my_records_toggled)
	
	_update_filter_button_styles()
	_update_toggle_style()
	_refresh_table()

func _set_track_filter(trk: String) -> void:
	_selected_track = trk
	_update_filter_button_styles()
	_refresh_table()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _on_my_records_toggled() -> void:
	_show_my_records_only = not _show_my_records_only
	_update_toggle_style()
	_refresh_table()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _update_filter_button_styles() -> void:
	var btns = [
		{"btn": track_all_button, "id": "all"},
		{"btn": track_sunset_button, "id": "sunset_circuit"},
		{"btn": track_harbor_button, "id": "harbor_run"},
		{"btn": track_neon_button, "id": "neon_loop"}
	]
	
	for b in btns:
		var btn = b.btn as Button
		var is_sel = (b.id == _selected_track)
		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		if is_sel:
			sb.bg_color = Color(1.0, 0.709, 0.106, 1.0)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(0.953, 0.416, 0.239, 1.0)
			btn.add_theme_color_override("font_color", Color(0.06, 0.07, 0.11, 1.0))
		else:
			sb.bg_color = Color(0.141, 0.149, 0.227, 0.9)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.25, 0.26, 0.35, 1.0)
			btn.add_theme_color_override("font_color", Color(0.956, 0.949, 0.949, 1.0))
		btn.add_theme_stylebox_override("normal", sb)

func _update_toggle_style() -> void:
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	if _show_my_records_only:
		sb.bg_color = Color(0.384, 0.773, 0.541, 1.0)
		sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		my_records_toggle.text = "✓ MY RECORDS ONLY (ACTIVE)"
		my_records_toggle.add_theme_color_override("font_color", Color(0.06, 0.07, 0.11, 1.0))
	else:
		sb.bg_color = Color(0.141, 0.149, 0.227, 0.9)
		sb.border_color = Color(0.25, 0.26, 0.35, 1.0)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		my_records_toggle.text = "MY RECORDS ONLY"
		my_records_toggle.add_theme_color_override("font_color", Color(0.956, 0.949, 0.949, 1.0))
	my_records_toggle.add_theme_stylebox_override("normal", sb)

func _refresh_table() -> void:
	for child in records_table.get_children():
		child.queue_free()
	
	var all_rows: Array[Dictionary] = []
	all_rows.append_array(CPU_ENTRIES)
	
	# Fetch player records from SaveManager
	if has_node("/root/SaveManager"):
		var p_name = SaveManager.get_player_name() + " (You)"
		var p_car_id = SaveManager.get_selected_car()
		var car_names = {
			"starter_gt": "Starter GT",
			"apex_cruiser": "Apex Cruiser",
			"phantom_turbo": "Phantom Turbo"
		}
		var p_car = car_names.get(p_car_id, "Starter GT")
		
		var tracks = [
			{"id": "sunset_circuit", "name": "Sunset Circuit", "default_time": 48.24},
			{"id": "harbor_run", "name": "Harbor Run", "default_time": 54.12},
			{"id": "neon_loop", "name": "Neon Loop", "default_time": 40.85}
		]
		
		for trk in tracks:
			var time_sec = SaveManager.get_best_time(trk.id)
			if time_sec <= 0.0:
				time_sec = trk.default_time # baseline local demonstration best time
			
			all_rows.append({
				"name": p_name,
				"car": p_car,
				"track": trk.id,
				"track_name": trk.name,
				"time": time_sec,
				"date": "2026-11-12",
				"is_player": true
			})
	
	# Filter rows
	var filtered: Array[Dictionary] = []
	for r in all_rows:
		if _selected_track != "all" and r.track != _selected_track:
			continue
		if _show_my_records_only and not r.is_player:
			continue
		filtered.append(r)
	
	# Sort ascending by time
	filtered.sort_custom(func(a, b): return float(a.time) < float(b.time))
	
	# Populate rows
	for i in range(filtered.size()):
		var row_data = filtered[i]
		var rank = i + 1
		var row_widget = _create_table_row(rank, row_data)
		records_table.add_child(row_widget)

func _create_table_row(rank: int, data: Dictionary) -> PanelContainer:
	var row = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 52)
	
	var sb = StyleBoxFlat.new()
	if data.is_player:
		sb.bg_color = Color(0.20, 0.24, 0.38, 0.95)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(1.0, 0.709, 0.106, 1.0)
	else:
		sb.bg_color = Color(0.12, 0.13, 0.20, 0.9) if rank % 2 == 0 else Color(0.141, 0.149, 0.227, 0.9)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.20, 0.21, 0.30, 0.5)
	
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	row.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	
	# Rank
	var rank_lbl = Label.new()
	rank_lbl.custom_minimum_size = Vector2(60, 0)
	if rank == 1:
		rank_lbl.text = "🥇 1ST"
		rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	elif rank == 2:
		rank_lbl.text = "🥈 2ND"
		rank_lbl.add_theme_color_override("font_color", Color(0.85, 0.87, 0.91, 1.0))
	elif rank == 3:
		rank_lbl.text = "🥉 3RD"
		rank_lbl.add_theme_color_override("font_color", Color(0.80, 0.50, 0.20, 1.0))
	else:
		rank_lbl.text = "#%d" % rank
		rank_lbl.add_theme_color_override("font_color", Color(0.659, 0.663, 0.722, 1.0))
	rank_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(rank_lbl)
	
	# Driver Name
	var name_lbl = Label.new()
	name_lbl.text = data.name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_stretch_ratio = 1.4
	if data.is_player:
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.709, 0.106, 1.0))
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.957, 0.949, 0.949, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(name_lbl)
	
	# Car Model
	var car_lbl = Label.new()
	car_lbl.text = data.car
	car_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	car_lbl.size_flags_stretch_ratio = 1.0
	car_lbl.add_theme_color_override("font_color", Color(0.75, 0.76, 0.85, 1.0))
	car_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(car_lbl)
	
	# Track Name
	var track_lbl = Label.new()
	track_lbl.text = data.track_name
	track_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_lbl.size_flags_stretch_ratio = 1.1
	track_lbl.add_theme_color_override("font_color", Color(0.659, 0.663, 0.722, 1.0))
	track_lbl.add_theme_font_size_override("font_size", 15)
	hbox.add_child(track_lbl)
	
	# Best Time
	var t = float(data.time)
	var mins = int(t) / 60
	var secs = int(t) % 60
	var ms = int((t - int(t)) * 100)
	var time_lbl = Label.new()
	time_lbl.text = "%02d:%02d.%02d" % [mins, secs, ms]
	time_lbl.custom_minimum_size = Vector2(110, 0)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.add_theme_color_override("font_color", Color(0.384, 0.773, 0.541, 1.0) if rank <= 3 else Color(0.957, 0.949, 0.949, 1.0))
	time_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(time_lbl)
	
	# Date
	var date_lbl = Label.new()
	date_lbl.text = data.date
	date_lbl.custom_minimum_size = Vector2(100, 0)
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_lbl.add_theme_color_override("font_color", Color(0.55, 0.56, 0.62, 1.0))
	date_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(date_lbl)
	
	return row

func _on_back_pressed() -> void:
	if has_node("/root/Navigation"):
		Navigation.pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
