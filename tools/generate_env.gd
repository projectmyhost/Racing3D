@tool
extends SceneTree

func _init():
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	
	var sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://assets/shaders/sky_sunset.gdshader")
	var sky = Sky.new()
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = sky
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.8
	env.ambient_light_color = Color(0.415, 0.353, 0.541, 1.0) # #6A5A8A
	
	# Tonemap
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	
	# Glow
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_strength = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	# SSAO
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.4
	
	# SSR
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.1
	env.ssr_depth_tolerance = 0.2
	
	# Fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.772, 0.541, 0.471, 1.0) # #C58A78
	env.fog_density = 0.0009
	env.fog_aerial_perspective = 0.35
	
	# Adjustment
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.05
	
	ResourceSaver.save(env, "res://assets/materials/environments/env_sunset.tres")
	print("Environment saved to assets/materials/environments/env_sunset.tres")
	quit()
