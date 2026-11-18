@tool
extends SceneTree

func _init():
	print("Generating environment scenes and models...")
	generate_road_plaza()
	generate_road_markings()
	generate_jersey_barrier()
	generate_highway_curve()
	generate_highway_straight()
	generate_waterfront()
	generate_skylines()
	generate_landmark_tower()
	generate_palms()
	generate_billboard()
	generate_streetlamps()
	generate_fence()
	print("All environment assets generated successfully!")
	quit()

func generate_road_plaza():
	var root = Node3D.new()
	root.name = "RoadPlaza"
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "PlazaMesh"
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(80, 80)
	plane_mesh.subdivide_width = 16
	plane_mesh.subdivide_depth = 16
	mesh_inst.mesh = plane_mesh
	mesh_inst.material_override = load("res://assets/materials/environments/mat_env_asphalt_wet.tres")
	root.add_child(mesh_inst)
	mesh_inst.owner = root
	
	# StaticBody3D collision
	var static_body = StaticBody3D.new()
	static_body.name = "PlazaCollision"
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(80, 0.4, 80)
	col_shape.shape = box
	col_shape.position = Vector3(0, -0.2, 0)
	static_body.add_child(col_shape)
	col_shape.owner = static_body
	root.add_child(static_body)
	static_body.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/road/env_road_plaza_01.tscn")

func generate_road_markings():
	var root = Node3D.new()
	root.name = "RoadMarkings"
	
	# Orange sun reflection streak decal/mesh directly under the sun angle
	var streak = MeshInstance3D.new()
	streak.name = "SunReflectionStreak"
	var quad = QuadMesh.new()
	quad.size = Vector2(16, 45)
	quad.orientation = PlaneMesh.FACE_Y
	var st_mat = StandardMaterial3D.new()
	st_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	st_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st_mat.albedo_color = Color(1.0, 0.60, 0.28, 0.38) # #FF9A4A
	streak.mesh = quad
	streak.material_override = st_mat
	streak.position = Vector3(-4.5, 0.005, 12.0)
	root.add_child(streak)
	streak.owner = root
	
	# Yellow road border line
	var line_mesh = MeshInstance3D.new()
	line_mesh.name = "YellowBorderLine"
	var line_quad = QuadMesh.new()
	line_quad.size = Vector2(0.25, 60)
	line_quad.orientation = PlaneMesh.FACE_Y
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.72, 0.1, 0.85)
	line_mat.roughness = 0.5
	line_mesh.mesh = line_quad
	line_mesh.material_override = line_mat
	line_mesh.position = Vector3(7.2, 0.006, 10.0)
	root.add_child(line_mesh)
	line_mesh.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/road/env_road_markings_01.tscn")

func generate_jersey_barrier():
	var root = Node3D.new()
	root.name = "JerseyBarrier"
	
	# Modular 3m segment
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "BarrierMesh"
	var box = BoxMesh.new()
	box.size = Vector3(0.45, 0.82, 3.0)
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 0.41, 0)
	mesh_inst.material_override = load("res://assets/materials/environments/mat_env_concrete_01.tres")
	root.add_child(mesh_inst)
	mesh_inst.owner = root
	
	var col_body = StaticBody3D.new()
	var col_shape = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(0.45, 0.82, 3.0)
	col_shape.shape = box_col
	col_shape.position = Vector3(0, 0.41, 0)
	col_body.add_child(col_shape)
	col_shape.owner = col_body
	root.add_child(col_body)
	col_body.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/props/barrier/env_prop_barrier_jersey_01.tscn")

