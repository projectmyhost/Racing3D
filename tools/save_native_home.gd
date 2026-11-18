extends SceneTree

func _init():
	var scene = load("res://scenes/main/home_screen.tscn")
	var home = scene.instantiate()
	var car = home.get_node("ShowcaseCar")
	car.position = Vector3(0.55, 0.0, 0.25)
	car.rotation_degrees = Vector3(0.0, -115.0, 0.0)
	
	var stage = home.get_node("Stage")
	var bb = stage.get_node("Billboard")
	bb.position = Vector3(4.5, -2.6, 15.0)
	bb.rotation_degrees = Vector3(0.0, -155.0, 0.0)
	
	var palm = stage.get_node("HeroPalm")
	palm.position = Vector3(10.5, 0.0, 12.0)
	
	# Pack and save home_screen.tscn
	var packed = PackedScene.new()
	packed.pack(home)
	ResourceSaver.save(packed, "res://scenes/main/home_screen.tscn")
	print("Native save of home_screen.tscn complete!")
	quit(0)
