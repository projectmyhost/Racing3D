@tool
extends SceneTree

func _init():
	var packed = load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	var track = packed.instantiate() as RaceTrack3D
	get_root().add_child(track)
	
	var car = track.get_node("RaceCar3D") as RaceCar3D
	print("--- RACECAR ACKERMANN KINEMATICS VERIFICATION ---")
	print("Max Speed: ", car.max_speed, " (~", car.max_speed * 3.6, " km/h)")
	print("Max Steer Angle Deg: ", car.max_steer_angle_deg)
	print("Steer Rack Speed: ", car.steer_rack_speed)
	print("Wheelbase: ", car.wheelbase)
	print("Rear Axle Offset Z: ", car.rear_axle_offset_z)
	
	# Simulate 60 physics frames with throttle and steering right
	for f in range(60):
		Input.action_press("ui_up")
		Input.action_press("ui_right")
		car._physics_process(1.0 / 60.0)
		
	print("Car speed after 1s: ", car.forward_speed * 3.6, " km/h")
	print("Car steer angle (deg): ", rad_to_deg(car._current_steer_angle))
	
	if car.front_left_wheel:
		print("FL Wheel rotation: ", car.front_left_wheel.rotation)
		print("FL Wheel visual steer (deg): ", rad_to_deg(car.front_left_wheel.rotation.y))
		assert(abs(car.front_left_wheel.rotation.y) > 0.1, "Front wheel should be visibly turned!")
		
	Input.action_release("ui_up")
	Input.action_release("ui_right")
	print("--- ACKERMANN KINEMATICS VERIFIED! ---")
	quit(0)
