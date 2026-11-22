class_name RaceTrack3D
extends Node3D

## Controller for the full modular 3D race circuit.
## Provides full map access, 60 FPS performance, chase camera, and lap timing.

const CollisionGuard = preload("res://scripts/race/CollisionGuard.gd")
const ModernRacingHUDScript = preload("res://scripts/race/ModernRacingHUD.gd")
const EnvMatEnhancer = preload("res://scripts/core/environment_material_enhancer.gd")

@onready var car: RaceCar3D = $RaceCar3D
@onready var camera: Camera3D = $ChaseCamera
@onready var hud_layer: CanvasLayer = $HUD

var modern_hud: CanvasLayer

# HUD elements
@onready var lap_label: Label = %LapLabel
@onready var time_label: Label = %TimeLabel
@onready var best_label: Label = %BestLabel
@onready var speed_label: Label = %SpeedLabel
@onready var speed_bar: ProgressBar = %SpeedBar
@onready var finish_panel: PanelContainer = %FinishPanel
@onready var finish_title: Label = %FinishTitle
@onready var finish_stars: Label = %FinishStars
@onready var finish_rank: Label = %FinishRank
@onready var finish_stats: Label = %FinishStats
@onready var finish_rewards: Label = %FinishRewards
@onready var play_again_btn: Button = %PlayAgainBtn
@onready var finish_home_btn: Button = %FinishHomeBtn
@onready var back_btn: Button = %BackBtn

var current_lap: int = 0
var max_laps: int = 3
var current_lap_time: float = 0.0
var total_race_time: float = 0.0
var best_lap_time: float = 99999.0
var is_finished: bool = false
var next_checkpoint: int = 1
var total_checkpoints: int = 4

# Cinematic Chase Camera Parameters
@export var camera_turn_lag: float = 3.8
@export var camera_lateral_offset_factor: float = 0.85
@export var min_camera_distance: float = 5.2

# Ingame Interactive Orbit & Zoom Camera Variables
var _cam_world_yaw: float = 0.0
var _cam_pitch: float = deg_to_rad(13.5)
var _cam_distance: float = 8.4
var _cam_current_dist: float = 8.4
var _cam_safe_dist: float = 8.4
var _cam_speed_pullback: float = 0.0
var _cam_lateral_shift: float = 0.0
var _cam_smooth_y: float = 0.0
var _cam_y_initialized: bool = false
var _is_dragging_cam: bool = false
var _cam_idle_timer: float = 0.0
var _is_manual_mode: bool = false
var _cam_ray_query: PhysicsRayQueryParameters3D = null
const MIN_CAM_DIST: float = 5.2
const MAX_CAM_DIST: float = 16.5
const MOUSE_SENSITIVITY: float = 0.005

func _ready() -> void:
	Engine.physics_jitter_fix = 0.0
	# Camera is driven in _process using car's interpolated transform:
	# disabling physics interpolation on the camera prevents double-interpolation stutter at 120 FPS.
	if camera:
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	# Ensure HUD overlay never intercepts 3D mouse drag/orbit inputs
	var hud_root = get_node_or_null("HUD/HUDRoot") as Control
	if hud_root:
		hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_panel = get_node_or_null("HUD/HUDRoot/TopPanel") as Control
	if top_panel:
		top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_panel.visible = false
	var spd_node = get_node_or_null("HUD/HUDRoot/Speedometer") as Control
	if spd_node:
		spd_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spd_node.visible = false

	# Instantiate Modern Racing HUD (Speedometer, Minimap, Lap/Timer, In-game Settings)
	modern_hud = ModernRacingHUDScript.new()
	add_child(modern_hud)
	modern_hud.setup_vehicle(car)
	modern_hud.exit_to_home_requested.connect(_return_to_home)
	modern_hud.restart_requested.connect(_restart_race)

	if car:
		car.speed_changed.connect(_on_speed_changed)
		_cam_world_yaw = atan2(car.global_transform.basis.z.x, car.global_transform.basis.z.z)
		_cam_current_dist = _cam_distance
		_cam_safe_dist = _cam_distance
		_cam_smooth_y = car.global_position.y + 1.55
		_cam_y_initialized = true
		_update_chase_camera(0.016)
		
	if play_again_btn:
		play_again_btn.pressed.connect(_restart_race)
	if finish_home_btn:
		finish_home_btn.pressed.connect(_return_to_home)
	if back_btn:
		back_btn.pressed.connect(_return_to_home)
		
	if finish_panel:
		finish_panel.visible = false
		
	_setup_checkpoints()
	
	EnvMatEnhancer.enhance_city_stage(get_node_or_null("CityMap"))
	if has_node("/root/QualitySettings"):
		get_node("/root/QualitySettings").apply_to_current_scene()

	# Execute runtime anti-bug collision guard
	CollisionGuard.run_guard(self)

	# Pre-warm particle/smoke pipelines on first frame so first corner drift never stutters
	_prewarm_race_pipelines()

