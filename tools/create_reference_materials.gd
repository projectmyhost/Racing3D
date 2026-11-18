@tool
extends SceneTree

func _init():
	print("Creating reference PBR materials...")
	
	# 1. Wet Asphalt
	var m_asphalt = StandardMaterial3D.new()
	m_asphalt.albedo_color = Color(0.12, 0.12, 0.14, 1.0)
	m_asphalt.albedo_texture = load("res://assets/textures/environments/tex_ref_asphalt_albedo.png")
	m_asphalt.roughness_texture = load("res://assets/textures/environments/tex_ref_asphalt_roughness.png")
	m_asphalt.normal_enabled = true
	m_asphalt.normal_texture = load("res://assets/textures/environments/tex_ref_asphalt_normal.png")
	m_asphalt.clearcoat_enabled = true
	m_asphalt.clearcoat = 0.55
	m_asphalt.clearcoat_roughness = 0.06
	m_asphalt.uv1_scale = Vector3(14, 14, 14)
	ResourceSaver.save(m_asphalt, "res://assets/materials/environments/mat_ref_asphalt_wet.tres")
	
	# 2. Billboard Face
	var m_bb = StandardMaterial3D.new()
	var bb_tex = load("res://assets/textures/environments/tex_ref_billboard_art.png")
	m_bb.albedo_texture = bb_tex
	m_bb.roughness = 0.25
	m_bb.emission_enabled = true
	m_bb.emission_texture = bb_tex
	m_bb.emission_energy_multiplier = 0.95
	ResourceSaver.save(m_bb, "res://assets/materials/environments/mat_ref_billboard_art.tres")
	
	# 3. Left HQ Building
	var m_b_left = StandardMaterial3D.new()
	var bl_albedo = load("res://assets/textures/environments/tex_ref_building_left_albedo.png")
	var bl_emission = load("res://assets/textures/environments/tex_ref_building_left_emission.png")
	m_b_left.albedo_texture = bl_albedo
	m_b_left.roughness = 0.42
	m_b_left.emission_enabled = true
	m_b_left.emission_texture = bl_emission
	m_b_left.emission_energy_multiplier = 1.15
	ResourceSaver.save(m_b_left, "res://assets/materials/environments/mat_ref_building_left.tres")
	
	# 4. Right Commercial Tower
	var m_b_right = StandardMaterial3D.new()
	var br_albedo = load("res://assets/textures/environments/tex_ref_building_right_albedo.png")
	var br_emission = load("res://assets/textures/environments/tex_ref_building_right_emission.png")
	m_b_right.albedo_texture = br_albedo
	m_b_right.roughness = 0.32
	m_b_right.metallic = 0.20
	m_b_right.emission_enabled = true
	m_b_right.emission_texture = br_emission
	m_b_right.emission_energy_multiplier = 1.20
	ResourceSaver.save(m_b_right, "res://assets/materials/environments/mat_ref_building_right.tres")
	
	# 5. Drainage Grate
	var m_grate = StandardMaterial3D.new()
	m_grate.albedo_texture = load("res://assets/textures/environments/tex_ref_drainage_grate.png")
	m_grate.metallic = 0.85
	m_grate.roughness = 0.35
	m_grate.uv1_scale = Vector3(1, 35, 1)
	ResourceSaver.save(m_grate, "res://assets/materials/environments/mat_ref_drainage_grate.tres")
	
	# 6. Racing Banner
	var m_banner = StandardMaterial3D.new()
	m_banner.albedo_texture = load("res://assets/textures/environments/tex_ref_racing_banner.png")
	m_banner.roughness = 0.60
	m_banner.cull_mode = BaseMaterial3D.CULL_DISABLED
	ResourceSaver.save(m_banner, "res://assets/materials/environments/mat_ref_racing_banner.tres")
	
	# 7. Palm Frond
	var m_palm = StandardMaterial3D.new()
	m_palm.albedo_texture = load("res://assets/textures/environments/tex_ref_palm_leaf.png")
	m_palm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m_palm.alpha_scissor_threshold = 0.40
	m_palm.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_palm.roughness = 0.50
	ResourceSaver.save(m_palm, "res://assets/materials/environments/mat_ref_palm_leaf.tres")
	
	print("All reference materials saved successfully!")
	quit(0)