func generate_highway_curve():
	var root = Node3D.new()
	root.name = "HighwayCurve"
	
	var concrete_mat = load("res://assets/materials/environments/mat_env_concrete_01.tres")
	var rail_mat = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	
	# Curved deck segments approximated by 8 segmented sections along an arc
	var segments = 10
	var radius = 55.0
	var arc_rad = deg_to_rad(85.0)
	var width = 14.0
	var thickness = 1.6
	
	for i in range(segments):
		var t0 = float(i) / float(segments)
		var angle = t0 * arc_rad
		var x = -radius * cos(angle) + radius
		var z = radius * sin(angle)
		var next_angle = float(i + 1) / float(segments) * arc_rad
		var seg_len = radius * (next_angle - angle) * 1.05
		
		var deck = MeshInstance3D.new()
		deck.name = "DeckSeg_" + str(i)
		var box = BoxMesh.new()
		box.size = Vector3(width, thickness, seg_len)
		deck.mesh = box
		deck.material_override = concrete_mat
		deck.position = Vector3(x, 0, z)
		deck.rotation.y = -angle
		root.add_child(deck)
		deck.owner = root
		
		# Metal guardrail on outer rim
		var rail = MeshInstance3D.new()
		rail.name = "Guardrail_" + str(i)
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.2, 0.8, seg_len)
		rail.mesh = r_box
		rail.material_override = rail_mat
		rail.position = Vector3(x - (width * 0.48) * cos(angle), thickness * 0.5 + 0.4, z - (width * 0.48) * sin(angle))
		rail.rotation.y = -angle
		root.add_child(rail)
		rail.owner = root
		
		# 4 Pillars along the deck
		if i % 3 == 0:
			var pillar = MeshInstance3D.new()
			pillar.name = "Pillar_" + str(i)
			var p_cyl = CylinderMesh.new()
			p_cyl.top_radius = 1.2
			p_cyl.bottom_radius = 1.4
			p_cyl.height = 9.0
			pillar.mesh = p_cyl
			pillar.material_override = concrete_mat
			pillar.position = Vector3(x, -5.3, z)
			root.add_child(pillar)
			pillar.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/highway/env_highway_curve_01.tscn")

func generate_highway_straight():
	var root = Node3D.new()
	root.name = "HighwayStraight"
	
	var concrete_mat = load("res://assets/materials/environments/mat_env_concrete_01.tres")
	var rail_mat = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	
	# 90m long, 12m wide, 1.4m thick overpass
	var deck = MeshInstance3D.new()
	deck.name = "StraightDeck"
	var box = BoxMesh.new()
	box.size = Vector3(12.0, 1.4, 90.0)
	deck.mesh = box
	deck.material_override = concrete_mat
	root.add_child(deck)
	deck.owner = root
	
	# Guardrails on both sides
	for side in [-1.0, 1.0]:
		var rail = MeshInstance3D.new()
		rail.name = "Guardrail_" + ("L" if side < 0 else "R")
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.2, 0.8, 90.0)
		rail.mesh = r_box
		rail.material_override = rail_mat
		rail.position = Vector3(side * 5.8, 1.1, 0)
		root.add_child(rail)
		rail.owner = root
		
	# Pillars every 18m
	for pz in range(-36, 45, 18):
		var pillar = MeshInstance3D.new()
		pillar.name = "Pillar_Z" + str(pz)
		var cyl = CylinderMesh.new()
		cyl.top_radius = 1.0
		cyl.bottom_radius = 1.2
		cyl.height = 8.0
		pillar.mesh = cyl
		pillar.material_override = concrete_mat
		pillar.position = Vector3(0, -4.7, pz)
		root.add_child(pillar)
		pillar.owner = root
		
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/highway/env_highway_straight_01.tscn")

func generate_waterfront():
	var root = Node3D.new()
	root.name = "Waterfront"
	
	# Quay concrete edge
	var quay = MeshInstance3D.new()
	quay.name = "QuayEdge"
	var q_box = BoxMesh.new()
	q_box.size = Vector3(200.0, 3.0, 10.0)
	quay.mesh = q_box
	quay.material_override = load("res://assets/materials/environments/mat_env_concrete_01.tres")
	quay.position = Vector3(0, 0, 0)
	root.add_child(quay)
	quay.owner = root
	
	# Reflective water plane
	var water = MeshInstance3D.new()
	water.name = "WaterPlane"
	var w_plane = PlaneMesh.new()
	w_plane.size = Vector2(240, 90)
	water.mesh = w_plane
	water.material_override = load("res://assets/materials/environments/mat_env_water_far.tres")
	water.position = Vector3(0, -1.2, 45)
	root.add_child(water)
	water.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/waterfront/env_waterfront_edge_01.tscn")

