class_name RaceCar3D
extends VehiclePhysicsCore

# Universal Grip-First Racing Vehicle Controller.
# Extends VehiclePhysicsCore to provide seamless backward compatibility
# with existing game scenes (RaceTrack3D.tscn), garage, and race setup systems.
# All vehicle dynamics, 4-wheel independent raycast suspension, Pacejka tire friction,
# transmission, and visual rigging are handled by VehiclePhysicsCore.

var _engine_audio: AudioStreamPlayer3D = null
var _smoke_left: CPUParticles3D
var _smoke_right: CPUParticles3D
var _exhaust_left: CPUParticles3D = null
var _exhaust_right: CPUParticles3D = null
var _exhaust_mat: StandardMaterial3D = null
var _backfire_light: OmniLight3D = null
var _backfire_timer: float = 0.0
var _was_shifting: bool = false
var _prev_throttle: float = 0.0
var _prev_rpm_ratio: float = 0.0
var _reflection_probe: ReflectionProbe

static var _soft_smoke_tex: Texture2D = null

func _ready() -> void:
	super._ready()
	_setup_reflection_probe()
	_setup_vehicle_lights()
	_setup_audio()
	_setup_drift_particles()
	_setup_exhaust_emitters()

func _setup_vehicle_lights() -> void:
	var s: float = config.get_world_scale() if config else VehicleConfig.WORLD_SCALE
	var half_wb: float = config.wheelbase * 0.5 if config else 1.4 * s
	var front_z: float = -(half_wb + 0.78 * s)
	var rear_z: float = half_wb + 0.96 * s
	for x_sign in [-1.0, 1.0]:
		var spot := SpotLight3D.new()
		spot.name = "HeadlightSpotL" if x_sign < 0.0 else "HeadlightSpotR"
		spot.position = Vector3(0.62 * s * x_sign, 0.50 * s, front_z)
		spot.rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
		spot.light_color = Color(0.98, 0.96, 0.9, 1.0)
		spot.light_energy = 0.85
		spot.light_specular = 0.12
		spot.spot_range = 16.0 * s
		spot.spot_attenuation = 1.45
		spot.spot_angle = 35.0
		spot.shadow_enabled = false
		add_child(spot)

	var rear_glow := OmniLight3D.new()
	rear_glow.name = "RearTaillightGlow"
	rear_glow.position = Vector3(0.0, 0.46 * s, rear_z)
	rear_glow.light_color = Color(1.0, 0.12, 0.08, 1.0)
	rear_glow.light_energy = 0.55
	rear_glow.light_specular = 0.12
	rear_glow.omni_range = 2.6 * s
	rear_glow.omni_attenuation = 1.4
	rear_glow.shadow_enabled = false
	add_child(rear_glow)

func _setup_reflection_probe() -> void:
	# Disabled: a frozen UPDATE_ONCE ReflectionProbe parented to a moving RigidBody3D rotates
	# rigidly with the car and stamps bright start-line cubemap blotches onto shadowed body/tires.
	# World Sky HDR IBL + real-time per-frame SSR provide smooth, physically accurate GTA V reflections.
	_reflection_probe = null

func _setup_audio() -> void:
	# Disabled: no vehicle sound
	pass

func _setup_drift_particles() -> void:
	_smoke_left = _create_tire_smoke_emitter("TireSmokeLeft")
	_smoke_right = _create_tire_smoke_emitter("TireSmokeRight")
	add_child(_smoke_left)
	add_child(_smoke_right)
	_update_smoke_positions()

