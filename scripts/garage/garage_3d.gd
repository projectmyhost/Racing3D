class_name Garage3DController
extends Node3D

## AAA Need For Speed-Grade 3D Showroom Garage Controller.
## Owns:
## - Lossless Warehouse.fbx material restoration (WetConcrete roughness + OpenGL normal + HDR Emissive lightbars)
## - Real-world 1:1 scale & exact dynamic tire-bottom grounding for all 16 vehicles (< 0.005m)
## - Handcrafted RTX 5050 indoor lighting rig + ReflectionProbe (protected via preserve_indoor_lighting)
## - Interruptible, spam-click-safe NFS Showroom Roll-In Car-Switch Entrance Animation
## - Preview-before-equip flow wired to PlayerProfile & GarageHudV2

const VehicleCatalogScript = preload("res://scripts/core/vehicle_catalog.gd")
const GarageHudV2Script = preload("res://scripts/ui/garage_hud_v2.gd")

const FLOOR_Y: float = 0.0
const PARKED_STEER_DEG: float = 14.0
const ROLL_IN_START_LOCAL_Z: float = 3.20
const ROLL_OUT_BACK_LOCAL_Z: float = 1.20
const KEY_SPOT_BASE_ENERGY: float = 10.5

const TEX_WET_ALBEDO_PATH: String = "res://assets/models/environment/garage_3d/textures/WetConcrete_Base_color.png"
const TEX_WET_ROUGHNESS_PATH: String = "res://assets/models/environment/garage_3d/textures/WetConcrete_Roughness@channels=G.png"
const TEX_WET_NORMAL_DX_PATH: String = "res://assets/models/environment/garage_3d/textures/WetConcrete_Normal_DirectX.png"
const TEX_METAL_NORMAL_PATH: String = "res://assets/models/environment/garage_3d/textures/Warehouse_normals.png"

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var warehouse_root: Node3D = $WarehouseModel
@onready var reflection_probe: ReflectionProbe = $GarageReflectionProbe
@onready var hero_key_spot: SpotLight3D = $LightingRig/HeroKeySpot
@onready var car_pad_root: Node3D = $CarPadRoot
@onready var showcase_car: ShowcaseCar = $CarPadRoot/ShowcaseCar
@onready var camera_rig: GarageCameraRig = $GarageCameraRig
@onready var ui_layer: CanvasLayer = $UILayer

var hud: GarageHudV2 = null
var _fade_overlay: ColorRect = null

var _preview_car_id: String = "sedan"
var _preview_paint_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _current_ground_y: float = 0.0
var _current_wheel_radius: float = 0.36

# Interruptible car-switch choreography state
var _switch_seq_id: int = 0
var _desired_car_id: String = ""
var _waiting_for_model: String = ""
var _pending_animate_on_ready: bool = true
var _entrance_tween: Tween = null
var _body_pitch_tween: Tween = null
var _light_pulse_tween: Tween = null
var _steer_tween: Tween = null
var _last_anim_local_z: float = 0.0
var _is_transitioning_scene: bool = false

# Verification telemetry
var material_audit_report: Dictionary = {}
var last_ground_metrics: Dictionary = {}

static var _cached_gl_concrete_normal: ImageTexture = null

func _enter_tree() -> void:
	set_meta("preserve_indoor_lighting", true)

