extends Node

## Adaptive Graphics Quality Settings Autoload for Sunset Street Racing (Forward+ AAA).
## Note: Never modifies Engine.max_fps (handled by HomeScreenUI FPS / Smart VSync controls).

const VehicleMaterialEnhancer = preload("res://vehicles/core/VehicleMaterialEnhancer.gd")
const EnvironmentMaterialEnhancer = preload("res://scripts/core/environment_material_enhancer.gd")

enum Tier { LOW = 0, MEDIUM = 1, HIGH = 2, ULTRA = 3 }

signal tier_changed(tier: Tier)

const CONFIG_PATH := "user://graphics_settings.cfg"
const CONFIG_SECTION := "graphics"
const CONFIG_KEY_TIER := "tier"

const TIER_NAMES: Array[String] = ["LOW", "MEDIUM", "HIGH", "ULTRA AAA"]

const TIER_PROFILES := {
	Tier.LOW: {
		"shadow_size": 2048,
		"shadow_quality": RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		"shadow_mode": DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		"shadow_max_dist": 135.0,
		"shadow_blend_splits": true,
		"shadow_blur": 2.0,
		"shadow_bias": 0.06,
		"shadow_normal_bias": 1.95,
		"use_taa": false,
		"msaa": Viewport.MSAA_DISABLED,
		"ssaa": Viewport.SCREEN_SPACE_AA_FXAA,
		"anisotropy": Viewport.ANISOTROPY_4X,
		"scaling_scale": 0.85,
		"mesh_lod_threshold": 2.5,
		"ssr": false,
		"ssr_steps": 16,
		"ssao": false,
		"ssao_quality": RenderingServer.ENV_SSAO_QUALITY_VERY_LOW,
		"ssao_half": true,
		"ssil": false,
		"ssil_quality": RenderingServer.ENV_SSIL_QUALITY_VERY_LOW,
		"ssil_half": true,
		"sdfgi": false,
		"gi_half": true,
		"volumetric_fog": false,
		"fog": true,
		"glow": false,
		"glow_bicubic": false,
		"shader_detail": 0.35,
		"exposure": 0.94,
		"ambient_energy": 0.30,
		"sky_contrib": 0.52,
		"sun_energy_scale": 0.80,
		"fill_energy_scale": 0.80,
		"sky_intensity": 1.15,
		"adj_brightness": 0.97,
		"adj_contrast": 1.15,
		"adj_saturation": 1.04,
	},
	Tier.MEDIUM: {
		"shadow_size": 2048,
		"shadow_quality": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM,
		"shadow_mode": DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		"shadow_max_dist": 145.0,
		"shadow_blend_splits": true,
		"shadow_blur": 2.1,
		"shadow_bias": 0.06,
		"shadow_normal_bias": 1.95,
		"use_taa": false,
		"msaa": Viewport.MSAA_DISABLED,
		"ssaa": Viewport.SCREEN_SPACE_AA_FXAA,
		"anisotropy": Viewport.ANISOTROPY_8X,
		"scaling_scale": 1.0,
		"mesh_lod_threshold": 1.2,
		"ssr": false,
		"ssr_steps": 16,
		"ssao": true,
		"ssao_quality": RenderingServer.ENV_SSAO_QUALITY_LOW,
		"ssao_half": true,
		"ssil": false,
		"ssil_quality": RenderingServer.ENV_SSIL_QUALITY_VERY_LOW,
		"ssil_half": true,
		"sdfgi": false,
		"gi_half": true,
		"volumetric_fog": false,
		"fog": true,
		"glow": true,
		"glow_bicubic": false,
		"shader_detail": 0.75,
		"exposure": 0.94,
		"ambient_energy": 0.42,
		"sky_contrib": 0.62,
		"sun_energy_scale": 0.90,
		"fill_energy_scale": 0.95,
		"sky_intensity": 1.28,
		"adj_brightness": 0.98,
		"adj_contrast": 1.14,
		"adj_saturation": 1.06,
	},
	Tier.HIGH: {
		"shadow_size": 2048,
		"shadow_quality": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM,
		"shadow_mode": DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		"shadow_max_dist": 155.0,
		"shadow_blend_splits": true,
		"shadow_blur": 2.2,
		"shadow_bias": 0.06,
		"shadow_normal_bias": 1.95,
		"use_taa": true,
		"msaa": Viewport.MSAA_DISABLED,
		"ssaa": Viewport.SCREEN_SPACE_AA_FXAA,
		"anisotropy": Viewport.ANISOTROPY_16X,
		"scaling_scale": 1.0,
		"mesh_lod_threshold": 1.05,
		"ssr": true,
		"ssr_steps": 20,
		"ssao": true,
		"ssao_quality": RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		"ssao_half": true,
		"ssil": false,
		"ssil_quality": RenderingServer.ENV_SSIL_QUALITY_LOW,
		"ssil_half": true,
		"sdfgi": false,
		"gi_half": true,
		"volumetric_fog": true,
		"fog": true,
		"glow": true,
		"glow_bicubic": true,
		"shader_detail": 0.92,
		"exposure": 0.95,
		"ambient_energy": 0.48,
		"sky_contrib": 0.68,
		"sun_energy_scale": 0.96,
		"fill_energy_scale": 1.0,
		"sky_intensity": 1.38,
		"adj_brightness": 0.99,
		"adj_contrast": 1.14,
		"adj_saturation": 1.08,
	},
	Tier.ULTRA: {
		"shadow_size": 3072,
		"shadow_quality": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM,
		"shadow_mode": DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		"shadow_max_dist": 160.0,
		"shadow_blend_splits": true,
		"shadow_blur": 2.35,
		"shadow_bias": 0.055,
		"shadow_normal_bias": 1.90,
		"use_taa": true,
		"msaa": Viewport.MSAA_DISABLED,
		"ssaa": Viewport.SCREEN_SPACE_AA_DISABLED,
		"anisotropy": Viewport.ANISOTROPY_16X,
		"scaling_scale": 1.0,
		"mesh_lod_threshold": 1.0,
		"ssr": true,
		"ssr_steps": 24,
		"ssao": true,
		"ssao_quality": RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		"ssao_half": true,
		"ssil": true,
		"ssil_quality": RenderingServer.ENV_SSIL_QUALITY_LOW,
		"ssil_half": true,
		"sdfgi": false,
		"gi_half": true,
		"volumetric_fog": true,
		"fog": true,
		"glow": true,
		"glow_bicubic": true,
		"shader_detail": 1.0,
		"exposure": 0.95,
		"ambient_energy": 0.52,
		"sky_contrib": 0.72,
		"sun_energy_scale": 1.0,
		"fill_energy_scale": 1.0,
		"sky_intensity": 1.45,
		"adj_brightness": 0.99,
		"adj_contrast": 1.14,
		"adj_saturation": 1.09,
	},
}

