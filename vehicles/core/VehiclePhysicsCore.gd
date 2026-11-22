class_name VehiclePhysicsCore
extends RigidBody3D

# Universal Professional Vehicle Dynamics Physics Core.
# Built on RigidBody3D with 4-wheel independent raycast suspension,
# asymmetric bump/rebound damping, anti-roll bar force transfer,
# friction-circle tire dynamics with realistic slip bite, dynamic weight transfer,
# aerodynamic downforce/drag, and automatic transmission.
# Purely data-driven: zero car names or asset paths hardcoded.

signal speed_changed(kmh: float)
signal gear_changed(gear: int)
signal rpm_changed(rpm: float, max_rpm: float)
signal lap_finished(lap_num: int, lap_time: float)
signal checkpoint_hit(idx: int)

@export var config: VehicleConfig

# Public properties for camera and game system compatibility
var is_active: bool = true
var forward_speed: float = 0.0
var lateral_speed: float = 0.0
var current_steer_angle: float = 0.0
var max_steer_angle: float = 0.593
var current_gear: int = 1
var engine_rpm: float = 850.0

# Subcomponents
var visual_adapter: VehicleVisualAdapter
var chassis_collision: CollisionShape3D

# Internal wheel simulation states: 0=FL, 1=FR, 2=RL, 3=RR
class WheelState:
	var mount_local_pos: Vector3 = Vector3.ZERO
	var is_front: bool = false
	var is_left: bool = false
	var is_drive: bool = false
	var is_grounded: bool = false
	var contact_point: Vector3 = Vector3.ZERO
	var contact_normal: Vector3 = Vector3.UP
	var suspension_length: float = 0.38
	var compression: float = 0.0
	var prev_compression: float = 0.0
	var was_grounded: bool = false
	var suspension_velocity: float = 0.0
	var mount_compress_vel: float = 0.0
	var spring_force_mag: float = 0.0
	var normal_force_mag: float = 0.0
	var wheel_angular_velocity: float = 0.0
	var steer_angle: float = 0.0
	var slip_ratio: float = 0.0
	var slip_angle: float = 0.0

var _wheels: Array[WheelState] = []
var _steer_input: float = 0.0
var _throttle_input: float = 0.0
var _brake_input: float = 0.0
var _handbrake_input: float = 0.0

# Progressive smoothed input channels for anti-snap acceleration and braking
var smoothed_throttle: float = 0.0
var smoothed_brake: float = 0.0

# Second-order damped harmonic spring states for pitch and heave suspension dynamics
var current_pitch: float = 0.0
var pitch_velocity: float = 0.0
var current_heave: float = 0.0
var heave_velocity: float = 0.0
var _prev_fwd_speed: float = 0.0
var _long_acceleration: float = 0.0

var _shift_timer: float = 0.0
var _is_shifting: bool = false
var override_inputs: bool = false
var _unflip_timer: float = 0.0
var _unflip_cooldown: float = 0.0
var _wheel_ray_query: PhysicsRayQueryParameters3D = null

# Allows AI, replays, or automated test harnesses to control vehicle inputs
func set_driver_input(throttle: float, brake: float, steer: float, handbrake: float) -> void:
	override_inputs = true
	_throttle_input = clampf(throttle, -1.0, 1.0)
	_brake_input = clampf(brake, 0.0, 1.0)
	_handbrake_input = clampf(handbrake, 0.0, 1.0)
	_steer_input = clampf(steer, -1.0, 1.0)
	current_steer_angle = _steer_input * max_steer_angle

# Calculates optimal spawn Y coordinate above ground for immediate equilibrium
func get_spawn_height() -> float:
	if not config: return 0.55 * VehicleConfig.WORLD_SCALE
	var c := config.create_world_scaled_copy()
	var k_total = (c.spring_stiffness_front + c.spring_stiffness_rear) * 2.0
	var eq_compression = (c.mass * 9.8) / maxf(k_total, 1000.0)
	var mount_y = c.suspension_rest_length * 0.5
	return c.wheel_radius + c.suspension_rest_length - eq_compression - mount_y

func _ready() -> void:
	continuous_cd = true
	max_contacts_reported = 4
	contact_monitor = true
	collision_layer = 2
	collision_mask = 1
	
	if not config:
		var car_id = "sedan"
		if has_node("/root/PlayerProfile"):
			var prof = get_node("/root/PlayerProfile")
			if prof.data and not prof.data.equipped_car.is_empty():
				car_id = prof.data.equipped_car
		elif has_node("/root/SaveManager"):
			var sm = get_node("/root/SaveManager")
			if sm.has_method("get_selected_car"):
				car_id = sm.get_selected_car()
		config = VehicleRegistry.get_config(car_id)
		
	initialize_vehicle(config)

