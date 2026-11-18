extends Node2D
class_name RaceScene

# Config from setup
var track_id: String = "sunset_circuit"
var difficulty: String = "normal"

# Scene references
var track: Track
var player_car: RaceCar
var ai_cars: Array[RaceCar] = []
var all_cars: Array[RaceCar] = []
var camera: Camera2D

# HUD references
@onready var hud_layer: CanvasLayer = %HUDLayer
@onready var countdown_container: CenterContainer = %CountdownContainer
@onready var countdown_label: Label = %CountdownLabel

@onready var lap_label: Label = %LapLabel
@onready var time_label: Label = %TimeLabel
@onready var best_label: Label = %BestLabel

@onready var pos_badge: Label = %PositionBadge
@onready var speed_label: Label = %SpeedLabel
@onready var speed_bar: ProgressBar = %SpeedBar

@onready var wrong_way_banner: PanelContainer = %WrongWayBanner
@onready var tutorial_banner: PanelContainer = %TutorialBanner

# Pause Menu references
@onready var pause_layer: CanvasLayer = %PauseLayer
@onready var pause_menu: Control = %PauseMenu
@onready var resume_btn: RaceButton = %ResumeBtn
@onready var restart_btn: RaceButton = %RestartBtn
@onready var exit_btn: RaceButton = %ExitBtn

# Results Screen references
@onready var result_layer: CanvasLayer = %ResultLayer
@onready var result_menu: Control = %ResultMenu
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_pos_label: Label = %ResultPosLabel
@onready var result_time_label: Label = %ResultTimeLabel
@onready var result_best_label: Label = %ResultBestLabel
@onready var result_record_banner: Label = %RecordBanner
@onready var result_reward_label: Label = %RewardLabel
@onready var retry_btn: RaceButton = %RetryBtn
@onready var home_btn: RaceButton = %HomeBtn

# Race state
var is_counting_down: bool = true
var race_started: bool = false
var race_finished: bool = false
var player_position_rank: int = 4
var max_laps: int = 2
var _trauma: float = 0.0 # Screen shake trauma
var _reward_claimed: bool = false # Session reward duplicate prevention
var _max_speed_reached: float = 0.0

func _ready() -> void:
	# Read config from RaceSetupScreen
	var setup_script = load("res://scenes/race/RaceSetupScreen.gd")
	if setup_script:
		track_id = setup_script.selected_track_id
		difficulty = setup_script.selected_difficulty

	_init_track_and_cars()
	_setup_camera()
	_setup_hud()
	_setup_pause_and_results()

	# Start initial countdown
	_start_countdown()

func _init_track_and_cars() -> void:
	# 1. Instantiate Track
	track = Track.new()
	track.name = "Track"
	track.track_id = track_id
	add_child(track)

	var waypoints = track.waypoints

	# 2. Player Car
	player_car = RaceCar.new()
	player_car.name = "PlayerCar"
	player_car.is_player = true
	player_car.driver_name = "Player"

	# Read player selected car and customizations
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		player_car.car_id = sm.get_selected_car()
		player_car.driver_name = sm.get_player_name()
		var custom = sm.get_customization()
		var paint_color = _get_paint_color(custom.get("paint_id", "silver_red"))
		player_car.apply_customization(paint_color)
	else:
		player_car.car_id = "starter_gt"

	player_car.waypoints = waypoints
	player_car.total_checkpoints_count = track.get_checkpoints_count()
	player_car.max_laps = max_laps

	# Place on Grid 4 (Player starts 4th)
	var p_xform = track.get_grid_transform(3)
	player_car.global_position = p_xform.origin
	player_car.rotation = p_xform.get_rotation()
	add_child(player_car)
	all_cars.append(player_car)

	# Connect player signals
	player_car.collided_with_wall.connect(_on_player_collided)
	player_car.wrong_way_changed.connect(_on_player_wrong_way_changed)
	player_car.lap_completed.connect(_on_player_lap_completed)
	player_car.race_finished.connect(_on_player_race_finished)

	# 3. AI Opponent Cars (3 cars)
	var ai_configs = [
		{"id": "phantom_turbo", "name": "Apex_Phantom [CPU]", "color": Color(0.95, 0.25, 0.25, 1.0), "grid": 0},
		{"id": "apex_cruiser", "name": "VelocityViper [CPU]", "color": Color(0.25, 0.55, 0.95, 1.0), "grid": 1},
		{"id": "starter_gt", "name": "NitroBlaze [CPU]", "color": Color(0.95, 0.75, 0.15, 1.0), "grid": 2}
	]

	for cfg in ai_configs:
		var ai_car = RaceCar.new()
		ai_car.name = cfg.name
		ai_car.is_player = false
		ai_car.car_id = cfg.id
		ai_car.driver_name = cfg.name
		ai_car.ai_difficulty = difficulty
		ai_car.waypoints = waypoints
		ai_car.total_checkpoints_count = track.get_checkpoints_count()
		ai_car.max_laps = max_laps

		var xform = track.get_grid_transform(cfg.grid)
		ai_car.global_position = xform.origin
		ai_car.rotation = xform.get_rotation()

		add_child(ai_car)
		ai_car.apply_customization(cfg.color)
		ai_cars.append(ai_car)
		all_cars.append(ai_car)