func generate_skylines():
	var glass_mat = load("res://assets/materials/environments/mat_env_glass_tower.tres")
	var facade_mat_1 = load("res://assets/materials/environments/mat_env_building_facade_01.tres")
	var facade_mat_2 = load("res://assets/materials/environments/mat_env_building_facade_02.tres")
	var building_mats = [facade_mat_1, glass_mat, facade_mat_2, facade_mat_1]
	
	# 1. Far Skyline (14 towers)
	var root_far = Node3D.new()
	root_far.name = "SkylineFar"
	var rng = RandomNumberGenerator.new()
	rng.seed = 2026
	
	var tower_widths = [18.0, 22.0, 16.0, 26.0, 32.0, 20.0, 24.0, 19.0, 28.0, 22.0, 18.0, 25.0, 30.0, 20.0]
	var tower_heights = [80.0, 130.0, 160.0, 110.0, 210.0, 170.0, 240.0, 150.0, 190.0, 140.0, 120.0, 180.0, 160.0, 95.0]
	var cur_x = -130.0
	
	for i in range(14):
		var w = tower_widths[i]
		var h = tower_heights[i]
		var tower = MeshInstance3D.new()
		tower.name = "FarTower_" + str(i)
		var box = BoxMesh.new()
		box.size = Vector3(w, h, w * 0.8)
		tower.mesh = box
		tower.material_override = building_mats[i % building_mats.size()]
		tower.position = Vector3(cur_x + w * 0.5, h * 0.5, rng.randf_range(-15, 15))
		root_far.add_child(tower)
		tower.owner = root_far
		cur_x += w + 2.0
		
	var scene_far = PackedScene.new()
	scene_far.pack(root_far)
	ResourceSaver.save(scene_far, "res://assets/environments/city/skyline/env_city_skyline_far_01.tscn")
	
	# 2. Mid Skyline (10 towers with storefront and corporate facades)
	var root_mid = Node3D.new()
	root_mid.name = "SkylineMid"
	cur_x = -80.0
	var mid_heights = [70.0, 110.0, 140.0, 95.0, 130.0, 115.0, 150.0, 85.0, 105.0, 75.0]
	for i in range(10):
		var w = rng.randf_range(16.0, 24.0)
		var h = mid_heights[i]
		var tower = MeshInstance3D.new()
		tower.name = "MidTower_" + str(i)
		var box = BoxMesh.new()
		box.size = Vector3(w, h, w)
		tower.mesh = box
		tower.material_override = building_mats[(i + 1) % building_mats.size()]
		tower.position = Vector3(cur_x + w * 0.5, h * 0.5, rng.randf_range(-10, 10))
		root_mid.add_child(tower)
		tower.owner = root_mid
		cur_x += w + 3.0
		
	var scene_mid = PackedScene.new()
	scene_mid.pack(root_mid)
	ResourceSaver.save(scene_mid, "res://assets/environments/city/skyline/env_city_skyline_mid_01.tscn")

func generate_landmark_tower():
	# Focal hero glass tower at 68% x screen (40x40x220m with setbacks and antenna)
	var root = Node3D.new()
	root.name = "LandmarkTower"
	var glass_mat = load("res://assets/materials/environments/mat_env_glass_tower.tres")
	
	# Base section (40x40x120m)
	var b1 = MeshInstance3D.new()
	b1.name = "BaseSection"
	var box1 = BoxMesh.new()
	box1.size = Vector3(40, 120, 40)
	b1.mesh = box1
	b1.material_override = glass_mat
	b1.position = Vector3(0, 60, 0)
	root.add_child(b1)
	b1.owner = root
	
	# Mid setback (32x32x60m)
	var b2 = MeshInstance3D.new()
	b2.name = "MidSection"
	var box2 = BoxMesh.new()
	box2.size = Vector3(32, 60, 32)
	b2.mesh = box2
	b2.material_override = glass_mat
	b2.position = Vector3(0, 150, 0)
	root.add_child(b2)
	b2.owner = root
	
	# Top crown (24x24x40m)
	var b3 = MeshInstance3D.new()
	b3.name = "CrownSection"
	var box3 = BoxMesh.new()
	box3.size = Vector3(24, 40, 24)
	b3.mesh = box3
	b3.material_override = glass_mat
	b3.position = Vector3(0, 200, 0)
	root.add_child(b3)
	b3.owner = root
	
	# Antenna spire (25m tall)
	var ant = MeshInstance3D.new()
	ant.name = "Spire"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 1.0
	cyl.height = 25.0
	ant.mesh = cyl
	ant.material_override = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	ant.position = Vector3(0, 232.5, 0)
	root.add_child(ant)
	ant.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/city/landmarks/env_landmark_tower_01.tscn")