static func _get_soft_smoke_texture() -> Texture2D:
	if _soft_smoke_tex != null:
		return _soft_smoke_tex
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := float(size) * 0.5
	for y in range(size):
		for x in range(size):
			var nx := (float(x) + 0.5 - half) / half
			var ny := (float(y) + 0.5 - half) / half
			var r := sqrt(nx * nx + ny * ny)
			if r >= 0.88:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.0))
				continue
			var ang := atan2(ny, nx)
			var wisp := 0.84 + 0.16 * (sin(ang * 3.0 + r * 4.2) * cos(ang * 2.0 - r * 3.1))
			var falloff := clampf(1.0 - r / 0.86, 0.0, 1.0)
			var smooth := falloff * falloff * (3.0 - 2.0 * falloff)
			var alpha := clampf(pow(smooth, 1.35) * wisp, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	img.generate_mipmaps()
	_soft_smoke_tex = ImageTexture.create_from_image(img)
	return _soft_smoke_tex

func _build_smoke_material(base_tint: Color) -> StandardMaterial3D:
	var s: float = config.get_world_scale() if config else VehicleConfig.WORLD_SCALE
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Per-vertex shading + no depth-texture proximity copy prevents corner-drift GPU spikes
	# while preserving smooth sunset-lit volumetric tire smoke appearance.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.roughness = 0.96
	mat.metallic = 0.0
	mat.albedo_color = base_tint
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _get_soft_smoke_texture()
	mat.texture_repeat = false
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = 2.2 * s
	mat.distance_fade_max_distance = 3.8 * s
	mat.proximity_fade_enabled = false
	return mat

func _build_exhaust_material(base_tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = base_tint
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _get_soft_smoke_texture()
	mat.texture_repeat = false
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return mat

func _create_tire_smoke_emitter(emitter_name: String) -> CPUParticles3D:
	var s: float = config.get_world_scale() if config else VehicleConfig.WORLD_SCALE
	var particles := CPUParticles3D.new()
	particles.name = emitter_name
	particles.emitting = false
	particles.amount = 28
	particles.lifetime = 0.72
	particles.speed_scale = 1.0
	particles.explosiveness = 0.0
	particles.randomness = 0.45
	particles.local_coords = false
	particles.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	particles.direction = Vector3(0.0, 0.35, 1.0)
	particles.spread = 28.0
	particles.gravity = Vector3(0.0, 0.95 * s, 0.0)
	particles.damping_min = 1.6 * s
	particles.damping_max = 2.8 * s
	particles.initial_velocity_min = 0.6 * s
	particles.initial_velocity_max = 1.8 * s
	particles.angle_min = -180.0
	particles.angle_max = 180.0
	particles.scale_amount_min = 0.85
	particles.scale_amount_max = 1.25
	
	var scale_curve := Curve.new()
	scale_curve.max_value = 2.5
	scale_curve.add_point(Vector2(0.0, 0.55))
	scale_curve.add_point(Vector2(0.42, 1.65))
	scale_curve.add_point(Vector2(1.0, 2.35))
	scale_curve.bake()
	particles.scale_amount_curve = scale_curve
	
	var grad := Gradient.new()
	grad.set_color(0, Color(0.88, 0.89, 0.91, 0.0))
	grad.add_point(0.14, Color(0.86, 0.87, 0.89, 0.52))
	grad.add_point(0.50, Color(0.83, 0.84, 0.87, 0.34))
	grad.set_color(grad.get_point_count() - 1, Color(0.80, 0.82, 0.85, 0.0))
	particles.color_ramp = grad
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.52 * s, 0.52 * s)
	quad.material = _build_smoke_material(Color(0.94, 0.95, 0.97, 0.82))
	particles.mesh = quad
	return particles

func _setup_exhaust_emitters() -> void:
	if not config:
		return
	var s: float = config.get_world_scale()
	var half_wb := config.wheelbase * 0.5
	var half_tw_r := config.track_width_rear * 0.5
	var rear_z := maxf(half_wb + 0.76 * s, config.chassis_size.z * 0.48)
	var exhaust_y := 0.14 * s
	var exhaust_x := half_tw_r * 0.58
	var cls := config.vehicle_class.to_lower()
	var is_dual := cls.contains("sport") or cls.contains("super") or config.peak_power_kw >= 260.0
	
	_exhaust_mat = _build_exhaust_material(Color(0.72, 0.74, 0.78, 0.32))
	_exhaust_right = _create_exhaust_emitter("ExhaustSmokeRight", _exhaust_mat)
	_exhaust_right.position = Vector3(exhaust_x, exhaust_y, rear_z)
	add_child(_exhaust_right)
	
	if is_dual:
		_exhaust_left = _create_exhaust_emitter("ExhaustSmokeLeft", _exhaust_mat)
		_exhaust_left.position = Vector3(-exhaust_x, exhaust_y, rear_z)
		add_child(_exhaust_left)
	
	_backfire_light = OmniLight3D.new()
	_backfire_light.name = "ExhaustBackfireLight"
	_backfire_light.position = Vector3(exhaust_x, exhaust_y + 0.04 * s, rear_z + 0.10 * s)
	_backfire_light.light_color = Color(1.0, 0.48, 0.15, 1.0)
	_backfire_light.light_energy = 0.0
	_backfire_light.light_specular = 0.45
	_backfire_light.omni_range = 2.4 * s
	_backfire_light.omni_attenuation = 1.6
	_backfire_light.shadow_enabled = false
	_backfire_light.visible = false
	add_child(_backfire_light)

func _create_exhaust_emitter(emitter_name: String, shared_mat: StandardMaterial3D) -> CPUParticles3D:
	var s: float = config.get_world_scale() if config else VehicleConfig.WORLD_SCALE
	var particles := CPUParticles3D.new()
	particles.name = emitter_name
	particles.emitting = true
	particles.amount = 18
	particles.lifetime = 0.58
	particles.speed_scale = 0.75
	particles.randomness = 0.35
	particles.local_coords = false
	particles.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	particles.direction = Vector3(0.0, 0.15, 1.0)
	particles.spread = 16.0
	particles.gravity = Vector3(0.0, 0.80 * s, 0.0)
	particles.damping_min = 2.2 * s
	particles.damping_max = 3.5 * s
	particles.initial_velocity_min = 1.2 * s
	particles.initial_velocity_max = 2.4 * s
	particles.angle_min = -180.0
	particles.angle_max = 180.0
	particles.scale_amount_min = 0.75
	particles.scale_amount_max = 1.15
	
	var scale_curve := Curve.new()
	scale_curve.max_value = 2.6
	scale_curve.add_point(Vector2(0.0, 0.28))
	scale_curve.add_point(Vector2(0.45, 0.95))
	scale_curve.add_point(Vector2(1.0, 1.55))
	scale_curve.bake()
	particles.scale_amount_curve = scale_curve
	
	var grad := Gradient.new()
	grad.set_color(0, Color(0.72, 0.74, 0.78, 0.0))
	grad.add_point(0.12, Color(0.70, 0.72, 0.76, 0.44))
	grad.add_point(0.52, Color(0.68, 0.70, 0.75, 0.24))
	grad.set_color(grad.get_point_count() - 1, Color(0.65, 0.68, 0.72, 0.0))
	particles.color_ramp = grad
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18 * s, 0.18 * s)
	quad.material = shared_mat
	particles.mesh = quad
	return particles

