@tool
extends SceneTree

func _init():
	find_wheels("res://assets/models/cars/car_kia_carnival.tscn", "kia_carnival")
	find_wheels("res://assets/models/cars/car_porsche_carrera_gt.tscn", "porsche_carrera_gt")
	quit(0)

func find_wheels(path: String, id: String):
	print("\n--- FIND WHEELS IN ", id, " ---")
	var scene = load(path)
	var inst = scene.instantiate()
	search(inst, "")
	inst.free()

func search(node: Node, path: String):
	var cur_path = path + "/" + node.name
	var n_lower = node.name.to_lower()
	if "wheel" in n_lower or "tire" in n_lower or "rim" in n_lower or "whl" in n_lower or "tyre" in n_lower:
		var extra = ""
		if node is Node3D:
			extra = " pos=" + str(node.position) + " rot=" + str(node.rotation_degrees) + " scale=" + str(node.scale)
		print(cur_path, " [", node.get_class(), "]", extra)
	for child in node.get_children():
		search(child, cur_path)
