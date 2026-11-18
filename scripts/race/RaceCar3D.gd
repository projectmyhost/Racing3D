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
	_setup_audio()
	_setup_drift_particles()

func _setup_reflection_probe() -> void:
	_reflection_probe = ReflectionProbe.new()
	_reflection_probe.name = "VehicleReflectionProbe"
	_reflection_probe.size = Vector3(4.8, 2.4, 4.8)
	_reflection_probe.origin_offset = Vector3(0.0, 1.0, 0.0)
	_reflection_probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	_reflection_probe.max_distance = 45.0
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
	var particles = CPUParticles3D.new()
	particles.name = emitter_name
	particles.emitting = false
	particles.amount = 16
	particles.lifetime = 0.35
	particles.speed_scale = 1.0
	particles.explosiveness = 0.0
	particles.randomness = 0.3
	particles.gravity = Vector3(0.0, 1.2, 0.0)
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 2.0
	particles.scale_amount_min = 0.15
	particles.scale_amount_max = 0.45
	particles.color = Color(0.9, 0.9, 0.95, 0.4)
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
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
	var half_wb = config.wheelbase * 0.5
	var half_tw_r = config.track_width_rear * 0.5
	var y_pos = 0.08
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