func generate_palms():
	var leaf_mat = load("res://assets/materials/environments/mat_env_palm_leaf.tres")
	var trunk_mat = load("res://assets/materials/environments/mat_env_concrete_01.tres")
	
	# 1. Tall Hero Palm (env_veg_palm_01) - 9m tall
	var root1 = Node3D.new()
	root1.name = "HeroPalm"
	
	var trunk1 = MeshInstance3D.new()
	trunk1.name = "Trunk"
	var cyl1 = CylinderMesh.new()
	cyl1.top_radius = 0.22
	cyl1.bottom_radius = 0.38
	cyl1.height = 9.0
	trunk1.mesh = cyl1
	trunk1.material_override = trunk_mat
	trunk1.position = Vector3(0, 4.5, 0)
	root1.add_child(trunk1)
	trunk1.owner = root1
	
	# Canopy fronds (crossed quads with leaf texture)
	var frond_count = 12
	for i in range(frond_count):
		var angle = float(i) / float(frond_count) * TAU
		var frond = MeshInstance3D.new()
		frond.name = "Frond_" + str(i)
		var q = QuadMesh.new()
		q.size = Vector2(2.5, 4.2)
		frond.mesh = q
		frond.material_override = leaf_mat
		frond.position = Vector3(sin(angle) * 1.5, 8.8, cos(angle) * 1.5)
		frond.rotation = Vector3(deg_to_rad(35.0), angle, 0)
		root1.add_child(frond)
		frond.owner = root1
		
	var scene1 = PackedScene.new()
	scene1.pack(root1)
	ResourceSaver.save(scene1, "res://assets/environments/vegetation/env_veg_palm_01.tscn")
	
	# 2. Cluster Palms (env_veg_palm_02) - 3 smaller palms (5m)
	var root2 = Node3D.new()
	root2.name = "PalmCluster"
	var offsets = [Vector3(0, 0, 0), Vector3(2.5, 0, 1.2), Vector3(-2.0, 0, 1.8)]
	for c_idx in range(3):
		var sub_p = Node3D.new()
		sub_p.name = "Palm_" + str(c_idx)
		sub_p.position = offsets[c_idx]
		root2.add_child(sub_p)
		sub_p.owner = root2
		
		var trunk = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.16
		cyl.bottom_radius = 0.26
		cyl.height = 5.0
		trunk.mesh = cyl
		trunk.material_override = trunk_mat
		trunk.position = Vector3(0, 2.5, 0)
		sub_p.add_child(trunk)
		trunk.owner = root2
		
		for f_idx in range(8):
			var a = float(f_idx) / 8.0 * TAU
			var fr = MeshInstance3D.new()
			var q = QuadMesh.new()
			q.size = Vector2(1.8, 3.2)
			fr.mesh = q
			fr.material_override = leaf_mat
			fr.position = Vector3(sin(a)*1.1, 4.9, cos(a)*1.1)
			fr.rotation = Vector3(deg_to_rad(30.0), a, 0)
			sub_p.add_child(fr)
			fr.owner = root2
		
	var scene2 = PackedScene.new()
	scene2.pack(root2)
	ResourceSaver.save(scene2, "res://assets/environments/vegetation/env_veg_palm_02.tscn")

func generate_billboard():
	# Frame 14x6m, steel pole 0.7m dia x 9m, catwalk, 4 small lights
	var root = Node3D.new()
	root.name = "Billboard"
	
	var metal_mat = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	var face_mat = load("res://assets/materials/environments/mat_env_billboard_face.tres")
	
	# Pole
	var pole = MeshInstance3D.new()
	pole.name = "SteelPole"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.4
	cyl.height = 9.0
	pole.mesh = cyl
	pole.material_override = metal_mat
	pole.position = Vector3(0, 4.5, 0)
	root.add_child(pole)
	pole.owner = root
	
	# Billboard Face (14x6m)
	var face = MeshInstance3D.new()
	face.name = "BillboardFace"
	var q = QuadMesh.new()
	q.size = Vector2(14.0, 6.0)
	face.mesh = q
	face.material_override = face_mat
	face.position = Vector3(0, 9.0, 0.1)
	root.add_child(face)
	face.owner = root
	
	# Frame / backing
	var frame = MeshInstance3D.new()
	frame.name = "FrameBacking"
	var box = BoxMesh.new()
	box.size = Vector3(14.4, 6.4, 0.3)
	frame.mesh = box
	frame.material_override = metal_mat
	frame.position = Vector3(0, 9.0, -0.05)
	root.add_child(frame)
	frame.owner = root
	
	# Catwalk at bottom
	var catwalk = MeshInstance3D.new()
	catwalk.name = "Catwalk"
	var c_box = BoxMesh.new()
	c_box.size = Vector3(15.0, 0.15, 1.2)
	catwalk.mesh = c_box
	catwalk.material_override = metal_mat
	catwalk.position = Vector3(0, 5.85, 0.6)
	root.add_child(catwalk)
	catwalk.owner = root
	
	# 4 Small floodlights
	for lx in [-5.0, -1.6, 1.6, 5.0]:
		var light_mesh = MeshInstance3D.new()
		light_mesh.name = "LightFixture_" + str(lx)
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.5, 0.3, 0.4)
		light_mesh.mesh = l_box
		light_mesh.material_override = metal_mat
		light_mesh.position = Vector3(lx, 6.2, 0.8)
		root.add_child(light_mesh)
		light_mesh.owner = root
		
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/props/billboard/env_prop_billboard_01.tscn")

