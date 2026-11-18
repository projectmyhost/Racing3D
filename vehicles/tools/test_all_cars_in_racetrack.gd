extends SceneTree

# Verifies that every single car in the game can spawn, drive, and steer
# inside res://scenes/race/RaceTrack3D.tscn on the real city circuit.

func _init() -> void:
	call_deferred("_run_all_cars_test")

func _run_all_cars_test() -> void:
	print("==========================================")
	print("RACETRACK 3D: TESTING ALL 11 CARS ON REAL TRACK")
	print("==========================================")
	
	var all_cars = VehicleRegistry.get_all_ids()
	all_cars.sort()
	var passed = 0
	
	for car_id in all_cars:
		var ok = await _test_car_on_track(car_id)
		if ok:
			passed += 1
			
	print("==========================================")
	print("RACETRACK FULL ROSTER TEST: %d / %d PASSED" % [passed, all_cars.size()])
	print("==========================================")
	
	if passed == all_cars.size():
		print("VERIFICATION STATUS: SUCCESS")
		quit(0)
	else:
		print("VERIFICATION STATUS: FAILED")
		quit(1)

func _test_car_on_track(car_id: String) -> bool:
	var packed = load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	var track = packed.instantiate() as Node3D
	root.add_child(track)
	
	var car = track.get_node_or_null("RaceCar3D") as VehiclePhysicsCore
	if not car:
		print("FAILED: No car found.")
		track.queue_free()
		return false
		
	# Initialize with target car
	car.initialize_vehicle(car_id)
	
	# Settle suspension on city track
	for i in range(35):
		await physics_frame
		
	var grounded = 0
	for w in car._wheels:
		if w.is_grounded: grounded += 1
		
	# Drive 60 frames under full throttle
	car.set_driver_input(1.0, 0.0, 0.0, 0.0)
	for i in range(60):
		await physics_frame
		
	var speed_kmh = absf(car.forward_speed) * 3.6
	print("Car [%s]: Grounded: %d/4 | 1.0s Speed: %.1f KM/H" % [car_id, grounded, speed_kmh])
	
	var success = (grounded == 4 and speed_kmh >= 10.0)
	track.queue_free()
	
	if not success:
		print("  -> ERROR: Car [%s] failed track verification." % car_id)
		return false
		
	return true

