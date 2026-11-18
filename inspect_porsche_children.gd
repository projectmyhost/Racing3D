@tool
extends SceneTree

func _init():
	var scene = load("res://assets/models/cars/car_porsche_carrera_gt.tscn")
	var inst = scene.instantiate()
	var model = inst.get_node("Body/ModelWrapper/Model")
	for child in model.get_children():
		print("Model child: ", child.name, " (", child.get_class(), ") pos=", child.position)
		if child.name.contains("Wheel"):
			for sub in child.get_children():
				print("  sub: ", sub.name, " pos=", sub.position)
				for sub2 in sub.get_children():
					print("    sub2: ", sub2.name, " pos=", sub2.position)
	inst.free()
	quit(0)
