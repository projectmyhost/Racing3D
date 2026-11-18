@tool
extends SceneTree

func _init():
	var glb_path = "res://assets/models/cars/generic_passenger_car_pack.glb"
	var scene = load(glb_path) as PackedScene
	var inst = scene.instantiate()
	var root_node = inst.find_child("RootNode", true, false)
	if not root_node:
		root_node = inst
	print("Found root_node: ", root_node.name)
	for c in root_node.get_children():
		print("CAR/GROUP: ", c.name, " Type: ", c.get_class(), " Children: ", c.get_child_count())
		for cc in c.get_children():
			print("   child: ", cc.name, " (", cc.get_class(), ")")
	quit(0)