@export var current_tier: Tier = Tier.ULTRA
var detected_adapter: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	detected_adapter = RenderingServer.get_video_adapter_name()
	if not _load_saved_tier():
		current_tier = _detect_default_tier(detected_adapter)
		if not detected_adapter.is_empty():
			_save_tier()

	var tree := get_tree()
	if tree and tree.has_signal("scene_changed"):
		tree.scene_changed.connect(_on_scene_changed)

	apply_tier(current_tier, false)

func _on_scene_changed() -> void:
	call_deferred("apply_to_current_scene")

func get_tier_name(tier: Tier = current_tier) -> String:
	var idx: int = clampi(int(tier), 0, TIER_NAMES.size() - 1)
	return TIER_NAMES[idx]

func cycle_tier() -> Tier:
	var next_idx: int = (int(current_tier) + 1) % TIER_NAMES.size()
	apply_tier(next_idx as Tier, true)
	return current_tier

func set_tier_by_index(idx: int) -> void:
	apply_tier(clampi(idx, 0, Tier.ULTRA) as Tier, true)

func apply_tier(tier: Tier, persist: bool = true) -> void:
	current_tier = clampi(int(tier), 0, Tier.ULTRA) as Tier
	var cfg: Dictionary = TIER_PROFILES[current_tier]

	RenderingServer.directional_shadow_atlas_set_size(cfg["shadow_size"], true)
	RenderingServer.directional_soft_shadow_filter_set_quality(cfg["shadow_quality"])
	RenderingServer.positional_soft_shadow_filter_set_quality(cfg["shadow_quality"])
	RenderingServer.environment_set_ssao_quality(cfg["ssao_quality"], cfg["ssao_half"], 0.5, 2, 45.0, 220.0)
	RenderingServer.environment_set_ssil_quality(cfg["ssil_quality"], cfg["ssil_half"], 0.5, 3, 45.0, 220.0)
	RenderingServer.gi_set_use_half_resolution(cfg["gi_half"])
	RenderingServer.environment_glow_set_use_bicubic_upscale(cfg["glow_bicubic"])
	if cfg["sdfgi"]:
		RenderingServer.environment_set_sdfgi_ray_count(RenderingServer.ENV_SDFGI_RAY_COUNT_8)
		RenderingServer.environment_set_sdfgi_frames_to_converge(RenderingServer.ENV_SDFGI_CONVERGE_IN_5_FRAMES)
	if cfg["volumetric_fog"]:
		RenderingServer.environment_set_volumetric_fog_volume_size(64, 64)
		RenderingServer.environment_set_volumetric_fog_filter_active(true)

	var vp := get_viewport()
	if vp:
		vp.use_taa = cfg["use_taa"]
		vp.msaa_3d = cfg["msaa"]
		vp.screen_space_aa = cfg["ssaa"]
		vp.anisotropic_filtering_level = cfg["anisotropy"]
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = cfg["scaling_scale"]
		vp.mesh_lod_threshold = cfg["mesh_lod_threshold"]

	var shader_detail: float = float(cfg["shader_detail"])
	VehicleMaterialEnhancer.set_quality_detail(shader_detail)
	EnvironmentMaterialEnhancer.set_quality_detail(shader_detail)

	apply_to_current_scene()

	if persist:
		_save_tier()

	tier_changed.emit(current_tier)

