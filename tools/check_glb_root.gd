@tool
extends SceneTree

# Check Untitled.glb root node transform

func _init() -> void:
	var path = "res://assets/models/environment/city_map/source/Untitled.glb"
	var p = load(path) as PackedScene
	var inst = p.instantiate()
	print("Untitled.glb root name: ", inst.name)
	print("Untitled.glb root transform: ", inst.transform)
	for c in inst.get_children():
		print("  child: ", c.name, " transform: ", c.transform)
		break
	inst.free()
	quit(0)

