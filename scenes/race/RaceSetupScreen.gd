extends Control

static var selected_track_id: String = "sunset_circuit"
static var selected_difficulty: String = "normal"

@onready var back_button: RaceButton = %BackButton
@onready var start_race_button: RaceButton = %StartRaceButton
@onready var change_car_button: RaceButton = %ChangeCarButton

@onready var coins_label: Label = %CoinsLabel
@onready var diamonds_label: Label = %DiamondsLabel

# Track elements
@onready var track_sunset_btn: RaceButton = %TrackSunsetBtn
@onready var track_harbor_btn: RaceButton = %TrackHarborBtn
@onready var track_neon_btn: RaceButton = %TrackNeonBtn
@onready var track_name_label: Label = %TrackNameLabel
@onready var track_desc_label: Label = %TrackDescLabel
@onready var track_stats_label: Label = %TrackStatsLabel
@onready var track_best_time_label: Label = %TrackBestTimeLabel

# Difficulty elements
@onready var diff_easy_btn: RaceButton = %DiffEasyBtn
@onready var diff_normal_btn: RaceButton = %DiffNormalBtn
@onready var diff_hard_btn: RaceButton = %DiffHardBtn
@onready var diff_desc_label: Label = %DiffDescLabel

# Car preview elements
@onready var car_preview_image: TextureRect = %CarPreviewImage
@onready var car_name_label: Label = %CarNameLabel
@onready var car_class_label: Label = %CarClassLabel
@onready var speed_bar: ProgressBar = %SpeedBar
@onready var speed_val_label: Label = %SpeedValLabel
@onready var accel_bar: ProgressBar = %AccelBar
@onready var accel_val_label: Label = %AccelValLabel
@onready var handling_bar: ProgressBar = %HandlingBar
@onready var handling_val_label: Label = %HandlingValLabel

const TRACK_INFO: Dictionary = {
	"sunset_circuit": {
		"name_key": "TRACK_SUNSET",
		"desc_key": "TRACK_SUNSET_DESC",
		"length": "2.4 KM // 12 TURNS",
		"color": Color(0.95, 0.42, 0.24, 1.0)
	},
	"harbor_run": {
		"name_key": "TRACK_HARBOR",
		"desc_key": "TRACK_HARBOR_DESC",
		"length": "2.1 KM // 12 TURNS",
		"color": Color(0.24, 0.65, 0.88, 1.0)
	},
	"neon_loop": {
		"name_key": "TRACK_NEON",
		"desc_key": "TRACK_NEON_DESC",
		"length": "2.6 KM // 12 TURNS",
		"color": Color(0.88, 0.24, 0.82, 1.0)
	}
}

const CAR_DATABASE: Dictionary = {
	"starter_gt": {
		"name": "Starter GT",
		"class": "CLASS C // BALANCED COUPE",
		"speed_pct": 70,
		"speed_val": "180 KM/H",
		"accel_pct": 65,
		"accel_val": "4.2s (0-100)",
		"handling_pct": 75,
		"handling_val": "75%",
		"image": "res://assets/art/cars/car_starter_gt.png"
	},
	"apex_cruiser": {
		"name": "Apex Cruiser",
		"class": "CLASS B // AERO SPEC",
		"speed_pct": 82,
		"speed_val": "210 KM/H",
		"accel_pct": 80,
		"accel_val": "3.6s (0-100)",
		"handling_pct": 85,
		"handling_val": "85%",
		"image": "res://assets/art/cars/car_apex_cruiser.png"
	},
	"phantom_turbo": {
		"name": "Phantom Turbo",
		"class": "CLASS S // TWIN-TURBO HYPERCAR",
		"speed_pct": 95,
		"speed_val": "245 KM/H",
		"accel_pct": 92,
		"accel_val": "2.8s (0-100)",
		"handling_pct": 92,
		"handling_val": "92%",
		"image": "res://assets/art/cars/car_phantom_turbo.png"
	}
}

func _ready() -> void:
	_connect_signals()
	_update_currency_display()
	_update_car_preview()
	_select_track(selected_track_id)
	_select_difficulty(selected_difficulty)

	if has_node("/root/Localization"):
		get_node("/root/Localization").language_changed.connect(func(_l): _on_language_changed())

func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)
	start_race_button.pressed.connect(_on_start_race_pressed)
	change_car_button.pressed.connect(_on_change_car_pressed)

	track_sunset_btn.pressed.connect(func(): _select_track("sunset_circuit"))
	track_harbor_btn.pressed.connect(func(): _select_track("harbor_run"))
	track_neon_btn.pressed.connect(func(): _select_track("neon_loop"))

	diff_easy_btn.pressed.connect(func(): _select_difficulty("easy"))
	diff_normal_btn.pressed.connect(func(): _select_difficulty("normal"))
	diff_hard_btn.pressed.connect(func(): _select_difficulty("hard"))

	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		sm.currency_changed.connect(_update_currency_display)
		sm.car_selected.connect(func(_c): _update_car_preview())
		sm.customization_changed.connect(_update_car_preview)