func _prewarm_race_pipelines() -> void:
	if car and car.get("_smoke_left") and car.get("_smoke_right"):
		var sl := car.get("_smoke_left") as CPUParticles3D
		var sr := car.get("_smoke_right") as CPUParticles3D
		if sl and sr:
			sl.emitting = true
			sr.emitting = true
			get_tree().create_timer(0.05).timeout.connect(func():
				if is_instance_valid(sl): sl.emitting = false
				if is_instance_valid(sr): sr.emitting = false
			)

func _setup_checkpoints() -> void:
	for i in range(total_checkpoints):
		var chk = get_node_or_null("Checkpoints/Checkpoint_" + str(i)) as Area3D
		if chk:
			var idx = i
			chk.body_entered.connect(func(body):
				if body == car:
					_on_checkpoint_entered(idx)
			)

func _physics_process(_delta: float) -> void:
	# Run camera obstacle raycast on the physics thread so _process never stalls at 120 FPS
	if not car:
		return
	var desired_dist = _cam_distance + _cam_speed_pullback
	var look_target = car.global_position + Vector3(0.0, 1.55, 0.0)
	var horiz_dist = desired_dist * cos(_cam_pitch)
	var vert_dist = desired_dist * sin(_cam_pitch)
	var cam_offset = Vector3(
		sin(_cam_world_yaw) * horiz_dist,
		vert_dist,
		cos(_cam_world_yaw) * horiz_dist
	)
	var cam_right = Vector3(cos(_cam_world_yaw), 0.0, -sin(_cam_world_yaw))
	var ray_target = look_target + cam_offset + cam_right * _cam_lateral_shift
	ray_target.y = maxf(ray_target.y, car.global_position.y + 0.90)
	ray_target.y = maxf(ray_target.y, 1.4)

	var w3d = get_world_3d()
	if w3d and w3d.direct_space_state:
		if _cam_ray_query == null:
			_cam_ray_query = PhysicsRayQueryParameters3D.new()
			_cam_ray_query.collision_mask = 1
			_cam_ray_query.exclude = [car.get_rid()]
		_cam_ray_query.from = look_target
		_cam_ray_query.to = ray_target
		var hit = w3d.direct_space_state.intersect_ray(_cam_ray_query)
		if hit:
			var hit_dist = look_target.distance_to(hit.position) - 0.65
			_cam_safe_dist = maxf(hit_dist, min_camera_distance)
		else:
			_cam_safe_dist = desired_dist
	else:
		_cam_safe_dist = desired_dist

func _process(delta: float) -> void:
	if not is_finished:
		current_lap_time += delta
		total_race_time += delta
		if time_label:
			time_label.text = _format_time(current_lap_time)
		if modern_hud and car:
			var speed_kmh = absf(car.forward_speed) * 3.6
			var max_rpm_val = car.config.max_engine_rpm if car.config else 10000.0
			var is_rev = car.forward_speed < -0.3
			modern_hud.update_telemetry(speed_kmh, car.engine_rpm, max_rpm_val, car.current_gear, is_rev)
			modern_hud.update_race_state(current_lap, max_laps, current_lap_time, best_lap_time, 1, 12)
			
	_update_chase_camera(delta)

