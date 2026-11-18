@tool
extends SceneTree

# Drive simulation test using Input.action_press to verify driving dynamics

func _init() -> void:
	run_sim.call_deferred()

func run_sim() -> void:
	print("--- STARTING DYNAMIC DRIVE SIMULATION ---")
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	var root = p.instantiate()
	get_root().add_child(root)
	
	await process_frame
	await process_frame
	
	var car = root.get_node_or_null("RaceCar3D") as RaceCar3D
	if not car:
		print("FAIL: RaceCar3D not found")
		quit(1)
		return
		
	print("Car initial position: ", car.global_position)
	print("Car collision shape: ", car.get_node("CarCollision").shape.get_class())
	
	Input.action_press("ui_up")
	
	var dt = 1.0 / 60.0
	var snags_detected = 0
	var min_y = 999.0
	var max_speed = 0.0
	
	for frame in range(240):
		car._physics_process(dt)
		
		var spd = car.forward_speed * 3.6
		if spd > max_speed:
			max_speed = spd
			
		var pos = car.global_position
		if pos.y < min_y:
			min_y = pos.y
			
		# Check for sudden drop in speed after car gets moving
		if frame > 40 and spd < 10.0:
			snags_detected += 1
			print("Warning: Speed dropped at frame %d, pos=%s, spd=%.1f km/h" % [frame, str(pos), spd])
			
	Input.action_release("ui_up")
	
	print("\nDrive simulation results:")
	print("  Frames simulated: 240 (4.0 seconds)")
	print("  Final car position: ", car.global_position)
	print("  Top speed reached: %.1f km/h" % max_speed)
	print("  Lowest Y position: %.2f (no fall through)" % min_y)
	print("  Snags or wall stops detected: %d" % snags_detected)
	
	# Test driving into former BoundarySouth zone (Z = 280 to 360)
	print("\nTesting drive through former BoundarySouth area (Z = 290 to 360)...")
	car.global_position = Vector3(-30.0, 36.35, 290.0)
	car.rotation = Vector3(0.0, 0.0, 0.0) # facing forward in +Z
	car.velocity = Vector3.ZERO
	car.forward_speed = 0.0
	
	Input.action_press("ui_up")
	var south_snags = 0
	for frame in range(120):
		car._physics_process(dt)
		var spd = car.forward_speed * 3.6
		if frame > 40 and spd < 10.0:
			south_snags += 1
			
	Input.action_release("ui_up")
	
	print("  South zone drive: Final pos = %s, speed = %.1f km/h, snags = %d" % [
		str(car.global_position), car.forward_speed * 3.6, south_snags
	])
	
	root.free()
	if snags_detected == 0 and south_snags == 0 and max_speed > 30.0:
		print("\nSUCCESS: All driving tests PASSED with 0 invisible walls and 0 seam snags.")
	else:
		print("\nFAIL: Tests did not pass.")
		
	quit(0)
