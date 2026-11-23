class_name GarageCameraRig
extends Node3D

## AAA Need For Speed-Grade Unlimited 360+ Orbit Camera Rig for Garage3D.
## Supports continuous unclamped horizontal rotation (past +/-360 deg with zero snapping),
## exponential inertia damping, vertical pitch limits, smooth zoom, idle auto-orbit,
## curved-arch indoor anti-clip clamping, camera presets, and arrival dolly pulse.

signal preset_changed(preset_id: String)
signal user_interacted

@export var orbit_target: Vector3 = Vector3(0.18, 0.72, 0.0)
@export var default_distance: float = 5.35
@export var min_distance: float = 2.90
@export var max_distance: float = 7.40

@export var default_yaw_deg: float = 34.0
@export var default_pitch_deg: float = 11.5
@export var min_pitch_deg: float = 4.0
@export var max_pitch_deg: float = 54.0

@export var orbit_sensitivity: float = 0.0062
@export var pitch_sensitivity: float = 0.0052
@export var zoom_step: float = 0.42
@export var damping: float = 8.5

@export var auto_orbit_enabled: bool = true
@export var auto_orbit_speed_deg: float = 4.2
@export var auto_orbit_idle_delay: float = 4.0

## Safe indoor warehouse interior bounds (populated/calibrated by Garage3D)
@export var interior_bounds_min: Vector3 = Vector3(-5.85, 0.42, -19.5)
@export var interior_bounds_max: Vector3 = Vector3(5.85, 3.85, 19.5)
@export var arch_ceiling_peak_y: float = 4.42
@export var arch_ceiling_drop_k: float = 0.048

@onready var camera: Camera3D = $GarageCamera

var _target_yaw: float = 0.0
var _current_yaw: float = 0.0
var _target_pitch: float = 0.0
var _current_pitch: float = 0.0
var _target_distance: float = 5.35
var _current_distance: float = 5.35
var _target_pivot: Vector3 = Vector3(0.18, 0.72, 0.0)
var _current_pivot: Vector3 = Vector3(0.18, 0.72, 0.0)
var _dolly_offset: float = 0.0

var _is_dragging: bool = false
var _input_enabled: bool = true
var _idle_timer: float = 0.0
var _active_preset: String = "hero_34"
var _last_click_msec: int = 0
var _dolly_tween: Tween = null

const PRESETS: Dictionary = {
	"hero_34": {
		"yaw_deg": 38.0,
		"pitch_deg": 11.2,
		"distance": 6.15,
		"pivot": Vector3(-0.36, 0.44, 0.08),
	},
	"front": {
		"yaw_deg": 0.0,
		"pitch_deg": 9.0,
		"distance": 5.75,
		"pivot": Vector3(0.0, 0.46, 0.20),
	},
	"side": {
		"yaw_deg": 90.0,
		"pitch_deg": 9.5,
		"distance": 6.10,
		"pivot": Vector3(0.0, 0.46, 0.0),
	},
	"rear": {
		"yaw_deg": 180.0,
		"pitch_deg": 11.5,
		"distance": 5.85,
		"pivot": Vector3(0.0, 0.48, -0.15),
	},
	"wheel": {
		"yaw_deg": 56.0,
		"pitch_deg": 6.8,
		"distance": 3.25,
		"pivot": Vector3(0.55, 0.34, 1.15),
	},
}

func _ready() -> void:
	var p_data: Dictionary = PRESETS["hero_34"]
	_target_yaw = deg_to_rad(float(p_data["yaw_deg"]))
	_current_yaw = _target_yaw
	_target_pitch = deg_to_rad(float(p_data["pitch_deg"]))
	_current_pitch = _target_pitch
	_target_distance = float(p_data["distance"])
	_current_distance = _target_distance
	_target_pivot = p_data["pivot"]
	_current_pivot = _target_pivot
	_update_camera_transform()

func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_is_dragging = false

func set_interior_bounds(b_min: Vector3, b_max: Vector3, arch_peak: float = 4.42, arch_k: float = 0.048) -> void:
	interior_bounds_min = b_min
	interior_bounds_max = b_max
	arch_ceiling_peak_y = arch_peak
	arch_ceiling_drop_k = arch_k
	_update_camera_transform()

func set_auto_orbit(enabled: bool) -> void:
	auto_orbit_enabled = enabled

