@tool
extends SceneTree

# Verify RaceTrack3D scene loads and CollisionGuard executes without errors

const CollisionGuard = preload("res://scripts/race/CollisionGuard.gd")

func _init() -> void:
	test_load.call_deferred()

func test_load() -> void:
	print("--- VERIFYING RACETRACK3D SCENE & COLLISION GUARD ---")
	var path = "res://scenes/race/RaceTrack3D.tscn"
	var p = load(path) as PackedScene
	if not p:
		print("FAIL: cannot load scene")
		quit(1)
		return
		
	var root = p.instantiate()
	get_root().add_child(root)
	
	await process_frame
	await process_frame
	
	print("Scene instantiated successfully.")
	
	# Verify TrackColliders
	var tc = root.get_node_or_null("TrackColliders")
	if tc:
		for c in tc.get_children():
			if c is CollisionShape3D:
				var s = c.shape
				var s_type = s.get_class() if s else "null"
				var info = ""
				if s is ConcavePolygonShape3D:
					info = "triangles=" + str((s as ConcavePolygonShape3D).get_faces().size() / 3)
				elif s is BoxShape3D:
					info = "size=" + str((s as BoxShape3D).size)
				print("  TrackCollider: %s | Shape: %s (%s) | pos: %s" % [c.name, s_type, info, str(c.position)])
				
	# Verify CarCollision
	var car = root.get_node_or_null("RaceCar3D") as CharacterBody3D
	if car:
		var col = car.get_node_or_null("CarCollision") as CollisionShape3D
		if col:
			var s = col.shape
			print("  RaceCar3D Collision: %s | points: %d | pos: %s" % [
				s.get_class() if s else "null",
				(s as ConvexPolygonShape3D).points.size() if s is ConvexPolygonShape3D else 0,
				str(col.position)
			])
		print("  RaceCar3D safe_margin: %.3f | floor_snap: %.2f | floor_max_angle: %.2f" % [
			car.safe_margin, car.floor_snap_length, car.floor_max_angle
		])
		
	# Execute CollisionGuard directly to test output
	var stats = CollisionGuard.run_guard(root)
	print("Guard results: ", stats)
	
	root.free()
	print("--- VERIFICATION COMPLETE ---")
	quit(0)
