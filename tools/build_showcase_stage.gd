@tool
extends SceneTree

func _init():
	print("Building showcase_stage.tscn...")
	var stage = Node3D.new()
	stage.name = "ShowcaseStage"
	
	# 1. Road Plaza
	var road_scene = load("res://assets/environments/road/env_road_plaza_01.tscn")
	var road = road_scene.instantiate()
	road.name = "Plaza"
	road.position = Vector3(0, -0.02, 20)
	stage.add_child(road)
	road.owner = stage
	
	# Markings
	var markings_scene = load("res://assets/environments/road/env_road_markings_01.tscn")
	var markings = markings_scene.instantiate()
	markings.name = "Markings"
	markings.position = Vector3(0, 0, 0)
	stage.add_child(markings)
	markings.owner = stage
	
	# 2. Elevated curve highway (-34, 7.5, 40), rot Y 15Â°
	var curve_scene = load("res://assets/environments/highway/env_highway_curve_01.tscn")
	var curve = curve_scene.instantiate()
	curve.name = "HighwayCurve"
	curve.position = Vector3(-34, 7.5, 40)
	curve.rotation_degrees = Vector3(0, 15, 0)
	stage.add_child(curve)
	curve.owner = stage
	
	# 3. Straight overpass (6, 6.5, 62), rot Y 90Â°
	var straight_scene = load("res://assets/environments/highway/env_highway_straight_01.tscn")
	var straight = straight_scene.instantiate()
	straight.name = "HighwayStraight"
	straight.position = Vector3(6, 6.5, 62)
	straight.rotation_degrees = Vector3(0, 90, 0)
	stage.add_child(straight)
	straight.owner = stage
	
	# 4. Waterfront (30, -1.2, 110)
	var water_scene = load("res://assets/environments/waterfront/env_waterfront_edge_01.tscn")
	var water = water_scene.instantiate()
	water.name = "Waterfront"
	water.position = Vector3(30, -1.2, 110)
	stage.add_child(water)
	water.owner = stage
	
	# 5. Skyline Far (45, 0, 300)
	var far_scene = load("res://assets/environments/city/skyline/env_city_skyline_far_01.tscn")
	var skyline_far = far_scene.instantiate()
	skyline_far.name = "SkylineFar"
	skyline_far.position = Vector3(45, 0, 300)
	stage.add_child(skyline_far)
	skyline_far.owner = stage
	
	# 6. Skyline Mid (30, 0, 140)
	var mid_scene = load("res://assets/environments/city/skyline/env_city_skyline_mid_01.tscn")
	var skyline_mid = mid_scene.instantiate()
	skyline_mid.name = "SkylineMid"
	skyline_mid.position = Vector3(30, 0, 140)
	stage.add_child(skyline_mid)
	skyline_mid.owner = stage
	
	# 7. Landmark Tower (60, 0, 160)
	var tower_scene = load("res://assets/environments/city/landmarks/env_landmark_tower_01.tscn")
	var tower = tower_scene.instantiate()
	tower.name = "LandmarkTower"
	tower.position = Vector3(60, 0, 160)
	stage.add_child(tower)
	tower.owner = stage
	
	# 8. Hero Palm (13.5, 0, 6), rot Y 12Â°
	var palm_scene = load("res://assets/environments/vegetation/env_veg_palm_01.tscn")
	var palm = palm_scene.instantiate()
	palm.name = "HeroPalm"
	palm.position = Vector3(13.5, 0, 6)
	palm.rotation_degrees = Vector3(0, 12, 0)
	stage.add_child(palm)
	palm.owner = stage
	
	# 9. Palm Cluster (18, 0, 12)
	var cluster_scene = load("res://assets/environments/vegetation/env_veg_palm_02.tscn")
	var cluster = cluster_scene.instantiate()
	cluster.name = "PalmCluster"
	cluster.position = Vector3(18, 0, 12)
	stage.add_child(cluster)
	cluster.owner = stage
	
	# 10. Billboard (11.5, 8.5, 16), rot Y -28Â°
	var bb_scene = load("res://assets/environments/props/billboard/env_prop_billboard_01.tscn")
	var bb = bb_scene.instantiate()
	bb.name = "Billboard"
	bb.position = Vector3(11.5, 0, 16)
	bb.rotation_degrees = Vector3(0, -28, 0)
	stage.add_child(bb)
	bb.owner = stage
	
	# 11. Streetlamps
	var lamp_single = load("res://assets/environments/props/streetlamp/env_prop_streetlamp_01.tscn")
	var lamp_double = load("res://assets/environments/props/streetlamp/env_prop_streetlamp_double_01.tscn")
	
	# L-near: (-12, 0, 9), rot Y 90Â°
	var l_near = lamp_single.instantiate()
	l_near.name = "Lamp_L_Near"
	l_near.position = Vector3(-12, 0, 9)
	l_near.rotation_degrees = Vector3(0, 90, 0)
	stage.add_child(l_near)
	l_near.owner = stage
	
	# L-far: (-18, 0, 28), rot Y 0Â°
	var l_far = lamp_single.instantiate()
	l_far.name = "Lamp_L_Far"
	l_far.position = Vector3(-18, 0, 28)
	stage.add_child(l_far)
	l_far.owner = stage
	
	# R-double: (6, 0, 30), rot Y 0Â°
	var l_r_double = lamp_double.instantiate()
	l_r_double.name = "Lamp_R_Double"
	l_r_double.position = Vector3(6, 0, 30)
	stage.add_child(l_r_double)
	l_r_double.owner = stage
	
	# 12. Chain-link fence run from (-22, 0, 10) to (-6, 0, 24)
	var fence_scene = load("res://assets/environments/props/fence/env_prop_fence_chainlink_01.tscn")
	var fence_root = Node3D.new()
	fence_root.name = "FenceRun"
	stage.add_child(fence_root)
	fence_root.owner = stage
	
	for i in range(6):
		var t = float(i) / 5.0
		var pos = Vector3(-22, 0, 10).lerp(Vector3(-6, 0, 24), t)
		var p_fence = fence_scene.instantiate()
		p_fence.name = "Fence_" + str(i)
		p_fence.position = pos
		p_fence.rotation_degrees = Vector3(0, -41, 0)
		fence_root.add_child(p_fence)
		p_fence.owner = stage
		
	# 13. Jersey barrier run along right side from (7.5, 0, 3) to (16, 0, 12)
	var barrier_scene = load("res://assets/environments/props/barrier/env_prop_barrier_jersey_01.tscn")
	var barrier_root = Node3D.new()
	barrier_root.name = "BarrierRun"
	stage.add_child(barrier_root)
	barrier_root.owner = stage
	
	for i in range(8):
		var t = float(i) / 7.0
		var pos = Vector3(7.5, 0, 1).lerp(Vector3(16, 0, 14), t)
		var p_barr = barrier_scene.instantiate()
		p_barr.name = "Barrier_" + str(i)
		p_barr.position = pos
		p_barr.rotation_degrees = Vector3(0, -33, 0)
		barrier_root.add_child(p_barr)
		p_barr.owner = stage
		
	# 14. Barrier Glow Light at (12, 1.2, 8)
	var bar_glow = OmniLight3D.new()
	bar_glow.name = "BarrierGlow"
	bar_glow.light_color = Color(1.0, 0.71, 0.40, 1.0) # #FFB566
	bar_glow.light_energy = 2.0
	bar_glow.omni_range = 7.0
	bar_glow.position = Vector3(12, 1.2, 8)
	stage.add_child(bar_glow)
	bar_glow.owner = stage
	
	# 15. Roadside Textured Buildings (Real Motorsport Pit Showroom & Commercial Tower)
	var facade_mat_1 = load("res://assets/materials/environments/mat_env_building_facade_01.tres")
	var facade_mat_2 = load("res://assets/materials/environments/mat_env_building_facade_02.tres")
	
	# Building 1: Left Pit Garage & Showroom (-24, 0, 20), rot Y 36°
	var b_left = MeshInstance3D.new()
	b_left.name = "RoadsidePitShowroom"
	var b1_mesh = BoxMesh.new()
	b1_mesh.size = Vector3(24.0, 15.0, 18.0)
	b_left.mesh = b1_mesh
	b_left.material_override = facade_mat_1
	b_left.position = Vector3(-24.0, 7.5, 20.0)
	b_left.rotation_degrees = Vector3(0, 36.0, 0)
	stage.add_child(b_left)
	b_left.owner = stage
	
	# Building 2: Right Commercial Race Tower (26, 0, 26), rot Y -28°
	var b_right = MeshInstance3D.new()
	b_right.name = "RoadsideRaceTower"
	var b2_mesh = BoxMesh.new()
	b2_mesh.size = Vector3(20.0, 32.0, 20.0)
	b_right.mesh = b2_mesh
	b_right.material_override = facade_mat_2
	b_right.position = Vector3(26.0, 16.0, 26.0)
	b_right.rotation_degrees = Vector3(0, -28.0, 0)
	stage.add_child(b_right)
	b_right.owner = stage
	
	# 16. ReflectionProbes (§8.4)
	var probe_car = ReflectionProbe.new()
	probe_car.name = "ReflectionProbe_Car"
	probe_car.size = Vector3(14, 5, 14)
	probe_car.position = Vector3(0, 1.5, 0)
	probe_car.box_projection = true
	probe_car.intensity = 1.0
	probe_car.update_mode = ReflectionProbe.UPDATE_ALWAYS
	stage.add_child(probe_car)
	probe_car.owner = stage
	
	var probe_road = ReflectionProbe.new()
	probe_road.name = "ReflectionProbe_Road"
	probe_road.size = Vector3(30, 6, 30)
	probe_road.position = Vector3(0, 1.0, 15)
	probe_road.box_projection = true
	probe_road.intensity = 1.0
	probe_road.update_mode = ReflectionProbe.UPDATE_ALWAYS
	stage.add_child(probe_road)
	probe_road.owner = stage
	
	var scene = PackedScene.new()
	scene.pack(stage)
	ResourceSaver.save(scene, "res://scenes/environment/showcase_stage.tscn")
	print("showcase_stage.tscn built successfully!")
	quit()
