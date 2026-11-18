@tool
extends SceneTree

func _init():
	var scene = load("res://assets/models/cars/car_porsche_carrera_gt.tscn")
	var inst = scene.instantiate()
	var comb = inst.find_child("Combined_Wheels_3D_", true, false)
	if comb:
		for c in comb.get_children():
			print("comb child: ", c.name, " (", c.get_class(), ") pos=", c.position, " rot=", c.rotation_degrees, " scale=", c.scale)
			for sub in c.get_children():
				print("    child: ", sub.name, " (", sub.get_class(), ") pos=", sub.position)
	inst.free()
	quit(0)
