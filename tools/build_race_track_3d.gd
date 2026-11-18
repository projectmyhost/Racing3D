@tool
extends SceneTree

func _init():
	print("--- BUILDING FULL MODULAR 3D RACE TRACK SCENE ---")
	
	var root_scene = Node3D.new()
	root_scene.name = "RaceTrack3D"
	var track_script = load("res://scripts/race/RaceTrack3D.gd")
	root_scene.set_script(track_script)
	
	# 1. Environment & Lighting
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = load("res://assets/materials/environments/env_sunset.tres")
	if env:
		env_node.environment = env
	root_scene.add_child(env_node)
	env_node.owner = root_scene
	
	var sun = DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.rotation_degrees = Vector3(-35.0, 45.0, 0.0)
	sun.light_color = Color(1.0, 0.72, 0.45)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	root_scene.add_child(sun)
	sun.owner = root_scene
	
	var fill = DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(45.0, -135.0, 0.0)
	fill.light_color = Color(0.4, 0.45, 0.65)
	fill.light_energy = 0.5
	root_scene.add_child(fill)
	fill.owner = root_scene

	# 2. Base Ground
	var ground = MeshInstance3D.new()
	ground.name = "GroundTerrain"
	var g_mesh = PlaneMesh.new()
	g_mesh.size = Vector2(300, 300)
	ground.mesh = g_mesh
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.09, 0.11, 0.08) # Dark dusk grass/pavement
	g_mat.roughness = 0.8
	ground.material_override = g_mat
	ground.position.y = -0.05
	root_scene.add_child(ground)
	ground.owner = root_scene

	# 3. Modular Track Container
	var track_container = Node3D.new()
	track_container.name = "TrackTiles"
	root_scene.add_child(track_container)
	track_container.owner = root_scene

	var road1_p = load("res://assets/models/roads/Road1.glb") as PackedScene
	var corner_p = load("res://assets/models/roads/Road10_90angle_Corner.glb") as PackedScene
	var lamp_p = load("res://assets/models/roads/lamp_1.glb") as PackedScene
	var tree_p = load("res://assets/models/roads/Tree3.glb") as PackedScene
	var barrier_p = load("res://assets/models/roads/road_barrier_1.glb") as PackedScene
	var cone_p = load("res://assets/models/roads/hazzard_cone_1.glb") as PackedScene
	var gantry_p = load("res://assets/models/roads/traffic_light_1.glb") as PackedScene

	var mat_road = StandardMaterial3D.new()
	var tex_road = load("res://assets/models/roads/Road1_B_dotted_white.png") as Texture2D
	mat_road.albedo_texture = tex_road
	mat_road.roughness = 0.42
	mat_road.metallic = 0.08

	# Define 16 tiles of the circuit (Grid size: 12m)
	# (gx, gz, tile_type, rot_deg)
	var circuit_tiles = [
		# Straight 1 (Start/Finish along +Z)
		{"x": 0, "z": 1, "type": "road1", "rot": 0.0},
		{"x": 0, "z": 2, "type": "road1", "rot": 0.0},
		{"x": 0, "z": 3, "type": "road1", "rot": 0.0},
		# Turn 1 (+Z to +X)
		{"x": 0, "z": 4, "type": "corner", "rot": 0.0},
		# Straight 2 (along +X)
		{"x": 1, "z": 4, "type": "road1", "rot": 90.0},
		{"x": 2, "z": 4, "type": "road1", "rot": 90.0},
		{"x": 3, "z": 4, "type": "road1", "rot": 90.0},
		# Turn 2 (+X to -Z)
		{"x": 4, "z": 4, "type": "corner", "rot": 90.0},
		# Straight 3 (along -Z)
		{"x": 4, "z": 3, "type": "road1", "rot": 180.0},
		{"x": 4, "z": 2, "type": "road1", "rot": 180.0},
		{"x": 4, "z": 1, "type": "road1", "rot": 180.0},
		# Turn 3 (-Z to -X)
		{"x": 4, "z": 0, "type": "corner", "rot": 180.0},
		# Straight 4 (along -X)
		{"x": 3, "z": 0, "type": "road1", "rot": 270.0},
		{"x": 2, "z": 0, "type": "road1", "rot": 270.0},
		{"x": 1, "z": 0, "type": "road1", "rot": 270.0},
		# Turn 4 (-X to +Z, back to Start)
		{"x": 0, "z": 0, "type": "corner", "rot": 270.0}
	]

	var tile_idx = 0
	for t in circuit_tiles:
		var p_scene = corner_p if t["type"] == "corner" else road1_p
		if p_scene:
			var tile = p_scene.instantiate()
			tile.name = "Tile_" + str(tile_idx)
			var gx = float(t["x"]) * 12.0
			var gz = float(t["z"]) * 12.0
			tile.position = Vector3(gx, 0.0, gz)
			tile.rotation_degrees = Vector3(0, t["rot"], 0)
			track_container.add_child(tile)
			tile.owner = root_scene
			for c in tile.get_children():
				c.owner = root_scene
				if c is MeshInstance3D:
					c.material_override = mat_road

			# Add static collision under road tile so the car drives smoothly
			var col_body = StaticBody3D.new()
			col_body.name = "Col_" + str(tile_idx)
			var col_shape = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(12.0, 0.4, 12.0)
			col_shape.shape = box
			col_shape.position = Vector3(0, 0.0, 0)
			col_body.add_child(col_shape)
			tile.add_child(col_body)
			col_body.owner = root_scene
			col_shape.owner = root_scene

			# Props: street lamps along straights
			if t["type"] == "road1" and tile_idx % 2 == 0 and lamp_p:
				var lamp = lamp_p.instantiate()
				lamp.name = "Lamp_" + str(tile_idx)
				lamp.position = Vector3(5.6, 0.48, 0.0)
				tile.add_child(lamp)
				lamp.owner = root_scene
				for c in lamp.get_children(): c.owner = root_scene

			# Props: barriers along corners
			if t["type"] == "corner" and barrier_p:
				for b in range(3):
					var bar = barrier_p.instantiate()
					bar.name = "Barrier_" + str(tile_idx) + "_" + str(b)
					bar.position = Vector3(5.2, 0.48, -4.0 + float(b)*3.5)
					tile.add_child(bar)
					bar.owner = root_scene
					for c in bar.get_children(): c.owner = root_scene

		tile_idx += 1

	# Start/Finish Gantry light on the side curb at (5.6, 0.2, 8.0)
	if gantry_p:
		var gantry = gantry_p.instantiate()
		gantry.name = "StartFinishGantry"
		gantry.position = Vector3(5.6, 0.2, 8.0)
		track_container.add_child(gantry)
		gantry.owner = root_scene
		for c in gantry.get_children(): c.owner = root_scene

	# 4. Checkpoints Area3D
	var chk_root = Node3D.new()
	chk_root.name = "Checkpoints"
	root_scene.add_child(chk_root)
	chk_root.owner = root_scene

	var chk_coords = [
		Vector3(0.0, 1.0, 12.0), # Checkpoint 0 (Start/Finish)
		Vector3(12.0, 1.0, 48.0), # Checkpoint 1 (After Turn 1)
		Vector3(48.0, 1.0, 36.0), # Checkpoint 2 (After Turn 2)
		Vector3(24.0, 1.0, 0.0)   # Checkpoint 3 (After Turn 3)
	]
	for i in range(chk_coords.size()):
		var area = Area3D.new()
		area.name = "Checkpoint_" + str(i)
		area.position = chk_coords[i]
		chk_root.add_child(area)
		area.owner = root_scene
		
		var c_shape = CollisionShape3D.new()
		var b_shape = BoxShape3D.new()
		b_shape.size = Vector3(14.0, 4.0, 6.0)
		c_shape.shape = b_shape
		area.add_child(c_shape)
		c_shape.owner = root_scene

	# 5. Playable 3D Race Car
	var car_body = CharacterBody3D.new()
	car_body.name = "RaceCar3D"
	var car_script = load("res://scripts/race/RaceCar3D.gd")
	car_body.set_script(car_script)
	car_body.position = Vector3(0.0, 0.35, 12.0) # Start line
	car_body.rotation_degrees = Vector3(0.0, 0.0, 0.0) # Facing +Z
	root_scene.add_child(car_body)
	car_body.owner = root_scene

	# Collision shape for car
	var car_col = CollisionShape3D.new()
	car_col.name = "CarCollision"
	var car_box = BoxShape3D.new()
	car_box.size = Vector3(1.9, 0.9, 4.6)
	car_col.shape = car_box
	car_col.position = Vector3(0, 0.45, 0)
	car_body.add_child(car_col)
	car_col.owner = root_scene

	# 6. Chase Camera
	var cam = Camera3D.new()
	cam.name = "ChaseCamera"
	cam.position = Vector3(0.0, 3.5, 19.5)
	cam.current = true
	cam.fov = 65.0
	root_scene.add_child(cam)
	cam.owner = root_scene

	# 7. Motorsport Race HUD
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 15
	root_scene.add_child(hud)
	hud.owner = root_scene

	# Top-Left Telemetry (Lap & Time)
	var top_left = PanelContainer.new()
	top_left.name = "TopLeftHUD"
	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.position = Vector2(30, 25)
	hud.add_child(top_left)
	top_left.owner = root_scene

	var tl_vbox = VBoxContainer.new()
	top_left.add_child(tl_vbox)
	tl_vbox.owner = root_scene

	var lap_lbl = Label.new()
	lap_lbl.name = "LapLabel"
	lap_lbl.unique_name_in_owner = true
	lap_lbl.text = "LAP 1 / 3"
	lap_lbl.add_theme_font_size_override("font_size", 24)
	lap_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tl_vbox.add_child(lap_lbl)
	lap_lbl.owner = root_scene

	var time_lbl = Label.new()
	time_lbl.name = "TimeLabel"
	time_lbl.unique_name_in_owner = true
	time_lbl.text = "00:00.00"
	time_lbl.add_theme_font_size_override("font_size", 32)
	tl_vbox.add_child(time_lbl)
	time_lbl.owner = root_scene

	var best_lbl = Label.new()
	best_lbl.name = "BestLabel"
	best_lbl.unique_name_in_owner = true
	best_lbl.text = "BEST: --:--.--"
	best_lbl.add_theme_font_size_override("font_size", 16)
	best_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	tl_vbox.add_child(best_lbl)
	best_lbl.owner = root_scene

	# Top-Right Controls / Back button
	var back_b = Button.new()
	back_b.name = "BackBtn"
	back_b.unique_name_in_owner = true
	back_b.text = "[ESC] RETURN TO MENU"
	back_b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	back_b.position = Vector2(1650, 25)
	back_b.size = Vector2(240, 48)
	hud.add_child(back_b)
	back_b.owner = root_scene

	# Bottom Controls Hint
	var hint_lbl = Label.new()
	hint_lbl.name = "HintLabel"
	hint_lbl.text = "W / UP: Accelerate | S / DOWN: Brake / Reverse | A/D / ARROWS: Steer | SPACE: Handbrake"
	hint_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_lbl.position = Vector2(600, 1020)
	hint_lbl.add_theme_font_size_override("font_size", 16)
	hint_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 0.8))
	hud.add_child(hint_lbl)
	hint_lbl.owner = root_scene

	# Bottom-Right Speedometer
	var speed_panel = PanelContainer.new()
	speed_panel.name = "SpeedPanel"
	speed_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	speed_panel.position = Vector2(1620, 920)
	hud.add_child(speed_panel)
	speed_panel.owner = root_scene

	var sp_vbox = VBoxContainer.new()
	speed_panel.add_child(sp_vbox)
	sp_vbox.owner = root_scene

	var sp_lbl = Label.new()
	sp_lbl.name = "SpeedLabel"
	sp_lbl.unique_name_in_owner = true
	sp_lbl.text = "0 KM/H"
	sp_lbl.add_theme_font_size_override("font_size", 34)
	sp_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	sp_vbox.add_child(sp_lbl)
	sp_lbl.owner = root_scene

	var sp_bar = ProgressBar.new()
	sp_bar.name = "SpeedBar"
	sp_bar.unique_name_in_owner = true
	sp_bar.max_value = 260.0
	sp_bar.custom_minimum_size = Vector2(240, 14)
	sp_vbox.add_child(sp_bar)
	sp_bar.owner = root_scene

	# Center Finish Panel (Hidden by default)
	var fin_panel = PanelContainer.new()
	fin_panel.name = "FinishPanel"
	fin_panel.unique_name_in_owner = true
	fin_panel.set_anchors_preset(Control.PRESET_CENTER)
	fin_panel.position = Vector2(710, 400)
	fin_panel.size = Vector2(500, 280)
	fin_panel.visible = false
	hud.add_child(fin_panel)
	fin_panel.owner = root_scene

	var fin_vbox = VBoxContainer.new()
	fin_panel.add_child(fin_vbox)
	fin_vbox.owner = root_scene

	var fin_title = Label.new()
	fin_title.name = "FinishTitle"
	fin_title.unique_name_in_owner = true
	fin_title.text = "VICTORY // GRAND PRIX FINISHED"
	fin_title.add_theme_font_size_override("font_size", 26)
	fin_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	fin_vbox.add_child(fin_title)
	fin_title.owner = root_scene

	var fin_stats = Label.new()
	fin_stats.name = "FinishStats"
	fin_stats.unique_name_in_owner = true
	fin_stats.text = "BEST LAP: 00:42.15\nAVERAGE SPEED: 198 KM/H\nREWARD: +5,000 COINS"
	fin_stats.add_theme_font_size_override("font_size", 18)
	fin_vbox.add_child(fin_stats)
	fin_stats.owner = root_scene

	var fin_btn = Button.new()
	fin_btn.name = "FinishHomeBtn"
	fin_btn.unique_name_in_owner = true
	fin_btn.text = "[RETURN TO MAIN MENU]"
	fin_btn.custom_minimum_size = Vector2(300, 48)
	fin_vbox.add_child(fin_btn)
	fin_btn.owner = root_scene

	# Save packed scene
	var packed = PackedScene.new()
	var err = packed.pack(root_scene)
	if err == OK:
		ResourceSaver.save(packed, "res://scenes/race/RaceTrack3D.tscn")
		print("SUCCESS: Built and saved res://scenes/race/RaceTrack3D.tscn!")
	else:
		print("ERROR packing RaceTrack3D.tscn: ", err)

	root_scene.free()
	quit(0)