func _update_smoke_positions() -> void:
	if not config or not _smoke_left or not _smoke_right:
		return
	var s: float = config.get_world_scale()
	var half_wb = config.wheelbase * 0.5
	var half_tw_r = config.track_width_rear * 0.5
	var y_pos = 0.08 * s
	_smoke_left.position = Vector3(-half_tw_r, y_pos, half_wb)
	_smoke_right.position = Vector3(half_tw_r, y_pos, half_wb)

func _process(delta: float) -> void:
	_update_engine_audio(delta)
	_update_drift_particles(delta)

func _update_engine_audio(_delta: float) -> void:
	# Disabled: no vehicle sound
	pass

func _update_drift_particles(delta: float) -> void:
	if not config:
		return
	var s: float = config.get_world_scale()
	if _smoke_left and _smoke_right and _wheels.size() >= 4:
		var rl = _wheels[2]
		var rr = _wheels[3]
		var slip_threshold = 0.26
		var slip_ratio_threshold = 0.32
		var rl_slipping = rl.is_grounded and (absf(rl.slip_angle) > slip_threshold or absf(rl.slip_ratio) > slip_ratio_threshold)
		var rr_slipping = rr.is_grounded and (absf(rr.slip_angle) > slip_threshold or absf(rr.slip_ratio) > slip_ratio_threshold)
		if rl.is_grounded:
			_smoke_left.global_position = rl.contact_point + rl.contact_normal * (0.08 * s)
		if rr.is_grounded:
			_smoke_right.global_position = rr.contact_point + rr.contact_normal * (0.08 * s)
		_smoke_left.emitting = rl_slipping
		_smoke_right.emitting = rr_slipping
	
	# Engine RPM & throttle driven exhaust plume + high-RPM gearshift/lift-off backfire flash
	var rpm_span := maxf(config.max_engine_rpm - config.idle_engine_rpm, 1.0)
	var rpm_ratio := clampf((engine_rpm - config.idle_engine_rpm) / rpm_span, 0.0, 1.0)
	var load_factor := clampf(rpm_ratio * 0.65 + absf(smoothed_throttle) * 0.45, 0.0, 1.0)
	
	if _exhaust_mat:
		_exhaust_mat.albedo_color = Color(0.72, 0.74, 0.78, lerpf(0.24, 0.56, load_factor))
	for ex in [_exhaust_left, _exhaust_right]:
		if ex:
			ex.emitting = is_active and config.vehicle_class.to_lower() != "electric"
			ex.speed_scale = lerpf(0.60, 1.90, load_factor)
			ex.initial_velocity_min = (1.1 + 2.4 * rpm_ratio) * s
			ex.initial_velocity_max = (2.1 + 4.2 * rpm_ratio) * s
	
	var shift_pop := _is_shifting and not _was_shifting and _prev_rpm_ratio > 0.72
	var liftoff_pop := _prev_throttle > 0.65 and _throttle_input <= 0.15 and _prev_rpm_ratio > 0.78
	if (shift_pop or liftoff_pop) and is_active:
		_backfire_timer = 0.075
	_was_shifting = _is_shifting
	_prev_throttle = _throttle_input
	_prev_rpm_ratio = rpm_ratio
	
	if _backfire_light:
		if _backfire_timer > 0.0:
			_backfire_timer = maxf(_backfire_timer - delta, 0.0)
			var t_flash := _backfire_timer / 0.075
			_backfire_light.visible = true
			_backfire_light.light_energy = 3.2 * t_flash
		else:
			_backfire_light.visible = false
			_backfire_light.light_energy = 0.0
