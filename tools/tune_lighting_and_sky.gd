@tool
extends SceneTree

func _init():
	print("Tuning lighting and camera for balanced cinematic contrast...")
	
	# 1. Update Environment
	var env = load("res://assets/materials/environments/env_sunset.tres") as Environment
	if env:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.32, 0.35, 0.48, 1.0) # Deep twilight indigo ambient
		env.ambient_light_sky_contribution = 0.65
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_white = 5.0
		env.glow_enabled = true
		env.glow_intensity = 0.35
		env.glow_strength = 0.85
		env.glow_bloom = 0.05
		env.glow_hdr_threshold = 1.15
		env.fog_enabled = true
		env.fog_light_color = Color(0.72, 0.48, 0.38, 1.0) # Warm sunset haze
		env.fog_density = 0.0005
		env.fog_aerial_perspective = 0.25
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.12
		env.adjustment_saturation = 1.08
		ResourceSaver.save(env, "res://assets/materials/environments/env_sunset.tres")
		print("env_sunset.tres tuned successfully!")
		
	# 2. Update home_screen.tscn
	var home_packed = load("res://scenes/main/home_screen.tscn") as PackedScene
	if home_packed:
		var home = home_packed.instantiate()
		
		# SunLight: Angled to illuminate the car and road from the sunset horizon without direct specular blowout
		var sun: DirectionalLight3D = home.get_node_or_null("SunLight")
		if sun:
			sun.light_color = Color(1.0, 0.65, 0.35, 1.0)
			sun.light_energy = 1.6 # Balanced, non-overblown
			sun.rotation_degrees = Vector3(-18.0, 68.0, 0.0)
			sun.shadow_enabled = true
			sun.shadow_bias = 0.02
			sun.shadow_normal_bias = 1.2
			sun.directional_shadow_max_distance = 60.0
			
		# FillCool: Soft twilight skylight
		var fill: DirectionalLight3D = home.get_node_or_null("FillCool")
		if fill:
			fill.light_color = Color(0.35, 0.38, 0.58, 1.0)
			fill.light_energy = 0.45
			fill.rotation_degrees = Vector3(-25.0, -115.0, 0.0)
			
		var new_packed = PackedScene.new()
		new_packed.pack(home)
		ResourceSaver.save(new_packed, "res://scenes/main/home_screen.tscn")
		print("home_screen.tscn tuned successfully!")
		
	quit(0)
