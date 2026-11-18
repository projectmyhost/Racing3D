@tool
extends SceneTree

func _init():
	measure_car("kia_carnival", "res://assets/models/cars/car_kia_carnival.tscn")
	measure_car("porsche_carrera_gt", "res://assets/models/cars/car_porsche_carrera_gt.tscn")
	quit(0)

func measure_car(car_id: String, path: String):
	print("\n================ MEASURE CAR: ", car_id, " ================")
	var scene = load(path)
	var inst = scene.instantiate() as Node3D
	root.add_child(inst)
	
	var aabb = AABB()
	var first = true
	var meshes = inst.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi = m as MeshInstance3D
		if not mi.mesh:
			continue
		var m_aabb = mi.mesh.get_aabb()
		var xform = inst.global_transform.affine_inverse() * mi.global_transform
		var transformed_aabb = xform * m_aabb
		if first:
			aabb = transformed_aabb
			first = false
		else:
			aabb = aabb.merge(transformed_aabb)
	
	print("Total visual AABB in car local space: ", aabb)
	print("Size (X, Y, Z): ", aabb.size)
	print("Center (X, Y, Z): ", aabb.get_center())
	
	# Look for front/rear specific nodes or meshes
	for child in inst.find_children("*", "Node3D", true, false):
		var c_name = child.name.to_lower()
		var p_name = child.get_parent().name.to_lower()
		if "head" in c_name or "front" in c_name or "tail" in c_name or "rear" in c_name or "grille" in c_name or "exhaust" in c_name or "bumper" in c_name:
			var lp = inst.to_local(child.global_position)
			print("  Node: ", child.name, " (parent: ", child.get_parent().name, ") -> car local pos: ", lp)
			
	inst.queue_free()