func initialize_vehicle(target: Variant) -> void:
	var p_config: VehicleConfig = null
	if target is String:
		p_config = VehicleRegistry.get_config(target)
	elif target is VehicleConfig:
		p_config = target
	elif target == null and config:
		p_config = config
	else:
		p_config = VehicleRegistry.get_config("sedan")
		
	if not p_config:
		push_error("VehiclePhysicsCore: Cannot initialize with null config.")
		return
	config = p_config.create_world_scaled_copy()
	
	mass = config.mass
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = config.center_of_mass_offset
	max_steer_angle = deg_to_rad(config.max_steer_angle_deg)
	contact_monitor = true
	max_contacts_reported = 6
	var chassis_mat := PhysicsMaterial.new()
	chassis_mat.bounce = 0.0
	chassis_mat.absorbent = true
	chassis_mat.friction = 0.18
	physics_material_override = chassis_mat
	
	_setup_wheel_states()
	_setup_visual_adapter()
	_setup_chassis_collision()
	
	forward_speed = 0.0
	lateral_speed = 0.0
	current_steer_angle = 0.0
	current_gear = 1
	engine_rpm = config.idle_engine_rpm
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _setup_chassis_collision() -> void:
	if not chassis_collision:
		chassis_collision = get_node_or_null("ChassisCollision") as CollisionShape3D
		if not chassis_collision:
			chassis_collision = get_node_or_null("CarCollision") as CollisionShape3D
		if not chassis_collision:
			chassis_collision = CollisionShape3D.new()
			chassis_collision.name = "ChassisCollision"
			add_child(chassis_collision)
		else:
			chassis_collision.name = "ChassisCollision"
	for child in get_children():
		if child is CollisionShape3D and child != chassis_collision:
			child.queue_free()
	var body_min_y: float = visual_adapter.get_visual_body_min_y() if visual_adapter else -999.0
	chassis_collision.shape = VehicleCollisionBuilder.build_chassis_shape(config, body_min_y)
	chassis_collision.position = Vector3.ZERO

func _setup_wheel_states() -> void:
	_wheels.clear()
	var half_wb = config.wheelbase * 0.5
	var half_tw_f = config.track_width_front * 0.5
	var half_tw_r = config.track_width_rear * 0.5
	# Suspension mounts located at chassis level
	var mount_y = config.suspension_rest_length * 0.5
	
	var is_fwd = (config.drivetrain_type == 0)
	var is_rwd = (config.drivetrain_type == 1)
	var is_awd = (config.drivetrain_type == 2)
	
	# 0 = FL
	var w_fl = WheelState.new()
	w_fl.mount_local_pos = Vector3(-half_tw_f, mount_y, -half_wb)
	w_fl.is_front = true
	w_fl.is_left = true
	w_fl.is_drive = is_fwd or is_awd
	_wheels.append(w_fl)
	
	# 1 = FR
	var w_fr = WheelState.new()
	w_fr.mount_local_pos = Vector3(half_tw_f, mount_y, -half_wb)
	w_fr.is_front = true
	w_fr.is_left = false
	w_fr.is_drive = is_fwd or is_awd
	_wheels.append(w_fr)
	
	# 2 = RL
	var w_rl = WheelState.new()
	w_rl.mount_local_pos = Vector3(-half_tw_r, mount_y, half_wb)
	w_rl.is_front = false
	w_rl.is_left = true
	w_rl.is_drive = is_rwd or is_awd
	_wheels.append(w_rl)
	
	# 3 = RR
	var w_rr = WheelState.new()
	w_rr.mount_local_pos = Vector3(half_tw_r, mount_y, half_wb)
	w_rr.is_front = false
	w_rr.is_left = false
	w_rr.is_drive = is_rwd or is_awd
	_wheels.append(w_rr)

func _setup_visual_adapter() -> void:
	if visual_adapter and is_instance_valid(visual_adapter):
		visual_adapter.queue_free()
	visual_adapter = VehicleVisualAdapter.new()
	visual_adapter.name = "VisualAdapter"
	add_child(visual_adapter)
	visual_adapter.setup(config)

func _physics_process(delta: float) -> void:
	var safe_delta = clampf(delta, 0.001, 0.05)
	
	_read_player_inputs(safe_delta)
	_update_transmission_and_rpm(safe_delta)
	_solve_suspension_raycasts(safe_delta)
	_solve_suspension_forces(safe_delta)
	_solve_tire_forces(safe_delta)
	_solve_aerodynamics(safe_delta)
	_solve_slope_hold_stabilization(safe_delta)
	_update_visual_adapter(safe_delta)
	_check_auto_unflip(safe_delta)
	
	var fwd_dir = -global_transform.basis.z
	var right_dir = global_transform.basis.x
	forward_speed = linear_velocity.dot(fwd_dir)
	lateral_speed = linear_velocity.dot(right_dir)
	
	var speed_kmh = absf(forward_speed) * 3.6
	speed_changed.emit(speed_kmh)
	rpm_changed.emit(engine_rpm, config.max_engine_rpm)
	
	if global_position.y < -15.0:
		respawn(Vector3(-30.0, 36.5, 146.0), deg_to_rad(-90.0))

