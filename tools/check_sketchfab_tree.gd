@tool
extends SceneTree

# Check Sketchfab_model children and transforms

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var p = load(path) as PackedScene
	var inst = p.instantiate()
	var sm = inst.get_node_or_null("Sketchfab_model")
	if sm:
		print("Sketchfab_model transform: ", sm.transform)
		for c in sm.get_children():
			print("  c: ", c.name, " transform: ", c.transform)
			for gc in c.get_children():
				print("    gc: ", gc.name, " transform: ", gc.transform)
				break
			break
	inst.free()
	quit(0)

