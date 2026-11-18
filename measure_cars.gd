@tool
extends SceneTree

func _init():
	measure_car("sedan", "res://assets/models/cars/car_sedan.tscn")
	measure_car("kia_carnival", "res://assets/models/cars/car_kia_carnival.tscn")
	measure_car("porsche_carrera_gt", "res://assets/models/cars/car_porsche_carrera_gt.tscn")
	quit(0)

func measure_car(car_id: String, path: String):
	print("\n================ MEASURE CAR: ", car_id, " ================")
	var scene = load(path)
	var inst = scene.instantiate() as Node3D
	
	# Calculate total AABB in inst local space
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
	
	print("Total visual AABB: ", aabb)
	print("Size (X, Y, Z): ", aabb.size)
	print("Center (X, Y, Z): ", aabb.get_center())
	print("Min: ", aabb.position, " Max: ", aabb.end)
	
	# Check where headlights and taillights or front/back features are
	for m in meshes:
		var mi = m as MeshInstance3D
		var nm = mi.name.to_lower()
		var pnm = mi.get_parent().name.to_lower()
		if "headlight" in nm or "headlight" in pnm or "head" in nm or "faro" in nm:
			var lp = inst.to_local(mi.global_position)
			print("  Headlight/Front feature: ", mi.name, " local pos: ", lp)
		elif "taillight" in nm or "taillight" in pnm or "tail" in nm or "rear" in nm:
			var lp = inst.to_local(mi.global_position)
			print("  Taillight/Rear feature: ", mi.name, " local pos: ", lp)
			
	inst.free()