func _ready() -> void:
	set_meta("preserve_indoor_lighting", true)
	if world_env:
		world_env.set_meta("preserve_indoor_lighting", true)

	_setup_indoor_world_environment()
	_audit_and_restore_warehouse_materials()
	_refresh_reflection_probe()

	# Read PlayerProfile initial state
	var prof := _get_profile()
	if prof and prof.data:
		_preview_car_id = prof.data.equipped_car
		_preview_paint_color = prof.data.custom_paint_color
	if not VehicleCatalogScript.FLEET_DATA.has(_preview_car_id):
		_preview_car_id = "sedan"

	# Configure ShowcaseCar for 1:1 true metric garage calibration
	if showcase_car:
		showcase_car.use_world_scale = false
		showcase_car.idle_sway_enabled = false
		showcase_car.auto_load_on_ready = false
		showcase_car.current_paint_color = _preview_paint_color
		showcase_car.headlights_on = true
		showcase_car.garage_open = true
		if not showcase_car.car_model_ready.is_connected(_on_showcase_car_ready):
			showcase_car.car_model_ready.connect(_on_showcase_car_ready)

	# Mount GarageHudV2 matching HomeScreen V2 design system
	_mount_hud()
	_mount_fade_overlay()

	# Re-apply QualitySettings with indoor lighting protection active
	if has_node("/root/QualitySettings"):
		get_node("/root/QualitySettings").apply_to_current_scene()

	# Load initial equipped vehicle flush onto the pad (no roll-out needed on entry)
	_desired_car_id = _preview_car_id
	_load_initial_vehicle(_preview_car_id)

	# Warm nearby fleet rigs on background thread for instant switching
	if showcase_car:
		showcase_car.warm_garage_fleet(VehicleCatalogScript.ORDER)

	# Bind live profile updates
	if prof:
		if not prof.is_connected("profile_updated", _on_profile_updated):
			prof.connect("profile_updated", _on_profile_updated)
		if not prof.is_connected("currency_changed", _on_currency_changed):
			prof.connect("currency_changed", _on_currency_changed)

	# Crisp fade-in from black transition
	_play_fade_in()

func _exit_tree() -> void:
	_kill_active_animations()
	var prof := _get_profile()
	if prof:
		if prof.is_connected("profile_updated", _on_profile_updated):
			prof.disconnect("profile_updated", _on_profile_updated)
		if prof.is_connected("currency_changed", _on_currency_changed):
			prof.disconnect("currency_changed", _on_currency_changed)

func _get_profile() -> Node:
	return get_node_or_null("/root/PlayerProfile")

# =============================================================================
# 1. INDOOR ENVIRONMENT & LOSSLESS WAREHOUSE MATERIAL RESTORATION
# =============================================================================
func _setup_indoor_world_environment() -> void:
	if not world_env:
		return
	var env := world_env.environment
	if env == null:
		env = Environment.new()
		world_env.environment = env

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.034, 0.050, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.24, 0.32, 0.45, 1.0)
	env.ambient_light_energy = 0.40

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.08
	env.tonemap_white = 6.0

	env.ssr_enabled = true
	env.ssr_max_steps = 40
	env.ssr_fade_in = 0.12
	env.ssr_fade_out = 1.8
	env.ssr_depth_tolerance = 0.22

	env.ssao_enabled = true
	env.ssao_radius = 1.10
	env.ssao_intensity = 2.25
	env.ssao_power = 1.55
	env.ssao_detail = 0.60
	env.ssao_horizon = 0.06
	env.ssao_sharpness = 0.94
	env.ssao_light_affect = 0.12

	env.ssil_enabled = true
	env.ssil_radius = 3.8
	env.ssil_intensity = 0.48
	env.ssil_sharpness = 0.92
	env.sdfgi_enabled = false

	env.glow_enabled = true
	env.glow_normalized = false
	env.glow_intensity = 0.42
	env.glow_strength = 0.78
	env.glow_bloom = 0.08
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 1.15
	env.glow_hdr_scale = 2.0
	env.glow_hdr_luminance_cap = 12.0

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.055, 0.078, 0.125, 1.0)
	env.fog_light_energy = 0.55
	env.fog_density = 0.011
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = false

	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.06

static func _load_opengl_normal_from_directx(path: String) -> Texture2D:
	if _cached_gl_concrete_normal != null:
		return _cached_gl_concrete_normal
	var raw_tex := load(path) as Texture2D
	if not raw_tex:
		return null
	var img := raw_tex.get_image()
	if not img:
		return raw_tex
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray = img.get_data()
	var n_bytes: int = data.size()
	var idx: int = 0
	# Flip ONLY the green (Y) normal channel from DirectX (+Y down) to Godot OpenGL (+Y up)
	# preserving 100% original 1024x1024 full-resolution detail!
	while idx < n_bytes:
		data[idx + 1] = 255 - data[idx + 1]
		idx += 4
	var out_img := Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
	out_img.generate_mipmaps()
	_cached_gl_concrete_normal = ImageTexture.create_from_image(out_img)
	return _cached_gl_concrete_normal

