extends Control

@onready var back_button: RaceButton = %BackButton
@onready var save_button: RaceButton = %SaveButton
@onready var cancel_button: RaceButton = %CancelButton

@onready var avatar_preview: TextureRect = %AvatarPreview
@onready var name_edit: LineEdit = %NameEdit
@onready var error_label: Label = %ErrorLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_label: Label = %XpLabel
@onready var xp_bar: ProgressBar = %XpBar

@onready var total_races_label: Label = %TotalRacesLabel
@onready var wins_label: Label = %WinsLabel
@onready var win_rate_label: Label = %WinRateLabel
@onready var best_time_label: Label = %BestTimeLabel
@onready var total_distance_label: Label = %TotalDistanceLabel

@onready var avatar_grid: HBoxContainer = %AvatarGrid

var _selected_avatar_id: String = "avatar_1"
var _saved_name: String = ""
var _saved_avatar_id: String = ""

const AVATAR_PRESETS: Array[Dictionary] = [
	{"id": "avatar_1", "path": "res://assets/art/avatars/avatar_1.png", "label": "Viper"},
	{"id": "avatar_2", "path": "res://assets/art/avatars/avatar_2.png", "label": "Apex"},
	{"id": "avatar_3", "path": "res://assets/art/avatars/avatar_3.png", "label": "Nitro"},
	{"id": "avatar_4", "path": "res://assets/art/avatars/avatar_4.png", "label": "Phantom"}
]

func _ready() -> void:
	if not error_label:
		return
	error_label.text = ""
	error_label.visible = false
	
	back_button.pressed.connect(_on_back_pressed)
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	name_edit.text_changed.connect(_on_name_text_changed)
	
	if has_node("/root/SaveManager"):
		SaveManager.profile_changed.connect(_refresh_profile_data)
	
	_setup_avatar_buttons()
	_refresh_profile_data()

func _setup_avatar_buttons() -> void:
	for child in avatar_grid.get_children():
		child.queue_free()
	
	for preset in AVATAR_PRESETS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 110)
		btn.focus_mode = Control.FOCUS_ALL
		btn.text = preset.label
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		
		if ResourceLoader.exists(preset.path):
			var tex = load(preset.path)
			btn.icon = tex
			btn.expand_icon = true
		
		# Custom stylebox for avatar card
		var normal_sb = StyleBoxFlat.new()
		normal_sb.bg_color = Color(0.141, 0.149, 0.227, 0.9)
		normal_sb.border_width_left = 2
		normal_sb.border_width_top = 2
		normal_sb.border_width_right = 2
		normal_sb.border_width_bottom = 2
		normal_sb.border_color = Color(0.25, 0.26, 0.35, 1.0)
		normal_sb.corner_radius_top_left = 6
		normal_sb.corner_radius_top_right = 6
		normal_sb.corner_radius_bottom_right = 6
		normal_sb.corner_radius_bottom_left = 6
		btn.add_theme_stylebox_override("normal", normal_sb)
		
		var hover_sb = normal_sb.duplicate()
		hover_sb.border_color = Color(1.0, 0.71, 0.11, 1.0)
		btn.add_theme_stylebox_override("hover", hover_sb)
		
		var p_id = preset.id
		btn.pressed.connect(func(): _select_avatar(p_id))
		btn.name = "AvatarBtn_" + p_id
		avatar_grid.add_child(btn)

