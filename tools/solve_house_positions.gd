@tool
extends SceneTree

func _init():
	print("--- SOLVING EXACT HOUSE POSITIONS WITH ZERO ROAD CLIPPING ---")
	
	# Sidewalk ends at X = +6.0 (right) and X = -6.0 (left)
	# Safe building front line: X = +6.8m (right) and X = -6.8m (left)
	
	var right_houses = [
		{"name": "Building1_Large", "mesh": "Building1_Large.obj", "z": -14.0, "scale": 1.7, "rot_y": 0.0},
		{"name": "House1", "mesh": "House1.obj", "z": -2.0, "scale": 2.0, "rot_y": -90.0},
		{"name": "Building2_Large", "mesh": "Building2_Large.obj", "z": 10.0, "scale": 1.6, "rot_y": 0.0},
		{"name": "House2", "mesh": "House2.obj", "z": 22.0, "scale": 2.0, "rot_y": -90.0}
	]

	print("\n--- RIGHT HOUSES ---")
	for h in right_houses:
		var m_path = "res://assets/models/buildings/OBJ/" + h["mesh"]
		var mesh = load(m_path) as Mesh
		var aabb = mesh.get_aabb()
		var s = h["scale"]
		var rot = h["rot_y"]
		
		# Compute rotated bounding box
		var rad = deg_to_rad(rot)
		# Corners of AABB in local space
		var min_local_x = 999.0
		var max_local_x = -999.0
		for cx in [aabb.position.x, aabb.end.x]:
			for cz in [aabb.position.z, aabb.end.z]:
				var rx = cx * cos(rad) - cz * sin(rad)
				min_local_x = minf(min_local_x, rx * s)
				max_local_x = maxf(max_local_x, rx * s)
				
		# We want the front of the house to be at X >= 6.8m
		# So (target_pos_x + min_local_x) = 6.8 -> target_pos_x = 6.8 - min_local_x
		var safe_pos_x = 6.8 - min_local_x
		print("House ", h["name"], " (rot=", rot, "): min_local_x=", min_local_x, " -> Safe Pos X = ", safe_pos_x, " (Front will be at ", safe_pos_x + min_local_x, "m)")

	var left_houses = [
		{"name": "Building3_Big", "mesh": "Building3_Big.obj", "z": -12.0, "scale": 1.7, "rot_y": 180.0},
		{"name": "Building4", "mesh": "Building4.obj", "z": 4.0, "scale": 1.7, "rot_y": 180.0},
		{"name": "Building1_Small", "mesh": "Building1_Small.obj", "z": 18.0, "scale": 1.8, "rot_y": 180.0}
	]

	print("\n--- LEFT HOUSES ---")
	for h in left_houses:
		var m_path = "res://assets/models/buildings/OBJ/" + h["mesh"]
		var mesh = load(m_path) as Mesh
		var aabb = mesh.get_aabb()
		var s = h["scale"]
		var rot = h["rot_y"]
		
		var rad = deg_to_rad(rot)
		var min_local_x = 999.0
		var max_local_x = -999.0
		for cx in [aabb.position.x, aabb.end.x]:
			for cz in [aabb.position.z, aabb.end.z]:
				var rx = cx * cos(rad) - cz * sin(rad)
				min_local_x = minf(min_local_x, rx * s)
				max_local_x = maxf(max_local_x, rx * s)
				
		# We want the front of the left house to be at X <= -6.8m
		# So (target_pos_x + max_local_x) = -6.8 -> target_pos_x = -6.8 - max_local_x
		var safe_pos_x = -6.8 - max_local_x
		print("House ", h["name"], " (rot=", rot, "): max_local_x=", max_local_x, " -> Safe Pos X = ", safe_pos_x, " (Front will be at ", safe_pos_x + max_local_x, "m)")

	quit(0)

