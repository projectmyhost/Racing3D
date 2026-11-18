@tool
extends SceneTree

func _init():
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	var err = gltf.append_from_file("assets/source/untitled.glb", state)
	var root = gltf.generate_scene(state)
	
	var mesh_node: MeshInstance3D = root.get_node("f1_2026_rb22")
	print("Mesh node transform: ", mesh_node.transform)
	print("Mesh node rotation_degrees: ", mesh_node.rotation_degrees)
	
	# Let's inspect vertices of the mesh to see where the front, back, bottom, top are
	var m = mesh_node.mesh
	var aabb = m.get_aabb()
	print("Mesh AABB: min=", aabb.position, " max=", aabb.position + aabb.size)
	
	# Test with rot.x = -90 or rot.x = 90
	# In Blender/DCC, +Y is usually up or forward, -Z is forward.
	# When rot is (90, 0, 0):
	# vertex (x, y, z) transformed by rot(90, 0, 0):
	# new_x = x
	# new_y = -z
	# new_z = y
	# Let's check:
	var t = mesh_node.transform
	var p_front = t * Vector3(0, aabb.position.y + aabb.size.y, 0)
	var p_back = t * Vector3(0, aabb.position.y, 0)
	var p_bottom = t * Vector3(0, 0, aabb.position.z)
	var p_top = t * Vector3(0, 0, aabb.position.z + aabb.size.z)
	print("Front point (y max): ", p_front)
	print("Back point (y min): ", p_back)
	print("Z min point: ", p_bottom)
	print("Z max point: ", p_top)
	
	# Check materials and textures
	print("\n--- Surfaces and Materials ---")
	for s in range(m.get_surface_count()):
		var mat = m.surface_get_material(s) as BaseMaterial3D
		if mat:
			var tex_name = "none"
			if mat.albedo_texture:
				tex_name = mat.albedo_texture.resource_path.get_file()
				if tex_name == "":
					tex_name = str(mat.albedo_texture.get_class())
			print("Surface ", s, ": ", mat.resource_name, " -> Albedo Tex: ", tex_name, " Color: ", mat.albedo_color, " Roughness: ", mat.roughness, " Metallic: ", mat.metallic)
	quit(0)
