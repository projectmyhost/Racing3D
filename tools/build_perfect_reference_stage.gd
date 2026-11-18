@tool
extends SceneTree

func _init():
	print("Building 1:1 photorealistic reference showcase stage with billboard face flip & tower alignment...")
	var stage = Node3D.new()
	stage.name = "ShowcaseStage"
	
	# Load Materials
	var mat_asphalt = load("res://assets/materials/environments/mat_ref_asphalt_wet.tres")
	var mat_bb = load("res://assets/materials/environments/mat_ref_billboard_art.tres")
	var mat_b_left = load("res://assets/materials/environments/mat_ref_building_left.tres")
	var mat_b_right = load("res://assets/materials/environments/mat_ref_building_right.tres")
	var mat_grate = load("res://assets/materials/environments/mat_ref_drainage_grate.tres")
	var mat_banner = load("res://assets/materials/environments/mat_ref_racing_banner.tres")
	var mat_palm_leaf = load("res://assets/materials/environments/mat_ref_palm_leaf.tres")
	var mat_metal = load("res://assets/materials/environments/mat_env_metal_rail.tres")
	var mat_concrete = load("res://assets/materials/environments/mat_env_concrete_01.tres")
	var mat_palm_trunk = load("res://assets/materials/environments/mat_env_palm_trunk.tres")
	
	# Tune asphalt material
	if mat_asphalt:
		mat_asphalt.albedo_color = Color(0.075, 0.075, 0.085, 1.0) # Deep rich dark asphalt
		mat_asphalt.clearcoat_enabled = true
		mat_asphalt.clearcoat = 0.28
		mat_asphalt.clearcoat_roughness = 0.10
		mat_asphalt.uv1_scale = Vector3(16, 16, 16)
		ResourceSaver.save(mat_asphalt, "res://assets/materials/environments/mat_ref_asphalt_wet.tres")
		
	# Tune building materials
	if mat_b_left:
		mat_b_left.emission_energy_multiplier = 0.85
		ResourceSaver.save(mat_b_left, "res://assets/materials/environments/mat_ref_building_left.tres")
	if mat_b_right:
		mat_b_right.emission_energy_multiplier = 0.85
		ResourceSaver.save(mat_b_right, "res://assets/materials/environments/mat_ref_building_right.tres")
	
	# =========================================================================
	# 1. WET ASPHALT GROUND (80m x 80m)
	# =========================================================================
	var road = MeshInstance3D.new()
	road.name = "WetAsphaltRoad"
	var road_mesh = PlaneMesh.new()
	road_mesh.size = Vector2(80, 80)
	road.mesh = road_mesh
	road.material_override = mat_asphalt
	road.position = Vector3(0, -0.01, 10)
	stage.add_child(road)
	road.owner = stage
	
	# =========================================================================
	# 2. ROAD DETAILS: WHITE LANE STRIPES & DRAINAGE GRATE
	# =========================================================================
	var markings_root = Node3D.new()
	markings_root.name = "Markings"
	stage.add_child(markings_root)
	markings_root.owner = stage
	
	# Crisp white lane stripe running along road, beside the car's left rear tire
	var mat_white_line = StandardMaterial3D.new()
	mat_white_line.albedo_color = Color(0.95, 0.95, 0.96, 0.95)
	mat_white_line.roughness = 0.40
	
	var main_line = MeshInstance3D.new()
	main_line.name = "MainWhiteLaneLine"
	var ml_mesh = BoxMesh.new()
	ml_mesh.size = Vector3(0.24, 0.005, 60.0)
	main_line.mesh = ml_mesh
	main_line.material_override = mat_white_line
	main_line.position = Vector3(-0.45, 0.004, 10.0)
	main_line.rotation_degrees = Vector3(0, 14.0, 0)
	markings_root.add_child(main_line)
	main_line.owner = stage
	
	# Linear Metal Slot Drainage Grate on the right edge of road (X = 4.6)
	var drain = MeshInstance3D.new()
	drain.name = "LinearSlotDrain"
	var dg_mesh = BoxMesh.new()
	dg_mesh.size = Vector3(0.38, 0.006, 60.0)
	drain.mesh = dg_mesh
	drain.material_override = mat_grate
	drain.position = Vector3(4.6, 0.005, 10.0)
	drain.rotation_degrees = Vector3(0, 14.0, 0)
	markings_root.add_child(drain)
	drain.owner = stage
	
	# Right Raised Sidewalk & Curb (from X = 4.9 to X = 25.0)
	var curb_root = Node3D.new()
	curb_root.name = "RightSidewalkCurb"
	curb_root.position = Vector3(4.9, 0, 10.0)
	curb_root.rotation_degrees = Vector3(0, 14.0, 0)
	stage.add_child(curb_root)
	curb_root.owner = stage
	
	var curb_mesh = BoxMesh.new()
	curb_mesh.size = Vector3(0.25, 0.15, 60.0)
	var curb_inst = MeshInstance3D.new()
	curb_inst.name = "CurbEdge"
	curb_inst.mesh = curb_mesh
	curb_inst.material_override = mat_concrete
	curb_inst.position = Vector3(0.12, 0.075, 0)
	curb_root.add_child(curb_inst)
	curb_inst.owner = stage
	
	var sw_mesh = BoxMesh.new()
	sw_mesh.size = Vector3(16.0, 0.14, 60.0)
	var sw_inst = MeshInstance3D.new()
	sw_inst.name = "SidewalkPavement"
	sw_inst.mesh = sw_mesh
	sw_inst.material_override = mat_concrete
	sw_inst.position = Vector3(8.25, 0.07, 0)
	curb_root.add_child(sw_inst)
	sw_inst.owner = stage

	# =========================================================================
	# 3. DUAL-PILLAR MOTORSPORT BILLBOARD (Matching Reference Image Perfectly)
	# =========================================================================
	# Positioned directly behind the car, face oriented toward camera (Y rot = 180 - 14 = 166 deg)
	var bb_root = Node3D.new()
	bb_root.name = "Billboard"
	bb_root.position = Vector3(1.6, 0, 8.8)
	bb_root.rotation_degrees = Vector3(0, -14.0, 0)
	stage.add_child(bb_root)
	bb_root.owner = stage
	
	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.26
	pole_mesh.bottom_radius = 0.30
	pole_mesh.height = 7.5
	
	# Left Pillar (to the left of the car)
	var pole_l = MeshInstance3D.new()
	pole_l.name = "PoleLeft"
	pole_l.mesh = pole_mesh
	pole_l.material_override = mat_metal
	pole_l.position = Vector3(-3.2, 3.75, 0)
	bb_root.add_child(pole_l)
	pole_l.owner = stage
	
	# Right Pillar (to the right of the car)
	var pole_r = MeshInstance3D.new()
	pole_r.name = "PoleRight"
	pole_r.mesh = pole_mesh
	pole_r.material_override = mat_metal
	pole_r.position = Vector3(3.2, 3.75, 0)
	bb_root.add_child(pole_r)
	pole_r.owner = stage
	
	# Billboard Face: Rotated 180° around Y so artwork faces toward camera!
	var bb_face = MeshInstance3D.new()
	bb_face.name = "BillboardFace"
	var face_mesh = QuadMesh.new()
	face_mesh.size = Vector2(9.2, 4.4)
	bb_face.mesh = face_mesh
	bb_face.material_override = mat_bb
	bb_face.position = Vector3(0, 5.5, -0.12)
	bb_face.rotation_degrees = Vector3(0, 180.0, 0) # Flip to face camera
	bb_root.add_child(bb_face)
	bb_face.owner = stage
	
	# Frame Backing (behind the face)
	var bb_frame = MeshInstance3D.new()
	bb_frame.name = "FrameBacking"
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(9.5, 4.6, 0.25)
	bb_frame.mesh = frame_mesh
	bb_frame.material_override = mat_metal
	bb_frame.position = Vector3(0, 5.5, 0.05)
	bb_root.add_child(bb_frame)
	bb_frame.owner = stage
	
	# Catwalk at bottom of billboard
	var catwalk = MeshInstance3D.new()
	catwalk.name = "Catwalk"
	var cw_mesh = BoxMesh.new()
	cw_mesh.size = Vector3(9.8, 0.12, 0.75)
	catwalk.mesh = cw_mesh
	catwalk.material_override = mat_metal
	catwalk.position = Vector3(0, 3.25, -0.35)
	bb_root.add_child(catwalk)
	catwalk.owner = stage

	# =========================================================================
	# 4. LEFT CORPORATE / PIT HEADQUARTERS (Warm Ribbon Windows)
	# =========================================================================
	var b_left_root = Node3D.new()
	b_left_root.name = "RoadsidePitShowroom"
	b_left_root.position = Vector3(-10.2, 0, 8.8)
	b_left_root.rotation_degrees = Vector3(0, 15.0, 0)
	stage.add_child(b_left_root)
	b_left_root.owner = stage
	
	var bl_mesh = BoxMesh.new()
	bl_mesh.size = Vector3(16.0, 13.0, 20.0)
	var bl_body = MeshInstance3D.new()
	bl_body.name = "BuildingMass"
	bl_body.mesh = bl_mesh
	bl_body.material_override = mat_b_left
	bl_body.position = Vector3(-6.0, 6.5, 6.0)
	b_left_root.add_child(bl_body)
	bl_body.owner = stage
	
	var pl_mesh = BoxMesh.new()
	pl_mesh.size = Vector3(16.0, 0.65, 1.6)
	var planter = MeshInstance3D.new()
	planter.name = "PlanterBox"
	planter.mesh = pl_mesh
	planter.material_override = mat_concrete
	planter.position = Vector3(-6.0, 0.32, -4.2)
	b_left_root.add_child(planter)
	planter.owner = stage

	# =========================================================================
	# 5. RIGHT LUXURY COMMERCIAL TOWER & MOTORSPORT BANNER
	# =========================================================================
	# Positioned right behind the right pillar, filling the right background!
	var b_right_root = Node3D.new()
	b_right_root.name = "RoadsideRaceTower"
	b_right_root.position = Vector3(8.5, 0, 10.5)
	b_right_root.rotation_degrees = Vector3(0, -18.0, 0)
	stage.add_child(b_right_root)
	b_right_root.owner = stage
	
	var br_mesh = BoxMesh.new()
	br_mesh.size = Vector3(20.0, 36.0, 18.0)
	var br_body = MeshInstance3D.new()
	br_body.name = "TowerMass"
	br_body.mesh = br_mesh
	br_body.material_override = mat_b_right
	br_body.position = Vector3(8.0, 18.0, 4.0)
	b_right_root.add_child(br_body)
	br_body.owner = stage
	
	# Streetlamp Post at right sidewalk edge (X = 5.4, Z = 5.2)
	var lamp_post = Node3D.new()
	lamp_post.name = "RightStreetlamp"
	lamp_post.position = Vector3(5.4, 0, 5.2)
	lamp_post.rotation_degrees = Vector3(0, 14.0, 0)
	stage.add_child(lamp_post)
	lamp_post.owner = stage
	
	var pole_inst = MeshInstance3D.new()
	pole_inst.name = "LampPole"
	var p_mesh = CylinderMesh.new()
	p_mesh.top_radius = 0.07
	p_mesh.bottom_radius = 0.11
	p_mesh.height = 6.8
	pole_inst.mesh = p_mesh
	pole_inst.material_override = mat_metal
	pole_inst.position = Vector3(0, 3.4, 0)
	lamp_post.add_child(pole_inst)
	pole_inst.owner = stage
	
	var lamp_head = MeshInstance3D.new()
	lamp_head.name = "LampFixture"
	var lh_mesh = SphereMesh.new()
	lh_mesh.radius = 0.25
	lh_mesh.height = 0.50
	lamp_head.mesh = lh_mesh
	var mat_bulb = StandardMaterial3D.new()
	mat_bulb.albedo_color = Color(1.0, 0.92, 0.70, 1.0)
	mat_bulb.emission_enabled = true
	mat_bulb.emission = Color(1.0, 0.90, 0.65, 1.0)
	mat_bulb.emission_energy_multiplier = 2.8
	lamp_head.material_override = mat_bulb
	lamp_head.position = Vector3(-0.30, 6.5, 0)
	lamp_post.add_child(lamp_head)
	lamp_head.owner = stage
	
	var street_light = OmniLight3D.new()
	street_light.name = "StreetLightOmni"
	street_light.light_color = Color(1.0, 0.88, 0.65, 1.0)
	street_light.light_energy = 2.2
	street_light.omni_range = 9.0
	street_light.position = Vector3(-0.30, 6.3, 0)
	lamp_post.add_child(street_light)
	street_light.owner = stage
	
	# Red Vertical Motorsport Banner ("R" logo)
	var banner = MeshInstance3D.new()
	banner.name = "MotorsportBanner"
	var bn_mesh = QuadMesh.new()
	bn_mesh.size = Vector2(0.85, 2.6)
	banner.mesh = bn_mesh
	banner.material_override = mat_banner
	banner.position = Vector3(0.50, 4.4, 0)
	banner.rotation_degrees = Vector3(0, 90.0, 0)
	lamp_post.add_child(banner)
	banner.owner = stage

	# =========================================================================
	# 6. PALM TREE (Gracefully framing sunset sky between HQ and Billboard)
	# =========================================================================
	var palm_root = Node3D.new()
	palm_root.name = "HeroPalmTree"
	palm_root.position = Vector3(-3.2, 0, 8.2)
	stage.add_child(palm_root)
	palm_root.owner = stage
	
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.15
	t_mesh.bottom_radius = 0.26
	t_mesh.height = 6.8
	trunk.mesh = t_mesh
	trunk.material_override = mat_palm_trunk
	trunk.position = Vector3(0, 3.4, 0)
	trunk.rotation_degrees = Vector3(0, 0, -3.5)
	palm_root.add_child(trunk)
	trunk.owner = stage
	
	var crown = Node3D.new()
	crown.name = "FrondsCrown"
	crown.position = Vector3(0.2, 6.7, 0)
	palm_root.add_child(crown)
	crown.owner = stage
	
	var frond_mesh = QuadMesh.new()
	frond_mesh.size = Vector2(1.5, 3.4)
	for i in range(8):
		var ang = float(i) * 45.0
		var frond = MeshInstance3D.new()
		frond.name = "Frond_" + str(i)
		frond.mesh = frond_mesh
		frond.material_override = mat_palm_leaf
		frond.rotation_degrees = Vector3(-32.0, ang, 0)
		frond.position = Vector3(0, -0.15, 0)
		crown.add_child(frond)
		frond.owner = stage

	# =========================================================================
	# 7. CAR REAR RED RAIN-LIGHT SPECULAR REFLECTION (1:1 with Reference!)
	# =========================================================================
	var rain_reflection = OmniLight3D.new()
	rain_reflection.name = "RainLightGroundReflection"
	rain_reflection.light_color = Color(1.0, 0.05, 0.08, 1.0)
	rain_reflection.light_energy = 3.6
	rain_reflection.omni_range = 4.2
	rain_reflection.omni_attenuation = 1.2
	rain_reflection.position = Vector3(1.35, 0.20, 0.65)
	stage.add_child(rain_reflection)
	rain_reflection.owner = stage

	# =========================================================================
	# 8. REFLECTION PROBES (Inexpensive Static PBR IBL)
	# =========================================================================
	var probe_car = ReflectionProbe.new()
	probe_car.name = "ReflectionProbe_Car"
	probe_car.size = Vector3(14, 5, 14)
	probe_car.position = Vector3(0.55, 1.5, 0.25)
	probe_car.box_projection = true
	probe_car.intensity = 0.85
	probe_car.update_mode = ReflectionProbe.UPDATE_ONCE
	stage.add_child(probe_car)
	probe_car.owner = stage
	
	var probe_road = ReflectionProbe.new()
	probe_road.name = "ReflectionProbe_Road"
	probe_road.size = Vector3(30, 5, 30)
	probe_road.position = Vector3(0, 1.0, 8.0)
	probe_road.box_projection = true
	probe_road.intensity = 0.80
	probe_road.update_mode = ReflectionProbe.UPDATE_ONCE
	stage.add_child(probe_road)
	probe_road.owner = stage
	
	var scene = PackedScene.new()
	scene.pack(stage)
	ResourceSaver.save(scene, "res://scenes/environment/showcase_stage.tscn")
	print("showcase_stage.tscn rebuilt cleanly!")
	quit(0)
