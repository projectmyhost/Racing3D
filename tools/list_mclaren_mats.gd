extends SceneTree

func _init() -> void:
	var path = "res://assets/models/cars/car_mclaren.tscn"
	var f = FileAccess.open(path, FileAccess.READ)
	var in_mat = false
	var mat_id = ""
	var mat_name = ""
	var line_num = 0
	while not f.eof_reached():
		line_num += 1
		var line = f.get_line()
		if line.begins_with("[sub_resource type=\"StandardMaterial3D\""):
			in_mat = true
			mat_id = line
			mat_name = ""
		elif in_mat:
			if line.begins_with("resource_name ="):
				mat_name = line
			elif line.begins_with("[sub_resource") or line.begins_with("[node"):
				in_mat = false
			elif line == "":
				print("Line ", line_num, ": ", mat_id, " -> ", mat_name)
				in_mat = false
	f.close()
	quit()

