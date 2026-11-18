@tool
extends SceneTree

func _init():
	var glb_path = "res://assets/models/cars/generic_passenger_car_pack.glb"
	var glb_scene = load(glb_path) as PackedScene
	var root_inst = glb_scene.instantiate()
	var nodes: Array[Node] = []
	_collect(root_inst, nodes)
	var f = FileAccess.open("docs/validation/glb_node_dump.txt", FileAccess.WRITE)
	for n in nodes:
		if n is Node3D:
			f.store_line("'%s' [%s] pos=(%.2f, %.2f, %.2f) rot=(%.1f, %.1f, %.1f)" % [n.name, n.get_class(), n.position.x, n.position.y, n.position.z, n.rotation_degrees.x, n.rotation_degrees.y, n.rotation_degrees.z])
	f.close()
	print("Dumped to docs/validation/glb_node_dump.txt")
	quit(0)

func _collect(n: Node, list: Array[Node]):
	list.append(n)
	for c in n.get_children():
		_collect(c, list)

