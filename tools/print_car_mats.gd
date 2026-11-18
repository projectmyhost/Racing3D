extends SceneTree

func _init() -> void:
	var car_names = [
		"sedan", "compact", "hatchback", "coupe", "wagon",
		"minivan", "suv", "pickup", "offroad", "sport", "mclaren"
	]
	
	for car_id in car_names:
		var path = "res://assets/models/cars/car_" + car_id + ".tscn"
		var packed = load(path) as PackedScene
		if not packed:
			continue
		var inst = packed.instantiate() as Node3D
		print("---------------------------------------------")
		print("CAR: ", car_id)
		var meshes = inst.find_children("*", "MeshInstance3D", true, false)
		for m in meshes:
			var mi = m as MeshInstance3D
			var sc = 0
			if mi.mesh:
				sc = mi.mesh.get_surface_count()
			for s in range(sc):
				var mat = mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var sm = mat as StandardMaterial3D
					var tex = sm.albedo_texture.resource_path.get_file() if sm.albedo_texture else "none"
					print("  Node: ", mi.name, " [surf ", s, "] Mat: ", sm.resource_name, 
						" | Col: ", sm.albedo_color, 
						" | Tex: ", tex, 
						" | Met: ", sm.metallic, 
						" | Rough: ", sm.roughness, 
						" | Clearcoat: ", sm.clearcoat_enabled, 
						" | Transp: ", sm.transparency)
		inst.free()
	quit()

