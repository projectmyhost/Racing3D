extends Node

func _ready():
	var scene = load("res://assets/models/cars/car_porsche_carrera_gt.tscn")
	var inst = scene.instantiate() as Node3D
	add_child(inst)
	
	var w = inst.find_child("Body7a_Window_Geo_lodA", true, false) as MeshInstance3D
	var mesh = w.mesh as ArrayMesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 1) # surface 1 is C1_Vidrios_Tr
	
	var min_z = 999.0
	var max_z = -999.0
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		min_z = minf(min_z, v.z)
		max_z = maxf(max_z, v.z)
	print("Surface 1 Z range: [", min_z, " to ", max_z, "] (count=", mdt.get_vertex_count(), ")")
	
	# Check where vertices are clustered
	var front_verts = 0
	var mid_verts = 0
	var rear_verts = 0
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.z < -0.01:
			front_verts += 1
		elif v.z > 0.01:
			rear_verts += 1
		else:
			mid_verts += 1
	print("Front verts (z < -0.01): ", front_verts, " mid verts: ", mid_verts, " rear verts: ", rear_verts)
	
	get_tree().quit(0)
