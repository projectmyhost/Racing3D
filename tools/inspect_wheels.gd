@tool
extends SceneTree

func _init():
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_file("res://assets/models/cars/mclaren_650s_gt3/source/mclaren_650s_gt3.glb", state)
	var scene = gltf.generate_scene(state)
	
	for name in ["Mesh_12", "Mesh_13", "Mesh_14", "Mesh_5"]:
		var m = scene.get_node_or_null(name) as MeshInstance3D
		if m and m.mesh:
			print(name, " surfaces: ", m.mesh.get_surface_count())
			for s in range(m.mesh.get_surface_count()):
				var arr = m.mesh.surface_get_arrays(s)
				var verts = arr[Mesh.ARRAY_VERTEX] as PackedVector3Array
				var aabb = AABB()
				if verts.size() > 0:
					aabb.position = verts[0]
					for v in verts:
						aabb = aabb.expand(v)
				print("  surface ", s, ": verts=", verts.size(), " aabb=", aabb)
	quit(0)