func _get_paint_color(paint_id: String) -> Color:
	match paint_id:
		"racing_yellow": return Color(1.0, 0.85, 0.1, 1.0)
		"crimson_red": return Color(0.95, 0.15, 0.2, 1.0)
		"royal_blue": return Color(0.2, 0.45, 0.95, 1.0)
		"stealth_black": return Color(0.4, 0.42, 0.48, 1.0)
		"emerald_green": return Color(0.15, 0.85, 0.4, 1.0)
		_: return Color(1.0, 1.0, 1.0, 1.0)

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "RaceCamera"
	camera.zoom = Vector2(0.9, 0.9)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.global_position = player_car.global_position

func _setup_hud() -> void:
	wrong_way_banner.visible = false
	pause_layer.visible = false
	result_layer.visible = false

	# Best time from SaveManager
	var best_rec = 0.0
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		best_rec = sm.get_best_time(track_id)
	
	if best_rec > 0.0:
		best_label.text = "BEST: %s" % _format_time(best_rec)
	else:
		best_label.text = "BEST: --:--.--"

	# Tutorial banner
	var show_tut = true
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		show_tut = bool(sm.get_setting("show_race_tutorial", true))
	tutorial_banner.visible = show_tut

	if show_tut:
		# Auto-fade tutorial after 5s
		var tw = create_tween()
		tw.tween_interval(5.0)
		tw.tween_property(tutorial_banner, "modulate:a", 0.0, 1.0)
		tw.tween_callback(func(): tutorial_banner.visible = false)

func _setup_pause_and_results() -> void:
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

	retry_btn.pressed.connect(_on_restart_pressed)
	home_btn.pressed.connect(_on_home_pressed)

func _start_countdown() -> void:
	is_counting_down = true
	countdown_container.visible = true

	# Sound helper
	var play_count_sfx = func():
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("race_countdown")

	# Step 3
	countdown_label.text = "3"
	countdown_label.modulate = Color(0.95, 0.3, 0.3, 1.0)
	play_count_sfx.call()
	_animate_countdown_pop()
	await get_tree().create_timer(1.0).timeout

	# Step 2
	countdown_label.text = "2"
	countdown_label.modulate = Color(1.0, 0.7, 0.15, 1.0)
	play_count_sfx.call()
	_animate_countdown_pop()
	await get_tree().create_timer(1.0).timeout

	# Step 1
	countdown_label.text = "1"
	countdown_label.modulate = Color(1.0, 0.9, 0.2, 1.0)
	play_count_sfx.call()
	_animate_countdown_pop()
	await get_tree().create_timer(1.0).timeout

	# GO!
	countdown_label.text = "GO!"
	countdown_label.modulate = Color(0.25, 0.95, 0.45, 1.0)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_click")
	_animate_countdown_pop()

	# Activate all cars
	is_counting_down = false
	race_started = true
	for car in all_cars:
		car.is_active = true

	await get_tree().create_timer(0.8).timeout
	countdown_container.visible = false