func _read_player_inputs(delta: float) -> void:
	if not is_active:
		_throttle_input = 0.0
		_brake_input = 0.5
		_handbrake_input = 0.0
		_steer_input = move_toward(_steer_input, 0.0, config.return_speed * delta)
		current_steer_angle = _steer_input * max_steer_angle
		smoothed_throttle = move_toward(smoothed_throttle, 0.0, 6.0 * delta)
		smoothed_brake = move_toward(smoothed_brake, 0.5, 6.0 * delta)
		return
		
	if override_inputs:
		var ov_throttle_rate = 4.0 if absf(_throttle_input) > absf(smoothed_throttle) else 6.0
		smoothed_throttle = move_toward(smoothed_throttle, _throttle_input, ov_throttle_rate * delta)
		var ov_brake_rate = 4.5 if _brake_input > smoothed_brake else 6.5
		smoothed_brake = move_toward(smoothed_brake, _brake_input, ov_brake_rate * delta)
		return
		
	var raw_throttle = Input.get_action_strength("ui_up")
	var raw_brake = Input.get_action_strength("ui_down")
	var raw_steer = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	
	if raw_throttle == 0.0 and Input.is_key_pressed(KEY_W): raw_throttle = 1.0
	if raw_brake == 0.0 and Input.is_key_pressed(KEY_S): raw_brake = 1.0
	if raw_steer == 0.0:
		if Input.is_key_pressed(KEY_A): raw_steer += 1.0
		if Input.is_key_pressed(KEY_D): raw_steer -= 1.0
		
	var raw_handbrake = 1.0 if Input.is_key_pressed(KEY_SPACE) else 0.0
	
	if forward_speed < -0.5 and raw_brake > 0.0:
		_throttle_input = -raw_brake
		_brake_input = 0.0
	elif forward_speed < 0.2 and raw_brake > 0.0:
		_throttle_input = -raw_brake
		_brake_input = 0.0
	else:
		_throttle_input = raw_throttle
		_brake_input = raw_brake
		
	_handbrake_input = raw_handbrake
	
	# Progressive throttle and brake smoothing to prevent snap on/off
	var throttle_rate = 4.0 if absf(_throttle_input) > absf(smoothed_throttle) else 6.0
	smoothed_throttle = move_toward(smoothed_throttle, _throttle_input, throttle_rate * delta)
	
	var brake_rate = 4.5 if _brake_input > smoothed_brake else 6.5
	smoothed_brake = move_toward(smoothed_brake, _brake_input, brake_rate * delta)
	
	var speed_kmh = absf(forward_speed) * 3.6
	var dyn_max_steer: float
	if speed_kmh <= 120.0:
		var mid_t := clampf((speed_kmh - 28.0) / 92.0, 0.0, 1.0)
		dyn_max_steer = lerpf(deg_to_rad(config.max_steer_angle_deg), deg_to_rad(config.min_steer_angle_deg), mid_t)
	else:
		var hi_t := clampf((speed_kmh - 120.0) / 140.0, 0.0, 1.0)
		# Smooth ease-out to agile high-speed angle (~5 deg) prevents sudden spinout on A/D lane changes
		hi_t = 1.0 - pow(1.0 - hi_t, 1.5)
		dyn_max_steer = lerpf(deg_to_rad(config.min_steer_angle_deg), deg_to_rad(config.high_speed_steer_angle_deg), hi_t)
	max_steer_angle = dyn_max_steer
	
	var target_steer = raw_steer * dyn_max_steer
	# Keep steering crisp yet progressive at highway/top speeds so A/D taps never snap chassis yaw
	var speed_steer_rate_scale := lerpf(1.0, 0.62, clampf((speed_kmh - 100.0) / 160.0, 0.0, 1.0))
	var steer_rate = config.return_speed
	if raw_steer != 0.0:
		if current_steer_angle * raw_steer < 0.0:
			steer_rate = config.counter_steer_speed * lerpf(1.0, 0.78, clampf((speed_kmh - 100.0) / 160.0, 0.0, 1.0))
		else:
			steer_rate = config.steer_speed * speed_steer_rate_scale
	current_steer_angle = move_toward(current_steer_angle, target_steer, steer_rate * delta)
	_steer_input = current_steer_angle / maxf(dyn_max_steer, 0.001)

func _update_transmission_and_rpm(delta: float) -> void:
	if _is_shifting:
		_shift_timer -= delta
		if _shift_timer <= 0.0:
			_is_shifting = false
			
	var speed_abs = absf(forward_speed)
	var num_gears = config.gear_ratios.size()
	
	if current_gear < 1: current_gear = 1
	if current_gear > num_gears: current_gear = num_gears
	
	var current_ratio = config.gear_ratios[current_gear - 1]
	var wheel_rot_rad_s = speed_abs / maxf(config.wheel_radius, 0.1)
	var driveshaft_rpm = (wheel_rot_rad_s * config.final_drive_ratio * current_ratio * 60.0) / (2.0 * PI)
	
	if absf(smoothed_throttle) > 0.01 and not _is_shifting:
		engine_rpm = maxf(driveshaft_rpm, config.idle_engine_rpm)
	else:
		engine_rpm = move_toward(engine_rpm, config.idle_engine_rpm, 2500.0 * delta)
	engine_rpm = clampf(engine_rpm, config.idle_engine_rpm, config.max_engine_rpm)
	
	if not _is_shifting:
		if engine_rpm > config.max_engine_rpm * 0.92 and current_gear < num_gears:
			current_gear += 1
			_is_shifting = true
			_shift_timer = config.shift_time_seconds
			gear_changed.emit(current_gear)
		elif engine_rpm < config.max_engine_rpm * 0.45 and current_gear > 1:
			current_gear -= 1
			_is_shifting = true
			_shift_timer = config.shift_time_seconds
			gear_changed.emit(current_gear)

