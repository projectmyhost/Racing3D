@tool
extends SceneTree

func _init():
	print("Building full 3D RB22 showcase car...")
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	var err = gltf.append_from_file("assets/source/untitled.glb", state)
	if err != OK:
		print("Error loading untitled.glb: ", err)
		quit(1)
		return
		
	var imported_scene = gltf.generate_scene(state)
	var raw_mesh_node: MeshInstance3D = imported_scene.get_node("f1_2026_rb22")
	
	# Root node with ShowcaseCar script
	var root = Node3D.new()
	root.name = "VehicleRoot"
	root.set_script(load("res://scripts/vehicle/showcase_car.gd"))
	
	# 1. VisualRoot
	var vis_root = Node3D.new()
	vis_root.name = "VisualRoot"
	root.add_child(vis_root)
	vis_root.owner = root
	
	# Create CarMesh under VisualRoot
	var car_mesh = MeshInstance3D.new()
	car_mesh.name = "CarMesh"
	car_mesh.mesh = raw_mesh_node.mesh.duplicate(true)
	
	# Orient car:
	# Local rot x=90 puts length on Z and height on Y
	# rot y=180 faces front toward -Z (Godot convention)
	# Bottom of tires is at Y = -0.032, so lift Y by +0.032 to make it sit exactly on ground Y = 0.0
	# Offset Z by -0.24 to center the wheelbase at (0, 0, 0)
	car_mesh.position = Vector3(0.0, 0.032, 0.24)
	car_mesh.rotation_degrees = Vector3(90.0, 180.0, 0.0)
	car_mesh.scale = Vector3(1.0, 1.0, 1.0)
	
	# Configure surfaces and PBR properties
	var mesh = car_mesh.mesh
	var surf_count = mesh.get_surface_count()
	print("Optimizing ", surf_count, " surfaces on RB22 mesh...")
	
	for s in range(surf_count):
		var orig_mat = mesh.surface_get_material(s) as BaseMaterial3D
		if orig_mat:
			var mat = orig_mat.duplicate() as StandardMaterial3D
			var m_name = mat.resource_name.to_lower()
			
			# Ensure cull mode is disabled so aerodynamic vanes & wings render both sides
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			
			if m_name.contains("paint"):
				# Main Livery Paint: rich Red Bull dark matte-navy sheen with clearcoat
				mat.roughness = 0.25
				mat.metallic = 0.35
				mat.clearcoat_enabled = true
				mat.clearcoat = 0.85
				mat.clearcoat_roughness = 0.1
				
			elif m_name.contains("decal"):
				# Decals (Oracle, Red Bull, Honda, Mobil 1, etc.)
				# Alpha scissor ensures zero depth artifacts and crisp edges
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mat.alpha_scissor_threshold = 0.35
				mat.roughness = 0.3
				
			elif m_name.contains("glass"):
				# Visor / windshield glass
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
				mat.albedo_color = Color(0.1, 0.12, 0.15, 0.5)
				mat.roughness = 0.05
				mat.metallic = 0.1
				
			elif m_name.contains("rear_light"):
				# FIA rear rain light
				mat.emission_enabled = true
				mat.emission = Color(1.0, 0.1, 0.1, 1.0)
				mat.emission_energy_multiplier = 2.5
				
			elif m_name.contains("carbon"):
				# Formula 1 exposed carbon fiber weaves
				mat.metallic = 0.15
				mat.roughness = 0.38
				
			elif m_name.contains("sidewall"):
				# Pirelli F1 Tires
				mat.metallic = 0.0
				mat.roughness = 0.88
				
			elif m_name.contains("discs"):
				# Carbon-carbon brake discs
				mat.metallic = 0.6
				mat.roughness = 0.45
				
			elif m_name.contains("wheel_hub") or m_name.contains("chrome"):
				# Wheel rims and center nuts
				mat.metallic = 0.9
				mat.roughness = 0.25
				
			elif m_name.contains("lcd") or m_name.contains("clearled"):
				# Steering wheel dashboard LCD display
				mat.emission_enabled = true
				mat.emission = Color(0.3, 0.8, 1.0, 1.0)
				mat.emission_energy_multiplier = 1.2
				
			car_mesh.set_surface_override_material(s, mat)
			mesh.surface_set_material(s, mat)
			
	vis_root.add_child(car_mesh)
	car_mesh.owner = root
	
	# Contract nodes (Â§4.3)
	var body_proxy = MeshInstance3D.new()
	body_proxy.name = "Body"
	vis_root.add_child(body_proxy)
	body_proxy.owner = root
	
	var hood_proxy = MeshInstance3D.new()
	hood_proxy.name = "Hood"
	vis_root.add_child(hood_proxy)
	hood_proxy.owner = root
	
	var fb_proxy = MeshInstance3D.new()
	fb_proxy.name = "FrontBumper"
	vis_root.add_child(fb_proxy)
	fb_proxy.owner = root
	
	var rb_proxy = MeshInstance3D.new()
	rb_proxy.name = "RearBumper"
	vis_root.add_child(rb_proxy)
	rb_proxy.owner = root
	
	var sp_proxy = MeshInstance3D.new()
	sp_proxy.name = "Spoiler"
	vis_root.add_child(sp_proxy)
	sp_proxy.owner = root
	
	var win_proxy = MeshInstance3D.new()
	win_proxy.name = "Windows"
	vis_root.add_child(win_proxy)
	win_proxy.owner = root
	
	var hl_root = Node3D.new()
	hl_root.name = "Headlights"
	vis_root.add_child(hl_root)
	hl_root.owner = root
	
	var tl_root = Node3D.new()
	tl_root.name = "Taillights"
	vis_root.add_child(tl_root)
	tl_root.owner = root
	
	var mir_root = Node3D.new()
	mir_root.name = "Mirrors"
	vis_root.add_child(mir_root)
	mir_root.owner = root
	
	var wheels_root = Node3D.new()
	wheels_root.name = "Wheels"
	vis_root.add_child(wheels_root)
	wheels_root.owner = root
	
	# Wheel pivots at authentic F1 2026 axle positions:
	# Front axle at Z â‰ˆ -1.75m, Rear axle at Z â‰ˆ +1.85m, Track width Â±0.88m
	var wheel_data = [
		{"name": "FrontLeft", "pos": Vector3(-0.88, 0.35, -1.75)},
		{"name": "FrontRight", "pos": Vector3(0.88, 0.35, -1.75)},
		{"name": "RearLeft", "pos": Vector3(-0.88, 0.36, 1.85)},
		{"name": "RearRight", "pos": Vector3(0.88, 0.36, 1.85)}
	]
	for wd in wheel_data:
		var p = Node3D.new()
		p.name = wd["name"]
		p.position = wd["pos"]
		wheels_root.add_child(p)
		p.owner = root
		
	# 2. CollisionRoot
	var col_root = Node3D.new()
	col_root.name = "CollisionRoot"
	root.add_child(col_root)
	col_root.owner = root
	
	var b_col = CollisionShape3D.new()
	b_col.name = "BodyCollision"
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(1.95, 1.15, 5.4)
	b_col.shape = box_col
	b_col.position = Vector3(0, 0.58, 0)
	col_root.add_child(b_col)
	b_col.owner = root
	
	# 3. WheelAnchors
	var anchors_root = Node3D.new()
	anchors_root.name = "WheelAnchors"
	root.add_child(anchors_root)
	anchors_root.owner = root
	for an in ["AnchorFL", "AnchorFR", "AnchorRL", "AnchorRR"]:
		var m = Marker3D.new()
		m.name = an
		anchors_root.add_child(m)
		m.owner = root
		
	# 4. VehicleEffects
	var fx_root = Node3D.new()
	fx_root.name = "VehicleEffects"
	root.add_child(fx_root)
	fx_root.owner = root
	
	var rain_light = OmniLight3D.new()
	rain_light.name = "RainLight"
	rain_light.light_color = Color(1.0, 0.1, 0.1, 1.0)
	rain_light.light_energy = 2.0
	rain_light.omni_range = 4.0
	rain_light.position = Vector3(0, 0.38, 2.7)
	fx_root.add_child(rain_light)
	rain_light.owner = root
	
	var ex_l = Marker3D.new()
	ex_l.name = "ExhaustPointL"
	ex_l.position = Vector3(-0.15, 0.52, 2.3)
	fx_root.add_child(ex_l)
	ex_l.owner = root
	
	var ex_r = Marker3D.new()
	ex_r.name = "ExhaustPointR"
	ex_r.position = Vector3(0.15, 0.52, 2.3)
	fx_root.add_child(ex_r)
	ex_r.owner = root
	
	var ug = Marker3D.new()
	ug.name = "UnderglowAnchor"
	ug.position = Vector3(0, 0.05, 0)
	fx_root.add_child(ug)
	ug.owner = root
	
	# Save packed scene
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/vehicles/showcase_car.tscn")
	print("Saved real RB22 showcase car to res://scenes/vehicles/showcase_car.tscn successfully!")
	quit(0)
