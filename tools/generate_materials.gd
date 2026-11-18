@tool
extends SceneTree

func _init():
	print("Generating PBR StandardMaterial3D resources...")
	
	# 1. mat_veh_paint_silver_pearl
	var m_paint = StandardMaterial3D.new()
	m_paint.albedo_color = Color(0.788, 0.796, 0.839, 1.0) # #C9CBD6
	m_paint.metallic = 0.85
	m_paint.roughness = 0.28
	m_paint.clearcoat_enabled = true
	m_paint.clearcoat = 1.0
	m_paint.clearcoat_roughness = 0.05
	m_paint.rim_enabled = true
	m_paint.rim = 0.15
	m_paint.rim_tint = 0.5
	if FileAccess.file_exists("res://assets/textures/vehicles/tex_veh_paint_detail_01.png"):
		m_paint.normal_enabled = true
		m_paint.normal_texture = load("res://assets/textures/vehicles/tex_veh_paint_detail_01.png")
	ResourceSaver.save(m_paint, "res://assets/materials/vehicles/mat_veh_paint_silver_pearl.tres")
	
	# 2. mat_veh_hood_stripe
	var m_stripe = StandardMaterial3D.new()
	m_stripe.albedo_color = Color(0.07, 0.075, 0.09, 1.0) # #121317
	m_stripe.metallic = 0.1
	m_stripe.roughness = 0.55
	ResourceSaver.save(m_stripe, "res://assets/materials/vehicles/mat_veh_hood_stripe.tres")
	
	# 3. mat_veh_carbon
	var m_carbon = StandardMaterial3D.new()
	m_carbon.albedo_color = Color(0.063, 0.067, 0.078, 1.0) # #101114
	m_carbon.metallic = 0.4
	m_carbon.roughness = 0.35
	ResourceSaver.save(m_carbon, "res://assets/materials/vehicles/mat_veh_carbon.tres")
	
	# 4. mat_veh_tire
	var m_tire = StandardMaterial3D.new()
	m_tire.albedo_color = Color(0.043, 0.043, 0.047, 1.0) # #0B0B0C
	m_tire.metallic = 0.0
	m_tire.roughness = 0.85
	ResourceSaver.save(m_tire, "res://assets/materials/vehicles/mat_veh_tire.tres")
	
	# 5. mat_veh_wheel_black
	var m_wheel = StandardMaterial3D.new()
	m_wheel.albedo_color = Color(0.086, 0.09, 0.106, 1.0) # #16171B
	m_wheel.metallic = 0.9
	m_wheel.roughness = 0.38
	ResourceSaver.save(m_wheel, "res://assets/materials/vehicles/mat_veh_wheel_black.tres")
	
	# 6. mat_veh_caliper
	var m_caliper = StandardMaterial3D.new()
	m_caliper.albedo_color = Color(0.702, 0.125, 0.165, 1.0) # #B3202A
	m_caliper.metallic = 0.3
	m_caliper.roughness = 0.4
	ResourceSaver.save(m_caliper, "res://assets/materials/vehicles/mat_veh_caliper.tres")
	
	# 7. mat_veh_glass_dark
	var m_glass = StandardMaterial3D.new()
	m_glass.albedo_color = Color(0.03, 0.035, 0.047, 0.85) # #08090C
	m_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_glass.metallic = 0.0
	m_glass.roughness = 0.06
	ResourceSaver.save(m_glass, "res://assets/materials/vehicles/mat_veh_glass_dark.tres")
	
	# 8. mat_veh_headlight_lens
	var m_lens = StandardMaterial3D.new()
	m_lens.albedo_color = Color(1.0, 1.0, 1.0, 0.35)
	m_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_lens.metallic = 0.0
	m_lens.roughness = 0.03
	ResourceSaver.save(m_lens, "res://assets/materials/vehicles/mat_veh_headlight_lens.tres")
	
	# 9. mat_veh_headlight_emit
	var m_h_emit = StandardMaterial3D.new()
	m_h_emit.albedo_color = Color(0.81, 0.90, 1.0, 1.0) # #CFE6FF
	m_h_emit.emission_enabled = true
	m_h_emit.emission = Color(0.81, 0.90, 1.0, 1.0)
	m_h_emit.emission_energy_multiplier = 1.5
	ResourceSaver.save(m_h_emit, "res://assets/materials/vehicles/mat_veh_headlight_emit.tres")
	
	# 10. mat_veh_taillight
	var m_tail = StandardMaterial3D.new()
	m_tail.albedo_color = Color(0.69, 0.06, 0.09, 0.85) # #B01018
	m_tail.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_tail.emission_enabled = true
	m_tail.emission = Color(1.0, 0.16, 0.16, 1.0)
	m_tail.emission_energy_multiplier = 0.6
	ResourceSaver.save(m_tail, "res://assets/materials/vehicles/mat_veh_taillight.tres")
	
	# 11. mat_env_asphalt_dry
	var m_asp_dry = StandardMaterial3D.new()
	m_asp_dry.albedo_color = Color(0.18, 0.176, 0.22, 1.0) # #2E2D38
	m_asp_dry.metallic = 0.0
	m_asp_dry.roughness = 0.85
	ResourceSaver.save(m_asp_dry, "res://assets/materials/environments/mat_env_asphalt_dry.tres")
	
	# 12. mat_env_asphalt_wet
	var m_asp_wet = StandardMaterial3D.new()
	m_asp_wet.albedo_color = Color(0.12, 0.118, 0.16, 1.0) # #1F1E29
	m_asp_wet.metallic = 0.0
	m_asp_wet.roughness = 0.25
	m_asp_wet.clearcoat_enabled = true
	m_asp_wet.clearcoat = 0.4
	m_asp_wet.clearcoat_roughness = 0.05
	if FileAccess.file_exists("res://assets/textures/environments/tex_env_asphalt_wet_albedo.png"):
		m_asp_wet.albedo_texture = load("res://assets/textures/environments/tex_env_asphalt_wet_albedo.png")
		m_asp_wet.roughness_texture = load("res://assets/textures/environments/tex_env_asphalt_wet_roughness.png")
		m_asp_wet.normal_enabled = true
		m_asp_wet.normal_texture = load("res://assets/textures/environments/tex_env_asphalt_wet_normal.png")
		m_asp_wet.uv1_scale = Vector3(8, 8, 8)
	ResourceSaver.save(m_asp_wet, "res://assets/materials/environments/mat_env_asphalt_wet.tres")
	
	# 13. mat_env_concrete_01
	var m_conc = StandardMaterial3D.new()
	m_conc.albedo_color = Color(0.43, 0.415, 0.47, 1.0) # #6E6A78
	m_conc.metallic = 0.0
	m_conc.roughness = 0.9
	ResourceSaver.save(m_conc, "res://assets/materials/environments/mat_env_concrete_01.tres")
	
	# 14. mat_env_metal_rail
	var m_rail = StandardMaterial3D.new()
	m_rail.albedo_color = Color(0.54, 0.556, 0.6, 1.0) # #8A8E99
	m_rail.metallic = 0.9
	m_rail.roughness = 0.45
	ResourceSaver.save(m_rail, "res://assets/materials/environments/mat_env_metal_rail.tres")
	
	# 15. mat_env_glass_tower
	var m_tower = StandardMaterial3D.new()
	m_tower.albedo_color = Color(0.118, 0.102, 0.2, 1.0) # #1E1A33
	m_tower.metallic = 0.5
	m_tower.roughness = 0.15
	if FileAccess.file_exists("res://assets/textures/environments/tex_env_windows_atlas_2k.png"):
		m_tower.emission_enabled = true
		m_tower.emission_texture = load("res://assets/textures/environments/tex_env_windows_atlas_2k.png")
		m_tower.emission = Color(1.0, 0.85, 0.63, 1.0) # #FFD9A0
		m_tower.emission_energy_multiplier = 0.8
	ResourceSaver.save(m_tower, "res://assets/materials/environments/mat_env_glass_tower.tres")
	
	# 16. mat_env_palm_leaf
	var m_palm = StandardMaterial3D.new()
	m_palm.albedo_color = Color(0.184, 0.29, 0.173, 1.0) # #2F4A2C
	m_palm.metallic = 0.0
	m_palm.roughness = 0.6
	m_palm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m_palm.alpha_scissor_threshold = 0.5
	m_palm.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_palm.backlight_enabled = true
	m_palm.backlight = Color(0.3, 0.35, 0.2, 1.0)
	if FileAccess.file_exists("res://assets/textures/environments/tex_env_palm_leaf_1k.png"):
		m_palm.albedo_texture = load("res://assets/textures/environments/tex_env_palm_leaf_1k.png")
	ResourceSaver.save(m_palm, "res://assets/materials/environments/mat_env_palm_leaf.tres")
	
	# 17. mat_env_billboard_face
	var m_bb = StandardMaterial3D.new()
	m_bb.roughness = 0.6
	m_bb.metallic = 0.0
	if FileAccess.file_exists("res://assets/textures/environments/tex_env_billboard_art_01.png"):
		m_bb.albedo_texture = load("res://assets/textures/environments/tex_env_billboard_art_01.png")
		m_bb.emission_enabled = true
		m_bb.emission_texture = load("res://assets/textures/environments/tex_env_billboard_art_01.png")
		m_bb.emission_energy_multiplier = 0.25
	ResourceSaver.save(m_bb, "res://assets/materials/environments/mat_env_billboard_face.tres")
	
	# 18. mat_env_streetlamp
	var m_lamp = StandardMaterial3D.new()
	m_lamp.albedo_color = Color(0.227, 0.239, 0.27, 1.0) # #3A3D45
	m_lamp.metallic = 0.7
	m_lamp.roughness = 0.45
	ResourceSaver.save(m_lamp, "res://assets/materials/environments/mat_env_streetlamp.tres")
	
	# 19. mat_env_chainlink
	var m_chain = StandardMaterial3D.new()
	m_chain.albedo_color = Color(0.482, 0.502, 0.541, 1.0) # #7B808A
	m_chain.metallic = 0.8
	m_chain.roughness = 0.5
	ResourceSaver.save(m_chain, "res://assets/materials/environments/mat_env_chainlink.tres")
	
	# 20. mat_env_water_far
	var m_water = StandardMaterial3D.new()
	m_water.albedo_color = Color(0.227, 0.208, 0.337, 1.0) # #3A3556
	m_water.metallic = 0.0
	m_water.roughness = 0.25
	ResourceSaver.save(m_water, "res://assets/materials/environments/mat_env_water_far.tres")
	
	print("All materials generated!")
	quit()