func _animate_countdown_pop() -> void:
	countdown_label.scale = Vector2(1.6, 1.6)
	countdown_label.pivot_offset = countdown_label.size * 0.5
	var tw = create_tween()
	tw.tween_property(countdown_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not is_instance_valid(player_car):
		return

	# Update Camera position following player with slight forward lookahead
	var forward_look = Vector2.UP.rotated(player_car.rotation) * (player_car.current_speed * 0.4)
	var target_cam_pos = player_car.global_position + forward_look

	# Apply screen shake if enabled
	var shake_offset = Vector2.ZERO
	var screen_shake_enabled = true
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		screen_shake_enabled = bool(sm.get_setting("screen_shake", true))

	if screen_shake_enabled and _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 2.5)
		shake_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * (_trauma * _trauma * 22.0)

	camera.global_position = target_cam_pos + shake_offset

	# Update HUD
	_update_hud()

	# Track top speed reached for achievement
	var cur_kmh = player_car.get_speed_kmh()
	if cur_kmh > _max_speed_reached:
		_max_speed_reached = cur_kmh

	# Update dynamic race rankings every frame
	_calculate_race_positions()

func _update_hud() -> void:
	if not race_started:
		return

	# Lap
	lap_label.text = "LAP %d/%d" % [player_car.current_lap, max_laps]

	# Current lap time
	time_label.text = "TIME: %s" % _format_time(player_car.current_lap_time)

	# Best lap time
	if player_car.best_lap_time > 0.0:
		best_label.text = "BEST: %s" % _format_time(player_car.best_lap_time)

	# Speed
	var kmh = player_car.get_speed_kmh()
	speed_label.text = "%d KM/H" % kmh
	speed_bar.value = kmh

	# Position Badge
	pos_badge.text = "%d / %d" % [player_position_rank, all_cars.size()]
	match player_position_rank:
		1:
			pos_badge.modulate = Color(1.0, 0.85, 0.2, 1.0) # Gold
		2:
			pos_badge.modulate = Color(0.85, 0.88, 0.95, 1.0) # Silver
		3:
			pos_badge.modulate = Color(0.85, 0.55, 0.35, 1.0) # Bronze
		_:
			pos_badge.modulate = Color(0.7, 0.72, 0.78, 1.0)

func _calculate_race_positions() -> void:
	# Sort cars by continuous progress score descending
	var sorted_cars = all_cars.duplicate()
	sorted_cars.sort_custom(func(a, b):
		return a.get_race_progress_score() > b.get_race_progress_score()
	)

	for i in range(sorted_cars.size()):
		if sorted_cars[i] == player_car:
			player_position_rank = i + 1
			break

func _on_player_collided(impact: float) -> void:
	_trauma = minf(_trauma + (impact / 350.0), 1.0)

func _on_player_wrong_way_changed(_car: RaceCar, is_wrong: bool) -> void:
	wrong_way_banner.visible = is_wrong

func _on_player_lap_completed(_car: RaceCar, lap_num: int, lap_time: float) -> void:
	if has_node("/root/ToastManager"):
		get_node("/root/ToastManager").show_success("Lap %d Finished! [%s]" % [lap_num, _format_time(lap_time)], 2.0)

func _on_player_race_finished(_car: RaceCar, total_time: float, best_lap: float) -> void:
	if race_finished:
		return
	race_finished = true

	# Play finish sound
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("race_finish")

	# Stop player car
	player_car.is_active = false

	# Show results screen
	_show_race_results(total_time, best_lap)

