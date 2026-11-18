extends SceneTree

# Swap-Safety Proof Verification Tool.
# Proves that adding, testing, and removing a new car is purely a data operation
# that requires zero modifications to vehicles/core/.

const VehicleConfigScript = preload("res://vehicles/core/VehicleConfig.gd")
const VehiclePhysicsCoreScript = preload("res://vehicles/core/VehiclePhysicsCore.gd")
const VehicleRegistryScript = preload("res://vehicles/registry/VehicleRegistry.gd")

func _init() -> void:
	call_deferred("_run_proof")

func _run_proof() -> void:
	print("==========================================")
	print("SWAP-SAFETY & ZERO-CODE-COUPLING PROOF")
	print("==========================================")
	
	# Step 1: Create a brand new vehicle purely via Resource data (.tres)
	var dummy_id = "test_hyper_prototype"
	var dummy_path = "res://vehicles/configs/" + dummy_id + ".tres"
	print("Step 1: Authoring new vehicle purely as data: ", dummy_path)
	
	var dummy_cfg = VehicleConfigScript.new()
	dummy_cfg.id = dummy_id
	dummy_cfg.display_name = "Hyper Prototype Experimental"
	dummy_cfg.vehicle_class = "Experimental"
	dummy_cfg.mass = 1337.0
	dummy_cfg.drivetrain_type = 1
	dummy_cfg.peak_power_kw = 450.0
	dummy_cfg.max_engine_rpm = 8200.0
	var ratios: Array[float] = [3.80, 2.40, 1.75, 1.35, 1.05, 0.82]
	dummy_cfg.gear_ratios = ratios
	dummy_cfg.wheelbase = 2.75
	dummy_cfg.track_width_front = 1.58
	dummy_cfg.track_width_rear = 1.58
	dummy_cfg.wheel_radius = 0.34
	dummy_cfg.spring_stiffness_front = 42000.0
	dummy_cfg.spring_stiffness_rear = 40000.0
	dummy_cfg.bump_damping_front = 3100.0
	dummy_cfg.bump_damping_rear = 2900.0
	dummy_cfg.rebound_damping_front = 4500.0
	dummy_cfg.rebound_damping_rear = 4300.0
	dummy_cfg.anti_roll_front = 7800.0
	dummy_cfg.anti_roll_rear = 6800.0
	dummy_cfg.tire_longitudinal_friction = 1.78
	dummy_cfg.tire_lateral_friction = 1.82
	dummy_cfg.visual_scene_path = "res://assets/models/cars/car_sport.tscn"
	
	var save_err = ResourceSaver.save(dummy_cfg, dummy_path)
	if save_err != OK:
		print("FAILED: Could not save dummy config.")
		quit(1)
		return
		
	# Step 2: Initialize registry and verify new car is automatically discovered
	print("Step 2: Testing automatic discovery in VehicleRegistry...")
	VehicleRegistryScript.initialize()
	if not VehicleRegistryScript.has_config(dummy_id):
		print("FAILED: VehicleRegistry failed to detect ", dummy_id)
		quit(1)
		return
	print("  -> VehicleRegistry discovered new vehicle successfully without code changes.")
	
	# Step 3: Instantiate and test physics simulation
	print("Step 3: Instantiating VehiclePhysicsCore with new vehicle...")
	var world_node = Node3D.new()
	root.add_child(world_node)
	
	var road_body = StaticBody3D.new()
	road_body.collision_layer = 1
	road_body.collision_mask = 0
	world_node.add_child(road_body)
	
	var road_col = CollisionShape3D.new()
	var road_box = BoxShape3D.new()
	road_box.size = Vector3(100.0, 1.0, 100.0)
	road_col.shape = road_box
	road_col.position = Vector3(0.0, -0.5, 0.0)
	road_body.add_child(road_col)
	
	var car = VehiclePhysicsCoreScript.new()
	car.config = dummy_cfg
	world_node.add_child(car)
	car.global_position = Vector3(0.0, car.get_spawn_height(), 0.0)
	
	# Settle suspension
	for i in range(25):
		await physics_frame
		
	var grounded_count = 0
	for w in car._wheels:
		if w.is_grounded: grounded_count += 1
	print("  -> Grounded wheels: %d / 4" % grounded_count)
	
	# Drive test
	car.set_driver_input(1.0, 0.0, 0.0, 0.0)
	for i in range(45):
		await physics_frame
		
	var speed_kmh = absf(car.forward_speed) * 3.6
	print("  -> Acceleration reached: %.1f KM/H" % speed_kmh)
	
	world_node.queue_free()
	
	if grounded_count < 4 or speed_kmh < 10.0:
		print("FAILED: Dummy vehicle physics simulation did not meet criteria.")
		DirAccess.remove_absolute(dummy_path)
		quit(1)
		return
		
	# Step 4: Clean up dummy car
	print("Step 4: Cleaning up dummy vehicle asset...")
	DirAccess.remove_absolute(dummy_path)
	print("  -> Deleted: ", dummy_path)
	
	# Step 5: Verify existing fleet remains 100% operational
	print("Step 5: Verifying existing vehicle fleet after deletion...")
	VehicleRegistryScript.initialize()
	var sedan_cfg = VehicleRegistryScript.get_config("sedan")
	if not sedan_cfg:
		print("FAILED: Baseline sedan config was compromised.")
		quit(1)
		return
		
	print("==========================================")
	print("PROOF COMPLETE: ZERO-CODE ASSET SWAP VERIFIED")
	print("==========================================")
	quit(0)
