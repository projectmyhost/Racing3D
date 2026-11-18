class_name ShowcaseCameraRig
extends Node3D

## Interactive 360Â° Orbit Camera Rig for Sunset Street Racing.
## Allows the user to drag freely to inspect the vehicle from any angle,
## zoom in/out with the mouse wheel, and smoothly returns to cinematic showcase.

@export var orbit_target: Vector3 = Vector3(1.4, 0.55, -0.1) # Center of ShowcaseCar in road lane
@export var default_distance: float = 8.2
@export var min_distance: float = 3.0
@export var max_distance: float = 14.0

@export var default_yaw_deg: float = -144.0
@export var default_pitch_deg: float = 6.5
@export var min_pitch_deg: float = 2.0
@export var max_pitch_deg: float = 55.0

@export var mouse_sensitivity: float = 0.005
@export var zoom_sensitivity: float = 0.65
@export var smoothness: float = 10.0
@export var auto_idle_orbit: bool = true
@export var idle_timeout: float = 2.0
@export var idle_orbit_speed: float = 0.022 # rad/s smooth cinematic drift

@onready var camera: Camera3D = $ShowcaseCamera

var _current_yaw: float
var _target_yaw: float
var _current_pitch: float
var _target_pitch: float
var _current_dist: float
var _target_dist: float

var _is_dragging: bool = false
var _idle_timer: float = 0.0
var _reset_tween: Tween

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_current_yaw = deg_to_rad(default_yaw_deg)
	_target_yaw = _current_yaw
	_current_pitch = deg_to_rad(default_pitch_deg)
	_target_pitch = _current_pitch
	_current_dist = default_distance
	_target_dist = default_distance
	
	if camera:
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		camera.fov = 35.0
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.near = 0.1
		camera.far = 800.0
		
	_update_camera_transform(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_is_dragging = true
				_idle_timer = 0.0
				if _reset_tween and _reset_tween.is_valid():
					_reset_tween.kill()
			else:
				_is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_target_dist = clampf(_target_dist - zoom_sensitivity, min_distance, max_distance)
			_idle_timer = 0.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_target_dist = clampf(_target_dist + zoom_sensitivity, min_distance, max_distance)
			_idle_timer = 0.0
			
	elif event is InputEventScreenTouch:
		if event.pressed:
			_is_dragging = true
			_idle_timer = 0.0
			if _reset_tween and _reset_tween.is_valid():
				_reset_tween.kill()
		else:
			_is_dragging = false

	elif event is InputEventScreenDrag:
		_target_yaw += -event.relative.x * mouse_sensitivity
		_target_pitch = clampf(_target_pitch + event.relative.y * mouse_sensitivity, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
		_idle_timer = 0.0

func _input(event: InputEvent) -> void:
	if _is_dragging:
		if event is InputEventMouseMotion:
			_target_yaw += -event.relative.x * mouse_sensitivity
			_target_pitch = clampf(_target_pitch + event.relative.y * mouse_sensitivity, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
			_idle_timer = 0.0
		elif event is InputEventMouseButton and not event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
				_is_dragging = false
		elif event is InputEventScreenTouch and not event.pressed:
			_is_dragging = false

func _process(delta: float) -> void:
	if not camera:
		return
		
	var safe_delta = clampf(delta, 0.0001, 0.05)
	if not _is_dragging:
		_idle_timer += safe_delta
		if auto_idle_orbit and _idle_timer > idle_timeout:
			_target_yaw += idle_orbit_speed * safe_delta
			
	var alpha = 1.0 - exp(-smoothness * safe_delta)
	_current_yaw = lerp_angle(_current_yaw, _target_yaw, alpha)
	_current_pitch = lerpf(_current_pitch, _target_pitch, alpha)
	_current_dist = lerpf(_current_dist, _target_dist, alpha)
	
	_update_camera_transform(false)

func _update_camera_transform(immediate: bool) -> void:
	var yaw_val = _current_yaw if not immediate else _target_yaw
	var pitch_val = _current_pitch if not immediate else _target_pitch
	var dist_val = _current_dist if not immediate else _target_dist
	
	var cos_p = cos(pitch_val)
	var sin_p = sin(pitch_val)
	var sin_y = sin(yaw_val)
	var cos_y = cos(yaw_val)
	
	var offset = Vector3(sin_y * cos_p, sin_p, cos_y * cos_p) * dist_val
	position = orbit_target + offset
	if camera:
		camera.look_at(orbit_target, Vector3.UP)

## Smoothly tweens camera back to default showcase view
func reset_to_default(duration: float = 0.8) -> void:
	if _reset_tween and _reset_tween.is_valid():
		_reset_tween.kill()
		
	_is_dragging = false
	_idle_timer = 0.0
	
	_reset_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_reset_tween.parallel().tween_property(self, "_target_yaw", deg_to_rad(default_yaw_deg), duration)
	_reset_tween.parallel().tween_property(self, "_target_pitch", deg_to_rad(default_pitch_deg), duration)
	_reset_tween.parallel().tween_property(self, "_target_dist", default_distance, duration)
