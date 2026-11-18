@tool
extends SceneTree

func _init():
	print("--- INSPECTING CAR MODELS ---")
	inspect_model("res://assets/models/cars/car_kia_carnival.tscn", "kia_carnival")
	inspect_model("res://assets/models/cars/car_porsche_carrera_gt.tscn", "porsche_carrera_gt")
	quit(0)

func inspect_model(path: String, id: String):
	print("\n================== ", id, " ==================")
	var scene = load(path)
	if not scene:
		print("FAILED TO LOAD ", path)
		return
	var inst = scene.instantiate()
	dump_node(inst, "")
	inst.free()

func dump_node(node: Node, indent: String):
	var info = indent + "- " + node.name + " (" + node.get_class() + ")"
	if node is Node3D:
		info += " pos=" + str(node.position) + " rot=" + str(node.rotation_degrees) + " scale=" + str(node.scale)
	if node is MeshInstance3D:
		info += " [MeshInstance3D]"
		if node.mesh:
			info += " surf_count=" + str(node.mesh.get_surface_count())
			for s in range(node.mesh.get_surface_count()):
				var mat = node.get_surface_override_material(s)
				if not mat:
					mat = node.mesh.surface_get_material(s)
				if mat:
					info += " [s" + str(s) + ":" + mat.resource_name + "/" + mat.get_class() + "]"
	print(info)
	for child in node.get_children():
		dump_node(child, indent + "  ")
