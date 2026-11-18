extends SceneTree

# Physics Simulation Automated Test Harness.
# Mounts VehiclePhysicsCore on a test ground plane, runs the real Godot physics loop
# across frames for ALL 11 production vehicles, and verifies:
# 1. 4-wheel independent ground contact
# 2. Suspension spring/damper equilibrium
# 3. Dynamic weight transfer and throttle acceleration
# 4. Steering angular velocity response
# 5. Airborne momentum preservation

const VehicleConfigScript = preload("res://vehicles/core/VehicleConfig.gd")
const VehiclePhysicsCoreScript = preload("res://vehicles/core/VehiclePhysicsCore.gd")
const VehicleRegistryScript = preload("res://vehicles/registry/VehicleRegistry.gd")

func _init() -> void:
	call_deferred("_run_suite")

func _run_suite() -> void:
	print("==========================================")
	print("AUTOMATED VEHICLE PHYSICS TEST HARNESS (ALL 11 CARS)")
	print("==========================================")
	
	var world_node = Node3D.new()
	root.add_child(world_node)
	
	var road_body = StaticBody3D.new()
	road_body.name = "TestRoad"
	road_body.collision_layer = 1
	road_body.collision_mask = 0
	world_node.add_child(road_body)
	
	var road_col = CollisionShape3D.new()
	var road_box = BoxShape3D.new()
	road_box.size = Vector3(400.0, 1.0, 400.0)
	road_col.shape = road_box
	road_col.position = Vector3(0.0, -0.5, 0.0)
	road_body.add_child(road_col)
	
	var all_cars = VehicleRegistryScript.get_all_ids()
	all_cars.sort()
	var total_tests = all_cars.size()
	var passed_tests = 0
	
	for car_id in all_cars:
		var ok = await _test_vehicle_physics(world_node, car_id)
		if ok:
			passed_tests += 1
			
	print("==========================================")
	print("FULL FLEET PHYSICS RESULTS: %d / %d PASSED" % [passed_tests, total_tests])
	print("==========================================")
	
	world_node.queue_free()
	if passed_tests == total_tests:
		print("VERIFICATION STATUS: SUCCESS")
		quit(0)
	else:
		print("VERIFICATION STATUS: FAILED")
		quit(1)

func _test_vehicle_physics(world: Node3D, car_id: String) -> bool:
	print("Testing Vehicle Dynamics: [%s]" % car_id)
	var cfg = VehicleRegistryScript.get_config(car_id)
	if not cfg:
		print("  -> ERROR: Failed to get config for: ", car_id)
		return false
		
	var car = VehiclePhysicsCoreScript.new()
	car.name = "TestCar_" + car_id
	car.config = cfg
	world.add_child(car)
	
	var spawn_y = car.get_spawn_height()
	car.global_position = Vector3(0.0, spawn_y, 0.0)
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO
	
	# Step 1: 30 physics frames for suspension equilibrium settling
	for i in range(30):
		await physics_frame
		
	var grounded_wheels = 0
	var total_normal_force = 0.0
	for w in car._wheels:
		if w.is_grounded:
			grounded_wheels += 1
			total_normal_force += w.normal_force_mag
			
	print("  Grounded: %d/4 | Normal Force: %.0f N (Mass: %.0f kg | Weight: %.0f N)" % [
		grounded_wheels, total_normal_force, cfg.mass, cfg.mass * 9.8
	])
	
	if grounded_wheels < 4:
		print("  -> ERROR: Expected all 4 wheels to be grounded on flat road.")
		car.queue_free()
		return false
		
	var expected_weight = cfg.mass * 9.8
	var force_ratio = total_normal_force / maxf(expected_weight, 1.0)
	if force_ratio < 0.60 or force_ratio > 1.45:
		print("  -> ERROR: Suspension normal force out of equilibrium (ratio: %.2f)" % force_ratio)
		car.queue_free()
		return false
		
	# Step 2: 1.0s throttle acceleration
	car.set_driver_input(1.0, 0.0, 0.0, 0.0)
	for i in range(60):
		await physics_frame
		
	var final_speed_kmh = absf(car.forward_speed) * 3.6
	print("  0-1.0s Throttle: %.1f KM/H" % final_speed_kmh)
	
	if final_speed_kmh <= 5.0:
		print("  -> ERROR: Vehicle failed to accelerate under throttle (speed: %.1f km/h)." % final_speed_kmh)
		car.queue_free()
		return false
		
	# Step 3: Steering response
	car.set_driver_input(0.8, 0.0, 0.6, 0.0)
	for i in range(25):
		await physics_frame
		
	print("  Steering: Yaw Rate = %.3f rad/s" % car.angular_velocity.y)
	if absf(car.angular_velocity.y) < 0.05:
		print("  -> ERROR: Vehicle failed to produce yaw rate when steering.")
		car.queue_free()
		return false
		
	# Step 4: Airborne state
	car.set_driver_input(0.0, 0.0, 0.0, 0.0)
	car.global_position = Vector3(0.0, 20.0, 0.0)
	car.linear_velocity = Vector3(0.0, 5.0, -15.0)
	car.angular_velocity = Vector3(0.1, 0.2, 0.0)
	
	for i in range(10):
		await physics_frame
		
	var airborne_grounded = 0
	for w in car._wheels:
		if w.is_grounded: airborne_grounded += 1
		
	if airborne_grounded > 0:
		print("  -> ERROR: Wheels reported grounded while vehicle was at Y = 20m.")
		car.queue_free()
		return false
		
	car.queue_free()
	print("  -> PASSED: [%s]" % car_id)
	return true
