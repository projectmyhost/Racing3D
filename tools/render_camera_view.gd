extends SceneTree

func _init():
	print("Testing ShowcaseCar with GLTFDocument in HomeScreen...")
	var home_scene = load("res://scenes/main/home_screen.tscn")
	var home = home_scene.instantiate()
	root.add_child(home)

var _frames = 0
func _process(delta):
	_frames += 1
	if _frames == 5:
		# Check if car is present
		var home = root.get_node("HomeScreen")
		var car = home.get_node("ShowcaseCar")
		print("ShowcaseCar children count: ", car.get_child_count())
		var vis = car.get_node_or_null("VisualRoot")
		if vis:
			print("VisualRoot children: ", vis.get_child_count())
			for c in vis.get_children():
				if c.name == "CarMesh" or c.name == "untitled":
					print("Found car mesh/model node: ", c.name, " pos: ", c.position, " rot: ", c.rotation_degrees)
	if _frames == 20:
		var vp = root.get_viewport()
		var img = vp.get_texture().get_image()
		img.save_png("docs/validation/test_car_view.png")
		print("Saved docs/validation/test_car_view.png successfully!")
		quit(0)
