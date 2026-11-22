extends SceneTree

func _init() -> void:
	var enhancer := load("res://vehicles/core/VehicleMaterialEnhancer.gd")
	var seltos := (load("res://assets/models/cars/car_kia_seltos.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(seltos)
	enhancer.enhance_vehicle_materials("kia_seltos", seltos, Color.WHITE)
	var interior_shadow_off := 0
	var exterior_shadow_on := 0
	for n in seltos.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var nm := mi.name.to_lower()
		if nm.contains("seat"):
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				printerr("FAIL: Seat mesh '%s' still casts shadows" % mi.name)
				seltos.free()
				quit(1)
				return
			if mi.visibility_range_end < 85.0:
				printerr("FAIL: Closed cabin interior '%s' missing visibility_range_end >= 85m (got %.1f)" % [mi.name, mi.visibility_range_end])
				seltos.free()
				quit(1)
				return
			interior_shadow_off += 1
		elif nm.contains("carpaint"):
			if mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				printerr("FAIL: Body shell '%s' must keep shadows enabled" % mi.name)
				seltos.free()
				quit(1)
				return
			if mi.visibility_range_end != 0.0:
				printerr("FAIL: Body shell '%s' must never cull" % mi.name)
				seltos.free()
				quit(1)
				return
			exterior_shadow_on += 1
	if interior_shadow_off <= 0 or exterior_shadow_on <= 0:
		printerr("FAIL: Counts invalid (interior=%d exterior=%d)" % [interior_shadow_off, exterior_shadow_on])
		seltos.free()
		quit(1)
		return
	print("PASS: interior_shadow_off=%d exterior_shadow_on=%d" % [interior_shadow_off, exterior_shadow_on])
	seltos.free()
	quit(0)
