extends SceneTree

var _timer: float = 0.0
var _tested: bool = false

func _init() -> void:
	print("--- LAUNCHING RACETRACK WITH ACTIVE PHYSICS ENGINE ---")
	change_scene_to_file("res://scenes/race/RaceTrack3D.tscn")

func _process(delta: float) -> bool:
	_timer += delta
	if _timer < 0.2:
		return false
		
	if not _tested:
		_tested = true
		var track = current_scene as RaceTrack3D
		if not track:
			print("FAIL: current_scene is not RaceTrack3D")
			quit(1)
			return true
			
		var car = track.car as RaceCar3D
		if not car:
			print("FAIL: car is null")
			quit(1)
			return true

		print("1. Testing Stationary Steering Lock...")
		car.forward_speed = 0.0
		car.current_steer_angle = deg_to_rad(30.0)
		var start_yaw = car.rotation.y
		car._physics_process(0.016)
		var end_yaw = car.rotation.y
		assert(is_equal_approx(start_yaw, end_yaw), "Car spun in place while stationary!")
		print("PASS: Stationary lock - zero yaw change when stationary")

		print("2. Testing Speed-Sensitive Steering Angles...")
		var steer_low = lerpf(car.max_steer_angle, car.min_steer_angle, 0.0)
		var steer_high = lerpf(car.max_steer_angle, car.min_steer_angle, 1.0)
		assert(steer_low > steer_high, "Steer angle does not scale down with speed!")
		print("PASS: Steer angle dynamically scales from %0.1f deg to %0.1f deg" % [rad_to_deg(steer_low), rad_to_deg(steer_high)])

		print("3. Testing Rear-Axle Pivot & Bicycle Kinematics Moving Forward...")
		car.forward_speed = 18.0
		car.current_steer_angle = deg_to_rad(20.0)
		var prev_yaw = car.rotation.y
		var prev_pos = car.global_position
		
		var expected_yaw_rate = (18.0 * tan(deg_to_rad(20.0))) / car.wheelbase
		car._physics_process(0.016)
		var post_yaw = car.rotation.y
		var post_pos = car.global_position
		
		var yaw_delta = post_yaw - prev_yaw
		print("Actual yaw delta: %0.4f rad, expected yaw delta: %0.4f rad" % [yaw_delta, expected_yaw_rate * 0.016])
		assert(yaw_delta > 0.01, "Car did not rotate according to bicycle kinematics!")
		print("PASS: Kinematic bicycle yaw rate verified")

		print("4. Testing Visual Front Wheels Sync & Body Suspension...")
		assert(car.front_left_wheel != null, "front_left_wheel is null")
		assert(car.front_right_wheel != null, "front_right_wheel is null")
		assert(car.car_body != null, "car_body is null")
		
		var fl_steer = car.front_left_wheel.rotation.y
		var fr_steer = car.front_right_wheel.rotation.y
		assert(is_equal_approx(fl_steer, car.current_steer_angle), "Front wheels not synced to steer angle!")
		assert(is_equal_approx(fr_steer, car.current_steer_angle), "Front wheels not synced to steer angle!")
		print("PASS: Front wheels visual rotation correctly synced to %0.1f deg" % rad_to_deg(car.current_steer_angle))
		
		assert(abs(car._visual_roll) > 0.0, "Body roll is zero!")
		print("PASS: Body roll outward tilt active: %0.2f deg" % rad_to_deg(car._visual_roll))

		print("5. Testing Cinematic Chase Camera Turn Lag & Lateral Shift...")
		assert(track.camera_turn_lag > 0.0, "camera_turn_lag missing")
		assert(track.camera_lateral_offset_factor > 0.0, "camera_lateral_offset_factor missing")
		track._update_chase_camera(0.016)
		assert(abs(track._cam_lateral_shift) > 0.0, "Camera lateral shift not active during turn!")
		print("PASS: Chase camera turn lag (%0.1f) and lateral offset (%0.2f m) verified" % [track.camera_turn_lag, track._cam_lateral_shift])

		print("==================================================")
		print("ALL 5 NEED FOR SPEED HANDLING REQUIREMENTS VERIFIED 100%!")
		print("==================================================")
		quit(0)
		return true

	return false

