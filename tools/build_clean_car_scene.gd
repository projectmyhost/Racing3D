@tool
extends SceneTree

func _init():
	print("Building lightweight showcase_car.tscn...")
	var root = Node3D.new()
	root.name = "VehicleRoot"
	root.set_script(load("res://scripts/vehicle/showcase_car.gd"))
	
	# 1. VisualRoot
	var vis_root = Node3D.new()
	vis_root.name = "VisualRoot"
	root.add_child(vis_root)
	vis_root.owner = root
	
	# Proxy contract nodes (Â§4.3)
	for n_name in ["Body", "Hood", "FrontBumper", "RearBumper", "Spoiler", "Windows"]:
		var p = MeshInstance3D.new()
		p.name = n_name
		vis_root.add_child(p)
		p.owner = root
		
	for n_name in ["Headlights", "Taillights", "Mirrors", "Wheels"]:
		var p = Node3D.new()
		p.name = n_name
		vis_root.add_child(p)
		p.owner = root
		if n_name == "Wheels":
			for w_name in ["FrontLeft", "FrontRight", "RearLeft", "RearRight"]:
				var wp = Node3D.new()
				wp.name = w_name
				p.add_child(wp)
				wp.owner = root
				
	# 2. CollisionRoot
	var col_root = Node3D.new()
	col_root.name = "CollisionRoot"
	root.add_child(col_root)
	col_root.owner = root
	
	var col_shape = CollisionShape3D.new()
	col_shape.name = "BodyCollision"
	var box = BoxShape3D.new()
	box.size = Vector3(1.95, 1.15, 5.4)
	col_shape.shape = box
	col_shape.position = Vector3(0, 0.58, 0)
	col_root.add_child(col_shape)
	col_shape.owner = root
	
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
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/vehicles/showcase_car.tscn")
	print("Saved clean showcase_car.tscn successfully!")
	quit(0)