func _audit_and_restore_warehouse_materials() -> void:
	## Non-destructive lossless material audit on Warehouse.fbx:
	## Fixes ONLY genuine FBX-import defects (dropped WetConcrete roughness map, DirectX normal Y,
	## zeroed HDR Emissive lightbars, dropped Metal metallic/roughness) while preserving 100% original
	## geometry and full-resolution PBR textures. NEVER calls EnvironmentMaterialEnhancer.enhance_city_stage().
	material_audit_report = {
		"meshes": 0,
		"surfaces": 0,
		"missing_textures": 0,
		"repaired_materials": [],
	}
	if not warehouse_root:
		return

	var wet_albedo := load(TEX_WET_ALBEDO_PATH) as Texture2D
	var wet_rough := load(TEX_WET_ROUGHNESS_PATH) as Texture2D
	var wet_normal_gl := _load_opengl_normal_from_directx(TEX_WET_NORMAL_DX_PATH)
	var metal_normal := load(TEX_METAL_NORMAL_PATH) as Texture2D

	for node in warehouse_root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		material_audit_report["meshes"] = int(material_audit_report["meshes"]) + 1
		# Keep warehouse floor/walls strictly on Layer 1 so under-car ContactShadowDecal (cull_mask=1)
		# projects cleanly onto the wet concrete floor without hitting vehicle geometry (Layer 2).
		mi.layers = 1
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

		var sc: int = mi.mesh.get_surface_count()
		for s in range(sc):
			material_audit_report["surfaces"] = int(material_audit_report["surfaces"]) + 1
			var src_mat := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if not src_mat:
				continue
			var mname: String = src_mat.resource_name.to_lower()
			var mat := src_mat.duplicate() as StandardMaterial3D
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

			if mname.contains("wetconcrete") or mname.contains("concrete") or mname.contains("floor"):
				# Restore missing WetConcrete roughness map + OpenGL normal + lossless 1024x1024 base color
				if wet_albedo:
					mat.albedo_texture = wet_albedo
					mat.albedo_color = Color(0.95, 0.96, 1.0, 1.0)
				else:
					material_audit_report["missing_textures"] = int(material_audit_report["missing_textures"]) + 1
				if wet_rough:
					mat.roughness_texture = wet_rough
					mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
					mat.roughness = 1.0
				else:
					material_audit_report["missing_textures"] = int(material_audit_report["missing_textures"]) + 1
				if wet_normal_gl:
					mat.normal_enabled = true
					mat.normal_texture = wet_normal_gl
					mat.normal_scale = 0.85
				mat.metallic = 0.04
				mat.metallic_specular = 0.65
				mat.emission_enabled = false
				(material_audit_report["repaired_materials"] as Array).append("WetConcrete")

			elif mname.contains("emissive") or mname.contains("light"):
				# Restore FBX-zeroed overhead industrial LED light fixture emission
				mat.albedo_color = Color(0.96, 0.98, 1.0, 1.0)
				mat.roughness = 0.14
				mat.metallic = 0.0
				mat.emission_enabled = true
				mat.emission = Color(0.94, 0.97, 1.0, 1.0)
				mat.emission_energy_multiplier = 3.2
				(material_audit_report["repaired_materials"] as Array).append("Emissive")

			elif mname.contains("metal") or mname.contains("steel") or mname.contains("wall"):
				# Restore corrugated industrial steel metallic/roughness while preserving 2048x2048 normal map
				mat.albedo_color = Color(0.38, 0.41, 0.46, 1.0)
				mat.metallic = 0.70
				mat.roughness = 0.37
				mat.metallic_specular = 0.72
				if mat.normal_texture == null and metal_normal != null:
					mat.normal_enabled = true
					mat.normal_texture = metal_normal
				mat.normal_scale = 1.0
				mat.emission_enabled = false
				(material_audit_report["repaired_materials"] as Array).append("Metal")

			mi.set_surface_override_material(s, mat)

func _refresh_reflection_probe() -> void:
	if not reflection_probe:
		return
	reflection_probe.interior = true
	reflection_probe.box_projection = true
	reflection_probe.cull_mask = 1
	reflection_probe.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
	reflection_probe.enable_shadows = false
	reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE

# =============================================================================
# 2. VEHICLE GROUNDING & NFS SHOWROOM ROLL-IN CAR-SWITCH ANIMATION
# =============================================================================
func _load_initial_vehicle(car_id: String) -> void:
	if not showcase_car:
		return
	_kill_active_animations()
	showcase_car.position = Vector3.ZERO
	showcase_car.rotation = Vector3.ZERO
	if showcase_car.visual_root:
		showcase_car.visual_root.rotation = Vector3.ZERO
	showcase_car.current_paint_color = _preview_paint_color
	showcase_car.load_car_model(car_id)
	if showcase_car.get_active_model_key() == car_id.to_lower():
		_ground_active_vehicle_flush()
		showcase_car.set_steer(PARKED_STEER_DEG)
		showcase_car.set_headlights(true)
		showcase_car.set_light_energy_multiplier(1.0)
		_refresh_hud_state()

func select_preview_car(car_id: String, animate: bool = true) -> void:
	## Preview-Before-Equip: switches the displayed 3D showcase car with NFS Roll-In choreography.
	## NEVER mutates PlayerProfile.data.equipped_car!
	if not VehicleCatalogScript.FLEET_DATA.has(car_id):
		return
	_preview_car_id = car_id
	_desired_car_id = car_id
	_refresh_hud_state()

	if not showcase_car:
		return

	_switch_seq_id += 1
	var seq: int = _switch_seq_id
	_pending_animate_on_ready = animate
	_kill_active_animations()

	if not animate:
		_waiting_for_model = car_id.to_lower()
		showcase_car.load_car_model(car_id)
		if showcase_car.get_active_model_key() == car_id.to_lower():
			_waiting_for_model = ""
			_snap_car_to_parked_pose()
		return

	# Phase 1: Outgoing car backs out gently (~1.2m over 0.15s), straightens wheels, dims lights
	if showcase_car.get_active_model_key() == car_id.to_lower():
		# Already showing same model (e.g. spam click back to same car): clean settle
		_snap_car_to_parked_pose()
		return

	_last_anim_local_z = showcase_car.position.z
	_steer_tween = create_tween()
	_steer_tween.tween_method(
		func(a: float): showcase_car.set_steer(a),
		showcase_car.steer_angle, 0.0, 0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_light_pulse_tween = create_tween()
	_light_pulse_tween.tween_method(
		func(e: float): showcase_car.set_light_energy_multiplier(e),
		1.0, 0.35, 0.13
	)

	_entrance_tween = create_tween()
	_entrance_tween.tween_method(
		func(z_val: float): _drive_car_z_with_wheel_spin(z_val),
		showcase_car.position.z,
		ROLL_OUT_BACK_LOCAL_Z,
		0.15
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_entrance_tween.tween_callback(func():
		if seq != _switch_seq_id or not is_instance_valid(showcase_car):
			return
		_begin_incoming_model_load(car_id, seq)
	)

func _begin_incoming_model_load(car_id: String, seq: int) -> void:
	if seq != _switch_seq_id or not showcase_car:
		return
	var target_key: String = car_id.to_lower()
	_waiting_for_model = target_key
	if hud:
		hud.set_loading_visible(true)
	showcase_car.load_car_model(car_id)
	# If model was already cached/pooled, car_model_ready fired synchronously inside load_car_model
	if showcase_car.get_active_model_key() == target_key and _waiting_for_model == target_key:
		_waiting_for_model = ""
		if hud:
			hud.set_loading_visible(false)
		_play_incoming_roll_in(seq)

func _on_showcase_car_ready(model_id: String) -> void:
	if model_id != _desired_car_id.to_lower():
		return
	if hud:
		hud.set_loading_visible(false)
	if _waiting_for_model == model_id:
		_waiting_for_model = ""
		if _pending_animate_on_ready:
			_play_incoming_roll_in(_switch_seq_id)
		else:
			_snap_car_to_parked_pose()
	else:
		_ground_active_vehicle_flush()

func _play_incoming_roll_in(seq: int) -> void:
	if seq != _switch_seq_id or not showcase_car:
		return
	_kill_active_animations()

	# Align incoming car vertically flush to garage floor before moving it to roll-in start
	_ground_active_vehicle_flush()
	showcase_car.position = Vector3(0.0, _current_ground_y, ROLL_IN_START_LOCAL_Z)
	_last_anim_local_z = ROLL_IN_START_LOCAL_Z
	if showcase_car.visual_root:
		showcase_car.visual_root.rotation = Vector3.ZERO
	showcase_car.set_steer(0.0)
	showcase_car.set_headlights(true)
	showcase_car.set_light_energy_multiplier(0.45)

	# Camera subtle arrival dolly breath (-0.18m)
	if camera_rig:
		camera_rig.play_arrival_dolly_pulse()

	# Phase 2: Smooth decelerating showroom roll-in (+3.2m -> 0.0m, TRANS_QUINT / EASE_OUT)
	# with physically synchronized 4-wheel rotation (delta_spin = delta_dist / wheel_radius)
	_entrance_tween = create_tween()
	_entrance_tween.tween_method(
		func(z_val: float): _drive_car_z_with_wheel_spin(z_val),
		ROLL_IN_START_LOCAL_Z,
		0.0,
		0.48
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# Dynamic braking nose-dive (~0.9 deg) + subtle suspension rebound settle
	if showcase_car.visual_root:
		_body_pitch_tween = create_tween()
		_body_pitch_tween.tween_interval(0.24)
		_body_pitch_tween.tween_property(
			showcase_car.visual_root, "rotation:x", deg_to_rad(-0.92), 0.14
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_body_pitch_tween.tween_property(
			showcase_car.visual_root, "rotation:x", deg_to_rad(0.22), 0.12
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_body_pitch_tween.tween_property(
			showcase_car.visual_root, "rotation:x", 0.0, 0.14
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Front wheels smoothly turn from 0 deg -> 14 deg heroic parked stance on arrival
	_steer_tween = create_tween()
	_steer_tween.tween_interval(0.26)
	_steer_tween.tween_method(
		func(a: float): showcase_car.set_steer(a),
		0.0, PARKED_STEER_DEG, 0.24
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Headlights/taillights greeting pulse + overhead hero key spotlight swell (0.82 -> 1.08 -> 1.0)
	_light_pulse_tween = create_tween().set_parallel(true)
	_light_pulse_tween.tween_method(
		func(e: float): showcase_car.set_light_energy_multiplier(e),
		0.45, 1.38, 0.28
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_light_pulse_tween.chain().tween_method(
		func(e: float): showcase_car.set_light_energy_multiplier(e),
		1.38, 1.0, 0.24
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if hero_key_spot:
		hero_key_spot.light_energy = KEY_SPOT_BASE_ENERGY * 0.82
		var spot_t := create_tween()
		spot_t.tween_property(hero_key_spot, "light_energy", KEY_SPOT_BASE_ENERGY * 1.08, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		spot_t.tween_property(hero_key_spot, "light_energy", KEY_SPOT_BASE_ENERGY, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _drive_car_z_with_wheel_spin(new_local_z: float) -> void:
	if not showcase_car:
		return
	var dz: float = new_local_z - _last_anim_local_z
	_last_anim_local_z = new_local_z
	showcase_car.position = Vector3(0.0, _current_ground_y, new_local_z)
	# Forward motion in ShowcaseCar local space is -Z, so forward_dist = -dz
	var wheel_r: float = maxf(_current_wheel_radius, 0.20)
	var delta_spin_rad: float = (-dz) / wheel_r
	showcase_car.spin_wheels_by_radians(delta_spin_rad)

func _snap_car_to_parked_pose() -> void:
	_kill_active_animations()
	if not showcase_car:
		return
	_ground_active_vehicle_flush()
	showcase_car.position = Vector3(0.0, _current_ground_y, 0.0)
	if showcase_car.visual_root:
		showcase_car.visual_root.rotation = Vector3.ZERO
	showcase_car.set_steer(PARKED_STEER_DEG)
	showcase_car.set_headlights(true)
	showcase_car.set_light_energy_multiplier(1.0)
	if hero_key_spot:
		hero_key_spot.light_energy = KEY_SPOT_BASE_ENERGY

func _kill_active_animations() -> void:
	for tw in [_entrance_tween, _body_pitch_tween, _light_pulse_tween, _steer_tween]:
		if tw and tw.is_valid():
			tw.kill()
	_entrance_tween = null
	_body_pitch_tween = null
	_light_pulse_tween = null
	_steer_tween = null
	if hero_key_spot:
		hero_key_spot.light_energy = KEY_SPOT_BASE_ENERGY

func _ground_active_vehicle_flush() -> void:
	if not showcase_car:
		return
	# Temporarily neutralize Y offset & pitch so local measurement is exact
	var prev_z: float = showcase_car.position.z
	showcase_car.position = Vector3(0.0, 0.0, prev_z)
	if showcase_car.visual_root:
		showcase_car.visual_root.rotation = Vector3.ZERO
	var metrics: Dictionary = showcase_car.compute_wheel_ground_metrics()
	last_ground_metrics = metrics
	var min_wheel_y: float = float(metrics.get("min_wheel_y", 0.0))
	_current_wheel_radius = float(metrics.get("wheel_radius", 0.36))
	# Shift ShowcaseCar.position.y so lowest tire vertex rests flush at FLOOR_Y (tolerance < 0.005m)
	_current_ground_y = FLOOR_Y - min_wheel_y
	showcase_car.position = Vector3(0.0, _current_ground_y, prev_z)
	# Place ContactShadowDecal at +0.006m above garage floor in ShowcaseCar local space
	var floor_local_y: float = FLOOR_Y - _current_ground_y
	showcase_car.align_contact_shadow_to_floor(
		floor_local_y,
		float(metrics.get("width", 2.0)),
		float(metrics.get("length", 4.6))
	)

## Public helper for automated grounding verification across all 16 vehicles
func measure_active_tire_world_bottom_y() -> float:
	if not showcase_car:
		return 0.0
	var metrics: Dictionary = showcase_car.compute_wheel_ground_metrics()
	return showcase_car.global_position.y + float(metrics.get("min_wheel_y", 0.0))

# =============================================================================
# 3. HUD MOUNTING, ACTIONS, PROFILE BINDING & SCENE TRANSITIONS
# =============================================================================
func _mount_hud() -> void:
	if not ui_layer:
		return
	hud = GarageHudV2Script.new()
	hud.name = "GarageHudV2"
	ui_layer.add_child(hud)

	hud.back_pressed.connect(_on_back_pressed)
	hud.car_preview_selected.connect(func(car_id: String): select_preview_car(car_id, true))
	hud.primary_cta_pressed.connect(_on_primary_cta_pressed)
	hud.race_now_pressed.connect(_on_race_now_pressed)
	hud.paint_swatch_selected.connect(_on_paint_swatch_selected)
	hud.camera_preset_selected.connect(_on_camera_preset_selected)
	hud.reset_camera_pressed.connect(_on_reset_camera_pressed)
	hud.view_mode_toggled.connect(_on_view_mode_toggled)

	if camera_rig:
		camera_rig.preset_changed.connect(func(pid: String):
			if hud:
				hud.set_active_camera_preset(pid)
		)

func _mount_fade_overlay() -> void:
	if not ui_layer:
		return
	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "SceneFadeOverlay"
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.z_index = 100
	ui_layer.add_child(_fade_overlay)

func _play_fade_in() -> void:
	if not _fade_overlay:
		return
	_fade_overlay.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade_overlay, "color:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _transition_to_scene(scene_path: String) -> void:
	if _is_transitioning_scene:
		return
	_is_transitioning_scene = true
	if camera_rig:
		camera_rig.set_input_enabled(false)
	if _fade_overlay:
		_fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var tw := create_tween()
		tw.tween_property(_fade_overlay, "color:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if is_inside_tree():
				get_tree().change_scene_to_file(scene_path)
		)
	else:
		get_tree().change_scene_to_file(scene_path)

func _refresh_hud_state() -> void:
	if not hud:
		return
	var prof := _get_profile()
	var p: PlayerProfileData = prof.data if prof else null
	var equipped_id: String = p.equipped_car if p else "sedan"
	var unlocked: Array[String] = p.unlocked_cars if p else ["sedan", "angkot_dki"]
	var coins: int = p.coins if p else 250000
	var gems: int = p.gems if p else 500
	hud.refresh_state(_preview_car_id, equipped_id, unlocked, coins, gems, _preview_paint_color)

func _on_profile_updated() -> void:
	_refresh_hud_state()

func _on_currency_changed(coins: int, gems: int) -> void:
	if hud:
		hud.update_currency(coins, gems)

func _on_paint_swatch_selected(color: Color, swatch_name: String) -> void:
	_preview_paint_color = color
	if showcase_car:
		showcase_car.set_paint_color(color)
	var prof := _get_profile()
	if prof and prof.data:
		prof.data.custom_paint_color = color
		prof.save_profile()
	if hud:
		hud.set_active_paint_color(color)
		hud.show_toast("CAT LIVERY DITERAPKAN: " + swatch_name)

func _on_primary_cta_pressed() -> void:
	var prof := _get_profile()
	if not prof or not prof.data:
		return
	var p: PlayerProfileData = prof.data
	var car: Dictionary = VehicleCatalogScript.get_car_data(_preview_car_id)

	if p.equipped_car == _preview_car_id:
		_on_race_now_pressed()
		return

	if p.unlocked_cars.has(_preview_car_id):
		p.custom_paint_color = _preview_paint_color
		prof.equip_car(_preview_car_id)
		_refresh_hud_state()
		if hud:
			hud.show_toast("TERPASANG: %s SIAP BALAPAN!" % str(car["name"]))
	else:
		var cost_c: int = int(car.get("cost_coins", 0))
		var cost_g: int = int(car.get("cost_gems", 0))
		if p.coins >= cost_c and p.gems >= cost_g:
			p.custom_paint_color = _preview_paint_color
			var ok: bool = prof.buy_car(_preview_car_id, cost_c, cost_g)
			if ok:
				_refresh_hud_state()
				if hud:
					hud.show_toast("BERHASIL DIBELI & DIPASANG: %s!" % str(car["name"]))
		else:
			var need: String = ""
			if p.coins < cost_c:
				need = "%s COINS" % VehicleCatalogScript.format_number(cost_c - p.coins)
			if p.gems < cost_g:
				if not need.is_empty():
					need += " & "
				need += "%d GEMS" % (cost_g - p.gems)
			if hud:
				hud.show_toast("SALDO KURANG! BUTUH %s LAGI." % need)

func _on_race_now_pressed() -> void:
	if hud:
		hud.show_toast("MEMUAT SIRKUIT BALAP 3D...")
	_transition_to_scene("res://scenes/race/RaceTrack3D.tscn")

func _on_back_pressed() -> void:
	_transition_to_scene("res://scenes/main/home_screen.tscn")

func _on_camera_preset_selected(preset_id: String) -> void:
	if camera_rig:
		camera_rig.set_preset(preset_id)

func _on_reset_camera_pressed() -> void:
	if camera_rig:
		camera_rig.reset_camera()
	if hud:
		hud.show_toast("KAMERA DIATUR ULANG KE HERO 3/4")

func _on_view_mode_toggled(clean_mode: bool) -> void:
	if camera_rig:
		camera_rig.set_auto_orbit(clean_mode or true)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning_scene:
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		match ke.keycode:
			KEY_ESCAPE:
				if hud and hud.is_view_mode_active():
					hud.set_view_mode(false)
				else:
					_on_back_pressed()
				get_viewport().set_input_as_handled()
			KEY_V:
				if hud:
					hud.set_view_mode(not hud.is_view_mode_active())
				get_viewport().set_input_as_handled()
			KEY_R:
				_on_reset_camera_pressed()
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				var idx_l: int = VehicleCatalogScript.get_index_of(_preview_car_id)
				var prev_id: String = VehicleCatalogScript.ORDER[posmod(idx_l - 1, VehicleCatalogScript.ORDER.size())]
				select_preview_car(prev_id, true)
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				var idx_r: int = VehicleCatalogScript.get_index_of(_preview_car_id)
				var next_id: String = VehicleCatalogScript.ORDER[posmod(idx_r + 1, VehicleCatalogScript.ORDER.size())]
				select_preview_car(next_id, true)
				get_viewport().set_input_as_handled()