func _solve_suspension_raycasts(_delta: float) -> void:
	var s: float = config.get_world_scale()
	var space = get_world_3d().direct_space_state
	var self_rid = get_rid()
	var ray_headroom = 0.55 * s
	var max_cast_dist = config.suspension_rest_length + config.suspension_travel + config.wheel_radius + ray_headroom
	var chassis_up = global_transform.basis.y.normalized()
	
	if _wheel_ray_query == null:
		_wheel_ray_query = PhysicsRayQueryParameters3D.new()
		_wheel_ray_query.hit_back_faces = true
	_wheel_ray_query.collision_mask = collision_mask
	_wheel_ray_query.exclude = [self_rid]

	for i in range(4):
		var w = _wheels[i]
		w.was_grounded = w.is_grounded
		w.prev_compression = w.compression
		var mount_world = global_transform * w.mount_local_pos
		var mount_rel = mount_world - global_position
		var mount_vel = linear_velocity + angular_velocity.cross(mount_rel)
		w.mount_compress_vel = -mount_vel.dot(chassis_up)
		var ray_origin = mount_world + chassis_up * ray_headroom
		var ray_target = ray_origin - chassis_up * max_cast_dist
		
		_wheel_ray_query.from = ray_origin
		_wheel_ray_query.to = ray_target
		var hit: Dictionary = space.intersect_ray(_wheel_ray_query)
		
		# Road surface normal check: handle double-sided reverse-wound road faces while rejecting steep walls
		var is_road_surface = false
		var hit_normal := Vector3.UP
		if not hit.is_empty():
			hit_normal = hit.normal
			if hit_normal.dot(Vector3.UP) < -0.55 and hit_normal.dot(chassis_up) < -0.45:
				hit_normal = -hit_normal
			var world_up_dot = hit_normal.dot(Vector3.UP)
			var chassis_up_dot = hit_normal.dot(chassis_up)
			if world_up_dot > 0.55 and chassis_up_dot > 0.45:
				is_road_surface = true
				
		if not hit.is_empty() and is_road_surface:
			w.is_grounded = true
			w.contact_point = hit.position
			w.contact_normal = hit_normal.normalized()
			var slope_compress_vel := -mount_vel.dot(w.contact_normal)
			if slope_compress_vel > w.mount_compress_vel:
				w.mount_compress_vel = slope_compress_vel
			
			# Displacement measured strictly along chassis suspension strut axis
			var dist_along_axis = (ray_origin - hit.position).dot(chassis_up) - ray_headroom
			w.suspension_length = maxf(0.0, dist_along_axis - config.wheel_radius)
			w.compression = clampf(config.suspension_rest_length - w.suspension_length, 0.0, config.suspension_travel)
			if not w.was_grounded:
				w.prev_compression = w.compression
		else:
			w.is_grounded = false
			w.compression = 0.0
			w.suspension_length = config.suspension_rest_length + config.suspension_travel
			w.contact_point = mount_world - chassis_up * (config.suspension_rest_length + config.wheel_radius)
			w.contact_normal = chassis_up

