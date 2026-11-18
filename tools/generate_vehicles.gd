@tool
extends SceneTree

func _init():
	print("Generating vehicle assets...")
	generate_wheel()
	generate_coupe(false, "res://scenes/vehicles/fallback_coupe.tscn")
	generate_coupe(true, "res://scenes/vehicles/showcase_car.tscn")
	print("Vehicle generation complete!")
	quit()

func generate_wheel():
	var root = Node3D.new()
	root.name = "WheelAssembly"
	
	var tire_mat = load("res://assets/materials/vehicles/mat_veh_tire.tres")
	var rim_mat = load("res://assets/materials/vehicles/mat_veh_wheel_black.tres")
	var caliper_mat = load("res://assets/materials/vehicles/mat_veh_caliper.tres")
	
	# Tire (19" diameter â‰ˆ 0.69m, width â‰ˆ 0.26m)
	# Wheel spins around local X axis
	var tire = MeshInstance3D.new()
	tire.name = "Tire"
	var cyl_t = CylinderMesh.new()
	cyl_t.top_radius = 0.345
	cyl_t.bottom_radius = 0.345
	cyl_t.height = 0.26
	tire.mesh = cyl_t
	tire.material_override = tire_mat
	tire.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(tire)
	tire.owner = root
	
	# Rim outer lip
	var rim = MeshInstance3D.new()
	rim.name = "Rim"
	var cyl_r = CylinderMesh.new()
	cyl_r.top_radius = 0.26
	cyl_r.bottom_radius = 0.26
	cyl_r.height = 0.27
	rim.mesh = cyl_r
	rim.material_override = rim_mat
	rim.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(rim)
	rim.owner = root
	
	# 10 Spokes
	for i in range(10):
		var angle = float(i) / 10.0 * TAU
		var spoke = MeshInstance3D.new()
		spoke.name = "Spoke_" + str(i)
		var box = BoxMesh.new()
		box.size = Vector3(0.04, 0.24, 0.02)
		spoke.mesh = box
		spoke.material_override = rim_mat
		# Place spoke on outer face
		spoke.position = Vector3(0.12, sin(angle) * 0.12, cos(angle) * 0.12)
		spoke.rotation_degrees = Vector3(rad_to_deg(angle), 0, 0)
		root.add_child(spoke)
		spoke.owner = root
		
	# Center cap
	var cap = MeshInstance3D.new()
	cap.name = "CenterCap"
	var cyl_c = CylinderMesh.new()
	cyl_c.top_radius = 0.05
	cyl_c.bottom_radius = 0.05
	cyl_c.height = 0.04
	cap.mesh = cyl_c
	cap.material_override = rim_mat
	cap.position = Vector3(0.13, 0, 0)
	cap.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(cap)
	cap.owner = root
	
	# Brake Caliper (red, mounted inside behind rim)
	var caliper = MeshInstance3D.new()
	caliper.name = "BrakeCaliper"
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.06, 0.14, 0.07)
	caliper.mesh = b_box
	caliper.material_override = caliper_mat
	caliper.position = Vector3(0.02, 0.18, 0.04)
	root.add_child(caliper)
	caliper.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/vehicles/wheels/veh_wheel_multispoke_01.tscn")

