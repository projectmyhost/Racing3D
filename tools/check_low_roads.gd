@tool
extends SceneTree

# Check roads below Y = 10 in RoadSurfacesCollision

func _init() -> void:
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var scene = load(path)
	var root = scene.instantiate()
	var tc = root.get_node_or_null("TrackColliders")
	var road_col = tc.get_node_or_null("RoadSurfacesCollision") as CollisionShape3D
	var shape = road_col.shape as ConcavePolygonShape3D
	var faces = shape.get_faces()
	
	var below_5: Array[Vector3] = []
	var below_0: Array[Vector3] = []
	for pt in faces:
		if pt.y < 5.85:
			below_5.append(pt)
		if pt.y < 0.0:
			below_0.append(pt)
			
	print("Total road faces points: ", faces.size())
	print("Points below Y=5.85: ", below_5.size())
	print("Points below Y=0.0: ", below_0.size())
	
	if below_5.size() > 0:
		print("Sample points below 5.85:")
		for i in range(mini(10, below_5.size())):
			print("  ", below_5[i])
			
	root.free()
	quit(0)