func _solve_suspension_forces(delta: float) -> void:
	var s: float = config.get_world_scale()
	for w in _wheels:
		var raw_vel := (w.compression - w.prev_compression) / maxf(delta, 0.001)
		if w.is_grounded and not w.was_grounded:
			# Engage hydraulic compression damping immediately on touchdown frame
			raw_vel = maxf(w.mount_compress_vel, raw_vel)
		elif w.is_grounded and w.compression >= config.suspension_travel * 0.985:
			# Bottomed out: compression saturates at max travel, so track real strut body velocity
			raw_vel = w.mount_compress_vel
		w.suspension_velocity = clampf(raw_vel, -6.5 * s, 6.5 * s)
		
	# Anti-Roll Bar Force computation
	var arb_f = (_wheels[0].compression - _wheels[1].compression) * config.anti_roll_front
	var arb_r = (_wheels[2].compression - _wheels[3].compression) * config.anti_roll_rear
	var arb_forces = [arb_f, -arb_f, arb_r, -arb_r]
	
	var chassis_up = global_transform.basis.y.normalized()
	var corner_mass := config.mass * 0.25
	var corner_weight := corner_mass * 9.8
	
	for i in range(4):
		var w = _wheels[i]
		if not w.is_grounded or w.compression <= 0.0001:
			w.spring_force_mag = 0.0
			w.normal_force_mag = 0.0
			continue
			
		var k = config.spring_stiffness_front if w.is_front else config.spring_stiffness_rear
		var c_bump = config.bump_damping_front if w.is_front else config.bump_damping_rear
		var c_reb = config.rebound_damping_front if w.is_front else config.rebound_damping_rear
		var c_crit := 2.0 * sqrt(maxf(k * corner_mass, 1.0))
		
		var f_spring = k * w.compression
		var f_damp := 0.0
		var hs_impact := 0.0
		if w.suspension_velocity >= 0.0:
			var comp_ratio := clampf(w.compression / maxf(config.suspension_travel, 0.01), 0.0, 1.0)
			var hs_blend := clampf((w.suspension_velocity - 0.45 * s) / (1.4 * s), 0.0, 1.0)
			var deep_blend := clampf((comp_ratio - 0.50) / 0.50, 0.0, 1.0)
			hs_impact = clampf((w.suspension_velocity - 0.75 * s) / (2.2 * s), 0.0, 1.0)
			var c_bump_eff := lerpf(c_bump, maxf(c_bump * 1.85, c_crit * 1.15), clampf(hs_blend * 0.65 + deep_blend * 0.65, 0.0, 1.0))
			f_damp = c_bump_eff * w.suspension_velocity
		else:
			# Critically damped asymmetric rebound absorbs jump energy without catapulting back into the air
			var c_reb_eff := maxf(c_reb, c_crit * 1.25)
			f_damp = c_reb_eff * w.suspension_velocity
		var f_arb = arb_forces[i]
		
		# Progressive viscoelastic elastomer bump-stop (high hysteresis, minimal spring-back)
		var f_bump_stop = 0.0
		var bump_threshold = config.suspension_travel * 0.75
		if w.compression > bump_threshold:
			var excess_norm = clampf((w.compression - bump_threshold) / maxf(config.suspension_travel - bump_threshold, 0.001), 0.0, 1.0)
			if w.suspension_velocity >= 0.0:
				var bs_spring = minf(config.bump_stop_stiffness, k * 0.30) * (excess_norm * excess_norm)
				var bs_damp = maxf(config.bump_stop_damping, c_crit * 1.05) * w.suspension_velocity * excess_norm
				f_bump_stop = bs_spring + bs_damp
			else:
				var bs_reb_spring = minf(config.bump_stop_stiffness, k * 0.10) * (excess_norm * excess_norm)
				var bs_reb_damp = (c_crit * 0.75) * w.suspension_velocity * excess_norm
				f_bump_stop = maxf(0.0, bs_reb_spring + bs_reb_damp)
			
		# Allow high-speed hydraulic absorption on hard landings, while softly clamping rebound push
		var rebound_fade := clampf((-w.mount_compress_vel - 0.05 * s) / (0.35 * s), 0.0, 1.0)
		var comp_cap := lerpf(corner_weight * 4.2, corner_weight * 7.8, hs_impact)
		var force_cap := lerpf(comp_cap, corner_weight * 1.12, rebound_fade)
		var f_total_normal = clampf(f_spring + f_damp + f_arb + f_bump_stop, 0.0, force_cap)
		w.spring_force_mag = f_spring
		w.normal_force_mag = f_total_normal
		
		# Apply suspension normal force along chassis strut axis to eliminate lateral rollover torque
		var force_vec = chassis_up * f_total_normal
		var contact_offset = w.contact_point - global_position
		apply_force(force_vec, contact_offset)

	# GTA V Crest & Landing Shock Absorber: damps pitch/roll oscillation cleanly
	var grounded_wheels := 0
	for w in _wheels:
		if w.is_grounded:
			grounded_wheels += 1
	var pitch_rate := angular_velocity.dot(global_transform.basis.x)
	var roll_rate := angular_velocity.dot(-global_transform.basis.z)
	var s2 := s * s
	if grounded_wheels >= 2:
		var pitch_damper_torque := -global_transform.basis.x * (pitch_rate * config.mass * 2.8 * s2)
		var roll_damper_torque := global_transform.basis.z * (roll_rate * config.mass * 1.6 * s2)
		apply_torque(pitch_damper_torque + roll_damper_torque)
	else:
		var air_pitch_damp := -global_transform.basis.x * (pitch_rate * config.mass * 0.45 * s2)
		var air_roll_damp := global_transform.basis.z * (roll_rate * config.mass * 0.55 * s2)
		apply_torque(air_pitch_damp + air_roll_damp)

