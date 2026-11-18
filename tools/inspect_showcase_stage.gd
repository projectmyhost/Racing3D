@tool
extends SceneTree

# Inspect showcase_stage.tscn

func _init() -> void:
	var path = "res://scenes/environment/showcase_stage.tscn"
	var p = load(path) as PackedScene
	if not p:
		print("Could not load")
		quit(0)
		return
	var inst = p.instantiate()
	print_tree(inst, "")
	inst.free()
	quit(0)

func print_tree(node: Node, indent: String) -> void:
	print("%s%s (%s) visible=%s" % [indent, node.name, node.get_class(), str(node.get("visible") if "visible" in node else "n/a")])
	for c in node.get_children():
		print_tree(c, indent + "  ")