func _update_chase_camera(delta: float) -> void:
	if not car or not camera:
		return

	var safe_delta = clampf(delta, 0.0001, 0.05)

	# CRITICAL FOR 30/60/120 FPS SMOOTHNESS:
	# Always read the physics-interpolated transform of the RigidBody3D car
	# so the camera advances smoothly on every render frame (zero 60Hz-vs-120Hz judder).
	var car_xform: Transform3D = car.get_global_transform_interpolated()
	var car_pos: Vector3 = car_xform.origin
	var car_yaw: float = atan2(car_xform.basis.z.x, car_xform.basis.z.z)

	# Frame-rate independent exponential smoothing helper: 1 - exp(-rate * dt)
	var yaw_alpha = 1.0 - exp(-camera_turn_lag * safe_delta)
	var pitch_alpha = 1.0 - exp(-4.0 * safe_delta)
	var lat_alpha = 1.0 - exp(-5.5 * safe_delta)

	# Handle camera mode:
	# When player is dragging or actively manipulating camera, the default chase turn-following
	# is completely OFF ("otomatis mati"). Turning the car has 0 effect on camera view.
	if _is_dragging_cam:
		_cam_idle_timer = 0.0
		_is_manual_mode = true
		_cam_lateral_shift = lerpf(_cam_lateral_shift, 0.0, 1.0 - exp(-8.0 * safe_delta))
	else:
		_cam_idle_timer += safe_delta
		# Re-engage chase alignment only after user is idle for > 3.0s AND driving fast
		var is_driving_fast = absf(car.forward_speed) > 4.5
		if is_driving_fast and _cam_idle_timer > 3.0:
			_cam_world_yaw = lerp_angle(_cam_world_yaw, car_yaw, yaw_alpha)
			_cam_pitch = lerpf(_cam_pitch, deg_to_rad(14.0), pitch_alpha)
			if absf(angle_difference(_cam_world_yaw, car_yaw)) < 0.04:
				_is_manual_mode = false
		elif not _is_manual_mode:
			# Normal chase camera: smoothly follow vehicle heading with rotational damping lag
			_cam_world_yaw = lerp_angle(_cam_world_yaw, car_yaw, yaw_alpha)

		# Lateral camera turn offset framing front wheels
		var steer_ratio = 0.0
		if "current_steer_angle" in car and "max_steer_angle" in car:
			if car.max_steer_angle > 0.001:
				steer_ratio = car.current_steer_angle / car.max_steer_angle
		var target_lateral = steer_ratio * camera_lateral_offset_factor
		if _is_manual_mode:
			target_lateral = 0.0
		_cam_lateral_shift = lerpf(_cam_lateral_shift, target_lateral, lat_alpha)

	# Subtle speed-based pullback (gives sense of acceleration without world-space lag stutter)
	var speed_ratio = clampf(absf(car.forward_speed) / 65.0, 0.0, 1.0)
	var target_pullback = speed_ratio * 1.15
	_cam_speed_pullback = lerpf(_cam_speed_pullback, target_pullback, 1.0 - exp(-4.5 * safe_delta))

	# Smoothly track safe obstacle-free camera distance
	var desired_dist = minf(_cam_distance + _cam_speed_pullback, _cam_safe_dist)
	desired_dist = maxf(desired_dist, min_camera_distance)
	var dist_rate = 22.0 if desired_dist < _cam_current_dist else 8.0
	_cam_current_dist = lerpf(_cam_current_dist, desired_dist, 1.0 - exp(-dist_rate * safe_delta))

	# Smooth vertical target slightly to absorb micro suspension bumps while locking XZ tightly to interpolated car
	var target_y = car_pos.y + 1.55
	if not _cam_y_initialized:
		_cam_smooth_y = target_y
		_cam_y_initialized = true
	else:
		_cam_smooth_y = lerpf(_cam_smooth_y, target_y, 1.0 - exp(-18.0 * safe_delta))

	var look_target = Vector3(car_pos.x, _cam_smooth_y, car_pos.z)
	var horiz_dist = _cam_current_dist * cos(_cam_pitch)
	var vert_dist = _cam_current_dist * sin(_cam_pitch)

	var cam_offset = Vector3(
		sin(_cam_world_yaw) * horiz_dist,
		vert_dist,
		cos(_cam_world_yaw) * horiz_dist
	)
	var cam_right = Vector3(cos(_cam_world_yaw), 0.0, -sin(_cam_world_yaw))
	cam_offset += cam_right * _cam_lateral_shift

	var final_pos = look_target + cam_offset
	# Absolute ground protection: camera must NEVER go below ground or view into void
	final_pos.y = maxf(final_pos.y, car_pos.y + 0.90)
	final_pos.y = maxf(final_pos.y, 1.4)

	# Anti-clip enforcement: never penetrate inside car body
	var to_cam_vec = final_pos - look_target
	var actual_dist = to_cam_vec.length()
	if actual_dist < min_camera_distance and actual_dist > 0.001:
		final_pos = look_target + to_cam_vec.normalized() * min_camera_distance

	camera.global_position = final_pos
	camera.look_at(look_target, Vector3.UP)

func _on_speed_changed(kmh: float) -> void:
	if speed_label:
		speed_label.text = "%d KM/H" % int(kmh)
	if speed_bar:
		speed_bar.value = clamp(kmh, 0.0, 260.0)

func _on_checkpoint_entered(idx: int) -> void:
	if is_finished:
		return
		
	if idx == next_checkpoint:
		next_checkpoint = (next_checkpoint + 1) % total_checkpoints
		
		# If completed full circuit loop (crossed checkpoint 0 after 3)
		if idx == 0:
			if current_lap_time < best_lap_time and current_lap > 0:
				best_lap_time = current_lap_time
				if best_label:
					best_label.text = "BEST: " + _format_time(best_lap_time)
					
			current_lap += 1
			current_lap_time = 0.0
			if lap_label:
				lap_label.text = "LAP %d / %d" % [current_lap, max_laps]
			if modern_hud:
				modern_hud.update_race_state(current_lap, max_laps, current_lap_time, best_lap_time, 1, 12)

			if current_lap > max_laps:
				_finish_race()