func _solve_tire_forces(delta: float) -> void:
	var drive_count = 0
	for w in _wheels:
		if w.is_drive: drive_count += 1
	var drive_mult = 1.0 / maxf(float(drive_count), 1.0)
	
	var engine_kw = config.peak_power_kw * clampf(engine_rpm / maxf(config.max_engine_rpm, 100.0), 0.25, 1.0)
	var engine_torque_nm = (engine_kw * 1000.0) / maxf((engine_rpm * 2.0 * PI / 60.0), 10.0)
	var current_gear_ratio = config.gear_ratios[current_gear - 1]
	if smoothed_throttle < 0.0:
		current_gear_ratio = config.reverse_gear_ratio
	var axle_drive_torque = engine_torque_nm * current_gear_ratio * config.final_drive_ratio * absf(smoothed_throttle) * drive_mult
	var wheel_radius = config.wheel_radius
	var axle_drive_force = (axle_drive_torque / maxf(wheel_radius, 0.1)) * signf(smoothed_throttle)
	
	# Slope Hold check (idle and slow on incline)
	var is_idle = absf(smoothed_throttle) <= 0.05 and smoothed_brake <= 0.05
	var is_slow = absf(forward_speed) * 3.6 < 6.0
	
	for w in _wheels:
		if w.is_front:
			w.steer_angle = current_steer_angle
		else:
			w.steer_angle = 0.0
			
		if not w.is_grounded or w.normal_force_mag <= 0.01:
			if w.is_drive and absf(smoothed_throttle) > 0.01:
				w.wheel_angular_velocity += (smoothed_throttle * 40.0) * delta
			elif smoothed_brake > 0.05:
				w.wheel_angular_velocity = move_toward(w.wheel_angular_velocity, 0.0, 30.0 * delta)
			else:
				var free_rolling_speed = forward_speed / maxf(wheel_radius, 0.1)
				w.wheel_angular_velocity = move_toward(w.wheel_angular_velocity, free_rolling_speed, 12.0 * delta)
			continue
			
		var chassis_fwd = -global_transform.basis.z
		var chassis_right = global_transform.basis.x
		var wheel_heading = chassis_fwd.rotated(global_transform.basis.y, w.steer_angle).normalized()
		var wheel_fwd = wheel_heading.slide(w.contact_normal).normalized()
		var wheel_right = wheel_fwd.cross(w.contact_normal).normalized()
		if wheel_right.dot(chassis_right) < 0.0:
			wheel_right = -wheel_right
			
		var contact_offset = w.contact_point - global_position
		var contact_vel = linear_velocity + angular_velocity.cross(contact_offset)
		var v_long = contact_vel.dot(wheel_fwd)
		var v_lat = contact_vel.dot(wheel_right)
		
		# Grip limits
		var max_long_force = config.tire_longitudinal_friction * w.normal_force_mag
		var max_lat_force = config.tire_lateral_friction * w.normal_force_mag
		
		var raw_f_x = 0.0
		# Drive force application
		if w.is_drive and absf(smoothed_throttle) > 0.01:
			raw_f_x = clampf(axle_drive_force, -max_long_force, max_long_force)
			
		# Brake force application with progressive soft stop below 5 KM/H (1.389 m/s)
		if smoothed_brake > 0.01 and absf(v_long) > 0.05:
			var brake_torque = smoothed_brake * (config.front_brake_torque if w.is_front else config.rear_brake_torque)
			var brake_f = (brake_torque / maxf(wheel_radius, 0.1))
			var soft_stop_factor = clampf(absf(v_long) / 1.389, 0.20, 1.0)
			raw_f_x -= signf(v_long) * minf(brake_f * soft_stop_factor, max_long_force)
		elif not w.is_front and _handbrake_input > 0.01 and absf(v_long) > 0.05:
			var hb_f = (config.handbrake_torque / maxf(wheel_radius, 0.1))
			raw_f_x -= signf(v_long) * minf(hb_f, max_long_force)
		elif is_idle and is_slow:
			# Slope Hold: Full automatic parking brake force prevents downhill slide
			var hold_torque = config.front_brake_torque if w.is_front else config.rear_brake_torque
			var hold_f = hold_torque / maxf(wheel_radius, 0.1)
			if absf(v_long) > 0.02:
				raw_f_x -= signf(v_long) * minf(hold_f, max_long_force)
			else:
				var hold_vel_damping = v_long * (config.mass * 80.0)
				raw_f_x -= clampf(hold_vel_damping, -max_long_force, max_long_force)
		elif absf(smoothed_throttle) <= 0.01 and absf(v_long) > 0.05:
			# Rolling resistance & engine braking drag with soft deceleration below 5 KM/H
			var coast_drag_mult = clampf(absf(v_long) / 1.389, 0.25, 1.0)
			var f_drag = signf(v_long) * (config.rolling_resistance_coeff * w.normal_force_mag + 120.0) * coast_drag_mult
			raw_f_x -= f_drag
			
		# Lateral cornering grip with smooth progressive Pacejka-like curve & rear stability margin
		w.slip_angle = -atan2(v_lat, maxf(absf(v_long), 0.6))
		var peak_slip_rad = deg_to_rad(maxf(config.slip_angle_peak_deg, 5.0))
		var slip_norm = w.slip_angle / peak_slip_rad
		# Smooth tanh curve avoids harsh cliff snap; rear axle keeps +8% baseline lateral stability unless handbraking
		var grip_shape = tanh(slip_norm * 1.35)
		var rear_stability_bonus = 1.08 if (not w.is_front and _handbrake_input <= 0.1) else (0.58 if (not w.is_front and _handbrake_input > 0.1) else 1.0)
		var effective_max_lat = max_lat_force * rear_stability_bonus
		var raw_f_y = grip_shape * effective_max_lat
		
		# Friction Circle Coupling with traction-control lateral reserve (prevents full-throttle 180 spinout)
		var ellipse_norm = sqrt((raw_f_x / maxf(max_long_force, 1.0)) ** 2.0 + (raw_f_y / maxf(effective_max_lat, 1.0)) ** 2.0)
		if ellipse_norm > 1.0:
			raw_f_x /= ellipse_norm
			# Preserve minimum 62% lateral bite when accelerating cleanly without handbrake
			var lat_scale = maxf(1.0 / ellipse_norm, 0.62 if _handbrake_input <= 0.1 else 0.35)
			raw_f_y *= lat_scale
			
		# Apply net tractive forces
		var tire_force_vec = wheel_fwd * raw_f_x + wheel_right * raw_f_y
		apply_force(tire_force_vec, contact_offset)
		
		# Wheel spin synchronization
		w.wheel_angular_velocity = v_long / maxf(wheel_radius, 0.1)

	# GTA V Electronic Stability & Controlled Racing Drift Assist (ESP)
	_apply_stability_and_drift_control()

