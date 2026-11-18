@tool
extends SceneTree

# Tool to fix collisions in environment prefabs

func _init() -> void:
	print("--- FIXING ENVIRONMENT PREFAB SCENES ---")
	fix_barrier_jersey()
	fix_road_plaza()
	fix_highway_straight()
	fix_highway_curve()
	fix_fence_chainlink()
	fix_streetlamp()
	fix_streetlamp_double()
	fix_billboard()
	print("--- ENVIRONMENT PREFABS FIXED ---")
	quit(0)

func fix_barrier_jersey() -> void:
	var path = "res://assets/environments/props/barrier/env_prop_barrier_jersey_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	# Remove orphan StaticBody3D without shapes
	var to_remove = []
	for c in root.get_children():
		if c is StaticBody3D:
			to_remove.append(c)
	for c in to_remove:
		root.remove_child(c)
		c.free()
		
	# Add proper StaticBody3D with 1:1 BoxShape3D
	var sb = StaticBody3D.new()
	sb.name = "BarrierStaticBody"
	root.add_child(sb)
	sb.owner = root
	
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box = BoxShape3D.new()
	box.size = Vector3(0.45, 0.82, 3.0)
	col.shape = box
	col.position = Vector3(0.0, 0.41, 0.0)
	sb.add_child(col)
	col.owner = root
	
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func fix_road_plaza() -> void:
	var path = "res://assets/environments/road/env_road_plaza_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	var mesh_node = root.get_node_or_null("PlazaMesh") as MeshInstance3D
	var old_col = root.get_node_or_null("PlazaCollision")
	if old_col:
		root.remove_child(old_col)
		old_col.free()
		
	if mesh_node and mesh_node.mesh:
		var sb = StaticBody3D.new()
		sb.name = "PlazaCollision"
		root.add_child(sb)
		sb.owner = root
		
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(mesh_node.mesh.get_faces())
		col.shape = shape
		sb.add_child(col)
		col.owner = root
		
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func fix_highway_straight() -> void:
	var path = "res://assets/environments/highway/env_highway_straight_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	var old_sb = root.get_node_or_null("HighwayStaticBody")
	if old_sb:
		root.remove_child(old_sb)
		old_sb.free()
		
	var sb = StaticBody3D.new()
	sb.name = "HighwayStaticBody"
	root.add_child(sb)
	sb.owner = root
	
	# Trimesh for deck to prevent seam lips
	var deck = root.get_node_or_null("StraightDeck") as MeshInstance3D
	if deck and deck.mesh:
		var col_deck = CollisionShape3D.new()
		col_deck.name = "DeckCollision"
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(deck.mesh.get_faces())
		col_deck.shape = shape
		col_deck.transform = deck.transform
		sb.add_child(col_deck)
		col_deck.owner = root
		
	# Individual colliders for guardrails
	var gl = root.get_node_or_null("Guardrail_L") as MeshInstance3D
	if gl and gl.mesh:
		var col_gl = CollisionShape3D.new()
		col_gl.name = "GuardrailL_Collision"
		var box = BoxShape3D.new()
		box.size = Vector3(0.2, 0.8, 90.0)
		col_gl.shape = box
		col_gl.transform = gl.transform
		sb.add_child(col_gl)
		col_gl.owner = root
		
	var gr = root.get_node_or_null("Guardrail_R") as MeshInstance3D
	if gr and gr.mesh:
		var col_gr = CollisionShape3D.new()
		col_gr.name = "GuardrailR_Collision"
		var box = BoxShape3D.new()
		box.size = Vector3(0.2, 0.8, 90.0)
		col_gr.shape = box
		col_gr.transform = gr.transform
		sb.add_child(col_gr)
		col_gr.owner = root
		
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func fix_highway_curve() -> void:
	var path = "res://assets/environments/highway/env_highway_curve_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	var old_sb = root.get_node_or_null("HighwayCurveStaticBody")
	if old_sb:
		root.remove_child(old_sb)
		old_sb.free()
		
	var sb = StaticBody3D.new()
	sb.name = "HighwayCurveStaticBody"
	root.add_child(sb)
	sb.owner = root
	
	# Extract all deck segment faces into Trimesh ConcavePolygonShape3D
	var all_deck_faces: PackedVector3Array = PackedVector3Array()
	for child in root.get_children():
		if child is MeshInstance3D and child.name.begins_with("DeckSeg_") and child.mesh:
			var faces = child.mesh.get_faces()
			var t = child.transform
			for v in faces:
				all_deck_faces.append(t * v)
				
	if all_deck_faces.size() > 0:
		var col_deck = CollisionShape3D.new()
		col_deck.name = "DeckCurveCollision"
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(all_deck_faces)
		col_deck.shape = shape
		sb.add_child(col_deck)
		col_deck.owner = root
		
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func fix_fence_chainlink() -> void:
	var path = "res://assets/environments/props/fence/env_prop_fence_chainlink_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	var old_sb = root.get_node_or_null("FenceStaticBody")
	if old_sb:
		root.remove_child(old_sb)
		old_sb.free()
		
	var sb = StaticBody3D.new()
	sb.name = "FenceStaticBody"
	root.add_child(sb)
	sb.owner = root
	
	var col_panel = CollisionShape3D.new()
	col_panel.name = "PanelCollision"
	var box = BoxShape3D.new()
	box.size = Vector3(3.0, 2.4, 0.08)
	col_panel.shape = box
	col_panel.position = Vector3(0.0, 1.2, 0.0)
	sb.add_child(col_panel)
	col_panel.owner = root
	
	var col_post = CollisionShape3D.new()
	col_post.name = "PostCollision"
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.05
	cyl.height = 2.4
	col_post.shape = cyl
	col_post.position = Vector3(1.5, 1.2, 0.0)
	sb.add_child(col_post)
	col_post.owner = root
	
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func fix_streetlamp() -> void:
	var path = "res://assets/environments/props/streetlamp/env_prop_streetlamp_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	var old_sb = root.get_node_or_null("StreetlampStaticBody")
	if old_sb:
		root.remove_child(old_sb)
		old_sb.free()
		
	var sb = StaticBody3D.new()
	sb.name = "StreetlampStaticBody"
	root.add_child(sb)
	sb.owner = root
	
	# Only pole on ground has collision, overhead arm is open
	var col_pole = CollisionShape3D.new()
	col_pole.name = "PoleCollision"
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.18
	cyl.height = 9.0
	col_pole.shape = cyl
	col_pole.position = Vector3(0.0, 4.5, 0.0)
	sb.add_child(col_pole)
	col_pole.owner = root
	
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func fix_streetlamp_double() -> void:
	var path = "res://assets/environments/props/streetlamp/env_prop_streetlamp_double_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	var old_sb = root.get_node_or_null("StreetlampDoubleStaticBody")
	if old_sb:
		root.remove_child(old_sb)
		old_sb.free()
		
	var sb = StaticBody3D.new()
	sb.name = "StreetlampDoubleStaticBody"
	root.add_child(sb)
	sb.owner = root
	
	var col_pole = CollisionShape3D.new()
	col_pole.name = "PoleCollision"
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.22
	cyl.height = 10.0
	col_pole.shape = cyl
	col_pole.position = Vector3(0.0, 5.0, 0.0)
	sb.add_child(col_pole)
	col_pole.owner = root
	
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func fix_billboard() -> void:
	var path = "res://assets/environments/props/billboard/env_prop_billboard_01.tscn"
	var p = load(path) as PackedScene
	if not p: return
	var root = p.instantiate()
	get_root().add_child(root)
	
	var old_sb = root.get_node_or_null("BillboardStaticBody")
	if old_sb:
		root.remove_child(old_sb)
		old_sb.free()
		
	var sb = StaticBody3D.new()
	sb.name = "BillboardStaticBody"
	root.add_child(sb)
	sb.owner = root
	
	# Only pole collides on ground level
	var col_pole = CollisionShape3D.new()
	col_pole.name = "PoleCollision"
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.40
	cyl.height = 9.0
	col_pole.shape = cyl
	col_pole.position = Vector3(0.0, 4.5, 0.0)
	sb.add_child(col_pole)
	col_pole.owner = root
	
	# Upper frame sign
	var col_sign = CollisionShape3D.new()
	col_sign.name = "SignCollision"
	var box = BoxShape3D.new()
	box.size = Vector3(14.4, 6.4, 0.3)
	col_sign.shape = box
	col_sign.position = Vector3(0.0, 9.0, 0.0)
	sb.add_child(col_sign)
	col_sign.owner = root
	
	save_scene(root, path)
	root.free()
	print("Fixed: ", path)

func save_scene(root: Node, path: String) -> void:
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err == OK:
		ResourceSaver.save(packed, path)
	else:
		print("Error packing: ", path, " err=", err)

