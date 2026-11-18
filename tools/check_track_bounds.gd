@tool
extends SceneTree

# Check bounds of RoadSurfacesCollision and boundaries in RaceTrack3D.tscn

func _init() -> void:
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var scene = load(path)
	var root = scene.instantiate()
	
	var tc = root.get_node_or_null("TrackColliders")
	if tc:
		var road_col = tc.get_node_or_null("RoadSurfacesCollision") as CollisionShape3D
		if road_col and road_col.shape is ConcavePolygonShape3D:
			var faces = (road_col.shape as ConcavePolygonShape3D).get_faces()
			var aabb = AABB()
			if faces.size() > 0:
				aabb = AABB(faces[0], Vector3.ZERO)
				for pt in faces:
					aabb = aabb.expand(pt)
			print("RoadSurfacesCollision AABB: ", aabb)
			print("  Min: ", aabb.position, " Max: ", aabb.position + aabb.size)
			
		for c in tc.get_children():
			if c != road_col and c is CollisionShape3D:
				var s = c.shape
				var s_size = s.size if s is BoxShape3D else Vector3.ZERO
				var pos = c.position
				print("Collider %s: pos=%s, size=%s" % [c.name, str(pos), str(s_size)])
				print("  Range X: [%.1f, %.1f], Y: [%.1f, %.1f], Z: [%.1f, %.1f]" % [
					pos.x - s_size.x/2, pos.x + s_size.x/2,
					pos.y - s_size.y/2, pos.y + s_size.y/2,
					pos.z - s_size.z/2, pos.z + s_size.z/2
				])
				
	root.free()
	quit(0)

