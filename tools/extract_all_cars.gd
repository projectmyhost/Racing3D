@tool
extends SceneTree

const CAR_DEFINITIONS = {
	"sedan": {
		"name": "Sedan Prime",
		"body_node": "Sedan Body",
		"wheels": ["Wheel_A", "Wheel_A001", "Wheel_A002", "Wheel_A003"]
	},
	"sport": {
		"name": "Super Sport GT",
		"body_node": "Sport body",
		"wheels": ["Wheel_H", "Wheel_H001", "Wheel_H002", "Wheel_H003"]
	},
	"coupe": {
		"name": "Apex Coupe",
		"body_node": "Coupe Body",
		"wheels": ["Wheel_F", "Wheel_F001", "Wheel_F002", "Wheel_F003"]
	},
	"compact": {
		"name": "Urban Compact",
		"body_node": "Compact Body",
		"wheels": ["Wheel_C", "Wheel_C001", "Wheel_C002", "Wheel_C003"]
	},
	"hatchback": {
		"name": "Speed Hatchback",
		"body_node": "Hatchback Body",
		"wheels": ["Wheel_B", "Wheel_B001", "Wheel_B002", "Wheel_B003"]
	},
	"pickup": {
		"name": "Titan Pickup",
		"body_node": "Pickup Body",
		"wheels": ["Wheel_E", "Wheel_E001", "Wheel_E002", "Wheel_E003"]
	},
	"offroad": {
		"name": "Tracker 4x4",
		"body_node": "Offroad Body",
		"wheels": ["Wheel_G", "Wheel_G001", "Wheel_G002", "Wheel_G003"]
	},
	"minivan": {
		"name": "Turbo Minivan",
		"body_node": "minivan body",
		"wheels": ["Wheel_D", "Wheel_D001", "Wheel_D002", "Wheel_D003"]
	},
	"suv": {
		"name": "Grand SUV",
		"body_node": "SUV Body",
		"wheels": ["Wheel_E2", "Wheel_E0012", "Wheel_E0022", "Wheel_E0032"]
	},
	"wagon": {
		"name": "Touring Wagon",
		"body_node": "Wagon Body",
		"wheels": ["Wheel_A2", "Wheel_A0012", "Wheel_A0022", "Wheel_A0032"]
	}
}

func _init():
	var glb_path = "res://assets/models/cars/generic_passenger_car_pack.glb"
	var glb_scene = load(glb_path) as PackedScene
	if not glb_scene:
		print("ERROR: Failed to load ", glb_path)
		quit(1)
		return
		
	var source_root = glb_scene.instantiate()
	var root_node = source_root.find_child("RootNode", true, false)
	if not root_node:
		root_node = source_root

	print("--- EXTRACTING ALL 10 CARS FROM generic_passenger_car_pack.glb ---")
	
	var rot_basis = Basis.from_euler(Vector3(deg_to_rad(-90.0), deg_to_rad(180.0), 0.0))
	
	for car_id in CAR_DEFINITIONS.keys():
		var def = CAR_DEFINITIONS[car_id]
		var body_src = root_node.find_child(def["body_node"], false, false) as Node3D
		if not body_src:
			print("WARNING: Body node not found: ", def["body_node"])
			continue
			
		var car_root = Node3D.new()
		car_root.name = car_id
		
		# Body container placed at (0, 0, 0)
		var body_container = Node3D.new()
		body_container.name = "Body"
		body_container.position = Vector3.ZERO
		body_container.rotation_degrees = Vector3(-90.0, 180.0, 0.0)
		body_container.scale = Vector3(0.001, 0.001, 0.001)
		car_root.add_child(body_container)
		body_container.owner = car_root
		
		# Clone body meshes into Body
		for child in body_src.get_children():
			if child is MeshInstance3D:
				var m = MeshInstance3D.new()
				m.name = child.name
				m.mesh = child.mesh
				m.skin = child.skin
				for surf in range(child.get_surface_override_material_count()):
					m.set_surface_override_material(surf, child.get_surface_override_material(surf))
				body_container.add_child(m)
				m.owner = car_root
		
		# Find wheel nodes in glb
		var wheel_src_nodes = []
		for wn in def["wheels"]:
			var w_src = root_node.find_child(wn, false, false) as Node3D
			if w_src:
				wheel_src_nodes.append(w_src)
		
		# Compute transform of wheel in body coordinate space, then rotate to Godot car space
		var body_inv = body_src.transform.affine_inverse()
		for w_src in wheel_src_nodes:
			var local_body_pos = (body_inv * w_src.position) * 0.001
			var vehicle_pos = rot_basis * local_body_pos
			
			var is_front = vehicle_pos.z < 0.0
			var is_left = vehicle_pos.x < 0.0
			
			var role_name = ""
			if is_front and is_left: role_name = "Wheel_FL"
			elif is_front and not is_left: role_name = "Wheel_FR"
			elif not is_front and is_left: role_name = "Wheel_RL"
			else: role_name = "Wheel_RR"
			
			var w_node = Node3D.new()
			w_node.name = role_name
			w_node.position = vehicle_pos
			w_node.rotation_degrees = Vector3.ZERO
			car_root.add_child(w_node)
			w_node.owner = car_root
			
			# Inside w_node, add the wheel mesh with native rotation and 0.001 scale
			for wc in w_src.get_children():
				if wc is MeshInstance3D:
					var wm = MeshInstance3D.new()
					wm.name = "Mesh"
					wm.mesh = wc.mesh
					wm.rotation_degrees = Vector3(-90.0, 180.0, 0.0)
					wm.scale = Vector3(0.001, 0.001, 0.001)
					w_node.add_child(wm)
					wm.owner = car_root
				elif wc is Node3D:
					for wcc in wc.get_children():
						if wcc is MeshInstance3D:
							var wm = MeshInstance3D.new()
							wm.name = "Mesh"
							wm.mesh = wcc.mesh
							wm.rotation_degrees = Vector3(-90.0, 180.0, 0.0)
							wm.scale = Vector3(0.001, 0.001, 0.001)
							w_node.add_child(wm)
							wm.owner = car_root
							
		# Save PackedScene to assets/models/cars/car_<id>.tscn
		var packed = PackedScene.new()
		var pack_err = packed.pack(car_root)
		if pack_err == OK:
			var save_path = "res://assets/models/cars/car_" + car_id + ".tscn"
			var save_err = ResourceSaver.save(packed, save_path)
			if save_err == OK:
				print("Extracted & Saved: ", save_path)
			else:
				print("ERROR saving: ", save_path, " code: ", save_err)
		else:
			print("ERROR packing: ", car_id, " code: ", pack_err)
			
	print("ALL 10 VEHICLES EXTRACTED SUCCESSFULLY!")
	quit(0)