func generate_streetlamps():
	var metal_mat = load("res://assets/materials/environments/mat_env_streetlamp.tres")
	
	# Single arm
	var root1 = Node3D.new()
	root1.name = "StreetlampSingle"
	
	var pole1 = MeshInstance3D.new()
	pole1.name = "Pole"
	var cyl1 = CylinderMesh.new()
	cyl1.top_radius = 0.12
	cyl1.bottom_radius = 0.18
	cyl1.height = 9.0
	pole1.mesh = cyl1
	pole1.material_override = metal_mat
	pole1.position = Vector3(0, 4.5, 0)
	root1.add_child(pole1)
	pole1.owner = root1
	
	var arm1 = MeshInstance3D.new()
	arm1.name = "Arm"
	var a_box1 = BoxMesh.new()
	a_box1.size = Vector3(0.1, 0.1, 2.2)
	arm1.mesh = a_box1
	arm1.material_override = metal_mat
	arm1.position = Vector3(0, 8.8, 1.0)
	root1.add_child(arm1)
	arm1.owner = root1
	
	var head1 = MeshInstance3D.new()
	head1.name = "LampHead"
	var h_box1 = BoxMesh.new()
	h_box1.size = Vector3(0.35, 0.15, 0.6)
	head1.mesh = h_box1
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(1.0, 0.85, 0.63, 1.0)
	head_mat.emission_enabled = true
	head_mat.emission = Color(1.0, 0.85, 0.63, 1.0)
	head_mat.emission_energy_multiplier = 2.0
	head1.material_override = head_mat
	head1.position = Vector3(0, 8.7, 2.0)
	root1.add_child(head1)
	head1.owner = root1
	
	var light1 = OmniLight3D.new()
	light1.name = "GlowLight"
	light1.light_color = Color(1.0, 0.85, 0.63, 1.0) # #FFD9A0
	light1.light_energy = 2.0
	light1.omni_range = 8.0
	light1.position = Vector3(0, 8.5, 2.0)
	root1.add_child(light1)
	light1.owner = root1
	
	var scene1 = PackedScene.new()
	scene1.pack(root1)
	ResourceSaver.save(scene1, "res://assets/environments/props/streetlamp/env_prop_streetlamp_01.tscn")
	
	# Double arm variant
	var root2 = Node3D.new()
	root2.name = "StreetlampDouble"
	var pole2 = pole1.duplicate()
	root2.add_child(pole2)
	pole2.owner = root2
	
	for dir in [-1.0, 1.0]:
		var arm = MeshInstance3D.new()
		arm.name = "Arm_" + ("F" if dir > 0 else "B")
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.1, 0.1, 2.2)
		arm.mesh = a_box
		arm.material_override = metal_mat
		arm.position = Vector3(0, 8.8, dir * 1.0)
		root2.add_child(arm)
		arm.owner = root2
		
		var head = MeshInstance3D.new()
		head.name = "LampHead_" + ("F" if dir > 0 else "B")
		var h_box = BoxMesh.new()
		h_box.size = Vector3(0.35, 0.15, 0.6)
		head.mesh = h_box
		head.material_override = head_mat
		head.position = Vector3(0, 8.7, dir * 2.0)
		root2.add_child(head)
		head.owner = root2
		
	var light2 = OmniLight3D.new()
	light2.name = "GlowLight"
	light2.light_color = Color(1.0, 0.85, 0.63, 1.0)
	light2.light_energy = 2.5
	light2.omni_range = 10.0
	light2.position = Vector3(0, 8.5, 0)
	root2.add_child(light2)
	light2.owner = root2
	
	var scene2 = PackedScene.new()
	scene2.pack(root2)
	ResourceSaver.save(scene2, "res://assets/environments/props/streetlamp/env_prop_streetlamp_double_01.tscn")

func generate_fence():
	var root = Node3D.new()
	root.name = "ChainlinkFence"
	var chain_mat = load("res://assets/materials/environments/mat_env_chainlink.tres")
	
	var mesh = MeshInstance3D.new()
	mesh.name = "FencePanel"
	var q = QuadMesh.new()
	q.size = Vector2(3.0, 2.4)
	mesh.mesh = q
	mesh.material_override = chain_mat
	mesh.position = Vector3(0, 1.2, 0)
	root.add_child(mesh)
	mesh.owner = root
	
	var post = MeshInstance3D.new()
	post.name = "Post"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.04
	cyl.height = 2.4
	post.mesh = cyl
	post.material_override = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	post.position = Vector3(1.5, 1.2, 0)
	root.add_child(post)
	post.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/props/fence/env_prop_fence_chainlink_01.tscn")