func _finish_race() -> void:
	is_finished = true
	if car:
		car.is_active = false
	if hud_layer:
		hud_layer.layer = 25
	if finish_panel:
		finish_panel.visible = true
		finish_panel.visible = true

	# Star and XP dynamic rating
	var stars_str = ""
	var rank_str = ""
	var xp_reward = 0
	var coin_reward = 0

	# Fast finish (<48s total or <16s best lap) awards maximum 3 Stars & 250 XP
	if total_race_time <= 48.0 or best_lap_time <= 16.0:
		stars_str = "★ ★ ★"
		rank_str = "S RANK - APEX MASTER"
		xp_reward = 250
		coin_reward = 5000
	elif total_race_time <= 68.0 or best_lap_time <= 22.0:
		stars_str = "★ ★ ☆"
		rank_str = "A RANK - PRO DRIVER"
		xp_reward = 175
		coin_reward = 3500
	else:
		stars_str = "★ ☆ ☆"
		rank_str = "B RANK - QUALIFIED"
		var scaling = 65.0 / max(total_race_time, 65.0)
		xp_reward = int(clamp(150.0 * scaling, 50.0, 150.0))
		coin_reward = 2000

	if finish_title:
		finish_title.text = "VICTORY - GRAND PRIX FINISHED"
	if finish_stars:
		finish_stars.text = stars_str
	if finish_rank:
		finish_rank.text = rank_str
	if finish_stats:
		finish_stats.text = "TOTAL TIME: %s\nBEST LAP: %s" % [_format_time(total_race_time), _format_time(best_lap_time)]
	if finish_rewards:
		finish_rewards.text = "REWARD: +%d XP  |  +%s COINS" % [xp_reward, _format_number(coin_reward)]

	# Award XP & Coins to PlayerProfile (advances level from Level 0)
	if has_node("/root/PlayerProfile"):
		var prof = get_node("/root/PlayerProfile")
		if prof.has_method("add_xp"):
			prof.add_xp(xp_reward)
		if prof.has_method("add_currency"):
			prof.add_currency(coin_reward, 0)

	# Award reward in SaveManager
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		if sm.has_method("add_coins"):
			sm.add_coins(coin_reward)

func _format_number(num: int) -> String:
	var s = str(num)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result

func _restart_race() -> void:
	get_tree().reload_current_scene()

func _format_time(sec: float) -> String:
	var mins = int(sec) / 60
	var s = int(sec) % 60
	var ms = int((sec - int(sec)) * 100.0)
	return "%02d:%02d.%02d" % [mins, s, ms]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if modern_hud and modern_hud.has_method("_open_pause_menu"):
			if modern_hud.is_paused:
				modern_hud._close_pause_menu()
			else:
				modern_hud._open_pause_menu()
		else:
			_return_to_home()
		return

	# Instant center hotkey (C key)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		if car:
			_cam_world_yaw = car.rotation.y
		_cam_pitch = deg_to_rad(14.0)
		_is_manual_mode = false
		_cam_idle_timer = 0.0
		return

	# Mouse Drag Rotation (180° / 360° orbit around car via Left, Right, or Middle Click)
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_is_dragging_cam = event.pressed
			if event.pressed:
				_is_manual_mode = true
				_cam_idle_timer = 0.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cam_distance = clampf(_cam_distance - 0.65, MIN_CAM_DIST, MAX_CAM_DIST)
			_cam_idle_timer = 0.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cam_distance = clampf(_cam_distance + 0.65, MIN_CAM_DIST, MAX_CAM_DIST)
			_cam_idle_timer = 0.0

	elif event is InputEventMouseMotion and _is_dragging_cam:
		_cam_world_yaw = wrapf(_cam_world_yaw - event.relative.x * MOUSE_SENSITIVITY, -PI, PI)
		# Safe pitch clamp (2.0° to 45.0°): camera stays above road horizon, impossible to view void
		_cam_pitch = clampf(_cam_pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(2.0), deg_to_rad(45.0))
		_is_manual_mode = true
		_cam_idle_timer = 0.0

	elif event is InputEventScreenTouch:
		_is_dragging_cam = event.pressed
		if event.pressed:
			_is_manual_mode = true
			_cam_idle_timer = 0.0

	elif event is InputEventScreenDrag:
		_cam_world_yaw = wrapf(_cam_world_yaw - event.relative.x * MOUSE_SENSITIVITY, -PI, PI)
		_cam_pitch = clampf(_cam_pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(2.0), deg_to_rad(45.0))
		_is_manual_mode = true
		_cam_idle_timer = 0.0

func _return_to_home() -> void:
	get_tree().change_scene_to_file("res://scenes/main/home_screen.tscn")
