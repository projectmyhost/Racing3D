extends SceneTree

func _init() -> void:
	var car_ids = [
		"sedan", "compact", "hatchback", "coupe", "wagon",
		"minivan", "suv", "pickup", "offroad", "sport", "mclaren"
	]
	
	for cid in car_ids:
		var path = "res://assets/models/cars/car_" + cid + ".tscn"
		if not ResourceLoader.exists(path):
			print("File not found: ", path)
			continue
		var packed = load(path) as PackedScene
		if not packed:
			print("Failed loading: ", path)
			continue
		
		var root_node = packed.instantiate() as Node3D
		print("Processing car: ", cid)
		
		var meshes = root_node.find_children("*", "MeshInstance3D", true, false)
		for m in meshes:
			var mi = m as MeshInstance3D
			if not mi.mesh:
				continue
			var sc = mi.mesh.get_surface_count()
			for s in range(sc):
				var mat = mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var sm = mat as StandardMaterial3D
					var m_name = mi.name.to_lower()
					var r_name = sm.resource_name.to_lower()
					
					if cid == "mclaren":
						if r_name.contains("paint"):
							sm.albedo_color = Color(0.96, 0.38, 0.05, 1.0)
							sm.metallic = 0.85
							sm.roughness = 0.12
							sm.clearcoat_enabled = true
							sm.clearcoat = 1.0
							sm.clearcoat_roughness = 0.04
							sm.specular = 0.9
						elif r_name.contains("windowinside"):
							sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
							sm.albedo_color = Color(0.10, 0.14, 0.20, 0.12)
							sm.roughness = 0.03
							sm.metallic = 0.05
							sm.specular = 0.9
							sm.clearcoat_enabled = true
							sm.clearcoat = 1.0
							sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						elif r_name.contains("window") or r_name.contains("glass"):
							if r_name.contains("red"):
								sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
								sm.albedo_color = Color(0.9, 0.05, 0.05, 0.75)
								sm.roughness = 0.08
								sm.emission_enabled = true
								sm.emission = Color(0.8, 0.02, 0.02)
								sm.emission_energy_multiplier = 1.2
							else:
								sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
								sm.albedo_color = Color(0.12, 0.16, 0.22, 0.25)
								sm.roughness = 0.03
								sm.metallic = 0.1
								sm.specular = 0.95
								sm.clearcoat_enabled = true
								sm.clearcoat = 1.0
								sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						elif r_name.contains("carbon"):
							sm.metallic = 0.35
							sm.roughness = 0.25
							sm.specular = 0.6
						elif r_name.contains("wheel"):
							sm.metallic = 0.85
							sm.roughness = 0.22
							sm.specular = 0.85
						elif r_name.contains("light"):
							sm.roughness = 0.1
							sm.specular = 0.9
					else:
						if r_name.contains("body") or m_name.contains("body"):
							if not m_name.contains("glass") and not m_name.contains("optic") and not m_name.contains("wheel"):
								sm.metallic = 0.65
								sm.roughness = 0.14
								sm.clearcoat_enabled = true
								sm.clearcoat = 1.0
								sm.clearcoat_roughness = 0.05
								sm.specular = 0.85
						if r_name.contains("glass") or m_name.contains("glass"):
							sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
							sm.albedo_color = Color(0.10, 0.14, 0.20, 0.28)
							sm.roughness = 0.03
							sm.metallic = 0.15
							sm.specular = 0.95
							sm.clearcoat_enabled = true
							sm.clearcoat = 1.0
							sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						elif r_name.contains("wheel") or m_name.contains("wheel"):
							sm.metallic = 0.45
							sm.roughness = 0.32
							sm.specular = 0.75
						elif r_name.contains("optic") or m_name.contains("optic"):
							sm.roughness = 0.05
							sm.metallic = 0.2
							sm.specular = 0.9
							sm.emission_enabled = true
							sm.emission = Color(1.0, 1.0, 1.0)
							sm.emission_energy_multiplier = 0.4
					
					mi.mesh.surface_set_material(s, sm)
					if mi.get_surface_override_material_count() > s:
						mi.set_surface_override_material(s, sm)
		
		var re_packed = PackedScene.new()
		var pack_err = re_packed.pack(root_node)
		if pack_err == OK:
			var save_err = ResourceSaver.save(re_packed, path)
			if save_err == OK:
				print("Successfully updated and saved: ", path)
			else:
				print("Failed saving: ", path, " err: ", save_err)
		else:
			print("Failed packing: ", path, " err: ", pack_err)
		
		root_node.free()
	
	quit()

