@tool
extends SceneTree

func _init():
	print("--- BUILDING LIGHTWEIGHT LOWPOLY SHOWCASE CAR SCENE ---")
	
	var car_root = Node3D.new()
	car_root.name = "ShowcaseCar"
	
	var car_script = load("res://scripts/vehicle/showcase_car.gd")
	car_root.set_script(car_script)
	
	# VisualRoot
	var vis_root = Node3D.new()
	vis_root.name = "VisualRoot"
	car_root.add_child(vis_root)
	vis_root.owner = car_root
	
	# VehicleEffects
	var fx_root = Node3D.new()
	fx_root.name = "VehicleEffects"
	car_root.add_child(fx_root)
	fx_root.owner = car_root
	
	# Headlight spotlights (pointing forward along +Z or -Z depending on orientation)
	var spot_l = SpotLight3D.new()
	spot_l.name = "HeadlightSpotL"
	spot_l.position = Vector3(-0.6, 0.45, 2.2)
	spot_l.rotation_degrees = Vector3(-5.0, 0.0, 0.0)
	spot_l.light_color = Color(0.9, 0.95, 1.0)
	spot_l.light_energy = 2.5
	spot_l.spot_range = 18.0
	spot_l.spot_angle = 38.0
	spot_l.spot_attenuation = 1.2
	fx_root.add_child(spot_l)
	spot_l.owner = car_root
	
	var spot_r = SpotLight3D.new()
	spot_r.name = "HeadlightSpotR"
	spot_r.position = Vector3(0.6, 0.45, 2.2)
	spot_r.rotation_degrees = Vector3(-5.0, 0.0, 0.0)
	spot_r.light_color = Color(0.9, 0.95, 1.0)
	spot_r.light_energy = 2.5
	spot_r.spot_range = 18.0
	spot_r.spot_angle = 38.0
	spot_r.spot_attenuation = 1.2
	fx_root.add_child(spot_r)
	spot_r.owner = car_root
	
	# Rear taillight glow (emissive red glow on ground and rear diffuser)
	var rear_glow = OmniLight3D.new()
	rear_glow.name = "RearTaillightGlow"
	rear_glow.position = Vector3(0.0, 0.45, -1.8)
	rear_glow.light_color = Color(1.0, 0.12, 0.08)
	rear_glow.light_energy = 2.8
	rear_glow.omni_range = 4.5
	rear_glow.omni_attenuation = 1.4
	fx_root.add_child(rear_glow)
	rear_glow.owner = car_root
	
	# Ground Contact Ambient Occlusion Shadow Plane (under car)
	var shadow_mesh = MeshInstance3D.new()
	shadow_mesh.name = "GroundShadow"
	var pmesh = PlaneMesh.new()
	pmesh.size = Vector2(2.4, 5.0)
	shadow_mesh.mesh = pmesh
	shadow_mesh.position = Vector3(0.0, 0.015, 0.4)
	
	var shadow_mat = StandardMaterial3D.new()
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.75)
	shadow_mat.roughness = 1.0
	shadow_mesh.material_override = shadow_mat
	fx_root.add_child(shadow_mesh)
	shadow_mesh.owner = car_root
	
	var packed = PackedScene.new()
	var err = packed.pack(car_root)
	if err == OK:
		ResourceSaver.save(packed, "res://scenes/vehicles/showcase_car.tscn")
		print("SUCCESS: Saved scenes/vehicles/showcase_car.tscn (File size is minimal, < 5 KB!)")
	else:
		print("ERROR packing showcase_car.tscn: ", err)
		
	car_root.free()
	quit(0)

