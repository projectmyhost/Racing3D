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
var _reflection_probe: ReflectionProbe

func _ready() -> void:
	super._ready()
	_setup_reflection_probe()
	_setup_vehicle_lights()
	_setup_audio()
	_setup_drift_particles()

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
		spot.light_energy = 1.5
		spot.light_specular = 0.25
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
	var s: float = config.get_world_scale() if config else VehicleConfig.WORLD_SCALE
	_reflection_probe = ReflectionProbe.new()
	_reflection_probe.name = "VehicleReflectionProbe"
	_reflection_probe.size = Vector3(4.8, 2.4, 4.8) * s
	_reflection_probe.origin_offset = Vector3(0.0, 1.0 * s, 0.0)
	_reflection_probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	_reflection_probe.max_distance = 45.0 * s
	_reflection_probe.enable_shadows = false
	_reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	_reflection_probe.intensity = 0.75
	add_child(_reflection_probe)

func _setup_audio() -> void:
	# Disabled: no vehicle sound
	pass

func _setup_drift_particles() -> void:
	_smoke_left = _create_tire_smoke_emitter("TireSmokeLeft")
	_smoke_right = _create_tire_smoke_emitter("TireSmokeRight")
	add_child(_smoke_left)
	add_child(_smoke_right)
	_update_smoke_positions()

func _create_tire_smoke_emitter(emitter_name: String) -> CPUParticles3D:
	var s: float = config.get_world_scale() if config else VehicleConfig.WORLD_SCALE
	var particles = CPUParticles3D.new()
	particles.name = emitter_name
	particles.emitting = false
	particles.amount = 16
	particles.lifetime = 0.35
	particles.speed_scale = 1.0
	particles.explosiveness = 0.0
	particles.randomness = 0.3
	particles.gravity = Vector3(0.0, 1.2 * s, 0.0)
	particles.initial_velocity_min = 0.5 * s
	particles.initial_velocity_max = 2.0 * s
	particles.scale_amount_min = 0.15
	particles.scale_amount_max = 0.45
	particles.color = Color(0.9, 0.9, 0.95, 0.4)
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.18 * s
	mesh.height = 0.36 * s
	mesh.radial_segments = 6
	mesh.rings = 4
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.92, 0.92, 0.95, 0.3)
	mesh.material = mat
	particles.mesh = mesh
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

func _update_drift_particles(_delta: float) -> void:
	if not _smoke_left or not _smoke_right or _wheels.size() < 4:
		return
	var rl = _wheels[2]
	var rr = _wheels[3]
	var slip_threshold = 0.28
	var slip_ratio_threshold = 0.35
	var rl_slipping = rl.is_grounded and (abs(rl.slip_angle) > slip_threshold or abs(rl.slip_ratio) > slip_ratio_threshold)
	var rr_slipping = rr.is_grounded and (abs(rr.slip_angle) > slip_threshold or abs(rr.slip_ratio) > slip_ratio_threshold)
	_smoke_left.emitting = rl_slipping
	_smoke_right.emitting = rr_slipping
