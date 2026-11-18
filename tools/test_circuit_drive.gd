@tool
extends SceneTree

# Circuit drive test steering towards checkpoints

func _init() -> void:
	run_circuit.call_deferred()

func run_circuit() -> void:
	print("--- CIRCUIT DRIVE TEST ---")
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	var root = p.instantiate()
	get_root().add_child(root)
	
	await process_frame
	await process_frame
	
	var car = root.get_node_or_null("RaceCar3D") as RaceCar3D
	var track = root as RaceTrack3D
	
	# Start line: drive East towards Checkpoint 1 (+X direction)
	# Checkpoint 1 is at (120, 38, 146)
	car.global_position = Vector3(-30.0, 36.35, 146.0)
	car.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0) # facing East (+X)
	car.velocity = Vector3.ZERO
	car.forward_speed = 0.0
	
	var dt = 1.0 / 60.0
	var east_max_spd = 0.0
	var east_snags = 0
	
	Input.action_press("ui_up")
	for frame in range(180): # 3 seconds towards East Checkpoint 1
		car._physics_process(dt)
		var spd = car.forward_speed * 3.6
		if spd > east_max_spd:
			east_max_spd = spd
		if frame > 45 and spd < 15.0:
			east_snags += 1
			
	Input.action_release("ui_up")
	
	print("East straightaway towards Checkpoint 1:")
	print("  Final pos: ", car.global_position)
	print("  Max speed: %.1f km/h" % east_max_spd)
	print("  Snags: %d" % east_snags)
	
	# Test driving West towards Checkpoint 3 (-X direction)
	car.global_position = Vector3(50.0, 36.35, 146.0)
	car.rotation = Vector3(0.0, deg_to_rad(-90.0), 0.0) # facing West (-X)
	car.velocity = Vector3.ZERO
	car.forward_speed = 0.0
	
	var west_max_spd = 0.0
	var west_snags = 0
	
	Input.action_press("ui_up")
	for frame in range(180):
		car._physics_process(dt)
		var spd = car.forward_speed * 3.6
		if spd > west_max_spd:
			west_max_spd = spd
		if frame > 45 and spd < 15.0:
			west_snags += 1
			
	Input.action_release("ui_up")
	
	print("\nWest straightaway towards Checkpoint 3:")
	print("  Final pos: ", car.global_position)
	print("  Max speed: %.1f km/h" % west_max_spd)
	print("  Snags: %d" % west_snags)
	
	# Test ramp climb (transition from Y=36 down/up towards lower city)
	# Ramp is around X=0 to 80, Z=0 to -150
	print("\nTesting slope/ramp drive...")
	car.global_position = Vector3(45.0, 36.35, 80.0)
	car.rotation = Vector3(0.0, deg_to_rad(180.0), 0.0) # facing North (-Z) towards ramp
	car.velocity = Vector3.ZERO
	car.forward_speed = 0.0
	
	var ramp_max_spd = 0.0
	var ramp_snags = 0
	
	Input.action_press("ui_up")
	for frame in range(180):
		car._physics_process(dt)
		var spd = car.forward_speed * 3.6
		if spd > ramp_max_spd:
			ramp_max_spd = spd
		if frame > 45 and spd < 10.0:
			ramp_snags += 1
			
	Input.action_release("ui_up")
	
	print("Ramp climb / descent results:")
	print("  Final pos: ", car.global_position)
	print("  Max speed: %.1f km/h" % ramp_max_spd)
	print("  Lowest Y: %.2f" % car.global_position.y)
	print("  Snags: %d" % ramp_snags)
	
	root.free()
	
	var all_ok = (east_snags == 0 and west_snags == 0 and ramp_snags == 0)
	if all_ok:
		print("\n>>> ALL TRACK SECTORS PASSED WITH ZERO SNAGS AND ZERO INVISIBLE WALLS! <<<")
	else:
		print("\n>>> WARNING: Snags were recorded. <<<")
		
	quit(0)

