@tool
extends SceneTree

var frame_count: int = 0
var track: RaceTrack3D
var car: RaceCar3D

func _init():
	var packed = load("res://scenes/race/RaceTrack3D.tscn") as PackedScene
	track = packed.instantiate() as RaceTrack3D
	get_root().add_child(track)
	car = track.get_node("RaceCar3D") as RaceCar3D
	process_frame.connect(_on_frame)

func _on_frame():
	frame_count += 1
	# Drive and steer right
	Input.action_press("ui_up")
	Input.action_press("ui_right")
	
	if frame_count == 40:
		Input.action_release("ui_up")
		Input.action_release("ui_right")
		var vp = get_root().get_viewport()
		var img = vp.get_texture().get_image()
		img.save_png("docs/validation/race_car_turning_smooth.png")
		print("Saved docs/validation/race_car_turning_smooth.png!")
		print("Car pos: ", car.global_position)
		print("Car rot Y: ", rad_to_deg(car.rotation.y))
		print("Front Wheel rot Y: ", rad_to_deg(car.front_left_wheel.rotation.y) if car.front_left_wheel else 0)
		quit(0)

