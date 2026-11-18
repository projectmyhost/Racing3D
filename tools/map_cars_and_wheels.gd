@tool
extends SceneTree

func _init():
	var glb_path = "res://assets/models/cars/generic_passenger_car_pack.glb"
	var scene = load(glb_path) as PackedScene
	var inst = scene.instantiate()
	var root_node = inst.find_child("RootNode", true, false)
	
	print("--- ALL BODIES ---")
	var bodies = []
	var wheels = []
	for c in root_node.get_children():
		if "body" in c.name.to_lower():
			bodies.append(c)
		elif "wheel" in c.name.to_lower():
			wheels.append(c)
			
	for b in bodies:
		print("BODY: '", b.name, "' pos=", b.position, " rot=", b.rotation_degrees)
	print("\n--- ALL WHEELS ---")
	for w in wheels:
		print("WHEEL: '", w.name, "' pos=", w.position, " rot=", w.rotation_degrees)
	quit(0)