func apply_to_current_scene() -> void:
	var tree := get_tree()
	if not tree:
		return
	var scene := tree.current_scene
	if not scene:
		return

	var cfg: Dictionary = TIER_PROFILES[current_tier]

	var world_env := scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	var preserve_indoor: bool = bool(scene.get_meta("preserve_indoor_lighting", false))
	if not preserve_indoor and world_env != null:
		preserve_indoor = bool(world_env.get_meta("preserve_indoor_lighting", false))
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		if preserve_indoor:
			# Indoor showcase scenes (e.g. Garage3D) keep their handcrafted exposure, ambient,
			# fog, color grading, and sky while honoring GPU quality toggles across all 4 tiers.
			env.ssr_enabled = bool(cfg["ssr"])
			env.ssr_max_steps = maxi(int(cfg["ssr_steps"]), 36) if current_tier == Tier.ULTRA else int(cfg["ssr_steps"])
			env.ssao_enabled = bool(cfg["ssao"])
			env.ssil_enabled = bool(cfg["ssil"])
			env.sdfgi_enabled = bool(cfg["sdfgi"])
			env.glow_enabled = bool(cfg["glow"])
		else:
			env.ssr_enabled = cfg["ssr"]
			env.ssr_max_steps = cfg["ssr_steps"]
			env.ssao_enabled = cfg["ssao"]
			env.ssil_enabled = cfg["ssil"]
			env.sdfgi_enabled = cfg["sdfgi"]
			env.volumetric_fog_enabled = cfg["volumetric_fog"]
			env.fog_enabled = cfg["fog"]
			env.glow_enabled = cfg["glow"]

			env.tonemap_exposure = float(cfg["exposure"])
			env.ambient_light_energy = float(cfg["ambient_energy"])
			env.ambient_light_sky_contribution = float(cfg["sky_contrib"])
			env.adjustment_brightness = float(cfg["adj_brightness"])
			env.adjustment_contrast = float(cfg["adj_contrast"])
			env.adjustment_saturation = float(cfg["adj_saturation"])

			if env.sky:
				var target_sky_int := float(cfg["sky_intensity"])
				if env.sky.sky_material is ShaderMaterial:
					var sky_mat := env.sky.sky_material as ShaderMaterial
					var cur_sky := float(sky_mat.get_shader_parameter("hdr_sky_intensity"))
					if absf(cur_sky - target_sky_int) > 0.005:
						sky_mat.set_shader_parameter("hdr_sky_intensity", target_sky_int)
				elif env.sky.sky_material is ProceduralSkyMaterial:
					var proc_mat := env.sky.sky_material as ProceduralSkyMaterial
					if absf(proc_mat.energy_multiplier - target_sky_int) > 0.005:
						proc_mat.energy_multiplier = target_sky_int

	if preserve_indoor:
		return

	var sun := scene.find_child("SunLight", true, false) as DirectionalLight3D
	if sun:
		if not sun.has_meta("_base_light_energy"):
			sun.set_meta("_base_light_energy", sun.light_energy)
		if not sun.has_meta("_base_shadow_bias"):
			sun.set_meta("_base_shadow_bias", sun.shadow_bias)
		if not sun.has_meta("_base_normal_bias"):
			sun.set_meta("_base_normal_bias", sun.shadow_normal_bias)
		var base_sun_e: float = float(sun.get_meta("_base_light_energy"))
		sun.directional_shadow_mode = cfg["shadow_mode"]
		sun.directional_shadow_blend_splits = bool(cfg.get("shadow_blend_splits", true))
		sun.directional_shadow_pancake_size = 0.0
		sun.directional_shadow_max_distance = float(cfg["shadow_max_dist"])
		# 2-split seamless near zone (0..38m) prevents any cascade cut-line near car/barriers,
		# while blend_splits smoothly feathers the single distant boundary!
		sun.directional_shadow_split_1 = 0.24
		sun.directional_shadow_split_2 = 0.52
		sun.directional_shadow_split_3 = 0.80
		# Disable noisy PCSS blocker-search stripes; smooth 16-tap Vogel PCF + shadow_blur yields silky GTA V/VI shadows
		sun.light_angular_distance = 0.0
		sun.shadow_blur = float(cfg.get("shadow_blur", 2.2))
		sun.shadow_bias = float(cfg.get("shadow_bias", 0.055))
		sun.shadow_normal_bias = float(cfg.get("shadow_normal_bias", 1.90))
		sun.light_energy = base_sun_e * float(cfg["sun_energy_scale"])

	for fill_name in ["FillCool", "FillLight"]:
		var fill := scene.find_child(fill_name, true, false) as DirectionalLight3D
		if fill:
			if not fill.has_meta("_base_light_energy"):
				fill.set_meta("_base_light_energy", fill.light_energy)
			fill.light_energy = float(fill.get_meta("_base_light_energy")) * float(cfg["fill_energy_scale"])

