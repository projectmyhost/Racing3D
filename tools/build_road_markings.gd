@tool
extends SceneTree

func _init():
	print("Building enhanced realistic road markings & racing track assets...")
	var root = Node3D.new()
	root.name = "RoadMarkings"
	
	# Materials
	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.96, 0.96, 0.98, 0.96)
	mat_white.roughness = 0.55
	
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.96, 0.78, 0.12, 0.92)
	mat_yellow.roughness = 0.55
	
	var mat_red_kerb = StandardMaterial3D.new()
	mat_red_kerb.albedo_color = Color(0.86, 0.14, 0.16, 1.0)
	mat_red_kerb.roughness = 0.6
	
	var mat_white_kerb = StandardMaterial3D.new()
	mat_white_kerb.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	mat_white_kerb.roughness = 0.6
	
	var mat_skid = StandardMaterial3D.new()
	mat_skid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_skid.albedo_color = Color(0.04, 0.04, 0.05, 0.55)
	mat_skid.roughness = 0.95
	
	var mat_sun = StandardMaterial3D.new()
	mat_sun.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_sun.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_sun.albedo_color = Color(1.0, 0.6, 0.28, 0.38)
	
	# 1. Sun Reflection Streak
	var sun_streak = MeshInstance3D.new()
	sun_streak.name = "SunReflectionStreak"
	var sm = QuadMesh.new()
	sm.size = Vector2(16, 45)
	sm.orientation = PlaneMesh.FACE_Y
	sun_streak.mesh = sm
	sun_streak.material_override = mat_sun
	sun_streak.position = Vector3(-4.5, 0.005, 12)
	root.add_child(sun_streak)
	sun_streak.owner = root
	
	# 2. White Center Dashed Lane Markings (from Z = -25 to Z = +55)
	var center_dashes = Node3D.new()
	center_dashes.name = "CenterDashedLines"
	root.add_child(center_dashes)
	center_dashes.owner = root
	
	var dash_mesh = BoxMesh.new()
	dash_mesh.size = Vector3(0.26, 0.006, 3.8) # 26cm wide, 3.8m long
	
	var z_pos = -25.0
	var dash_idx = 0
	while z_pos <= 55.0:
		var d = MeshInstance3D.new()
		d.name = "Dash_" + str(dash_idx)
		d.mesh = dash_mesh
		d.material_override = mat_white
		d.position = Vector3(0.0, 0.006, z_pos)
		center_dashes.add_child(d)
		d.owner = root
		z_pos += 8.0 # 3.8m stripe + 4.2m gap
		dash_idx += 1
		
	# 3. Solid White Lane Boundaries (Left: -6.8m, Right: +6.8m)
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.28, 0.007, 85.0)
	
	var left_white = MeshInstance3D.new()
	left_white.name = "LeftWhiteBorder"
	left_white.mesh = b_mesh
	left_white.material_override = mat_white
	left_white.position = Vector3(-6.8, 0.007, 15.0)
	root.add_child(left_white)
	left_white.owner = root
	
	var right_white = MeshInstance3D.new()
	right_white.name = "RightWhiteBorder"
	right_white.mesh = b_mesh
	right_white.material_override = mat_white
	right_white.position = Vector3(6.8, 0.007, 15.0)
	root.add_child(right_white)
	right_white.owner = root
	
	# 4. Yellow Safety Shoulder Lines (Left: -7.25m, Right: +7.25m)
	var y_mesh = BoxMesh.new()
	y_mesh.size = Vector3(0.22, 0.008, 85.0)
	
	var left_yellow = MeshInstance3D.new()
	left_yellow.name = "LeftYellowLine"
	left_yellow.mesh = y_mesh
	left_yellow.material_override = mat_yellow
	left_yellow.position = Vector3(-7.25, 0.008, 15.0)
	root.add_child(left_yellow)
	left_yellow.owner = root
	
	var right_yellow = MeshInstance3D.new()
	right_yellow.name = "RightYellowLine"
	right_yellow.mesh = y_mesh
	right_yellow.material_override = mat_yellow
	right_yellow.position = Vector3(7.25, 0.008, 15.0)
	root.add_child(right_yellow)
	right_yellow.owner = root
	
	# 5. Starting Grid Staging Boxes (Pole 1 & Pole 2)
	var grid_node = Node3D.new()
	grid_node.name = "StartingGridBoxes"
	root.add_child(grid_node)
	grid_node.owner = root
	
	# Slot 1: Driver Right (X = 3.2m, Z = 4.0m)
	var slot1_front = MeshInstance3D.new()
	slot1_front.name = "Slot1_Front"
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(2.6, 0.008, 0.35)
	slot1_front.mesh = s_mesh
	slot1_front.material_override = mat_white
	slot1_front.position = Vector3(3.2, 0.008, 1.5)
	grid_node.add_child(slot1_front)
	slot1_front.owner = root
	
	var slot1_side = MeshInstance3D.new()
	slot1_side.name = "Slot1_Side"
	var ss_mesh = BoxMesh.new()
	ss_mesh.size = Vector3(0.18, 0.008, 5.0)
	slot1_side.mesh = ss_mesh
	slot1_side.material_override = mat_white
	slot1_side.position = Vector3(4.5, 0.008, 4.0)
	grid_node.add_child(slot1_side)
	slot1_side.owner = root
	
	# Slot 2: Driver Left (X = -3.2m, Z = 12.0m)
	var slot2_front = MeshInstance3D.new()
	slot2_front.name = "Slot2_Front"
	slot2_front.mesh = s_mesh
	slot2_front.material_override = mat_white
	slot2_front.position = Vector3(-3.2, 0.008, 9.5)
	grid_node.add_child(slot2_front)
	slot2_front.owner = root
	
	var slot2_side = MeshInstance3D.new()
	slot2_side.name = "Slot2_Side"
	slot2_side.mesh = ss_mesh
	slot2_side.material_override = mat_white
	slot2_side.position = Vector3(-4.5, 0.008, 12.0)
	grid_node.add_child(slot2_side)
	slot2_side.owner = root
	
	# 6. Apex Kerbs (Red & White alternating rumble strips along right barrier line)
	var kerb_node = Node3D.new()
	kerb_node.name = "ApexKerbs"
	root.add_child(kerb_node)
	kerb_node.owner = root
	
	var k_mesh = BoxMesh.new()
	k_mesh.size = Vector3(0.8, 0.04, 1.2)
	
	for i in range(16):
		var k = MeshInstance3D.new()
		k.name = "Kerb_" + str(i)
		k.mesh = k_mesh
		k.material_override = mat_red_kerb if (i % 2 == 0) else mat_white_kerb
		k.position = Vector3(7.85, 0.02, float(i) * 1.2 - 2.0)
		k.rotation_degrees = Vector3(0, 0, 8.0) # slightly beveled
		kerb_node.add_child(k)
		k.owner = root
		
	# 7. Heavy Braking Tire Skidmarks
	var skid_node = Node3D.new()
	skid_node.name = "TireSkidmarks"
	root.add_child(skid_node)
	skid_node.owner = root
	
	var skid_mesh = BoxMesh.new()
	skid_mesh.size = Vector3(0.35, 0.004, 18.0)
	
	var left_skid = MeshInstance3D.new()
	left_skid.name = "LeftTireSkid"
	left_skid.mesh = skid_mesh
	left_skid.material_override = mat_skid
	left_skid.position = Vector3(-1.4, 0.004, 8.0)
	skid_node.add_child(left_skid)
	left_skid.owner = root
	
	var right_skid = MeshInstance3D.new()
	right_skid.name = "RightTireSkid"
	right_skid.mesh = skid_mesh
	right_skid.material_override = mat_skid
	right_skid.position = Vector3(1.4, 0.004, 8.0)
	skid_node.add_child(right_skid)
	right_skid.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/environments/road/env_road_markings_01.tscn")
	print("env_road_markings_01.tscn built successfully with full road assets!")
	quit(0)

