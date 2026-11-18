@tool
extends SceneTree

func _init():
	print("Building reference-accurate showcase_stage.tscn...")
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
	
	# =========================================================================
	# 1. MAIN WET ASPHALT ROAD PLAZA (80m x 80m)
	# =========================================================================
	var road = MeshInstance3D.new()
	road.name = "WetAsphaltRoad"
	var road_mesh = PlaneMesh.new()
	road_mesh.size = Vector2(80, 80)
	road_mesh.subdivide_width = 8
	road_mesh.subdivide_depth = 8
	road.mesh = road_mesh
	road.material_override = mat_asphalt
	road.position = Vector3(0, -0.01, 15)
	stage.add_child(road)
	road.owner = stage
	
	# =========================================================================
	# 2. ROAD MARKINGS & LINEAR DRAINAGE GRATE
	# =========================================================================
	var markings_root = Node3D.new()
	markings_root.name = "Markings"
	stage.add_child(markings_root)
	markings_root.owner = stage
	
	# White Lane Line (passes directly by the car's left rear tire)
	var mat_white_line = StandardMaterial3D.new()
	mat_white_line.albedo_color = Color(0.96, 0.96, 0.98, 0.95)
	mat_white_line.roughness = 0.45
	
	var center_white = MeshInstance3D.new()
	center_white.name = "MainWhiteLaneLine"
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(0.24, 0.006, 70.0)
	center_white.mesh = c_mesh
	center_white.material_override = mat_white_line
	center_white.position = Vector3(-0.65, 0.005, 12.0)
	center_white.rotation_degrees = Vector3(0, 12.0, 0)
	markings_root.add_child(center_white)
	center_white.owner = stage
	
	# Foreground angled white staging line
	var fg_line = MeshInstance3D.new()
	fg_line.name = "ForegroundStagingLine"
	var fg_mesh = BoxMesh.new()
	fg_mesh.size = Vector3(0.22, 0.006, 35.0)
	fg_line.mesh = fg_mesh
	fg_line.material_override = mat_white_line
	fg_line.position = Vector3(-4.5, 0.005, -1.0)
	fg_line.rotation_degrees = Vector3(0, -42.0, 0)
	markings_root.add_child(fg_line)
	fg_line.owner = stage
	
	# Linear Metal Slot Drainage Grate along right edge of road (X = 6.2)
	var drain_grate = MeshInstance3D.new()
	drain_grate.name = "LinearSlotDrain"
	var dg_mesh = BoxMesh.new()
	dg_mesh.size = Vector3(0.45, 0.008, 65.0)
	drain_grate.mesh = dg_mesh
	drain_grate.material_override = mat_grate
	drain_grate.position = Vector3(6.2, 0.006, 15.0)
	markings_root.add_child(drain_grate)
	drain_grate.owner = stage
	
	# Raised Concrete Sidewalk on the Right (X = 6.5 to 25.0)
	var sidewalk = MeshInstance3D.new()
	sidewalk.name = "RightSidewalk"
	var sw_mesh = BoxMesh.new()
	sw_mesh.size = Vector3(18.0, 0.16, 65.0)
	sidewalk.mesh = sw_mesh
	sidewalk.material_override = mat_concrete
	sidewalk.position = Vector3(15.5, 0.08, 15.0)
	stage.add_child(sidewalk)
	sidewalk.owner = stage
	
	# Raised Sidewalk Curb Bevel
	var curb = MeshInstance3D.new()
	curb.name = "SidewalkCurb"
	var cb_mesh = BoxMesh.new()
	cb_mesh.size = Vector3(0.30, 0.18, 65.0)
	curb.mesh = cb_mesh
	curb.material_override = mat_concrete
	curb.position = Vector3(6.55, 0.09, 15.0)
	stage.add_child(curb)
	curb.owner = stage

	# =========================================================================
	# 3. DUAL-PILLAR MOTORSPORT BILLBOARD (Matching Reference Image)
	# =========================================================================
	var bb_root = Node3D.new()
	bb_root.name = "Billboard"
	bb_root.position = Vector3(3.2, 0, 11.8)
	bb_root.rotation_degrees = Vector3(0, -18.0, 0)
	stage.add_child(bb_root)
	bb_root.owner = stage
	
	var pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.28
	pole_mesh.bottom_radius = 0.32
	pole_mesh.height = 9.5
	
	# Left Pillar
	var pole_left = MeshInstance3D.new()
	pole_left.name = "PoleLeft"
	pole_left.mesh = pole_mesh
	pole_left.material_override = mat_metal
	pole_left.position = Vector3(-3.8, 4.75, 0)
	bb_root.add_child(pole_left)
	pole_left.owner = stage
	
	# Right Pillar
	var pole_right = MeshInstance3D.new()
	pole_right.name = "PoleRight"
	pole_right.mesh = pole_mesh
	pole_right.material_override = mat_metal
	pole_right.position = Vector3(3.8, 4.75, 0)
	bb_root.add_child(pole_right)
	pole_right.owner = stage
	
	# Billboard Face
	var bb_face = MeshInstance3D.new()
	bb_face.name = "BillboardFace"
	var face_mesh = QuadMesh.new()
	face_mesh.size = Vector2(10.5, 5.2)
	bb_face.mesh = face_mesh
	bb_face.material_override = mat_bb
	bb_face.position = Vector3(0, 8.2, 0.25)
	bb_root.add_child(bb_face)
	bb_face.owner = stage
	
	# Steel Backing Frame
	var bb_frame = MeshInstance3D.new()
	bb_frame.name = "FrameBacking"
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(10.8, 5.5, 0.35)
	bb_frame.mesh = frame_mesh
	bb_frame.material_override = mat_metal
	bb_frame.position = Vector3(0, 8.2, 0.05)
	bb_root.add_child(bb_frame)
	bb_frame.owner = stage
	
	# Catwalk under board
	var catwalk = MeshInstance3D.new()
	catwalk.name = "Catwalk"
	var cw_mesh = BoxMesh.new()
	cw_mesh.size = Vector3(11.2, 0.14, 0.9)
	catwalk.mesh = cw_mesh
	catwalk.material_override = mat_metal
	catwalk.position = Vector3(0, 5.4, 0.5)
	bb_root.add_child(catwalk)
	catwalk.owner = stage
	
	# Billboard Upward Spotlights
	var bb_light = OmniLight3D.new()
	bb_light.name = "BillboardFloodlight"
	bb_light.light_color = Color(1.0, 0.88, 0.70, 1.0)
	bb_light.light_energy = 2.4
	bb_light.omni_range = 8.0
	bb_light.position = Vector3(0, 5.8, 1.2)
	bb_root.add_child(bb_light)
	bb_light.owner = stage

	# =========================================================================
	# 4. LEFT PIT GARAGE & CORPORATE HEADQUARTERS BUILDING
	# =========================================================================
	var b_left = MeshInstance3D.new()
	b_left.name = "RoadsidePitShowroom"
	var bl_mesh = BoxMesh.new()
	bl_mesh.size = Vector3(22.0, 14.0, 24.0)
	b_left.mesh = bl_mesh
	b_left.material_override = mat_b_left
	b_left.position = Vector3(-17.0, 7.0, 16.0)
	b_left.rotation_degrees = Vector3(0, 16.0, 0)
	stage.add_child(b_left)
	b_left.owner = stage
	
	# Left Building Foundation Planter & Shrubbery
	var planter = MeshInstance3D.new()
	planter.name = "HQPlanterBox"
	var pl_mesh = BoxMesh.new()
	pl_mesh.size = Vector3(20.0, 0.75, 2.0)
	planter.mesh = pl_mesh
	planter.material_override = mat_concrete
	planter.position = Vector3(-15.5, 0.38, 5.5)
	planter.rotation_degrees = Vector3(0, 16.0, 0)
	stage.add_child(planter)
	planter.owner = stage
	
	# Ground Downlight illuminating left sidewalk
	var hq_downlight = OmniLight3D.new()
	hq_downlight.name = "HQGroundDownlight"
	hq_downlight.light_color = Color(1.0, 0.85, 0.60, 1.0)
	hq_downlight.light_energy = 2.0
	hq_downlight.omni_range = 9.0
	hq_downlight.position = Vector3(-11.5, 2.2, 7.0)
	stage.add_child(hq_downlight)
	hq_downlight.owner = stage

	# =========================================================================
	# 5. RIGHT LUXURY COMMERCIAL TOWER & MOTORSPORT BANNERS
	# =========================================================================
	var b_right = MeshInstance3D.new()
	b_right.name = "RoadsideRaceTower"
	var br_mesh = BoxMesh.new()
	br_mesh.size = Vector3(24.0, 38.0, 24.0)
	b_right.mesh = br_mesh
	b_right.material_override = mat_b_right
	b_right.position = Vector3(22.0, 19.0, 20.0)
	b_right.rotation_degrees = Vector3(0, -18.0, 0)
	stage.add_child(b_right)
	b_right.owner = stage
	
	# Right Streetlamp Post with Warm Luminaire
	var lamp_post = Node3D.new()
	lamp_post.name = "RightStreetlamp"
	lamp_post.position = Vector3(7.6, 0, 8.5)
	stage.add_child(lamp_post)
	lamp_post.owner = stage
	
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.08
	post_mesh.bottom_radius = 0.12
	post_mesh.height = 7.0
	var post_inst = MeshInstance3D.new()
	post_inst.name = "LampPole"
	post_inst.mesh = post_mesh
	post_inst.material_override = mat_metal
	post_inst.position = Vector3(0, 3.5, 0)
	lamp_post.add_child(post_inst)
	post_inst.owner = stage
	
	# Lamp Arm & Fixture
	var lamp_head = MeshInstance3D.new()
	lamp_head.name = "LampFixture"
	var lh_mesh = SphereMesh.new()
	lh_mesh.radius = 0.28
	lh_mesh.height = 0.56
	lamp_head.mesh = lh_mesh
	var mat_bulb = StandardMaterial3D.new()
	mat_bulb.albedo_color = Color(1.0, 0.92, 0.70, 1.0)
	mat_bulb.emission_enabled = true
	mat_bulb.emission = Color(1.0, 0.90, 0.65, 1.0)
	mat_bulb.emission_energy_multiplier = 3.5
	lamp_head.material_override = mat_bulb
	lamp_head.position = Vector3(-0.35, 6.8, 0)
	lamp_post.add_child(lamp_head)
	lamp_head.owner = stage
	
	var street_light = OmniLight3D.new()
	street_light.name = "StreetLightOmni"
	street_light.light_color = Color(1.0, 0.88, 0.65, 1.0)
	street_light.light_energy = 2.2
	street_light.omni_range = 10.0
	street_light.position = Vector3(-0.35, 6.6, 0)
	lamp_post.add_child(street_light)
	street_light.owner = stage
	
	# Red Vertical Motorsport Banner hanging on streetlamp
	var banner = MeshInstance3D.new()
	banner.name = "MotorsportBanner"
	var bn_mesh = QuadMesh.new()
	bn_mesh.size = Vector2(0.9, 2.8)
	banner.mesh = bn_mesh
	banner.material_override = mat_banner
	banner.position = Vector3(0.55, 4.6, 0)
	banner.rotation_degrees = Vector3(0, 90.0, 0)
	lamp_post.add_child(banner)
	banner.owner = stage

	# =========================================================================
	# 6. PALM TREE BETWEEN HQ AND BILLBOARD (Matching Reference Image)
	# =========================================================================
	var palm_root = Node3D.new()
	palm_root.name = "HeroPalmTree"
	palm_root.position = Vector3(-4.8, 0, 9.8)
	stage.add_child(palm_root)
	palm_root.owner = stage
	
	# Curved Trunk
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 7.5
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	trunk.mesh = trunk_mesh
	trunk.material_override = mat_palm_trunk
	trunk.position = Vector3(0, 3.75, 0)
	trunk.rotation_degrees = Vector3(0, 0, -4.5)
	palm_root.add_child(trunk)
	trunk.owner = stage
	
	# Palm Fronds Crown
	var crown = Node3D.new()
	crown.name = "FrondsCrown"
	crown.position = Vector3(0.3, 7.3, 0)
	palm_root.add_child(crown)
	crown.owner = stage
	
	var frond_mesh = QuadMesh.new()
	frond_mesh.size = Vector2(1.6, 3.6)
	
	for i in range(8):
		var ang = float(i) * 45.0
		var frond = MeshInstance3D.new()
		frond.name = "Frond_" + str(i)
		frond.mesh = frond_mesh
		frond.material_override = mat_palm_leaf
		frond.rotation_degrees = Vector3(-35.0, ang, 0)
		frond.position = Vector3(0, -0.2, 0)
		crown.add_child(frond)
		frond.owner = stage

	# =========================================================================
	# 7. CAR REAR RED RAIN-LIGHT GROUND SPECULAR POOL (Key Visual in Reference!)
	# =========================================================================
	# Located directly under the rear rain light of the car
	var rain_light_reflection = OmniLight3D.new()
	rain_light_reflection.name = "RainLightGroundReflection"
	rain_light_reflection.light_color = Color(1.0, 0.06, 0.08, 1.0) # Vivid Formula 1 rain red
	rain_light_reflection.light_energy = 5.5
	rain_light_reflection.omni_range = 5.2
	rain_light_reflection.omni_attenuation = 1.4
	# Positioned right beneath rear crash structure rain light (car is at 0.55, 0, 0.25 rot -115°)
	rain_light_reflection.position = Vector3(1.7, 0.38, 0.78)
	stage.add_child(rain_light_reflection)
	rain_light_reflection.owner = stage
	
	# Warm Sunset Horizon Specular Enhancer Light
	var sunset_puddle_glow = OmniLight3D.new()
	sunset_puddle_glow.name = "SunsetPuddleGlow"
	sunset_puddle_glow.light_color = Color(1.0, 0.65, 0.25, 1.0) # Warm sunset amber
	sunset_puddle_glow.light_energy = 2.6
	sunset_puddle_glow.omni_range = 14.0
	sunset_puddle_glow.omni_attenuation = 1.8
	sunset_puddle_glow.position = Vector3(-3.5, 0.45, 3.5)
	stage.add_child(sunset_puddle_glow)
	sunset_puddle_glow.owner = stage

	# =========================================================================
	# 8. REFLECTION PROBES (Inexpensive PBR IBL approximations)
	# =========================================================================
	var probe_car = ReflectionProbe.new()
	probe_car.name = "ReflectionProbe_Car"
	probe_car.size = Vector3(16, 6, 16)
	probe_car.position = Vector3(0.5, 1.5, 0.5)
	probe_car.box_projection = true
	probe_car.intensity = 0.85
	probe_car.update_mode = ReflectionProbe.UPDATE_ONCE
	stage.add_child(probe_car)
	probe_car.owner = stage
	
	var probe_road = ReflectionProbe.new()
	probe_road.name = "ReflectionProbe_Road"
	probe_road.size = Vector3(35, 6, 35)
	probe_road.position = Vector3(0, 1.0, 10.0)
	probe_road.box_projection = true
	probe_road.intensity = 0.80
	probe_road.update_mode = ReflectionProbe.UPDATE_ONCE
	stage.add_child(probe_road)
	probe_road.owner = stage
	
	# Save packed scene
	var scene = PackedScene.new()
	scene.pack(stage)
	ResourceSaver.save(scene, "res://scenes/environment/showcase_stage.tscn")
	print("showcase_stage.tscn built successfully with reference-accurate assets!")
	quit(0)