func set_preset(preset_id: String, instant: bool = false) -> void:
	if not PRESETS.has(preset_id):
		return
	var p_data: Dictionary = PRESETS[preset_id]
	var desired_deg: float = float(p_data["yaw_deg"])
	# Smoothly aim at the nearest equivalent full turn so presets glide naturally
	# without rewinding multiple revolutions after a 720-degree orbit!
	var current_deg: float = rad_to_deg(_target_yaw)
	var delta_deg: float = fposmod(desired_deg - current_deg + 180.0, 360.0) - 180.0
	_target_yaw = deg_to_rad(current_deg + delta_deg)
	_target_pitch = deg_to_rad(clampf(float(p_data["pitch_deg"]), min_pitch_deg, max_pitch_deg))
	_target_distance = clampf(float(p_data["distance"]), min_distance, max_distance)
	_target_pivot = p_data["pivot"]
	_active_preset = preset_id
	_idle_timer = 0.0
	if instant:
		_current_yaw = _target_yaw
		_current_pitch = _target_pitch
		_current_distance = _target_distance
		_current_pivot = _target_pivot
		_update_camera_transform()
	preset_changed.emit(preset_id)

func reset_camera(instant: bool = false) -> void:
	set_preset("hero_34", instant)

func play_arrival_dolly_pulse() -> void:
	if _dolly_tween and _dolly_tween.is_valid():
		_dolly_tween.kill()
	_dolly_offset = 0.0
	_dolly_tween = create_tween()
	_dolly_tween.tween_property(self, "_dolly_offset", -0.18, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_dolly_tween.tween_property(self, "_dolly_offset", 0.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Programmatic continuous orbit helper (also used by automated verification tests)
func orbit_by_degrees(delta_yaw_deg: float, delta_pitch_deg: float = 0.0, instant: bool = false) -> void:
	_target_yaw += deg_to_rad(delta_yaw_deg)
	_target_pitch = clampf(
		_target_pitch + deg_to_rad(delta_pitch_deg),
		deg_to_rad(min_pitch_deg),
		deg_to_rad(max_pitch_deg)
	)
	_idle_timer = 0.0
	if instant:
		_current_yaw = _target_yaw
		_current_pitch = _target_pitch
		_update_camera_transform()

func set_continuous_angles_deg(yaw_deg: float, pitch_deg: float, distance: float = -1.0, instant: bool = false) -> void:
	_target_yaw = deg_to_rad(yaw_deg)
	_target_pitch = clampf(deg_to_rad(pitch_deg), deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	if distance > 0.0:
		_target_distance = clampf(distance, min_distance, max_distance)
	_idle_timer = 0.0
	if instant:
		_current_yaw = _target_yaw
		_current_pitch = _target_pitch
		_current_distance = _target_distance
		_update_camera_transform()

func get_current_yaw_deg() -> float:
	return rad_to_deg(_current_yaw)

func get_target_yaw_deg() -> float:
	return rad_to_deg(_target_yaw)

func get_camera_world_pos() -> Vector3:
	return camera.global_position if camera else global_position

func is_camera_within_bounds(margin: float = 0.05) -> bool:
	var pos: Vector3 = get_camera_world_pos()
	if pos.x < interior_bounds_min.x - margin or pos.x > interior_bounds_max.x + margin:
		return false
	if pos.z < interior_bounds_min.z - margin or pos.z > interior_bounds_max.z + margin:
		return false
	if pos.y < interior_bounds_min.y - margin:
		return false
	var arch_max_y: float = _get_arch_ceiling_y(pos.x)
	if pos.y > minf(interior_bounds_max.y, arch_max_y) + margin:
		return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var now_ms: int = Time.get_ticks_msec()
				if mb.double_click or (now_ms - _last_click_msec < 320):
					reset_camera()
					_last_click_msec = 0
					_is_dragging = false
				else:
					_last_click_msec = now_ms
					_is_dragging = true
					_idle_timer = 0.0
					user_interacted.emit()
			else:
				_is_dragging = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_target_distance = clampf(_target_distance - zoom_step, min_distance, max_distance)
			_idle_timer = 0.0
			user_interacted.emit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_target_distance = clampf(_target_distance + zoom_step, min_distance, max_distance)
			_idle_timer = 0.0
			user_interacted.emit()

	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		# Continuous unclamped yaw: NEVER wrap or clamp _target_yaw so user can spin infinitely!
		_target_yaw -= mm.relative.x * orbit_sensitivity
		_target_pitch = clampf(
			_target_pitch + mm.relative.y * pitch_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		_idle_timer = 0.0

	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_target_yaw -= sd.relative.x * orbit_sensitivity
		_target_pitch = clampf(
			_target_pitch + sd.relative.y * pitch_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		_idle_timer = 0.0
		user_interacted.emit()

	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		if mg.factor > 0.01:
			_target_distance = clampf(_target_distance / mg.factor, min_distance, max_distance)
			_idle_timer = 0.0
			user_interacted.emit()

func _process(delta: float) -> void:
	if not _is_dragging:
		_idle_timer += delta
		if auto_orbit_enabled and _idle_timer >= auto_orbit_idle_delay:
			_target_yaw += deg_to_rad(auto_orbit_speed_deg) * delta

	var alpha: float = 1.0 - exp(-damping * delta)
	# Strictly use lerpf (NOT lerp_angle!) on _current_yaw so unlimited 360+ rotations
	# remain continuous and monotonic without ever snapping or wrapping!
	_current_yaw = lerpf(_current_yaw, _target_yaw, alpha)
	_current_pitch = lerpf(_current_pitch, _target_pitch, alpha)
	_current_distance = lerpf(_current_distance, _target_distance, alpha)
	_current_pivot = _current_pivot.lerp(_target_pivot, alpha)
	_update_camera_transform()

func _get_arch_ceiling_y(world_x: float) -> float:
	return clampf(arch_ceiling_peak_y - arch_ceiling_drop_k * world_x * world_x, 2.35, interior_bounds_max.y)

func _clamp_camera_inside_garage(pivot: Vector3, desired_pos: Vector3) -> Vector3:
	var dir: Vector3 = desired_pos - pivot
	var t_max: float = 1.0

	# 1. Analytical ray-box clamping against flat side/end walls & floor
	if dir.x > 0.0001 and desired_pos.x > interior_bounds_max.x:
		t_max = minf(t_max, (interior_bounds_max.x - pivot.x) / dir.x)
	elif dir.x < -0.0001 and desired_pos.x < interior_bounds_min.x:
		t_max = minf(t_max, (interior_bounds_min.x - pivot.x) / dir.x)

	if dir.z > 0.0001 and desired_pos.z > interior_bounds_max.z:
		t_max = minf(t_max, (interior_bounds_max.z - pivot.z) / dir.z)
	elif dir.z < -0.0001 and desired_pos.z < interior_bounds_min.z:
		t_max = minf(t_max, (interior_bounds_min.z - pivot.z) / dir.z)

	if dir.y < -0.0001 and desired_pos.y < interior_bounds_min.y:
		t_max = minf(t_max, (interior_bounds_min.y - pivot.y) / dir.y)
	elif dir.y > 0.0001 and desired_pos.y > interior_bounds_max.y:
		t_max = minf(t_max, (interior_bounds_max.y - pivot.y) / dir.y)

	t_max = clampf(t_max, 0.25, 1.0)
	var clamped: Vector3 = pivot + dir * t_max

	# 2. Curved arch roof clearance refinement
	var arch_y: float = _get_arch_ceiling_y(clamped.x)
	if clamped.y > arch_y:
		# Pull smoothly along ray until safely beneath the curved industrial arch
		var lo: float = 0.25
		var hi: float = t_max
		for _iter in range(8):
			var mid: float = (lo + hi) * 0.5
			var cand: Vector3 = pivot + dir * mid
			if cand.y <= _get_arch_ceiling_y(cand.x):
				lo = mid
			else:
				hi = mid
		clamped = pivot + dir * lo

	clamped.x = clampf(clamped.x, interior_bounds_min.x, interior_bounds_max.x)
	clamped.z = clampf(clamped.z, interior_bounds_min.z, interior_bounds_max.z)
	clamped.y = clampf(clamped.y, interior_bounds_min.y, minf(interior_bounds_max.y, _get_arch_ceiling_y(clamped.x)))
	return clamped

func _update_camera_transform() -> void:
	if not camera:
		return
	var eff_dist: float = clampf(_current_distance + _dolly_offset, min_distance * 0.85, max_distance)
	var cos_p: float = cos(_current_pitch)
	var offset := Vector3(
		sin(_current_yaw) * cos_p * eff_dist,
		sin(_current_pitch) * eff_dist,
		cos(_current_yaw) * cos_p * eff_dist
	)
	var desired_pos: Vector3 = _current_pivot + offset
	var safe_pos: Vector3 = _clamp_camera_inside_garage(_current_pivot, desired_pos)
	camera.global_position = safe_pos
	camera.look_at(_current_pivot, Vector3.UP)