func _apply_stability_and_drift_control() -> void:
	var grounded := 0
	for w in _wheels:
		if w.is_grounded:
			grounded += 1
	if grounded < 2:
		return

	var fwd_speed := linear_velocity.dot(-global_transform.basis.z)
	var lat_speed := linear_velocity.dot(global_transform.basis.x)
	var abs_fwd := absf(fwd_speed)
	var speed_kmh := abs_fwd * 3.6
	if speed_kmh < 35.0 or fwd_speed < 0.0:
		return

	var assist_strength := clampf(config.stability_assist, 0.0, 1.0)
	var chassis_up := global_transform.basis.y.normalized()
	var body_slip_rad := atan2(lat_speed, maxf(abs_fwd, 2.0))
	var abs_slip_deg := rad_to_deg(absf(body_slip_rad))
	var yaw_rate := angular_velocity.dot(chassis_up)

	# Allow crisp racing drift up to ~26 deg with handbrake, smoothly damp runaway rotation before 180 spinout
	var slip_limit_deg := 26.0 if _handbrake_input > 0.1 else 10.0
	if abs_slip_deg > slip_limit_deg and assist_strength > 0.01:
		var excess := clampf((abs_slip_deg - slip_limit_deg) / 22.0, 0.0, 1.6)
		var hb_scale := 0.22 if _handbrake_input > 0.1 else 1.0
		# +lat_speed means nose is turned left of velocity vector; apply negative yaw torque to align nose toward travel direction
		var corrective_yaw := -signf(body_slip_rad) * excess * config.mass * 16.0 * assist_strength * hb_scale
		apply_torque(chassis_up * corrective_yaw)

	# Always damp excessive angular yaw velocity (counteracts uncontrollable pendulum snap)
	var yaw_damp_coeff := (config.mass * 3.8 * assist_strength) * (0.32 if _handbrake_input > 0.1 else lerpf(0.65, 1.35, clampf((speed_kmh - 80.0) / 140.0, 0.0, 1.0)))
	apply_torque(-chassis_up * yaw_rate * yaw_damp_coeff)

func _solve_slope_hold_stabilization(delta: float) -> void:
	var is_idle = absf(smoothed_throttle) <= 0.05 and smoothed_brake <= 0.05
	var speed_kmh = absf(forward_speed) * 3.6
	if is_idle and speed_kmh < 4.0:
		var grounded_count = 0
		for w in _wheels:
			if w.is_grounded: grounded_count += 1
		if grounded_count >= 2:
			linear_velocity = linear_velocity.move_toward(Vector3.ZERO, 15.0 * delta)
			angular_velocity = angular_velocity.move_toward(Vector3.ZERO, 10.0 * delta)

func _check_auto_unflip(delta: float) -> void:
	if _unflip_cooldown > 0.0:
		_unflip_cooldown -= delta
		return
		
	var chassis_up = global_transform.basis.y.normalized()
	var up_dot = chassis_up.dot(Vector3.UP)
	var speed_magnitude = linear_velocity.length()
	
	# Only execute unflip if vehicle is overturned (dot < 0.35) and slowed down (< 3.0 m/s) for at least 2.0s
	if up_dot < 0.35 and speed_magnitude < 3.0:
		_unflip_timer += delta
		if _unflip_timer >= 2.0:
			_perform_auto_unflip()
			_unflip_timer = 0.0
			_unflip_cooldown = 2.5
	else:
		_unflip_timer = 0.0

func _perform_auto_unflip() -> void:
	var space = get_world_3d().direct_space_state
	var self_rid = get_rid()
	
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	var fwd = -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.001:
		fwd = Vector3.FORWARD
	else:
		fwd = fwd.normalized()
	var target_yaw = atan2(-fwd.x, -fwd.z)
	
	var start_pos = global_position + Vector3(0.0, 5.0, 0.0)
	var end_pos = global_position - Vector3(0.0, 15.0, 0.0)
	var ray_q = PhysicsRayQueryParameters3D.create(start_pos, end_pos, collision_mask)
	ray_q.exclude = [self_rid]
	var hit = space.intersect_ray(ray_q)
	
	var safe_y = global_position.y + 1.35
	if hit:
		safe_y = hit.position.y + 1.35
	else:
		safe_y = maxf(global_position.y + 1.35, 1.0)
		
	var safe_pos = Vector3(global_position.x, safe_y, global_position.z)
	
	var right_dir = Basis(Vector3.UP, target_yaw).x
	var left_q = PhysicsRayQueryParameters3D.create(safe_pos, safe_pos - right_dir * 1.8, collision_mask)
	left_q.exclude = [self_rid]
	var hit_left = space.intersect_ray(left_q)
	
	var right_q = PhysicsRayQueryParameters3D.create(safe_pos, safe_pos + right_dir * 1.8, collision_mask)
	right_q.exclude = [self_rid]
	var hit_right = space.intersect_ray(right_q)
	
	if hit_left and not hit_right:
		safe_pos += right_dir * 1.0
	elif hit_right and not hit_left:
		safe_pos -= right_dir * 1.0
	elif hit_left and hit_right:
		safe_pos.x = (hit_left.position.x + hit_right.position.x) * 0.5
		safe_pos.z = (hit_left.position.z + hit_right.position.z) * 0.5
		
	global_position = safe_pos
	global_transform.basis = Basis(Vector3.UP, target_yaw)
	
	for w in _wheels:
		w.compression = 0.0
		w.prev_compression = 0.0
		w.suspension_velocity = 0.0
		w.spring_force_mag = 0.0
		w.normal_force_mag = 0.0
		w.wheel_angular_velocity = 0.0
	current_steer_angle = 0.0
	forward_speed = 0.0
	lateral_speed = 0.0
	smoothed_throttle = 0.0
	smoothed_brake = 0.0
	current_pitch = 0.0
	pitch_velocity = 0.0
	current_heave = 0.0
	heave_velocity = 0.0
	_prev_fwd_speed = 0.0
	_long_acceleration = 0.0

