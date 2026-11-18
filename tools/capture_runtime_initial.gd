extends SceneTree

func _init() -> void:
	var vp = get_root()
	var scene = load("res://scenes/main/home_screen.tscn").instantiate()
	vp.add_child(scene)
	
	var car = scene.find_child("ShowcaseCar", true, false)
	if car:
		print("ShowcaseCar found. Model loaded: ", car.current_model)
		var meshes = car.find_children("*", "MeshInstance3D", true, false)
		print("Number of meshes in ShowcaseCar: ", meshes.size())
		for m in meshes:
			var mi = m as MeshInstance3D
			var sc = 0
			if mi.mesh:
				sc = mi.mesh.get_surface_count()
			for s in range(sc):
				var mat = mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var sm = mat as StandardMaterial3D
					if mi.name.to_lower().contains("paint") or mi.name.to_lower().contains("window") or mi.name.to_lower().contains("body"):
						print("Runtime Active Mat: ", mi.name, " [s:", s, "] name: ", sm.resource_name, " alb:", sm.albedo_color, " met:", sm.metallic, " rough:", sm.roughness, " transp:", sm.transparency, " clearcoat:", sm.clearcoat_enabled)
	
	for i in range(15):
		await process_frame
	
	var img = vp.get_texture().get_image()
	img.save_png("docs/validation/runtime_check_initial.png")
	print("Saved docs/validation/runtime_check_initial.png")
	quit()
