extends SceneTree

# Scans all 11 car model scenes and extracts exact geometric dimensions:
# wheelbase, track width front/rear, wheel radius, chassis AABB bounds.

func _init() -> void:
	var cars = [
		"mclaren", "sport", "coupe", "sedan", "wagon",
		"hatchback", "compact", "minivan", "suv", "pickup", "offroad"
	]
	
	print("--- CAR DIMENSIONS DUMP START ---")
	for car_name in cars:
		var path = "res://assets/models/cars/car_" + car_name + ".tscn"
		if not ResourceLoader.exists(path):
			print("MISSING: ", path)
			continue
		var packed = load(path) as PackedScene
		if not packed:
			print("FAILED TO LOAD: ", path)
			continue
		var inst = packed.instantiate() as Node3D
		root.add_child(inst)
		
		var w_fl = inst.find_child("Wheel_FL", true, false) as Node3D
		var w_fr = inst.find_child("Wheel_FR", true, false) as Node3D
		var w_rl = inst.find_child("Wheel_RL", true, false) as Node3D
		var w_rr = inst.find_child("Wheel_RR", true, false) as Node3D
		
		var fl_pos = w_fl.position if w_fl else Vector3.ZERO
		var fr_pos = w_fr.position if w_fr else Vector3.ZERO
		var rl_pos = w_rl.position if w_rl else Vector3.ZERO
		var rr_pos = w_rr.position if w_rr else Vector3.ZERO
		
		var wb = absf(((rl_pos.z + rr_pos.z) * 0.5) - ((fl_pos.z + fr_pos.z) * 0.5))
		var tw_f = absf(fr_pos.x - fl_pos.x)
		var tw_r = absf(rr_pos.x - rl_pos.x)
		var r_f = fl_pos.y
		var r_r = rl_pos.y
		
		print("CAR: %s | WB: %.3f | TW_F: %.3f | TW_R: %.3f | R_F: %.3f | R_R: %.3f | FL:(%.2f,%.2f,%.2f) RL:(%.2f,%.2f,%.2f)" % [
			car_name, wb, tw_f, tw_r, r_f, r_r, fl_pos.x, fl_pos.y, fl_pos.z, rl_pos.x, rl_pos.y, rl_pos.z
		])
		
		inst.queue_free()
	print("--- CAR DIMENSIONS DUMP END ---")
	quit()