func _solve_aerodynamics(delta: float) -> void:
	var s: float = config.get_world_scale()
	var grounded_count := 0
	var avg_ground_normal := Vector3.ZERO
	for w in _wheels:
		if w.is_grounded:
			grounded_count += 1
			avg_ground_normal += w.contact_normal
	if grounded_count > 0:
		avg_ground_normal = (avg_ground_normal / float(grounded_count)).normalized()
	else:
		avg_ground_normal = Vector3.UP
	
	# Anti-launch wall & curb contact damper: absorbs vertical bounce and pitch/roll spikes on hard scrapes
	if get_contact_count() > 0:
		var vel_along_ground_norm := linear_velocity.dot(avg_ground_normal)
		var max_pop_speed := 1.6 * s
		if linear_velocity.y > max_pop_speed and vel_along_ground_norm > max_pop_speed:
			linear_velocity -= avg_ground_normal * (vel_along_ground_norm - max_pop_speed) * 0.85
		var pitch_roll_damp := exp(-9.5 * delta)
		angular_velocity.x *= pitch_roll_damp
		angular_velocity.z *= pitch_roll_damp
	
	var speed = linear_velocity.length()
	if speed < 0.5:
		return
		
	var air_density = 1.225
	var dyn_pressure = 0.5 * air_density * speed * speed
	var drag_force_mag = dyn_pressure * config.drag_coefficient * config.frontal_area
	var drag_vec = -linear_velocity.normalized() * drag_force_mag
	
	var downforce_mag = dyn_pressure * config.downforce_coefficient * config.frontal_area
	if grounded_count >= 2:
		# Extra high-speed ground-effect planting keep tires glued over crests and curbs
		downforce_mag += dyn_pressure * 0.30 * config.frontal_area
	var downforce_vec = -global_transform.basis.y.normalized() * downforce_mag
	
	apply_central_force(drag_vec + downforce_vec)

func _update_visual_adapter(delta: float) -> void:
	if not visual_adapter:
		return
		
	var grounded_count := 0
	var max_comp_ratio := 0.0
	for i in range(4):
		var w = _wheels[i]
		if w.is_grounded:
			grounded_count += 1
		max_comp_ratio = maxf(max_comp_ratio, w.compression / maxf(config.suspension_travel, 0.01))
		visual_adapter.set_wheel_angular_velocity(i, w.wheel_angular_velocity)
		visual_adapter.update_wheel_visual(
			i,
			w.is_grounded,
			w.contact_point,
			w.contact_normal,
			w.steer_angle,
			0.0
		)
		
	var chassis_fwd = -global_transform.basis.z
	var cur_fwd_speed = linear_velocity.dot(chassis_fwd)
	var lat_accel = cur_fwd_speed * angular_velocity.y
	var lat_g = clampf(lat_accel / 35.0, -1.0, 1.0)
	var target_roll = -lat_g * deg_to_rad(3.5)
	
	# Continuous longitudinal acceleration measurement
	var delta_v = cur_fwd_speed - _prev_fwd_speed
	var measured_accel = delta_v / maxf(delta, 0.001)
	_prev_fwd_speed = cur_fwd_speed
	_long_acceleration = lerpf(_long_acceleration, measured_accel, clampf(18.0 * delta, 0.0, 1.0))
	
	var input_accel = (smoothed_throttle - smoothed_brake) * 9.8
	var blended_accel = _long_acceleration * 0.65 + input_accel * 0.35
	
	# Speed-dependent pitch/heave sensitivity attenuation below 10 KM/H
	var speed_kmh = absf(cur_fwd_speed) * 3.6
	var speed_sensitivity = clampf(0.35 + 0.65 * (speed_kmh / 10.0), 0.35, 1.0)
		
	# Second-order damped harmonic spring for pitch with natural rebound (bounded to avoid bumper clipping)
	var max_pitch_rad = deg_to_rad(1.75)
	var target_pitch = clampf(blended_accel / 12.0, -1.0, 1.0) * max_pitch_rad * speed_sensitivity
	if cur_fwd_speed == 0.0 and smoothed_brake <= 0.05:
		target_pitch = 0.0
	var pitch_spring_acc = (target_pitch - current_pitch) * 225.0 - pitch_velocity * 15.0
	pitch_velocity += pitch_spring_acc * delta
	current_pitch += pitch_velocity * delta
	
	# Second-order damped harmonic spring for vertical heave
	var target_heave = clampf(-absf(blended_accel) / 25.0, -0.04, 0.02) * speed_sensitivity
	var heave_spring_acc = (target_heave - current_heave) * 280.0 - heave_velocity * 18.0
	heave_velocity += heave_spring_acc * delta
	current_heave += heave_velocity * delta
	
	var lean_scale := 1.0
	if grounded_count == 0:
		lean_scale = 0.25
	elif max_comp_ratio > 0.68:
		lean_scale = clampf(1.0 - (max_comp_ratio - 0.68) / 0.30, 0.15, 1.0)
	visual_adapter.set_chassis_lean(current_pitch * lean_scale, target_roll * lean_scale, current_heave * lean_scale)

func respawn(target_position: Vector3, yaw_rad: float) -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = target_position
	global_rotation = Vector3(0.0, yaw_rad, 0.0)
	current_steer_angle = 0.0
	forward_speed = 0.0
	lateral_speed = 0.0
	smoothed_throttle = 0.0
	smoothed_brake = 0.0
	current_pitch = 0.0
	pitch_velocity = 0.0
	current_heave = 0.0
	heave_velocity = 0.0
	_prev_fwd_speed = 0.0
	_long_acceleration = 0.0
	for w in _wheels:
		w.compression = 0.0
		w.prev_compression = 0.0
		w.wheel_angular_velocity = 0.0
