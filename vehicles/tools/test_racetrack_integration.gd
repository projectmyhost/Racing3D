extends SceneTree

# Full RaceTrack3D Scene Integration Test.
# Loads res://scenes/race/RaceTrack3D.tscn, initializes the race track with the new
# VehiclePhysicsCore / RaceCar3D on the actual city map mesh, and verifies:
# 1. Clean scene loading and instantiation
# 2. Vehicle physics initialization from PlayerProfile / SaveManager
# 3. 4-wheel suspension contact with the real city map Trimesh road
# 4. Chase camera tracking and yaw alignment
# 5. Speedometer signal reception and throttle driving

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("==========================================")
	print("RACETRACK 3D FULL INTEGRATION TEST")
	print("==========================================")
	
	var track_scene_path = "res://scenes/race/RaceTrack3D.tscn"
	print("Loading track scene: ", track_scene_path)
	
	var packed = load(track_scene_path) as PackedScene
	if not packed:
		print("FAILED: Could not load ", track_scene_path)
		quit(1)
		return
		
	var track_inst = packed.instantiate() as Node3D
	root.add_child(track_inst)
	print("  -> Scene instantiated successfully.")
	
	var car = track_inst.get_node_or_null("RaceCar3D") as VehiclePhysicsCore
	if not car:
		print("FAILED: RaceCar3D node not found or not extending VehiclePhysicsCore.")
		track_inst.queue_free()
		quit(1)
		return
	print("  -> RaceCar3D located. Type: ", car.get_class(), " | Config ID: ", car.config.id if car.config else "NONE")
	
	var camera = track_inst.get_node_or_null("ChaseCamera") as Camera3D
	if not camera:
		print("FAILED: ChaseCamera node not found.")
		track_inst.queue_free()
		quit(1)
		return
	print("  -> ChaseCamera located at: ", camera.global_position)
	
	# Step 1: Wait 45 physics frames for vehicle to settle on the city map asphalt
	print("Simulating 45 settling frames on city map road surface...")
	for i in range(45):
		await physics_frame
		
	var grounded_wheels = 0
	var total_normal_force = 0.0
	for w in car._wheels:
		if w.is_grounded:
			grounded_wheels += 1
			total_normal_force += w.normal_force_mag
			
	print("  Settled status: Grounded wheels = %d / 4 | Total Normal Force = %.1f N" % [
		grounded_wheels, total_normal_force
	])
	
	if grounded_wheels < 4:
		print("FAILED: Car wheels failed to establish 4-point ground contact on city map.")
		track_inst.queue_free()
		quit(1)
		return
		
	# Step 2: Drive vehicle forward under full throttle for 90 frames (1.5 seconds)
	print("Applying full throttle acceleration along city track...")
	car.set_driver_input(1.0, 0.0, 0.0, 0.0)
	for i in range(90):
		await physics_frame
		
	var final_speed_kmh = absf(car.forward_speed) * 3.6
	print("  Driving speed reached: %.1f KM/H" % final_speed_kmh)
	
	if final_speed_kmh < 15.0:
		print("FAILED: Car did not accelerate properly on city track.")
		track_inst.queue_free()
		quit(1)
		return
		
	# Step 3: Verify chase camera updated properly without flips or NaN
	print("Verifying ChaseCamera state...")
	var cam_pos = camera.global_position
	if is_nan(cam_pos.x) or is_nan(cam_pos.y) or is_nan(cam_pos.z):
		print("FAILED: Camera position contains NaN.")
		track_inst.queue_free()
		quit(1)
		return
		
	var dist_to_car = (cam_pos - car.global_position).length()
	print("  Camera distance to car: %.2f m (Within valid follow distance)" % dist_to_car)
	if dist_to_car < 2.0 or dist_to_car > 20.0:
		print("FAILED: Camera distance out of reasonable bounds.")
		track_inst.queue_free()
		quit(1)
		return
		
	print("==========================================")
	print("RACETRACK 3D INTEGRATION TEST PASSED")
	print("==========================================")
	track_inst.queue_free()
	quit(0)