func _detect_default_tier(adapter_name: String) -> Tier:
	var lower := adapter_name.to_lower()
	if lower.is_empty():
		return Tier.MEDIUM

	# High-end / target AAA laptop & desktop GPUs -> ULTRA AAA
	for token in ["5050", "5060", "5070", "5080", "5090", "4060", "4070", "4080", "4090", "3070", "3080", "3090", "rx 77", "rx 78", "rx 79", "rx 90"]:
		if lower.contains(token):
			return Tier.ULTRA

	# Entry RTX / thermal-conscious mobile GPUs -> MEDIUM (safe cool & 60 FPS for partner's RTX 2050)
	for token in ["2050", "1650", "3050", "1050", "rx 6500", "arc a3"]:
		if lower.contains(token):
			return Tier.MEDIUM

	# Integrated / software adapters -> LOW
	for token in ["intel", "uhd", "iris", "vega", "radeon(tm) graphics", "llvmpipe", "swiftshader"]:
		if lower.contains(token):
			return Tier.LOW

	# Mid-range discrete GPUs (2060, 3060, 4050, 1660, etc.) -> HIGH
	return Tier.HIGH

func _load_saved_tier() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return false
	if not cfg.has_section_key(CONFIG_SECTION, CONFIG_KEY_TIER):
		return false
	var saved_idx: int = int(cfg.get_value(CONFIG_SECTION, CONFIG_KEY_TIER, Tier.MEDIUM))
	current_tier = clampi(saved_idx, 0, Tier.ULTRA) as Tier
	return true

func _save_tier() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(CONFIG_SECTION, CONFIG_KEY_TIER, int(current_tier))
	cfg.save(CONFIG_PATH)
