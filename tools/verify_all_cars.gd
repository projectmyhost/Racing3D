extends SceneTree

func _init() -> void:
	var car_ids = [
		"sedan", "compact", "hatchback", "coupe", "wagon",
		"minivan", "suv", "pickup", "offroad", "sport", "mclaren"
	]
	var ok_count = 0
	for cid in car_ids:
		var path = "res://assets/models/cars/car_" + cid + ".tscn"
		var packed = ResourceLoader.load(path) as PackedScene
		if not packed:
			print("FAIL: Cannot load ", path)
			continue
		var inst = packed.instantiate()
		if not inst:
			print("FAIL: Cannot instantiate ", path)
			continue
		var meshes = inst.find_children("*", "MeshInstance3D", true, false)
		print("OK: ", cid, " -> meshes found: ", meshes.size())
		inst.free()
		ok_count += 1
	print("Summary: ", ok_count, "/", car_ids.size(), " loaded successfully.")
	quit()

