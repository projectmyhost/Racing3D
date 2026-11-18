@tool
extends SceneTree

func _init():
	var glb_path = "res://assets/models/cars/generic_passenger_car_pack.glb"
	var glb_scene = load(glb_path) as PackedScene
	var root = glb_scene.instantiate()
	var root_node = root.find_child("RootNode", true, false)
	var body_src = root_node.find_child("Sedan Body", false, false) as Node3D
	
	# body_src.rotation_degrees is (-90, 180, 0)
	print("body_src rotation_degrees: ", body_src.rotation_degrees)
	# Check where vertex (0, 0, 1500) goes with body_src's rotation:
	var v_roof = body_src.basis * Vector3(0, 0, 1500)
	print("Roof after basis: ", v_roof)
	var v_front = body_src.basis * Vector3(0, -2000, 500)
	print("Front after basis: ", v_front)
	quit(0)

