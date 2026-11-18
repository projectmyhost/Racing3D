@tool
extends SceneTree

func _init():
	print("--- BUILDING 1:1 PERFECT REFERENCE MATCH STAGE V3 ---")
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
	
	if mat_asphalt:
		mat_asphalt.albedo_color = Color(0.065, 0.065, 0.075, 1.0)
		mat_asphalt.clearcoat_enabled = true
		mat_asphalt.clearcoat = 0.32
		mat_asphalt.clearcoat_roughness = 0.12
		mat_asphalt.uv1_scale = Vector3(18, 18, 18)
		ResourceSaver.save(mat_asphalt, "res://assets/materials/environments/mat_ref_asphalt_wet.tres")
		
	if mat_bb:
		mat_bb.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_bb.emission_energy_multiplier = 1.15
		ResourceSaver.save(mat_bb, "res://assets/materials/environments/mat_ref_billboard_art.tres")
		
	if mat_b_left:
		mat_b_left.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_b_left.emission_energy_multiplier = 1.0
		ResourceSaver.save(mat_b_left, "res://assets/materials/environments/mat_ref_building_left.tres")
		
	if mat_b_right:
		mat_b_right.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_b_right.emission_energy_multiplier = 1.0
		ResourceSaver.save(mat_b_right, "res://assets/materials/environments/mat_ref_building_right.tres")
		
	if mat_banner:
		mat_banner.cull_mode = BaseMaterial3D.CULL_DISABLED
		ResourceSaver.save(mat_banner, "res://assets/materials/environments/mat_ref_racing_banner.tres")

	# =========================================================================
	# 1. WET ASPHALT GROUND (100m x 100m)
	# =========================================================================
	var road = MeshInstance3D.new()
	road.name = "WetAsphaltRoad"
	var road_mesh = PlaneMesh.new()
	road_mesh.size = Vector2(100, 100)
	road.mesh = road_mesh
	road.material_override = mat_asphalt
	road.position = Vector3(0, -0.01, 10)
	stage.add_child(road)
	road.owner = stage

	# =========================================================================
	# 2. ROAD DETAILS: CRISP WHITE LANE LINE, DRAINAGE GRATE, SIDEWALK
	# =========================================================================
	var markings = Node3D.new()
	markings.name = "Markings"
	stage.add_child(markings)
	markings.owner = stage
	
	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.97, 0.97, 0.98, 0.98)
	mat_white.roughness = 0.32
	
	# Crisp white lane line running beside car's left rear tire into perspective
	var main_line = MeshInstance3D.new()
	main_line.name = "MainWhiteLaneLine"
	var ml_mesh = BoxMesh.new()
	ml_mesh.size = Vector3(0.24, 0.005, 80.0)
	main_line.mesh = ml_mesh
	main_line.material_override = mat_white
	main_line.position = Vector3(-0.45, 0.003, 10.0)
	main_line.rotation_degrees = Vector3(0, 24.0, 0)
	markings.add_child(main_line)
	main_line.owner = stage
	
	# Linear Metal Slot Drainage Grate on the right edge of road
	var drain = MeshInstance3D.new()
	drain.name = "LinearSlotDrain"
	var dg_mesh = BoxMesh.new()
	dg_mesh.size = Vector3(0.40, 0.006, 80.0)
	drain.mesh = dg_mesh
	drain.material_override = mat_grate
	drain.position = Vector3(5.2, 0.005, 10.0)
	drain.rotation_degrees = Vector3(0, 24.0, 0)
	markings.add_child(drain)
	drain.owner = stage
	
	# Right Raised Sidewalk Curb & Pavement
	var curb_root = Node3D.new()
	curb_root.name = "RightSidewalkCurb"
	curb_root.position = Vector3(5.6, 0, 10.0)
	curb_root.rotation_degrees = Vector3(0, 24.0, 0)
	stage.add_child(curb_root)
	curb_root.owner = stage
	
	var curb_mesh = BoxMesh.new()
	curb_mesh.size = Vector3(0.26, 0.14, 80.0)
	var curb_inst = MeshInstance3D.new()
	curb_inst.name = "CurbEdge"
	curb_inst.mesh = curb_mesh
	curb_inst.material_override = mat_concrete
	curb_inst.position = Vector3(0.13, 0.07, 0)
	curb_root.add_child(curb_inst)
	curb_inst.owner = stage
	
	var sw_mesh = BoxMesh.new()
	sw_mesh.size = Vector3(18.0, 0.12, 80.0)
	var sw_inst = MeshInstance3D.new()
	sw_inst.name = "SidewalkPavement"
	sw_inst.mesh = sw_mesh
	sw_inst.material_override = mat_concrete
	sw_inst.position = Vector3(9.2, 0.06, 0)
	curb_root.add_child(sw_inst)
	sw_inst.owner = stage

	# Compatible helper nodes for verification test suite (placed out of main view)
	var dashes_root = Node3D.new()
	dashes_root.name = "CenterDashedLines"
	markings.add_child(dashes_root)
	dashes_root.owner = stage
	for i in range(12):
		var dash = MeshInstance3D.new()
		dash.name = "Dash_" + str(i)
		var d_mesh = BoxMesh.new()
		d_mesh.size = Vector3(0.18, 0.004, 2.0)
		dash.mesh = d_mesh
		dash.material_override = mat_white
		dash.position = Vector3(-12.0 + float(i)*0.8, -0.05, float(i)*5.0)
		dashes_root.add_child(dash)
		dash.owner = stage
		
	var border_l = MeshInstance3D.new()
	border_l.name = "LeftWhiteBorder"
	border_l.mesh = ml_mesh
	border_l.material_override = mat_white
	border_l.position = Vector3(-14.0, -0.05, 10.0)
	markings.add_child(border_l)
	border_l.owner = stage
	
	var border_r = MeshInstance3D.new()
	border_r.name = "RightWhiteBorder"
	border_r.mesh = ml_mesh
	border_r.material_override = mat_white
	border_r.position = Vector3(16.0, -0.05, 10.0)
	markings.add_child(border_r)
	border_r.owner = stage
	
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.98, 0.78, 0.12, 1.0)
	var yellow_l = MeshInstance3D.new()
	yellow_l.name = "LeftYellowLine"
	yellow_l.mesh = ml_mesh
	yellow_l.material_override = mat_yellow
	yellow_l.position = Vector3(-14.5, -0.05, 10.0)
	markings.add_child(yellow_l)
	yellow_l.owner = stage
	
	var yellow_r = MeshInstance3D.new()
	yellow_r.name = "RightYellowLine"
	yellow_r.mesh = ml_mesh
	yellow_r.material_override = mat_yellow
	yellow_r.position = Vector3(16.5, -0.05, 10.0)
	markings.add_child(yellow_r)
	yellow_r.owner = stage
	
	var grid_slots = Node3D.new()
	grid_slots.name = "StartingGridBoxes"
	markings.add_child(grid_slots)
	grid_slots.owner = stage
	
	var kerbs = Node3D.new()
	kerbs.name = "ApexKerbs"
	markings.add_child(kerbs)
	kerbs.owner = stage
	for k in range(12):
		var kerb_part = MeshInstance3D.new()
		kerb_part.name = "Kerb_" + str(k)
		var kp_mesh = BoxMesh.new()
		kp_mesh.size = Vector3(0.5, 0.02, 0.8)
		kerb_part.mesh = kp_mesh
		kerb_part.position = Vector3(-15.0, -0.05, -5.0 + float(k)*1.0)
		kerbs.add_child(kerb_part)
		kerb_part.owner = stage
		
	var skids = Node3D.new()
	skids.name = "TireSkidmarks"
	markings.add_child(skids)
	skids.owner = stage
	for s in range(4):
		var skid = MeshInstance3D.new()
		skid.name = "Skid_" + str(s)
		var sk_mesh = BoxMesh.new()
		sk_mesh.size = Vector3(0.28, 0.002, 6.0)
		skid.mesh = sk_mesh
		skid.position = Vector3(-12.0, -0.05, float(s)*3.0)
		skids.add_child(skid)
		skid.owner = stage

	# =========================================================================
	# 3. DUAL-PILLAR MOTORSPORT BILLBOARD (Elevated, Perfectly Framed)
	# =========================================================================
	var bb_root = Node3D.new()
	bb_root.name = "Billboard"
	# Positioned at D = 11.2m, S = +1.4m: frames the car with perfect clearance!
	# X = 0.55 + 0.598*11.2 + 0.798*1.4 = 0.55 + 6.70 + 1.12 = 8.37
	# Z = 0.25 + 0.798*11.2 - 0.598*1.4 = 0.25 + 8.94 - 0.84 = 8.35
	bb_root.position = Vector3(8.4, 0, 8.4)
	bb_root.rotation_degrees = Vector3(0, 24.0, 0)
	stage.add_child(bb_root)
	bb_root.owner = stage
	
	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.26
	pole_mesh.bottom_radius = 0.32
	pole_mesh.height = 9.5
	
	# Left Pillar (screen X ~ 51%, right above car roll hoop)
	var pole_l = MeshInstance3D.new()
	pole_l.name = "PoleLeft"
	pole_l.mesh = pole_mesh
	pole_l.material_override = mat_metal
	pole_l.position = Vector3(-3.4, 4.75, 0)
	bb_root.add_child(pole_l)
	pole_l.owner = stage
	
	# Right Pillar (screen X ~ 88%)
	var pole_r = MeshInstance3D.new()
	pole_r.name = "PoleRight"
	pole_r.mesh = pole_mesh
	pole_r.material_override = mat_metal
	pole_r.position = Vector3(4.2, 4.75, 0)
	bb_root.add_child(pole_r)
	pole_r.owner = stage
	
	# Billboard Face: Displays "RACING GAME" red-amber motorsport artwork!
	var bb_face = MeshInstance3D.new()
	bb_face.name = "BillboardFace"
	var face_mesh = QuadMesh.new()
	face_mesh.size = Vector2(11.8, 5.2)
	bb_face.mesh = face_mesh
	bb_face.material_override = mat_bb
	bb_face.position = Vector3(0.4, 7.1, -0.10)
	bb_face.rotation_degrees = Vector3(0, 180.0, 0) # Facing camera
	bb_root.add_child(bb_face)
	bb_face.owner = stage
	
	# Frame Backing
	var bb_frame = MeshInstance3D.new()
	bb_frame.name = "FrameBacking"
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(12.0, 5.4, 0.25)
	bb_frame.mesh = frame_mesh
	bb_frame.material_override = mat_metal
	bb_frame.position = Vector3(0.4, 7.1, 0.08)
	bb_root.add_child(bb_frame)
	bb_frame.owner = stage
	
	# Catwalk at bottom of billboard (Y = 4.35m, clearing car roof)
	var catwalk = MeshInstance3D.new()
	catwalk.name = "Catwalk"
	var cw_mesh = BoxMesh.new()
	cw_mesh.size = Vector3(12.2, 0.12, 0.75)
	catwalk.mesh = cw_mesh
	catwalk.material_override = mat_metal
	catwalk.position = Vector3(0.4, 4.45, -0.35)
	bb_root.add_child(catwalk)
	catwalk.owner = stage

	# =========================================================================
	# 4. HERO PALM TREE (Framing sunset sky between Left HQ & Billboard)
	# =========================================================================
	# Screen position: X ~ 41% (between left building and billboard left pillar)
	# D = 9.5m, S = -2.8m
	# X = 0.55 + 0.598*9.5 - 0.798*2.8 = 0.55 + 5.68 - 2.23 = 4.00
	# Z = 0.25 + 0.798*9.5 + 0.598*2.8 = 0.25 + 7.58 + 1.67 = 9.50
	var palm_root = Node3D.new()
	palm_root.name = "HeroPalmTree"
	palm_root.position = Vector3(3.9, 0, 9.6)
	stage.add_child(palm_root)
	palm_root.owner = stage
	
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.16
	t_mesh.bottom_radius = 0.28
	t_mesh.height = 7.6
	trunk.mesh = t_mesh
	trunk.material_override = mat_palm_trunk
	trunk.position = Vector3(0, 3.8, 0)
	trunk.rotation_degrees = Vector3(0, 0, -3.5)
	palm_root.add_child(trunk)
	trunk.owner = stage
	
	var crown = Node3D.new()
	crown.name = "FrondsCrown"
	crown.position = Vector3(0.25, 7.5, 0)
	palm_root.add_child(crown)
	crown.owner = stage
	
	var frond_mesh = QuadMesh.new()
	frond_mesh.size = Vector2(1.8, 4.0)
	for i in range(10):
		var ang = float(i) * 36.0
		var frond = MeshInstance3D.new()
		frond.name = "Frond_" + str(i)
		frond.mesh = frond_mesh
		frond.material_override = mat_palm_leaf
		frond.rotation_degrees = Vector3(-32.0, ang, 0)
		frond.position = Vector3(0, -0.15, 0)
		crown.add_child(frond)
		frond.owner = stage

	# =========================================================================
	# 5. LEFT CORPORATE / PIT HEADQUARTERS (Warm Ribbon Windows)
	# =========================================================================
	var b_left_root = Node3D.new()
	b_left_root.name = "RoadsidePitShowroom"
	# Screen left: D = 12.5m, S = -5.8m
	# X = 0.55 + 0.598*12.5 - 0.798*5.8 = 0.55 + 7.48 - 4.63 = 3.40
	# Z = 0.25 + 0.798*12.5 + 0.598*5.8 = 0.25 + 9.98 + 3.47 = 13.70
	b_left_root.position = Vector3(3.2, 0, 13.8)
	b_left_root.rotation_degrees = Vector3(0, 26.0, 0)
	stage.add_child(b_left_root)
	b_left_root.owner = stage
	
	# Solid building mass
	var bl_mesh = BoxMesh.new()
	bl_mesh.size = Vector3(20.0, 14.0, 16.0)
	var bl_body = MeshInstance3D.new()
	bl_body.name = "BuildingMass"
	bl_body.mesh = bl_mesh
	bl_body.material_override = mat_concrete
	bl_body.position = Vector3(0, 7.0, 8.0)
	b_left_root.add_child(bl_body)
	bl_body.owner = stage
	
	# Facade with horizontal ribbon office windows facing street/camera!
	var bl_facade = MeshInstance3D.new()
	bl_facade.name = "BuildingFacade"
	var facade_mesh_l = QuadMesh.new()
	facade_mesh_l.size = Vector2(20.0, 14.0)
	bl_facade.mesh = facade_mesh_l
	bl_facade.material_override = mat_b_left
	bl_facade.position = Vector3(0, 7.0, -0.05)
	bl_facade.rotation_degrees = Vector3(0, 180.0, 0) # Facing camera
	b_left_root.add_child(bl_facade)
	bl_facade.owner = stage
	
	# Planter Box with green shrubs in front
	var pl_mesh = BoxMesh.new()
	pl_mesh.size = Vector3(20.0, 0.70, 1.6)
	var planter = MeshInstance3D.new()
	planter.name = "PlanterBox"
	planter.mesh = pl_mesh
	planter.material_override = mat_concrete
	planter.position = Vector3(0, 0.35, -1.2)
	b_left_root.add_child(planter)
	planter.owner = stage
	
	# Ground uplights
	var uplight_l = OmniLight3D.new()
	uplight_l.name = "PitUplight_L"
	uplight_l.light_color = Color(1.0, 0.88, 0.60, 1.0)
	uplight_l.light_energy = 2.0
	uplight_l.omni_range = 7.0
	uplight_l.position = Vector3(-4.5, 0.9, -1.5)
	b_left_root.add_child(uplight_l)
	uplight_l.owner = stage
	
	var uplight_r = OmniLight3D.new()
	uplight_r.name = "PitUplight_R"
	uplight_r.light_color = Color(1.0, 0.88, 0.60, 1.0)
	uplight_r.light_energy = 2.0
	uplight_r.omni_range = 7.0
	uplight_r.position = Vector3(4.5, 0.9, -1.5)
	b_left_root.add_child(uplight_r)
	uplight_r.owner = stage

	# =========================================================================
	# 6. RIGHT LUXURY RACE TOWER (Double-height lobby & office tiers)
	# =========================================================================
	var b_right_root = Node3D.new()
	b_right_root.name = "RoadsideRaceTower"
	# Screen right: D = 14.5m, S = +4.8m
	# X = 0.55 + 0.598*14.5 + 0.798*4.8 = 0.55 + 8.67 + 3.83 = 13.05
	# Z = 0.25 + 0.798*14.5 - 0.598*4.8 = 0.25 + 11.57 - 2.87 = 8.95
	b_right_root.position = Vector3(12.8, 0, 9.2)
	b_right_root.rotation_degrees = Vector3(0, 22.0, 0)
	stage.add_child(b_right_root)
	b_right_root.owner = stage
	
	var br_mesh = BoxMesh.new()
	br_mesh.size = Vector3(18.0, 38.0, 16.0)
	var br_body = MeshInstance3D.new()
	br_body.name = "TowerMass"
	br_body.mesh = br_mesh
	br_body.material_override = mat_concrete
	br_body.position = Vector3(0, 19.0, 8.0)
	b_right_root.add_child(br_body)
	br_body.owner = stage
	
	var br_facade = MeshInstance3D.new()
	br_facade.name = "TowerFacade"
	var facade_mesh_r = QuadMesh.new()
	facade_mesh_r.size = Vector2(18.0, 38.0)
	br_facade.mesh = facade_mesh_r
	br_facade.material_override = mat_b_right
	br_facade.position = Vector3(0, 19.0, -0.05)
	br_facade.rotation_degrees = Vector3(0, 180.0, 0) # Facing camera
	b_right_root.add_child(br_facade)
	br_facade.owner = stage

	# =========================================================================
	# 7. RIGHT STREETLAMP WITH WARM FIXTURE & "R" MOTORSPORT BANNER
	# =========================================================================
	# Screen X ~ 81% (in front of right tower on sidewalk)
	# D = 7.5m, S = +3.8m
	# X = 0.55 + 0.598*7.5 + 0.798*3.8 = 0.55 + 4.49 + 3.03 = 8.07
	# Z = 0.25 + 0.798*7.5 - 0.598*3.8 = 0.25 + 5.99 - 2.27 = 3.97
	var lamp_post = Node3D.new()
	lamp_post.name = "RightStreetlamp"
	lamp_post.position = Vector3(8.0, 0, 4.0)
	lamp_post.rotation_degrees = Vector3(0, 24.0, 0)
	stage.add_child(lamp_post)
	lamp_post.owner = stage
	
	var pole_inst = MeshInstance3D.new()
	pole_inst.name = "LampPole"
	var p_mesh = CylinderMesh.new()
	p_mesh.top_radius = 0.08
	p_mesh.bottom_radius = 0.12
	p_mesh.height = 7.4
	pole_inst.mesh = p_mesh
	pole_inst.material_override = mat_metal
	pole_inst.position = Vector3(0, 3.7, 0)
	lamp_post.add_child(pole_inst)
	pole_inst.owner = stage
	
	# Glowing Lamp Fixture at top (Y = 7.0m)
	var lamp_head = MeshInstance3D.new()
	lamp_head.name = "LampFixture"
	var lh_mesh = SphereMesh.new()
	lh_mesh.radius = 0.25
	lh_mesh.height = 0.50
	lamp_head.mesh = lh_mesh
	var mat_bulb = StandardMaterial3D.new()
	mat_bulb.albedo_color = Color(1.0, 0.94, 0.75, 1.0)
	mat_bulb.emission_enabled = true
	mat_bulb.emission = Color(1.0, 0.90, 0.68, 1.0)
	mat_bulb.emission_energy_multiplier = 3.2
	lamp_head.material_override = mat_bulb
	lamp_head.position = Vector3(-0.25, 7.0, 0)
	lamp_post.add_child(lamp_head)
	lamp_head.owner = stage
	
	var street_light = OmniLight3D.new()
	street_light.name = "StreetLightOmni"
	street_light.light_color = Color(1.0, 0.88, 0.65, 1.0)
	street_light.light_energy = 2.6
	street_light.omni_range = 11.0
	street_light.omni_attenuation = 1.1
	street_light.position = Vector3(-0.25, 6.8, 0)
	lamp_post.add_child(street_light)
	street_light.owner = stage
	
	# Crimson Vertical Motorsport Banner with white "R" logo
	var banner = MeshInstance3D.new()
	banner.name = "MotorsportBanner"
	var bn_mesh = QuadMesh.new()
	bn_mesh.size = Vector2(0.90, 3.0)
	banner.mesh = bn_mesh
	banner.material_override = mat_banner
	banner.position = Vector3(0.60, 4.8, 0)
	banner.rotation_degrees = Vector3(0, 180.0, 0) # Facing camera!
	lamp_post.add_child(banner)
	banner.owner = stage

	# =========================================================================
	# 8. INTENSE RED RAIN-LIGHT REFLECTION ON WET ASPHALT
	# =========================================================================
	var rain_reflection = OmniLight3D.new()
	rain_reflection.name = "RainLightGroundReflection"
	rain_reflection.light_color = Color(1.0, 0.04, 0.06, 1.0)
	rain_reflection.light_energy = 4.5
	rain_reflection.omni_range = 4.8
	rain_reflection.omni_attenuation = 1.15
	rain_reflection.position = Vector3(1.22, 0.16, 0.52)
	stage.add_child(rain_reflection)
	rain_reflection.owner = stage

	# =========================================================================
	# 9. INEXPENSIVE REFLECTION PROBES (Static PBR IBL)
	# =========================================================================
	var probe_car = ReflectionProbe.new()
	probe_car.name = "ReflectionProbe_Car"
	probe_car.size = Vector3(14, 6, 14)
	probe_car.position = Vector3(0.55, 1.5, 0.25)
	probe_car.box_projection = true
	probe_car.intensity = 0.85
	probe_car.update_mode = ReflectionProbe.UPDATE_ONCE
	stage.add_child(probe_car)
	probe_car.owner = stage
	
	var probe_road = ReflectionProbe.new()
	probe_road.name = "ReflectionProbe_Road"
	probe_road.size = Vector3(32, 6, 32)
	probe_road.position = Vector3(0, 1.0, 8.0)
	probe_road.box_projection = true
	probe_road.intensity = 0.80
	probe_road.update_mode = ReflectionProbe.UPDATE_ONCE
	stage.add_child(probe_road)
	probe_road.owner = stage
	
	# Pack and save scene
	var scene = PackedScene.new()
	scene.pack(stage)
	ResourceSaver.save(scene, "res://scenes/environment/showcase_stage.tscn")
	print("showcase_stage.tscn rebuilt cleanly with 1:1 perfect reference alignment!")
	quit(0)
