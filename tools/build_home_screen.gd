@tool
extends SceneTree

func _init():
	print("Building home_screen.tscn...")
	var root = Node3D.new()
	root.name = "HomeScreen"
	
	# 1. WorldEnvironment (Â§8.3)
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = load("res://assets/materials/environments/env_sunset.tres")
	root.add_child(env_node)
	env_node.owner = root
	
	# 2. DirectionalLight3D SunLight (Â§8.1)
	var sun = DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.rotation_degrees = Vector3(-8.0, 215.0, 0.0)
	sun.light_color = Color(1.0, 0.698, 0.408, 1.0) # #FFB268
	sun.light_energy = 2.6
	sun.light_angular_distance = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 40.0
	sun.directional_shadow_bias_split_scale = 0.25
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.5
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	root.add_child(sun)
	sun.owner = root
	
	# 3. DirectionalLight3D FillCool (Â§8.2)
	var fill = DirectionalLight3D.new()
	fill.name = "FillCool"
	fill.rotation_degrees = Vector3(-35.0, 40.0, 0.0)
	fill.light_color = Color(0.498, 0.498, 0.71, 1.0) # #7F7FB5
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	root.add_child(fill)
	fill.owner = root
	
	# 4. SpotLight3D RimWarm (Â§8.2)
	var rim = SpotLight3D.new()
	rim.name = "RimWarm"
	rim.position = Vector3(6.0, 3.0, 8.0)
	rim.light_color = Color(1.0, 0.643, 0.369, 1.0) # #FFA45E
	rim.light_energy = 6.0
	rim.spot_range = 18.0
	rim.spot_angle = 45.0
	rim.shadow_enabled = false
	root.add_child(rim)
	rim.owner = root
	
	# 5. Stage instance
	var stage_scene = load("res://scenes/environment/showcase_stage.tscn")
	var stage = stage_scene.instantiate()
	stage.name = "Stage"
	root.add_child(stage)
	stage.owner = root
	
	# 6. ShowcaseCar instance
	var car_scene = load("res://scenes/vehicles/showcase_car.tscn")
	var car = car_scene.instantiate()
	car.name = "ShowcaseCar"
	car.position = Vector3(0, 0, 0)
	root.add_child(car)
	car.owner = root
	
	# 7. CameraRig & ShowcaseCamera (Â§7)
	var rig = Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(load("res://scripts/camera/showcase_camera_rig.gd"))
	rig.position = Vector3(-4.6, 1.10, -6.60)
	root.add_child(rig)
	rig.owner = root
	
	var cam = Camera3D.new()
	cam.name = "ShowcaseCamera"
	cam.fov = 35.0
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 0.1
	cam.far = 800.0
	cam.current = true
	rig.add_child(cam)
	cam.owner = root
	
	# 8. UILayer (CanvasLayer 20)
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 20
	root.add_child(ui_layer)
	ui_layer.owner = root
	
	var ui_scene = load("res://scenes/ui/home_screen_ui.tscn")
	var ui = ui_scene.instantiate()
	ui.name = "HomeScreenUI"
	ui_layer.add_child(ui)
	ui.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/main/home_screen.tscn")
	print("res://scenes/main/home_screen.tscn built successfully!")
	quit()