func generate_coupe(is_showcase: bool, out_path: String):
	# Root node conforming strictly to Â§4.3 contract
	var root = Node3D.new()
	root.name = "VehicleRoot"
	root.set_script(load("res://scripts/vehicle/showcase_car.gd"))
	
	# Materials
	var paint_mat = load("res://assets/materials/vehicles/mat_veh_paint_silver_pearl.tres")
	var stripe_mat = load("res://assets/materials/vehicles/mat_veh_hood_stripe.tres")
	var carbon_mat = load("res://assets/materials/vehicles/mat_veh_carbon.tres")
	var glass_mat = load("res://assets/materials/vehicles/mat_veh_glass_dark.tres")
	var trim_mat = load("res://assets/materials/vehicles/mat_veh_tire.tres")
	var head_lens_mat = load("res://assets/materials/vehicles/mat_veh_headlight_lens.tres")
	var head_emit_mat = load("res://assets/materials/vehicles/mat_veh_headlight_emit.tres")
	var tail_mat = load("res://assets/materials/vehicles/mat_veh_taillight.tres")
	
	# 1. VisualRoot
	var vis_root = Node3D.new()
	vis_root.name = "VisualRoot"
	root.add_child(vis_root)
	vis_root.owner = root
	
	# --- BODY ---
	var body = MeshInstance3D.new()
	body.name = "Body"
	var b_box = BoxMesh.new()
	# Long low Japanese sports coupe dimensions: 4.75m length, 1.97m width (flares), 1.34m height
	b_box.size = Vector3(1.88, 0.52, 4.4)
	body.mesh = b_box
	body.material_override = paint_mat
	body.position = Vector3(0, 0.48, 0)
	vis_root.add_child(body)
	body.owner = root
	
	# Wide over-fenders (bolt-on flares +0.07m outward)
	for flare_z in [-1.36, 1.36]:
		for side in [-1.0, 1.0]:
			var flare = MeshInstance3D.new()
			flare.name = "OverFender_" + ("F" if flare_z < 0 else "R") + ("L" if side < 0 else "R")
			var f_box = BoxMesh.new()
			f_box.size = Vector3(0.12, 0.42, 0.95)
			flare.mesh = f_box
			flare.material_override = paint_mat
			flare.position = Vector3(side * 0.96, 0.44, flare_z)
			vis_root.add_child(flare)
			flare.owner = root
			
	# Cabin / Fastback roof (wedge shape, windshield at 42% from nose)
	var cabin = MeshInstance3D.new()
	cabin.name = "CabinRoof"
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.52, 0.48, 2.3)
	cabin.mesh = c_box
	cabin.material_override = paint_mat
	cabin.position = Vector3(0, 0.95, 0.15)
	vis_root.add_child(cabin)
	cabin.owner = root
	
	# --- WINDOWS ---
	var windows = MeshInstance3D.new()
	windows.name = "Windows"
	var w_box = BoxMesh.new()
	w_box.size = Vector3(1.54, 0.44, 2.1)
	windows.mesh = w_box
	windows.material_override = glass_mat
	windows.position = Vector3(0, 0.96, 0.15)
	vis_root.add_child(windows)
	windows.owner = root
	
	# --- HOOD ---
	var hood = MeshInstance3D.new()
	hood.name = "Hood"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(1.68, 0.08, 1.6)
	hood.mesh = h_box
	hood.material_override = paint_mat
	hood.position = Vector3(0, 0.72, -1.35)
	vis_root.add_child(hood)
	hood.owner = root
	
	# Twin Matte Black Stripes on Hood (Â§2.2, Â§4.2: ~0.28m wide each, 0.12m gap)
	for s_idx in [-1.0, 1.0]:
		var stripe = MeshInstance3D.new()
		stripe.name = "HoodStripe_" + ("L" if s_idx < 0 else "R")
		var s_quad = QuadMesh.new()
		s_quad.size = Vector2(0.28, 1.62)
		s_quad.orientation = PlaneMesh.FACE_Y
		stripe.mesh = s_quad
		stripe.material_override = stripe_mat
		stripe.position = Vector3(s_idx * 0.20, 0.765, -1.35)
		vis_root.add_child(stripe)
		stripe.owner = root
		
	# --- FRONT BUMPER ---
	var fBumper = MeshInstance3D.new()
	fBumper.name = "FrontBumper"
	var fb_box = BoxMesh.new()
	fb_box.size = Vector3(1.88, 0.48, 0.42)
	fBumper.mesh = fb_box
	fBumper.material_override = paint_mat
	fBumper.position = Vector3(0, 0.42, -2.25)
	vis_root.add_child(fBumper)
	fBumper.owner = root
	
	# Large black mesh grille (upper) + lower intercooler intake + front splitter
	var grille = MeshInstance3D.new()
	grille.name = "GrilleMesh"
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.82, 0.20, 0.05)
	grille.mesh = g_box
	grille.material_override = trim_mat
	grille.position = Vector3(0, 0.52, -2.47)
	vis_root.add_child(grille)
	grille.owner = root
	
	# Emblem on grille (SR Monogram Badge)
	var badge = MeshInstance3D.new()
	badge.name = "EmblemBadge"
	var b_quad = QuadMesh.new()
	b_quad.size = Vector2(0.10, 0.07)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_texture = load("res://assets/textures/vehicles/tex_veh_showcase_badge.png")
	b_mat.roughness = 0.3
	b_mat.metallic = 0.9
	badge.mesh = b_quad
	badge.material_override = b_mat
	badge.position = Vector3(0, 0.52, -2.50)
	vis_root.add_child(badge)
	badge.owner = root
	
	# Lower intake (1.10m x 0.30m)
	var intake = MeshInstance3D.new()
	intake.name = "LowerIntake"
	var in_box = BoxMesh.new()
	in_box.size = Vector3(1.10, 0.24, 0.05)
	intake.mesh = in_box
	intake.material_override = trim_mat
	intake.position = Vector3(0, 0.26, -2.47)
	vis_root.add_child(intake)
	intake.owner = root
	
	# Carbon front lip / splitter extending ~12cm
	var splitter = MeshInstance3D.new()
	splitter.name = "FrontSplitter"
	var sp_box = BoxMesh.new()
	sp_box.size = Vector3(1.94, 0.05, 0.52)
	splitter.mesh = sp_box
	splitter.material_override = carbon_mat
	splitter.position = Vector3(0, 0.12, -2.40)
	vis_root.add_child(splitter)
	splitter.owner = root
	
	# Side skirts
	for side in [-1.0, 1.0]:
		var skirt = MeshInstance3D.new()
		skirt.name = "SideSkirt_" + ("L" if side < 0 else "R")
		var sk_box = BoxMesh.new()
		sk_box.size = Vector3(0.08, 0.06, 2.6)
		skirt.mesh = sk_box
		skirt.material_override = carbon_mat
		skirt.position = Vector3(side * 0.98, 0.12, 0)
		vis_root.add_child(skirt)
		skirt.owner = root
		
	# --- REAR BUMPER ---
	var rBumper = MeshInstance3D.new()
	rBumper.name = "RearBumper"
	var rb_box = BoxMesh.new()
	rb_box.size = Vector3(1.90, 0.50, 0.45)
	rBumper.mesh = rb_box
	rBumper.material_override = paint_mat
	rBumper.position = Vector3(0, 0.44, 2.25)
	vis_root.add_child(rBumper)
	rBumper.owner = root
	
	# Rear carbon diffuser + quad exhaust
	var diffuser = MeshInstance3D.new()
	diffuser.name = "RearDiffuser"
	var d_box = BoxMesh.new()
	d_box.size = Vector3(1.50, 0.18, 0.35)
	diffuser.mesh = d_box
	diffuser.material_override = carbon_mat
	diffuser.position = Vector3(0, 0.20, 2.38)
	vis_root.add_child(diffuser)
	diffuser.owner = root
	
	# Quad exhaust tips
	for ex_x in [-0.55, -0.42, 0.42, 0.55]:
		var tip = MeshInstance3D.new()
		tip.name = "ExhaustTip_" + str(ex_x)
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.05
		t_cyl.bottom_radius = 0.05
		t_cyl.height = 0.18
		tip.mesh = t_cyl
		tip.material_override = trim_mat
		tip.position = Vector3(ex_x, 0.20, 2.50)
		tip.rotation_degrees = Vector3(90, 0, 0)
		vis_root.add_child(tip)
		tip.owner = root
		
	# --- SPOILER / GT WING ---
	var spoiler = MeshInstance3D.new()
	spoiler.name = "Spoiler"
	var wing_box = BoxMesh.new()
	wing_box.size = Vector3(1.80, 0.04, 0.28) # 1.80m span
	spoiler.mesh = wing_box
	spoiler.material_override = carbon_mat
	spoiler.position = Vector3(0, 1.25, 2.15)
	vis_root.add_child(spoiler)
	spoiler.owner = root
	
	# Wing uprights (0.30m tall, swan-neck mounts)
	for up_x in [-0.55, 0.55]:
		var upright = MeshInstance3D.new()
		upright.name = "WingUpright_" + ("L" if up_x < 0 else "R")
		var u_box = BoxMesh.new()
		u_box.size = Vector3(0.04, 0.34, 0.12)
		upright.mesh = u_box
		upright.material_override = carbon_mat
		upright.position = Vector3(up_x, 1.08, 2.15)
		vis_root.add_child(upright)
		upright.owner = root
		
	# Red accent strips on wing end plates
	for ep_x in [-0.91, 0.91]:
		var endplate = MeshInstance3D.new()
		endplate.name = "WingEndPlate_" + ("L" if ep_x < 0 else "R")
		var ep_box = BoxMesh.new()
		ep_box.size = Vector3(0.02, 0.18, 0.32)
		endplate.mesh = ep_box
		var ep_mat = StandardMaterial3D.new()
		ep_mat.albedo_color = Color(0.78, 0.13, 0.17, 1.0) # Red accent #C8232B
		endplate.material_override = ep_mat
		endplate.position = Vector3(ep_x, 1.25, 2.15)
		vis_root.add_child(endplate)
		endplate.owner = root
		
	# --- HEADLIGHTS ---
	var headlights = Node3D.new()
	headlights.name = "Headlights"
	vis_root.add_child(headlights)
	headlights.owner = root
	
	for h_side in [-1.0, 1.0]:
		var hl = MeshInstance3D.new()
		hl.name = "Headlight" + ("L" if h_side < 0 else "R")
		var hl_box = BoxMesh.new()
		hl_box.size = Vector3(0.32, 0.12, 0.22)
		hl.mesh = hl_box
		hl.material_override = head_emit_mat # Blue-white emissive ring glow #CFE6FF
		hl.position = Vector3(h_side * 0.70, 0.58, -2.18)
		hl.rotation_degrees = Vector3(0, h_side * -15, 0)
		headlights.add_child(hl)
		hl.owner = root
		
	# --- TAILLIGHTS ---
	var taillights = Node3D.new()
	taillights.name = "Taillights"
	vis_root.add_child(taillights)
	taillights.owner = root
	
	# Quad round taillights (2 on each side)
	for t_side in [-1.0, 1.0]:
		for t_sub in [0, 1]:
			var tl = MeshInstance3D.new()
			tl.name = "Taillight_" + ("L" if t_side < 0 else "R") + "_" + str(t_sub)
			var tl_cyl = CylinderMesh.new()
			tl_cyl.top_radius = 0.065
			tl_cyl.bottom_radius = 0.065
			tl_cyl.height = 0.04
			tl.mesh = tl_cyl
			tl.material_override = tail_mat # Red emissive
			tl.position = Vector3(t_side * (0.62 + t_sub * 0.15), 0.62, 2.44)
			tl.rotation_degrees = Vector3(90, 0, 0)
			taillights.add_child(tl)
			tl.owner = root
			
	# --- MIRRORS ---
	var mirrors = Node3D.new()
	mirrors.name = "Mirrors"
	vis_root.add_child(mirrors)
	mirrors.owner = root
	
	for m_side in [-1.0, 1.0]:
		var mir = MeshInstance3D.new()
		mir.name = "Mirror" + ("L" if m_side < 0 else "R")
		var m_box = BoxMesh.new()
		m_box.size = Vector3(0.20, 0.11, 0.14)
		mir.mesh = m_box
		mir.material_override = paint_mat
		mir.position = Vector3(m_side * 0.95, 0.85, -0.65)
		mirrors.add_child(mir)
		mir.owner = root
		
	# --- WHEELS (FrontLeft, FrontRight, RearLeft, RearRight) ---
	var wheels_root = Node3D.new()
	wheels_root.name = "Wheels"
	vis_root.add_child(wheels_root)
	wheels_root.owner = root
	
	var wheel_scene = load("res://assets/vehicles/wheels/veh_wheel_multispoke_01.tscn")
	var wheel_configs = [
		{"name": "FrontLeft", "pos": Vector3(-0.81, 0.345, -1.36), "rot": 0.0},
		{"name": "FrontRight", "pos": Vector3(0.81, 0.345, -1.36), "rot": 180.0},
		{"name": "RearLeft", "pos": Vector3(-0.82, 0.35, 1.36), "rot": 0.0},
		{"name": "RearRight", "pos": Vector3(0.82, 0.35, 1.36), "rot": 180.0}
	]
	
	for wc in wheel_configs:
		var pivot = Node3D.new()
		pivot.name = wc["name"]
		pivot.position = wc["pos"]
		wheels_root.add_child(pivot)
		pivot.owner = root
		
		var w_inst = wheel_scene.instantiate()
		w_inst.name = "WheelMesh"
		w_inst.rotation_degrees = Vector3(0, wc["rot"], 0)
		pivot.add_child(w_inst)
		w_inst.owner = root
		
	# 2. CollisionRoot
	var col_root = Node3D.new()
	col_root.name = "CollisionRoot"
	var body_col = CollisionShape3D.new()
	body_col.name = "BodyCollision"
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(1.95, 1.2, 4.7)
	body_col.shape = col_box
	body_col.position = Vector3(0, 0.65, 0)
	col_root.add_child(body_col)
	body_col.owner = root
	root.add_child(col_root)
	col_root.owner = root
	
	# 3. WheelAnchors
	var anchors_root = Node3D.new()
	anchors_root.name = "WheelAnchors"
	for an_name in ["AnchorFL", "AnchorFR", "AnchorRL", "AnchorRR"]:
		var m = Marker3D.new()
		m.name = an_name
		anchors_root.add_child(m)
		m.owner = root
	root.add_child(anchors_root)
	anchors_root.owner = root
	
	# 4. VehicleEffects
	var fx_root = Node3D.new()
	fx_root.name = "VehicleEffects"
	
	# Headlight spots
	for sp_side in [-1.0, 1.0]:
		var spot = SpotLight3D.new()
		spot.name = "HeadlightSpot" + ("L" if sp_side < 0 else "R")
		spot.light_color = Color(0.81, 0.90, 1.0, 1.0) # #CFE6FF
		spot.light_energy = 3.0
		spot.spot_range = 8.0
		spot.spot_angle = 35.0
		spot.position = Vector3(sp_side * 0.70, 0.58, -2.2)
		spot.rotation_degrees = Vector3(-10, sp_side * -10, 0)
		fx_root.add_child(spot)
		spot.owner = root
		
	var brake_glow = OmniLight3D.new()
	brake_glow.name = "BrakeGlow"
	brake_glow.light_color = Color(1.0, 0.1, 0.1, 1.0)
	brake_glow.light_energy = 0.0
	brake_glow.position = Vector3(0, 0.6, 2.5)
	fx_root.add_child(brake_glow)
	brake_glow.owner = root
	
	for ex_side in [-1.0, 1.0]:
		var ex_pt = Marker3D.new()
		ex_pt.name = "ExhaustPoint" + ("L" if ex_side < 0 else "R")
		ex_pt.position = Vector3(ex_side * 0.48, 0.20, 2.55)
		fx_root.add_child(ex_pt)
		ex_pt.owner = root
		
	var ug = Marker3D.new()
	ug.name = "UnderglowAnchor"
	ug.position = Vector3(0, 0.05, 0)
	fx_root.add_child(ug)
	ug.owner = root
	
	root.add_child(fx_root)
	fx_root.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, out_path)
	print("Saved vehicle to ", out_path)
