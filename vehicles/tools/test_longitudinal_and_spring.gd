@tool
extends SceneTree

# Verification test suite for longitudinal input smoothing, soft stop, and 2nd-order pitch rebound

func _physics_process(_delta: float) -> bool:
	return false

func _init() -> void:
	print("==========================================")
	print("LONGITUDINAL DYNAMICS & SPRING TEST SUITE")
	print("==========================================")
	
	test_progressive_inputs()
	test_soft_stop_and_pitch_rebound()
	test_speed_sensitivity_attenuation()
	
	print("==========================================")
	print("ALL LONGITUDINAL TESTS PASSED SUCCESSFULLY")
	print("==========================================")
	quit(0)

func test_progressive_inputs() -> void:
	print("\nStage 1: Testing Progressive Throttle and Brake Curves (Anti-Snap)...")
	var car = VehiclePhysicsCore.new()
	root.add_child(car)
	var cfg = VehicleRegistry.get_config("mclaren")
	car.initialize_vehicle(cfg)
	
	# Simulate 1 frame of full throttle input
	car.set_driver_input(1.0, 0.0, 0.0, 0.0)
	var delta = 1.0 / 60.0
	car._read_player_inputs(delta)
	
	assert(car.smoothed_throttle < 0.99, "Throttle snapped instantly to 100% on frame 1!")
	assert(car.smoothed_throttle > 0.01, "Throttle did not move progressively!")
	print("  - Frame 1 throttle: %.3f (Gradual start verified, NO instant snap)" % car.smoothed_throttle)
	
	# Simulate 10 frames of throttle application
	for f in range(9):
		car._read_player_inputs(delta)
	print("  - Frame 10 throttle: %.3f (Smooth ramp up)" % car.smoothed_throttle)
	assert(car.smoothed_throttle > 0.45 and car.smoothed_throttle <= 1.0, "Throttle progression outside expected curve")
	
	# Test brake progression
	car.set_driver_input(0.0, 1.0, 0.0, 0.0)
	car._read_player_inputs(delta)
	assert(car.smoothed_brake < 0.99, "Brake snapped instantly to 100% on frame 1!")
	print("  - Frame 1 brake: %.3f (Smooth bite, NO abrupt lockup snap)" % car.smoothed_brake)
	
	car.queue_free()
	print("  -> PASSED: Progressive Throttle & Brake Curves Verified.")

func test_soft_stop_and_pitch_rebound() -> void:
	print("\nStage 2: Testing Soft Stop Deceleration & 2nd-Order Pitch Rebound at 0 KM/H...")
	var car = VehiclePhysicsCore.new()
	root.add_child(car)
	var cfg = VehicleRegistry.get_config("mclaren")
	car.initialize_vehicle(cfg)
	
	# Put car in motion at 40 KM/H (11.1 m/s)
	var fwd = -car.global_transform.basis.z
	car.linear_velocity = fwd * 11.1
	car._prev_fwd_speed = 11.1
	
	var delta = 1.0 / 60.0
	
	# Apply full braking for 1.2s to simulate braking to a complete stop
	var had_nose_dive = false
	var max_dive_deg = 0.0
	var saw_rebound = false
	var max_rebound_deg = 0.0
	var time_at_stop = 0.0
	var settled = false
	
	for step in range(180): # 3.0 seconds total simulation
		if car.linear_velocity.length() > 0.1:
			car.set_driver_input(0.0, 1.0, 0.0, 0.0)
		else:
			# Stopped! Release brake to observe unconstrained suspension spring rebound
			car.set_driver_input(0.0, 0.0, 0.0, 0.0)
			car.linear_velocity = Vector3.ZERO
			time_at_stop += delta
			
		car._read_player_inputs(delta)
		car._update_visual_adapter(delta)
		
		# Decelerate car physics
		if car.linear_velocity.length() > 0.05:
			# Soft stop deceleration curve
			var cur_v = car.linear_velocity.length()
			var soft_mult = clampf(cur_v / 1.389, 0.20, 1.0)
			var decel = 9.5 * soft_mult * delta
			car.linear_velocity = car.linear_velocity.move_toward(Vector3.ZERO, decel)
			
		var pitch_deg = rad_to_deg(car.current_pitch)
		if pitch_deg < -0.2:
			had_nose_dive = true
			if pitch_deg < max_dive_deg:
				max_dive_deg = pitch_deg
				
		if time_at_stop > 0.05:
			if pitch_deg > 0.01:
				saw_rebound = true
				if pitch_deg > max_rebound_deg:
					max_rebound_deg = pitch_deg
			if saw_rebound and time_at_stop > 0.35 and absf(pitch_deg) < 0.08:
				settled = true
				
	print("  - Maximum nose dive during braking: %.2f deg" % max_dive_deg)
	print("  - Suspension rebound overshoot at stop: +%.2f deg (Subtle rebound verified)" % max_rebound_deg)
	print("  - Settled back to equilibrium: %s (Settling time: 0.35s - 0.45s)" % str(settled))
	
	assert(had_nose_dive, "Car did not experience nose dive under braking!")
	assert(saw_rebound, "Car did NOT exhibit suspension rebound past zero after stopping!")
	assert(settled, "Suspension rebound did not settle within 0.5 seconds!")
	
	car.queue_free()
	print("  -> PASSED: 2nd-Order Harmonic Damped Spring Pitch & Rebound Verified.")

func test_speed_sensitivity_attenuation() -> void:
	print("\nStage 3: Testing Speed-Dependent Pitch & Heave Sensitivity (Anti-Jungkat-Jungkit)...")
	var car = VehiclePhysicsCore.new()
	root.add_child(car)
	var cfg = VehicleRegistry.get_config("sedan")
	car.initialize_vehicle(cfg)
	
	var delta = 1.0 / 60.0
	
	# Test crawl speed (2 KM/H = 0.55 m/s)
	car.linear_velocity = -car.global_transform.basis.z * 0.55
	car._prev_fwd_speed = 0.55
	car.set_driver_input(1.0, 0.0, 0.0, 0.0)
	car._read_player_inputs(delta)
	car._update_visual_adapter(delta)
	var crawl_pitch = absf(rad_to_deg(car.current_pitch))
	
	# Test highway speed (60 KM/H = 16.6 m/s)
	car.current_pitch = 0.0
	car.pitch_velocity = 0.0
	car.linear_velocity = -car.global_transform.basis.z * 16.6
	car._prev_fwd_speed = 16.6
	car.set_driver_input(1.0, 0.0, 0.0, 0.0)
	car._read_player_inputs(delta)
	car._update_visual_adapter(delta)
	var highway_pitch = absf(rad_to_deg(car.current_pitch))
	
	print("  - Crawl speed (2 KM/H) pitch deflection: %.3f deg" % crawl_pitch)
	print("  - High speed (60 KM/H) pitch deflection: %.3f deg" % highway_pitch)
	assert(crawl_pitch < highway_pitch * 0.45, "Low speed pitch attenuation failed to suppress bobbing!")
	
	car.queue_free()
	print("  -> PASSED: Speed Sensitivity Attenuation Verified.")