func _refresh_profile_data() -> void:
	if has_node("/root/SaveManager"):
		_saved_name = SaveManager.get_player_name()
		_saved_avatar_id = SaveManager.get_avatar_id()
		_selected_avatar_id = _saved_avatar_id
		
		name_edit.text = _saved_name
		_update_avatar_preview(_selected_avatar_id)
		_update_avatar_highlights()
		
		var lvl = SaveManager.get_player_level()
		var xp = SaveManager.get_player_xp()
		level_label.text = "LEVEL %d" % lvl
		xp_label.text = "%d / 1000 XP" % xp
		xp_bar.max_value = 1000
		xp_bar.value = xp
		
		var prog = SaveManager.get_progress()
		var races = int(prog.get("races_completed", 0))
		var wins = int(prog.get("wins", 0))
		var dist = float(SaveManager.current_data.player.get("total_distance", 0.0))
		
		total_races_label.text = str(races)
		wins_label.text = str(wins)
		
		if races > 0:
			var win_rate = (float(wins) / float(races)) * 100.0
			win_rate_label.text = "%.1f%%" % win_rate
		else:
			win_rate_label.text = "0.0%"
		
		total_distance_label.text = "%.1f km" % dist
		
		# Find best lap time across tracks
		var best_overall = 0.0
		var records = SaveManager.current_data.get("records", {})
		for trk in records.keys():
			var t = float(records[trk])
			if t > 0.0 and (best_overall == 0.0 or t < best_overall):
				best_overall = t
		
		if best_overall > 0.0:
			var mins = int(best_overall) / 60
			var secs = int(best_overall) % 60
			var ms = int((best_overall - int(best_overall)) * 100)
			best_time_label.text = "%02d:%02d.%02d" % [mins, secs, ms]
		else:
			best_time_label.text = "--:--.--"
	else:
		name_edit.text = "RacerX"
		level_label.text = "LEVEL 12"
		xp_label.text = "420 / 1000 XP"
		xp_bar.value = 420
		total_races_label.text = "24"
		wins_label.text = "14"
		win_rate_label.text = "58.3%"
		best_time_label.text = "00:48.24"
		total_distance_label.text = "128.5 km"

func _select_avatar(avatar_id: String) -> void:
	_selected_avatar_id = avatar_id
	_update_avatar_preview(avatar_id)
	_update_avatar_highlights()
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _update_avatar_preview(avatar_id: String) -> void:
	var path = "res://assets/art/avatars/%s.png" % avatar_id
	if ResourceLoader.exists(path):
		avatar_preview.texture = load(path)

func _update_avatar_highlights() -> void:
	for child in avatar_grid.get_children():
		if child is Button:
			var is_selected = child.name == ("AvatarBtn_" + _selected_avatar_id)
			var sb = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if sb:
				if is_selected:
					sb.border_color = Color(1.0, 0.71, 0.11, 1.0)
					sb.border_width_left = 3
					sb.border_width_top = 3
					sb.border_width_right = 3
					sb.border_width_bottom = 3
					sb.bg_color = Color(0.20, 0.22, 0.32, 1.0)
				else:
					sb.border_color = Color(0.25, 0.26, 0.35, 1.0)
					sb.border_width_left = 2
					sb.border_width_top = 2
					sb.border_width_right = 2
					sb.border_width_bottom = 2
					sb.bg_color = Color(0.141, 0.149, 0.227, 0.9)
				child.add_theme_stylebox_override("normal", sb)

func _on_name_text_changed(_new_text: String) -> void:
	error_label.visible = false
	error_label.text = ""

func _on_save_pressed() -> void:
	var raw_name = name_edit.text
	var cleaned = raw_name.strip_edges()
	
	if cleaned.length() < 3 or cleaned.length() > 16:
		error_label.text = "Name must be between 3 and 16 characters!"
		error_label.visible = true
		if has_node("/root/ToastManager"):
			ToastManager.show_warning("Invalid name length (3-16 chars required)")
		return
	
	error_label.visible = false
	error_label.text = ""
	
	if has_node("/root/SaveManager"):
		SaveManager.set_player_name(cleaned)
		SaveManager.set_avatar_id(_selected_avatar_id)
		_saved_name = cleaned
		_saved_avatar_id = _selected_avatar_id
	
	if has_node("/root/ToastManager"):
		ToastManager.show_success("Profile updated successfully!")
	
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _on_cancel_pressed() -> void:
	error_label.visible = false
	error_label.text = ""
	name_edit.text = _saved_name
	_selected_avatar_id = _saved_avatar_id
	_update_avatar_preview(_selected_avatar_id)
	_update_avatar_highlights()
	if has_node("/root/ToastManager"):
		ToastManager.show_toast("Changes discarded", 1.5, "↺")
	if has_node("/root/AudioManager"):
		AudioManager.play_click_sfx()

func _on_back_pressed() -> void:
	if has_node("/root/Navigation"):
		Navigation.pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
