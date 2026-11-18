@tool
extends SceneTree

# Clean forward East drive from -30 to +120

func _init() -> void:
	run_clean.call_deferred()

func run_clean() -> void:
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	var root = p.instantiate()
	get_root().add_child(root)
	
	await process_frame
	await process_frame
	
	var car = root.get_node_or_null("RaceCar3D") as RaceCar3D
	
	# Start line: X = -30, Y = 36.35, Z = 146
	# Facing East (+X), which in Godot is rotation.y = -PI/2 (-90 deg)
	car.global_position = Vector3(-30.0, 36.35, 146.0)
	car.rotation = Vector3(0.0, -deg_to_rad(90.0), 0.0)
	car.velocity = Vector3.ZERO
	car.forward_speed = 0.0
	
	var dt = 1.0 / 60.0
	var max_spd = 0.0
	var snags = 0
	
	Input.action_press("ui_up")
	for frame in range(120): # 2 seconds to reach ~100m
		car._physics_process(dt)
		var spd = car.forward_speed * 3.6
		if spd > max_spd: max_spd = spd
		if frame > 40 and spd < 15.0:
			snags += 1
	Input.action_release("ui_up")
	
	print("Start-to-Checkpoint1 (East) Drive:")
	print("  Start Pos: (-30, 36.35, 146)")
	print("  Final Pos: ", car.global_position)
	print("  Max Speed: %.1f km/h" % max_spd)
	print("  Snags: %d" % snags)
	
	root.free()
	if snags == 0 and max_spd > 50.0:
		print("SUCCESS: 0 snags, smooth drive!")
	quit(0)