func _show_race_results(total_time: float, best_lap: float) -> void:
	result_layer.visible = true

	var is_win = (player_position_rank == 1)
	if is_win:
		result_title_label.text = "VICTORY!"
		result_title_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		result_pos_label.text = "1ST PLACE - CHAMPION 🏆"
		result_pos_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	elif player_position_rank == 2:
		result_title_label.text = "PODIUM FINISH!"
		result_title_label.modulate = Color(0.85, 0.88, 0.95, 1.0)
		result_pos_label.text = "2ND PLACE - RUNNER UP 🥈"
	elif player_position_rank == 3:
		result_title_label.text = "PODIUM FINISH!"
		result_title_label.modulate = Color(0.85, 0.55, 0.35, 1.0)
		result_pos_label.text = "3RD PLACE - BRONZE 🥉"
	else:
		result_title_label.text = "RACE COMPLETED"
		result_title_label.modulate = Color(0.7, 0.72, 0.78, 1.0)
		result_pos_label.text = "%dTH PLACE - FINISHER" % player_position_rank

	result_time_label.text = "Total Time: %s" % _format_time(total_time)
	result_best_label.text = "Best Lap: %s" % _format_time(best_lap)

	# Coin reward calculation
	var reward_coins = 500
	match player_position_rank:
		1: reward_coins = 1250 # 1000 + 250 win bonus
		2: reward_coins = 750
		3: reward_coins = 500
		_: reward_coins = 300

	result_reward_label.text = "REWARD: +%d COINS" % reward_coins

	# Check Track Record
	var is_new_record = false
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		var prev_best = sm.get_best_time(track_id)
		if prev_best <= 0.0 or best_lap < prev_best:
			is_new_record = true

	result_record_banner.visible = is_new_record

	# Save progression with duplicate prevention
	if not _reward_claimed:
		_reward_claimed = true
		if has_node("/root/SaveManager"):
			var sm = get_node("/root/SaveManager")
			var valid_lap = best_lap if best_lap > 0.0 else 45.0
			# Updates stats, records, wins, event_races_completed, total_distance, xp
			sm.record_race_finished(track_id, valid_lap, is_win, 2.5)
			# Award coins
			sm.add_coins(reward_coins)

	# Grab focus on Home button
	home_btn.grab_focus()

func _format_time(time_sec: float) -> String:
	var mins = int(time_sec) / 60
	var secs = int(time_sec) % 60
	var millis = int((time_sec - int(time_sec)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, millis]

# Input & Pause Menu
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if not result_layer.visible:
			_toggle_pause()
			get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	var paused_now = not get_tree().paused
	get_tree().paused = paused_now
	pause_layer.visible = paused_now

	if paused_now:
		resume_btn.grab_focus()
		if has_node("/root/Navigation"):
			get_node("/root/Navigation").register_modal(pause_menu)
	else:
		if has_node("/root/Navigation"):
			get_node("/root/Navigation").unregister_modal(pause_menu)

func _on_resume_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	get_tree().paused = false
	pause_layer.visible = false
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").unregister_modal(pause_menu)

func _on_restart_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	get_tree().paused = false
	pause_layer.visible = false
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").unregister_modal(pause_menu)
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()

	var confirm_needed = true
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		confirm_needed = bool(sm.get_setting("confirm_before_leaving_race", true))

	if confirm_needed:
		var confirm_scene = preload("res://scenes/common/ConfirmDialog.tscn")
		var dlg = confirm_scene.instantiate()
		pause_layer.add_child(dlg)
		dlg.setup(
			"Leave Race?",
			"Are you sure you want to exit the current race? Any ongoing lap progress will be lost.",
			"LEAVE RACE",
			"CONTINUE"
		)
		dlg.confirmed.connect(func():
			get_tree().paused = false
			if has_node("/root/Navigation"):
				get_node("/root/Navigation").unregister_modal(pause_menu)
				get_node("/root/Navigation").pop_scene()
			else:
				get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")
		)
	else:
		get_tree().paused = false
		if has_node("/root/Navigation"):
			get_node("/root/Navigation").unregister_modal(pause_menu)
			get_node("/root/Navigation").pop_scene()
		else:
			get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")

func _on_home_pressed() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click_sfx()
	get_tree().paused = false
	if has_node("/root/Navigation"):
		get_node("/root/Navigation").go_home()
	else:
		get_tree().change_scene_to_file("res://scenes/home/HomeScreen.tscn")
