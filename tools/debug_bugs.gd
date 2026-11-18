@tool
extends SceneTree

func _init():
	print("--- DEBUGGING CAR GROUND & HOUSE CLIPPING ---")
	
	# 1. Car wheels and ground
	var glb = load("res://assets/models/cars/italia.glb") as PackedScene
	var inst = glb.instantiate()
	var mesh_inst: MeshInstance3D = null
	if inst is MeshInstance3D:
		mesh_inst = inst
	else:
		for c in inst.get_children():
			if c is MeshInstance3D:
				mesh_inst = c
				break
	
	var car_aabb = mesh_inst.mesh.get_aabb()
	print("Car Body AABB: min_y=", car_aabb.position.y, " max_y=", car_aabb.end.y)
	
	# Find lowest vertex across all wheels
	var lowest_wheel_y = 999.0
	for c in mesh_inst.get_children():
		if c is MeshInstance3D and c.mesh:
			var w_aabb = c.mesh.get_aabb()
			var global_w_bottom = c.position.y + w_aabb.position.y
			print("Wheel ", c.name, " local pos: ", c.position, " aabb: ", w_aabb, " bottom_y: ", global_w_bottom)
			lowest_wheel_y = minf(lowest_wheel_y, global_w_bottom)
	print("LOWEST WHEEL Y in italia.glb: ", lowest_wheel_y)
	
	# 2. Road1.glb dimensions and X span
	var road_p = load("res://assets/models/roads/Road1.glb") as PackedScene
	var r_inst = road_p.instantiate()
	var r_mesh: MeshInstance3D = null
	for c in r_inst.get_children():
		if c is MeshInstance3D:
			r_mesh = c
			break
	var r_aabb = r_mesh.mesh.get_aabb()
	print("Road1 AABB: min=", r_aabb.position, " max=", r_aabb.end)

	# 3. Check house positions and bounds in showcase_stage.tscn
	var stage_p = load("res://scenes/environment/showcase_stage.tscn") as PackedScene
	var stage = stage_p.instantiate()
	for c in stage.get_children():
		if c is MeshInstance3D and ("Building" in c.name or "House" in c.name):
			var h_aabb = c.mesh.get_aabb()
			var world_min_x = c.position.x + h_aabb.position.x * c.scale.x
			var world_max_x = c.position.x + h_aabb.end.x * c.scale.x
			var world_min_z = c.position.z + h_aabb.position.z * c.scale.z
			var world_max_z = c.position.z + h_aabb.end.z * c.scale.z
			print("House: ", c.name, " pos=", c.position, " scale=", c.scale, " X_span=[", world_min_x, " .. ", world_max_x, "] Z_span=[", world_min_z, " .. ", world_max_z, "]")

	quit(0)