func _update_currency_display() -> void:
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		coins_label.text = sm.format_currency(sm.get_coins())
		diamonds_label.text = sm.format_currency(sm.get_diamonds())
	else:
		coins_label.text = "12,750"
		diamonds_label.text = "120"

func _update_car_preview() -> void:
	var car_id = "starter_gt"
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		car_id = sm.get_selected_car()
	
	if not CAR_DATABASE.has(car_id):
		car_id = "starter_gt"

	var car_info = CAR_DATABASE[car_id]
	car_name_label.text = car_info.name
	car_class_label.text = car_info.class
	speed_bar.value = car_info.speed_pct
	speed_val_label.text = car_info.speed_val
	accel_bar.value = car_info.accel_pct
	accel_val_label.text = car_info.accel_val
	handling_bar.value = car_info.handling_pct
	handling_val_label.text = car_info.handling_val

	if ResourceLoader.exists(car_info.image):
		car_preview_image.texture = load(car_info.image)

	# Apply paint color tint if customized
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		var custom = sm.get_customization()
		var paint_id = custom.get("paint_id", "silver_red")
		car_preview_image.modulate = _get_paint_tint(paint_id)

func _get_paint_tint(paint_id: String) -> Color:
	match paint_id:
		"racing_yellow": return Color(1.0, 0.85, 0.1, 1.0)
		"crimson_red": return Color(0.95, 0.15, 0.2, 1.0)
		"royal_blue": return Color(0.2, 0.45, 0.95, 1.0)
		"stealth_black": return Color(0.4, 0.42, 0.48, 1.0)
		"emerald_green": return Color(0.15, 0.85, 0.4, 1.0)
		_: return Color(1.0, 1.0, 1.0, 1.0) # Silver / default

func _select_track(track_id: String) -> void:
	selected_track_id = track_id
	if not is_node_ready():
		return
	
	# Update button styles
	_update_track_button_state(track_sunset_btn, track_id == "sunset_circuit")
	_update_track_button_state(track_harbor_btn, track_id == "harbor_run")
	_update_track_button_state(track_neon_btn, track_id == "neon_loop")

	var info = TRACK_INFO.get(track_id, TRACK_INFO["sunset_circuit"])
	var loc_name = info.name_key
	var loc_desc = info.desc_key
	if has_node("/root/Localization"):
		var loc = get_node("/root/Localization")
		loc_name = loc.get_string(info.name_key)
		loc_desc = loc.get_string(info.desc_key)

	track_name_label.text = loc_name
	track_desc_label.text = loc_desc
	track_stats_label.text = info.length

	# Best time from SaveManager
	var best_sec = 0.0
	if has_node("/root/SaveManager"):
		best_sec = get_node("/root/SaveManager").get_best_time(track_id)

	if best_sec > 0.0:
		var mins = int(best_sec) / 60
		var secs = int(best_sec) % 60
		var millis = int((best_sec - int(best_sec)) * 100)
		track_best_time_label.text = "RECORD: %02d:%02d.%02d" % [mins, secs, millis]
		track_best_time_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		track_best_time_label.text = "RECORD: --:--.--"
		track_best_time_label.modulate = Color(0.65, 0.65, 0.72, 1.0)

func _update_track_button_state(btn: RaceButton, is_selected: bool) -> void:
	if is_selected:
		btn.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		btn.modulate = Color(0.8, 0.8, 0.85, 0.9)

func _select_difficulty(diff: String) -> void:
	selected_difficulty = diff
	if not is_node_ready():
		return

	_update_diff_button_state(diff_easy_btn, diff == "easy")
	_update_diff_button_state(diff_normal_btn, diff == "normal")
	_update_diff_button_state(diff_hard_btn, diff == "hard")

	match diff:
		"easy":
			diff_desc_label.text = "Relaxed AI speed. Perfect for learning circuit apexes and car handling."
		"normal":
			diff_desc_label.text = "Competitive AI pack. Balanced racing challenge with standard rewards."
		"hard":
			diff_desc_label.text = "Aggressive AI rivals racing on the limit. Top prize and maximum bragging rights."

func _update_diff_button_state(btn: RaceButton, is_selected: bool) -> void:
	if is_selected:
		btn.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		btn.modulate = Color(0.75, 0.75, 0.8, 0.8)

func _on_start_race_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	# Launch 3D Race Scene
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").push_scene("res://scenes/race/RaceTrack3D.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")

func _on_change_car_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").push_scene("res://scenes/garage/GarageScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/garage/GarageScreen.tscn")

func _on_back_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").pop_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_language_changed() -> void:
	_select_track(selected_track_id)
	_select_difficulty(selected_difficulty)
